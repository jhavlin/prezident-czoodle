module Polls.D21Poll exposing
    ( Model
    , Msg
    , deserialize
    , init
    , serialize
    , summarize
    , update
    , view
    )

import Array
import Candidates
import Component
import Dict exposing (Dict)
import FeatherIcons
import Html exposing (Html, div, h1, h2, input, label, li, p, section, text)
import Html.Attributes exposing (attribute, checked, class, disabled, name, type_, value)
import Html.Events exposing (onInput)
import Html.Keyed
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig, Summary(..), Validation(..), editableClass)
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


optionToInt : Option -> Int
optionToInt option =
    case option of
        Positive ->
            1

        Neutral ->
            0

        Negative ->
            -1


intToOption : Int -> Option
intToOption i =
    if i < 0 then
        Negative

    else if i == 0 then
        Neutral

    else
        Positive


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


view : PollConfig -> Model -> Html Msg
view pollConfig model =
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
            li [ class "poll-row", class <| optionToClass value ]
                [ Component.candidateView candidate
                , rowValueView
                    pollConfig
                    { value = value
                    , candidateId = candidate.id
                    , positiveAssigned = positiveAssigned
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
            [ if pollConfig.readOnly then
                text ""

              else
                creditView
                    { positiveAssigned = positiveAssigned
                    , negativeAssigned = negativeAssigned
                    , negativeEnabled = negativeEnabled
                    }
            ]
        , div [ class "narrow" ]
            [ Html.Keyed.ul [ class "d21-poll poll-rows" ]
                (List.map (\c -> ( "d21-poll" ++ String.fromInt c.id, row c )) pollConfig.candidates)
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
                , text "použijete alespoň dva kladné hlasy, můžete udělit také jeden záporný "
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
            List.range 1 maxPositive |> List.reverse |> List.map (\i -> positiveItem (i > positiveAssigned))

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
    PollConfig
    ->
        { candidateId : Int
        , value : Option
        , positiveAssigned : Int
        , positiveAvailable : Bool
        , negativeAvailable : Bool
        , negativeEnabled : Bool
        }
    -> Html Msg
rowValueView pollConfig { candidateId, value, positiveAvailable, negativeAvailable, negativeEnabled, positiveAssigned } =
    let
        isDisabled option =
            case option of
                Positive ->
                    not positiveAvailable && option /= value

                Neutral ->
                    False

                Negative ->
                    (not negativeAvailable && option /= value)
                        || (not negativeEnabled && option /= value)
                        || (value == Positive && positiveAssigned == minPositiveToEnableNegative)

        disabledClass option =
            if not negativeEnabled && option == Negative && option == value then
                "disabled"

            else
                ""

        radio option =
            label
                [ attribute "aria-label" <| optionToName option, class <| disabledClass option ]
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "d21-", String.fromInt candidateId ]
                    , Html.Attributes.value <| optionToValue option
                    , checked <| option == value
                    , disabled <| isDisabled option
                    , onInput <| \_ -> SetValue candidateId option
                    ]
                    []
                , optionView pollConfig option
                ]

        options =
            List.map radio [ Negative, Neutral, Positive ]
    in
    div [ class "d21-poll-value" ] options


optionView : PollConfig -> Option -> Html Msg
optionView pollConfig option =
    case option of
        Positive ->
            viewPositive pollConfig

        Neutral ->
            viewNeutral pollConfig

        Negative ->
            viewNegative pollConfig


viewPositive : PollConfig -> Html Msg
viewPositive pollConfig =
    div
        [ class <| "d21-poll-option positive", editableClass pollConfig ]
        [ text "+1" ]


viewNeutral : PollConfig -> Html Msg
viewNeutral pollConfig =
    div
        [ class <| "d21-poll-option neutral", editableClass pollConfig ]
        [ text "-" ]


viewNegative : PollConfig -> Html Msg
viewNegative pollConfig =
    div
        [ class <| "d21-poll-option negative", editableClass pollConfig ]
        [ text "-1" ]


serialize : Bool -> Model -> Json.Encode.Value
serialize final model =
    let
        mapper =
            \_ v -> optionToInt v

        mapped =
            Dict.map mapper model.values
    in
    if final then
        let
            positiveCount =
                Dict.values mapped |> List.filter (\v -> v > 0) |> List.length
        in
        if positiveCount < 2 then
            let
                fixed =
                    Dict.map
                        (\_ v ->
                            if v < 0 then
                                0

                            else
                                v
                        )
                        mapped
            in
            Polls.Common.serializeIntDict fixed

        else
            Polls.Common.serializeIntDict mapped

    else
        Polls.Common.serializeIntDict mapped


deserialize : Json.Decode.Decoder Model
deserialize =
    Json.Decode.map Model <| Polls.Common.deserializeMappedIntDict intToOption


summarize : Model -> Polls.Common.Summary
summarize model =
    let
        positive =
            Dict.values model.values
                |> List.filter (\v -> v == Positive)
                |> List.length

        negative =
            Dict.values model.values
                |> List.filter (\v -> v == Negative)
                |> List.length
    in
    if positive > 3 || negative > 1 then
        let
            html =
                div [] [ text "V\u{00A0}hlasování D21 je rozdělen chybný počet hlasů." ]
        in
        Summary Error html

    else if positive == 0 then
        let
            html =
                div [] [ text "V\u{00A0}hlasování D21 nebyl udělen ani jeden hlas." ]
        in
        Summary Error html

    else
        let
            pointsDisplayName =
                if positive > 1 then
                    "kladné hlasy"

                else
                    "kladný hlas"

            positiveNames =
                Dict.toList model.values
                    |> List.filter (\( _, v ) -> v == Positive)
                    |> List.filterMap (\( k, _ ) -> Array.get k Candidates.all)
                    |> List.sortBy .surname
                    |> List.map .p3
                    |> Component.itemsString ", " " a "

            negativeNames =
                Dict.toList model.values
                    |> List.filter (\( _, v ) -> v == Negative)
                    |> List.filterMap (\( k, _ ) -> Array.get k Candidates.all)
                    |> List.sortBy .surname
                    |> List.map .p3
                    |> Component.itemsString ", " " a "

            negativeInfoOrEnd =
                if positive >= 2 && negative >= 1 then
                    String.concat
                        [ " a záporný hlas "
                        , negativeNames
                        , "."
                        ]

                else
                    "."

            summaryText =
                String.concat
                    [ "V hlasování D21 jste udělili "
                    , pointsDisplayName
                    , " "
                    , positiveNames
                    , negativeInfoOrEnd
                    ]

            html =
                div [] [ text summaryText ]
        in
        Summary Valid html
