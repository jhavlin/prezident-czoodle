module Polls.DoodlePoll exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Component
import Dict exposing (Dict)
import Html exposing (Html, div, h1, h2, input, label, p, section, text)
import Html.Attributes exposing (attribute, checked, class, name, type_, value)
import Html.Events exposing (onInput)
import Polls.Common exposing (PollConfig)
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
                [ class "doodle-poll" ]
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


rowValueView : { candidateId : Int, value : Option } -> Html Msg
rowValueView { candidateId, value } =
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
                , optionSvg option
                ]

        options =
            List.map radio [ No, IfNeeded, Yes ]
    in
    div [ class "doodle-poll-value" ] options


optionSvg : Option -> Html Msg
optionSvg option =
    case option of
        Yes ->
            viewYes

        No ->
            viewNo

        IfNeeded ->
            viewIfNeeded


viewYes : Html Msg
viewYes =
    div
        [ class <| "doodle-poll-option yes" ]
        [ viewYesSvg ]


viewYesSvg : Html Msg
viewYesSvg =
    svg [ SAttr.class "doodle-poll-option-svg yes", SAttr.width "34", SAttr.height "34", SAttr.viewBox "0 0 34 34" ]
        [ circle [ SAttr.cx "17", SAttr.cy "17", SAttr.r "12" ] [] ]


viewNo : Html Msg
viewNo =
    div
        [ class <| "doodle-poll-option no" ]
        [ viewNoSvg ]


viewNoSvg : Html Msg
viewNoSvg =
    svg [ SAttr.class "doodle-poll-option-svg no", SAttr.width "34", SAttr.height "34", SAttr.viewBox "0 0 34 34" ]
        [ line [ SAttr.x1 "6", SAttr.y1 "6", SAttr.x2 "28", SAttr.y2 "28" ] []
        , line [ SAttr.x1 "6", SAttr.y1 "28", SAttr.x2 "28", SAttr.y2 "6" ] []
        ]


viewIfNeeded : Html Msg
viewIfNeeded =
    div
        [ class <| "doodle-poll-option if-needed" ]
        [ viewIfNeededSvg ]


viewIfNeededSvg : Html Msg
viewIfNeededSvg =
    svg [ SAttr.class "doodle-poll-option-svg if-needed", SAttr.width "34", SAttr.height "34", SAttr.viewBox "0 0 34 34" ]
        [ circle [ SAttr.cx "17", SAttr.cy "17", SAttr.r "12" ] [] ]
