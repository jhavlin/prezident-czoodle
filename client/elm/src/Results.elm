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
        , viewSingle (List.map .twoRound model.votes)
        , viewSingle (List.map .oneRound model.votes)
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


viewSingle : List Int -> Html Msg
viewSingle ids =
    let
        counted =
            countValues ids

        data =
            Array.toList counted
                |> List.map toFloat
                |> List.indexedMap (\i v -> { id = idToLabel i, value = v, gradient = idToGradient i })
                |> List.sortBy .value
                |> List.reverse

        chart =
            C.chart
                [ CA.height 500
                , CA.width 500
                , CA.margin { top = 50, bottom = 150, left = 50, right = 50 }
                ]
                [ C.binLabels .id [ CA.moveDown 15, CA.moveRight 5, CA.rotate 90, CA.alignRight, CA.color "white" ]
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
