module Polls.EmojiPoll exposing
    ( Model
    , Msg
    , deserialize
    , init
    , serialize
    , update
    , view
    )

import Candidates
import Component
import Dict exposing (Dict)
import Html exposing (Html, div, h1, h2, input, section, text)
import Html.Attributes exposing (class, maxlength, type_)
import Html.Events exposing (onInput)
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig)


type Msg
    = SetValue Int String


type alias Model =
    { values : Dict Int String
    }


init : Model
init =
    { values = Dict.empty
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetValue id string ->
            { model | values = Dict.insert id (String.left 3 string) model.values }


view : PollConfig -> Model -> Html Msg
view pollConfig model =
    let
        row candidate =
            div [ class "poll-row" ]
                [ Component.candidateView candidate
                , rowValueView { model = model, candidate = candidate }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ div
                [ class "emoji-poll" ]
                (List.map row pollConfig.candidates)
            ]
        ]


headerView : Html Msg
headerView =
    let
        heading =
            h2 [] [ text "Hodnocení kandidátů" ]
    in
    div
        []
        [ h1 [ class "poll-heading" ] [ text "Bonus: Emoji Hlasování" ]
        , div [ class "poll-info emoji-poll-info" ]
            [ text "Přiřaďte každé osobnosti emoji nebo textového smajlíka (až 3 znaky)."
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


rowValueView : { candidate : Candidates.Candidate, model : Model } -> Html Msg
rowValueView { candidate, model } =
    let
        field =
            input
                [ type_ "text"
                , Html.Attributes.value <| Maybe.withDefault "" <| Dict.get candidate.id model.values
                , onInput <| SetValue candidate.id
                , maxlength 3
                , class "emoji-poll-input"
                ]
                []
    in
    div [ class "emoji-poll-value" ] [ field ]


serialize : Model -> Json.Encode.Value
serialize model =
    Polls.Common.serializeStringDict model.values


deserialize : Json.Decode.Decoder Model
deserialize =
    Json.Decode.map Model <| Polls.Common.deserializeStringDict
