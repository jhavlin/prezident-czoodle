module Polls.DoodlePoll exposing
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
import Html exposing (Html, div, h1, h2, input, label, li, p, section, text)
import Html.Attributes exposing (attribute, checked, class, name, type_, value)
import Html.Events exposing (onInput)
import Html.Keyed
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig, Summary(..), Validation(..), editableClass)
import Svg exposing (circle, line, svg)
import Svg.Attributes as SAttr


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


optionToInt : Option -> Int
optionToInt option =
    case option of
        No ->
            0

        IfNeeded ->
            1

        Yes ->
            2


intToOption : Int -> Option
intToOption i =
    case i of
        1 ->
            IfNeeded

        2 ->
            Yes

        _ ->
            No


optionToClass : Option -> String
optionToClass option =
    case option of
        No ->
            "no"

        IfNeeded ->
            "if-needed"

        Yes ->
            "yes"


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
        row candidate =
            let
                value =
                    Maybe.withDefault No <| Dict.get candidate.id model.values
            in
            li [ class "poll-row", class <| optionToClass value ]
                [ Component.candidateView candidate
                , rowValueView pollConfig { value = value, candidateId = candidate.id }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ Html.Keyed.ul [ class "doodle-poll poll-rows" ]
                (List.map (\c -> ( "doodle-row-" ++ String.fromInt c.id, row c )) pollConfig.candidates)
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
        , div [ class "poll-info doodle-poll-info" ]
            [ p []
                [ text "V tomto hlasování u každého kandidáta uvedete, zdali si ho ve funkci "
                , text "prezidenta přejete "
                , text "(Ano "
                , viewYesSvg
                , text "), je pro vás přijatelný (Pokud nutno "
                , viewIfNeededSvg
                , text "), "
                , text "nebo ho za prezidenta nechcete (Ne "
                , viewNoSvg
                , text ")."
                ]
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


rowValueView : PollConfig -> { candidateId : Int, value : Option } -> Html Msg
rowValueView pollConfig { candidateId, value } =
    let
        radio option =
            label
                [ attribute "aria-label" <| optionToName option ]
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "doodle-", String.fromInt candidateId ]
                    , Html.Attributes.value <| optionToValue option
                    , checked <| option == value
                    , onInput <| \_ -> SetValue candidateId option
                    ]
                    []
                , optionSvg pollConfig option
                ]

        options =
            List.map radio [ No, IfNeeded, Yes ]
    in
    div [ class "doodle-poll-value" ] options


optionSvg : PollConfig -> Option -> Html Msg
optionSvg pollConfig option =
    case option of
        Yes ->
            viewYes pollConfig

        No ->
            viewNo pollConfig

        IfNeeded ->
            viewIfNeeded pollConfig


viewYes : PollConfig -> Html Msg
viewYes pollConfig =
    div
        [ class <| "doodle-poll-option yes", editableClass pollConfig ]
        [ viewYesSvg ]


viewYesSvg : Html Msg
viewYesSvg =
    svg [ SAttr.class "doodle-poll-option-svg yes", SAttr.width "34", SAttr.height "34", SAttr.viewBox "0 0 34 34" ]
        [ circle [ SAttr.cx "17", SAttr.cy "17", SAttr.r "12" ] [] ]


viewNo : PollConfig -> Html Msg
viewNo pollConfig =
    div
        [ class <| "doodle-poll-option no", editableClass pollConfig ]
        [ viewNoSvg ]


viewNoSvg : Html Msg
viewNoSvg =
    svg [ SAttr.class "doodle-poll-option-svg no", SAttr.width "34", SAttr.height "34", SAttr.viewBox "0 0 34 34" ]
        [ line [ SAttr.x1 "6", SAttr.y1 "6", SAttr.x2 "28", SAttr.y2 "28" ] []
        , line [ SAttr.x1 "6", SAttr.y1 "28", SAttr.x2 "28", SAttr.y2 "6" ] []
        ]


viewIfNeeded : PollConfig -> Html Msg
viewIfNeeded pollConfig =
    div
        [ class <| "doodle-poll-option if-needed", editableClass pollConfig ]
        [ viewIfNeededSvg ]


viewIfNeededSvg : Html Msg
viewIfNeededSvg =
    svg [ SAttr.class "doodle-poll-option-svg if-needed", SAttr.width "34", SAttr.height "34", SAttr.viewBox "0 0 34 34" ]
        [ circle [ SAttr.cx "17", SAttr.cy "17", SAttr.r "12" ] [] ]


serialize : Model -> Json.Encode.Value
serialize model =
    Polls.Common.serializeIntDict <| Dict.map (\_ v -> optionToInt v) model.values


deserialize : Json.Decode.Decoder Model
deserialize =
    Json.Decode.map Model <| Polls.Common.deserializeMappedIntDict intToOption


summarize : Model -> Polls.Common.Summary
summarize model =
    let
        yesCount =
            Dict.values model.values
                |> List.filter (\v -> v == Yes)
                |> List.length

        ifNeededCount =
            Dict.values model.values
                |> List.filter (\v -> v == IfNeeded)
                |> List.length
    in
    if yesCount + ifNeededCount == 0 then
        let
            html =
                div [] [ text "V\u{00A0}Doodle hlasování nebyl udělen ani jeden hlas Ano nebo Pokud nutno." ]
        in
        Summary Error html

    else
        let
            yesNames =
                Dict.toList model.values
                    |> List.filter (\( _, v ) -> v == Yes)
                    |> List.filterMap (\( k, _ ) -> Array.get k Candidates.all)
                    |> List.sortBy .surname
                    |> List.map .p4
                    |> Component.itemsString ", " " a "

            ifNeededNames =
                Dict.toList model.values
                    |> List.filter (\( _, v ) -> v == IfNeeded)
                    |> List.filterMap (\( k, _ ) -> Array.get k Candidates.all)
                    |> List.sortBy .surname
                    |> List.map .p4
                    |> Component.itemsString ", " " a "

            yesText =
                if yesCount > 0 then
                    String.concat [ "kladně (Ano) ", yesNames ]

                else
                    ""

            andOptional =
                if yesCount > 0 && ifNeededCount > 0 then
                    " a "

                else
                    ""

            ifNeededText =
                if ifNeededCount > 0 then
                    String.concat [ "přijatelně (Pokud nutno) ", ifNeededNames ]

                else
                    ""

            summaryText =
                String.concat
                    [ "V Doodle hlasování jste hodnotili "
                    , yesText
                    , andOptional
                    , ifNeededText
                    , "."
                    ]

            html =
                div [] [ text summaryText ]
        in
        Summary Valid html
