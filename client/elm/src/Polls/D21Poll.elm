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
import FeatherIcons
import Html exposing (Html, div, h1, h2, input, label, p, section, text)
import Html.Attributes exposing (attribute, checked, class, disabled, name, type_, value)
import Html.Events exposing (onInput)
import Svg.Attributes as SAttr


maxPositive : Int
maxPositive =
    3


maxNegative : Int
maxNegative =
    1


minPositiveToEnableNegative : Int
minPositiveToEnableNegative =
    2


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
        positiveAssigned =
            model.values |> Dict.values |> List.filter (\i -> i == Positive) |> List.length

        negativeAssigned =
            model.values |> Dict.values |> List.filter (\i -> i == Negative) |> List.length

        positiveAvailable =
            maxPositive > positiveAssigned

        negativeEnabled =
            positiveAssigned >= minPositiveToEnableNegative

        negativeAvailable =
            negativeAssigned < maxNegative

        row candidate =
            let
                value =
                    Maybe.withDefault Neutral <| Dict.get candidate.id model.values
            in
            div [ class "poll-row", class <| optionToClass value ]
                [ Component.candidateView candidate
                , rowValueView
                    { value = value
                    , candidateId = candidate.id
                    , positiveAvailable = positiveAvailable
                    , negativeAvailable = negativeAvailable
                    , negativeEnabled = negativeEnabled
                    }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ creditView
                { positiveAssigned = positiveAssigned
                , negativeAssigned = negativeAssigned
                , negativeEnabled = negativeEnabled
                }
            ]
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


creditView :
    { positiveAssigned : Int
    , negativeAssigned : Int
    , negativeEnabled : Bool
    }
    -> Html Msg
creditView { positiveAssigned, negativeAssigned, negativeEnabled } =
    let
        freeClass free =
            if free then
                "free"

            else
                ""

        positiveItem free =
            div [ class "d21-poll-credit-item positive", class <| freeClass free ] [ text "+1" ]

        positives =
            List.range 1 maxPositive |> List.map (\i -> positiveItem (i > positiveAssigned))

        negativeItem free =
            div [ class "d21-poll-credit-item negative", class <| freeClass free ] [ text "-1" ]

        negatives =
            List.range 1 maxNegative |> List.map (\i -> negativeItem (i > negativeAssigned))

        lock =
            if negativeEnabled then
                []

            else
                [ FeatherIcons.lock |> FeatherIcons.toHtml [ SAttr.class "d21-poll-credit-lock" ] ]

        divider =
            [ div [ class "d21-poll-credit-divider" ] [] ]

        label =
            [ div [ class "d21-poll-credit-label" ] [ text "Zbývající hlasy: " ] ]
    in
    div [ class "d21-poll-credit" ] (label ++ positives ++ divider ++ negatives ++ lock)


rowValueView :
    { candidateId : Int
    , value : Option
    , positiveAvailable : Bool
    , negativeAvailable : Bool
    , negativeEnabled : Bool
    }
    -> Html Msg
rowValueView { candidateId, value, positiveAvailable, negativeAvailable, negativeEnabled } =
    let
        isDisabled option =
            case option of
                Positive ->
                    not positiveAvailable && option /= value

                Neutral ->
                    False

                Negative ->
                    not negativeEnabled || (not negativeAvailable && option /= value)

        radio option =
            label
                [ attribute "aria-label" <| optionToName option ]
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "d21-", String.fromInt candidateId ]
                    , Html.Attributes.value <| optionToValue option
                    , checked <| option == value
                    , disabled <| isDisabled option
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
