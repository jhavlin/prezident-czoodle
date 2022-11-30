module Polls.EmojiPoll exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Array
import Candidates
import Component
import Dict exposing (Dict)
import Html exposing (Html, div, h1, h2, input, section, text)
import Html.Attributes exposing (class, maxlength, type_)
import Html.Events exposing (onInput)


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
            { model | values = Dict.insert id (String.left 2 string) model.values }


view : Model -> Html Msg
view model =
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
                (Array.toList Candidates.all |> List.map row)
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
            [ text "Přiřaďte každé osobnosti emoji nebo jiný symbol."
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
                , maxlength 2
                , class "emoji-poll-input"
                ]
                []
    in
    div [ class "emoji-poll-value" ] [ field ]
