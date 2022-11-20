module Polls.DoodlePoll exposing
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
import Html exposing (Html, div, h1, h2, input, label, p, section, text)
import Html.Attributes exposing (checked, class, name, type_, value)
import Html.Events exposing (onInput)


type Option
    = No
    | IfNeeded
    | Yes


type Msg
    = SetValue Int Option


type alias Model =
    { values : Dict Int Option
    }


optionToName : Option -> String
optionToName option =
    case option of
        No ->
            "Ne"

        IfNeeded ->
            "Pokud nutno"

        Yes ->
            "Ano"


optionToValue : Option -> String
optionToValue option =
    case option of
        No ->
            "0"

        IfNeeded ->
            "1"

        Yes ->
            "2"


init : Model
init =
    { values = Dict.empty
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetValue id option ->
            let
                updatedValues =
                    Dict.insert id option model.values
            in
            { model | values = updatedValues }


view : Model -> Html Msg
view model =
    let
        row candidate =
            let
                value =
                    Maybe.withDefault No <| Dict.get candidate.id model.values
            in
            div [ class "poll-row" ]
                [ Component.candidateView candidate
                , rowValueView { value = value, candidateId = candidate.id }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ div
                [ class "doodle-poll" ]
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
        [ h1 [ class "poll-heading" ] [ text "Doodle hlasování" ]
        , div [ class "poll-info" ]
            [ p []
                [ text <|
                    String.concat
                        [ "V tomto hlasování u každého kandidáta uvedete, zdali si ho ve funkci "
                        , "prezidenta přejete (Ano), je pro vás přijatelný (Pokud nutno), "
                        , "nebo ho za prezidenta nechcete (Ne)."
                        ]
                ]
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


rowValueView : { candidateId : Int, value : Option } -> Html Msg
rowValueView { candidateId, value } =
    let
        radio option =
            label
                []
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "doodle-", String.fromInt candidateId ]
                    , Html.Attributes.value <| optionToValue option
                    , checked <| option == value
                    , onInput <| \_ -> SetValue candidateId option
                    ]
                    []
                , text <| optionToName option
                ]

        options =
            List.map radio [ No, IfNeeded, Yes ]
    in
    div [ class "doodle-poll-value" ] options
