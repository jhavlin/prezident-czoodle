module Polls.D21Poll exposing
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
import Html.Attributes exposing (attribute, checked, class, name, type_, value)
import Html.Events exposing (onInput)


type Option
    = Positive
    | Neutral
    | Negative


type Msg
    = SetValue Int Option


type alias Model =
    { values : Dict Int Option
    }


optionToName : Option -> String
optionToName option =
    case option of
        Positive ->
            "+1"

        Neutral ->
            "0"

        Negative ->
            "-1"


optionToValue : Option -> String
optionToValue option =
    case option of
        Positive ->
            "1"

        Neutral ->
            "0"

        Negative ->
            "-1"


optionToClass : Option -> String
optionToClass option =
    case option of
        Positive ->
            "positive"

        Neutral ->
            "neutral"

        Negative ->
            "negative"


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
                    Maybe.withDefault Neutral <| Dict.get candidate.id model.values
            in
            div [ class "poll-row", class <| optionToClass value ]
                [ Component.candidateView candidate
                , rowValueView { value = value, candidateId = candidate.id }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ div
                [ class "d21-poll" ]
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
        [ h1 [ class "poll-heading" ] [ text "Metoda D21" ]
        , div [ class "poll-info d21-poll-info" ]
            [ p []
                [ text "V tomto hlasování můžete udělit jeden až tři kladné hlasy, a pokud "
                , text "použijete alespoň dva kladné hlasy, můžete přidělit také jeden záporný "
                , text "hlas."
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
                [ attribute "aria-label" <| optionToName option ]
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "d21-", String.fromInt candidateId ]
                    , Html.Attributes.value <| optionToValue option
                    , checked <| option == value
                    , onInput <| \_ -> SetValue candidateId option
                    ]
                    []
                , optionSvg option
                ]

        options =
            List.map radio [ Negative, Neutral, Positive ]
    in
    div [ class "d21-poll-value" ] options


optionSvg : Option -> Html Msg
optionSvg option =
    case option of
        Positive ->
            viewPositive

        Neutral ->
            viewNeutral

        Negative ->
            viewNegative


viewPositive : Html Msg
viewPositive =
    div
        [ class <| "d21-poll-option positive" ]
        [ text "+1" ]


viewNeutral : Html Msg
viewNeutral =
    div
        [ class <| "d21-poll-option neutral" ]
        [ text "0" ]


viewNegative : Html Msg
viewNegative =
    div
        [ class <| "d21-poll-option negative" ]
        [ text "-1" ]
