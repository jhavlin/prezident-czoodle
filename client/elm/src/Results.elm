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
        [ text "Hele, výsledky"
        , p [] [ text <| String.fromInt (List.length model.votes) ]
        , viewOneRound (List.map .oneRound model.votes)
        ]


idToInitials : Int -> String
idToInitials id =
    let
        initials candidate =
            String.concat
                [ String.slice 0 1 candidate.firstName
                , String.slice 0 1 candidate.surname
                ]
    in
    Array.get id Candidates.all |> Maybe.map .surname |> Maybe.withDefault "--"


idToColor : Int -> String
idToColor id =
    Array.get id Candidates.all |> Maybe.map .color |> Maybe.withDefault "white"


viewOneRound : List Int -> Html Msg
viewOneRound ids =
    let
        counted =
            countValues ids

        chart =
            C.chart
                [ CA.height 500
                , CA.width 500
                , CA.htmlAttrs
                    [ Html.Attributes.style "max-width" "400px"
                    , Html.Attributes.style "margin" "40px"
                    ]
                ]
                [ C.binLabels .id [ CA.moveDown 15, CA.moveRight 5, CA.rotate 90, CA.alignRight ]
                , C.yLabels [ CA.alignLeft, CA.withGrid, CA.moveLeft 20 ]
                , C.bars [ CA.margin 0.2 ]
                    [ C.bar .value [] |> C.variation (\i d -> [ CA.color d.color ])
                    ]
                    (Array.toList counted |> List.map toFloat |> List.indexedMap (\i v -> { id = idToInitials i, value = v, color = idToColor i }))
                ]
    in
    div []
        [ div [] (Array.toList <| Array.map (\v -> span [] [ text <| String.fromInt v, text " " ]) counted)
        , chart
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
