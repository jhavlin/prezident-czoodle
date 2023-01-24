module Results exposing (..)

import Array exposing (Array)
import Browser
import Candidates
import Chart as C
import Chart.Attributes as CA
import Component exposing (ariaLabel)
import FeatherIcons
import Html exposing (Html, a, button, div, h1, p, section, span, text)
import Html.Attributes exposing (class, disabled, href, title)
import Html.Events exposing (onClick)
import Http
import Json.Decode as D
import Json.Encode
import Polls.Common exposing (Summary(..), Validation(..))
import Polls.D21Poll
import Polls.DividePoll
import Polls.DoodlePoll
import Polls.EmojiPoll
import Polls.OneRoundPoll
import Polls.OrderPoll
import Polls.StarPoll
import Polls.TwoRoundPoll
import Process
import Random
import RandomUtils
import Svg.Attributes
import Task



-- MAIN


main : Program D.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS
-- MODEL


type alias Vote =
    { twoRound : Int
    , oneRound : Int
    , divide : List Int
    , d21 : List Int
    , doodle : List Int
    , order : List Int
    , star : List Int
    , emoji : List String
    }


type alias D21Counts =
    { negatives : Float
    , positives : Float
    , total : Float
    }


type alias Model =
    { votes : List Vote
    }


init : D.Value -> ( Model, Cmd Msg )
init _ =
    ( { votes = [] }, load False )


load : Bool -> Cmd Msg
load all =
    let
        url =
            if all then
                "/api/get_all_votes"

            else
                "/api/get_valid_votes"
    in
    Http.get
        { url = url
        , expect = Http.expectJson Loaded votesDecoder
        }


votesDecoder : D.Decoder (List Vote)
votesDecoder =
    let
        voteDecoder =
            D.map8 Vote
                (D.field "twoRound" D.int)
                (D.field "oneRound" D.int)
                (D.field "divide" (D.list D.int))
                (D.field "d21" (D.list D.int))
                (D.field "doodle" (D.list D.int))
                (D.field "order" (D.list D.int))
                (D.field "star" (D.list D.int))
                (D.field "emoji" (D.list D.string))
    in
    D.list voteDecoder



-- UPDATE


type Msg
    = NoOp
    | Loaded (Result Http.Error (List Vote))


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    case cmd of
        NoOp ->
            ( model, Cmd.none )

        Loaded result ->
            case result of
                Ok votes ->
                    ( { model | votes = votes }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )



-- VIEW


countValues : List Int -> Array Int
countValues list =
    let
        fn curr acc =
            Array.set curr (1 + (Maybe.withDefault 0 <| Array.get curr acc)) acc

        initial =
            Array.initialize (Array.length Candidates.all) (always 0)
    in
    List.foldl fn initial list


view : Model -> Html Msg
view model =
    div []
        [ p [] [ text <| String.fromInt (List.length model.votes) ]
        , section [ class "wide" ]
            [ h1 [] [ text "Dvoukolový systém" ]
            , viewSingle (List.map .twoRound model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Jednokolový systém" ]
            , viewSingle (List.map .oneRound model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Rozdělovací hlasování" ]
            , viewDivide (List.map .divide model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Metoda D21" ]
            , viewD21 (List.map .d21 model.votes)
            ]
        ]


idToLabel : Int -> String
idToLabel id =
    Array.get id Candidates.all |> Maybe.map .surname |> Maybe.withDefault "--"


idToColor : Int -> String
idToColor id =
    Array.get id Candidates.all |> Maybe.map .color |> Maybe.withDefault "white"


idToGradient : Int -> List String
idToGradient id =
    case id of
        0 ->
            [ "#54bf01", "white" ]

        1 ->
            [ "#964B00", "#c68B40" ]

        2 ->
            [ "#9400D3", "white" ]

        3 ->
            [ "#4444FF", "white" ]

        4 ->
            [ "skyblue", "white" ]

        5 ->
            [ "#FFFF00", "white" ]

        6 ->
            [ "pink", "white" ]

        7 ->
            [ "#4E5b31", "white" ]

        8 ->
            [ "#FF7F00", "white" ]

        9 ->
            [ "#FF0000", "white" ]

        _ ->
            [ "white" ]


viewSimpleChart : Array Float -> Html Msg
viewSimpleChart counted =
    let
        data =
            Array.toList counted
                |> List.indexedMap (\i v -> { id = idToLabel i, value = v, gradient = idToGradient i })
                |> List.sortBy .value
                |> List.reverse

        chart =
            C.chart
                [ CA.height 500
                , CA.width 500
                , CA.margin { top = 50, bottom = 150, left = 50, right = 50 }
                ]
                [ C.binLabels .id [ CA.moveDown 15, CA.moveRight 5, CA.rotate 90, CA.alignRight, CA.color "white", CA.fontSize 22 ]
                , C.yLabels [ CA.alignLeft, CA.withGrid, CA.moveLeft 20 ]
                , C.bars [ CA.margin 0.2 ]
                    [ C.bar .value [ CA.border "white", CA.borderWidth 1 ] |> C.variation (\i d -> [ CA.gradient d.gradient ])
                    ]
                    data
                , C.barLabels [ CA.color "white", CA.moveUp 15 ]
                ]
    in
    div [ class "chart-center" ]
        [ div [ class "chart-container" ] [ chart ]
        ]


viewSingle : List Int -> Html Msg
viewSingle ids =
    let
        counted =
            countValues ids |> Array.map toFloat
    in
    viewSimpleChart counted


viewDivide : List (List Int) -> Html Msg
viewDivide pointsList =
    let
        initial =
            Array.initialize (Array.length Candidates.all) (always 0)

        fnInner : ( Int, Int ) -> Array Int -> Array Int
        fnInner ( index, value ) acc =
            Array.set index (value + (Maybe.withDefault 0 <| Array.get index acc)) acc

        fn : List Int -> Array Int -> Array Int
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        counted =
            List.foldl fn initial pointsList |> Array.map toFloat
    in
    viewSimpleChart counted


viewD21 : List (List Int) -> Html Msg
viewD21 pointsList =
    let
        emptyCounts =
            { negatives = 0, positives = 0, total = 0 }

        initial =
            Array.initialize (Array.length Candidates.all) (always emptyCounts)

        updateCounts : D21Counts -> Int -> D21Counts
        updateCounts counts value =
            if value > 0 then
                { counts | positives = counts.positives + 1, total = counts.total + 1 }

            else if value < 0 then
                { counts | negatives = counts.negatives - 1, total = counts.total - 1 }

            else
                counts

        fnInner : ( Int, Int ) -> Array D21Counts -> Array D21Counts
        fnInner ( index, value ) acc =
            Array.set index (updateCounts (Maybe.withDefault emptyCounts <| Array.get index acc) value) acc

        fn : List Int -> Array D21Counts -> Array D21Counts
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        counted =
            List.foldl fn initial pointsList

        data =
            Array.toList counted
                |> List.indexedMap
                    (\i v ->
                        { id = idToLabel i
                        , value = v
                        , gradient = idToGradient i
                        , positives = v.positives
                        , negatives = v.negatives
                        , total = v.total
                        }
                    )
                |> List.sortBy .total
                |> List.reverse

        chart =
            C.chart
                [ CA.height 500
                , CA.width 500
                , CA.margin { top = 50, bottom = 150, left = 50, right = 50 }
                ]
                [ C.binLabels .id [ CA.moveUp 5, CA.moveLeft 10, CA.rotate 90, CA.alignLeft, CA.color "white", CA.fontSize 18 ]
                , C.yLabels [ CA.alignLeft, CA.withGrid, CA.moveLeft 30 ]
                , C.bars [ CA.margin 0.4, CA.spacing 0, CA.ungroup ]
                    [ C.bar .total [ CA.border "white", CA.borderWidth 1 ] |> C.variation (\i d -> [ CA.gradient d.gradient ])
                    , C.bar .positives [ CA.striped [ CA.spacing 3 ], CA.color "rgba(0, 255, 0, 0.3)" ]
                    , C.bar .negatives [ CA.striped [ CA.spacing 3 ], CA.color "rgba(255, 0, 0, 0.3)" ]
                    ]
                    data
                ]
    in
    div [ class "chart-center" ]
        [ div [ class "chart-container" ] [ chart ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
