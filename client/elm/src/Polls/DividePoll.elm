module Polls.DividePoll exposing
    ( Model
    , Msg
    , init
    , serialize
    , update
    , view
    )

import Component
import Dict exposing (Dict)
import FeatherIcons
import Html exposing (Html, div, h1, h2, input, label, p, section, text)
import Html.Attributes exposing (checked, class, disabled, name, title, type_)
import Html.Events exposing (onClick, onInput)
import Json.Encode
import Polls.Common exposing (PollConfig)
import Svg.Attributes as SAttr


type Msg
    = SetValue { id : Int, value : Int }
    | NoOp


type alias Model =
    { values : Dict Int Int
    }


init : Model
init =
    { values = Dict.empty
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetValue { id, value } ->
            let
                updatedValues =
                    Dict.insert id value model.values
            in
            { model | values = updatedValues }

        NoOp ->
            model


view : PollConfig -> Model -> Html Msg
view pollConfig model =
    let
        free =
            5 - (List.sum <| Dict.values model.values)

        row candidate =
            let
                value =
                    Maybe.withDefault 0 <| Dict.get candidate.id model.values
            in
            div [ class "poll-row" ]
                [ Component.candidateView candidate
                , rowValueView { value = value, candidateId = candidate.id, free = free }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ creditView { freeCount = free } ]
        , div [ class "narrow" ]
            [ div
                [ class "divide-poll"
                ]
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
        [ h1 [ class "poll-heading" ] [ text "Rozdělovací hlasování" ]
        , div [ class "poll-info" ]
            [ p []
                [ text <|
                    String.concat
                        [ "Rozdělte pět bodů mezi kandidáty. Jeden kandidát může obdržet všechny vaše body, "
                        , "pěti kandidátům můžete udělit po jednom bodu, nebo cokoliv mezi tím."
                        ]
                ]
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


rowValueView : { candidateId : Int, value : Int, free : Int } -> Html Msg
rowValueView { candidateId, value, free } =
    let
        iconSize =
            32

        isDisabled points =
            (points - value) > free

        offClass points =
            if isDisabled points then
                "off"

            else
                ""

        onClickHandler points =
            if isDisabled points then
                SetValue { id = candidateId, value = min points (free + value) }

            else
                NoOp

        oneDot cls points =
            label
                []
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "div", String.fromInt candidateId ]
                    , Html.Attributes.value <| String.fromInt points
                    , onInput <| \_ -> SetValue { id = candidateId, value = points }
                    , disabled <| isDisabled points
                    ]
                    []
                , div
                    [ title <| String.concat [ String.fromInt points ]
                    , class "divide-poll-option divide-poll-dot"
                    , class cls
                    , class <| offClass points
                    , onClick <| onClickHandler points
                    ]
                    [ FeatherIcons.circle
                        |> FeatherIcons.withSize iconSize
                        |> FeatherIcons.toHtml
                            [ SAttr.title <| String.concat [ String.fromInt points ]
                            ]
                    ]
                ]

        oneDotDisabled points =
            oneDot "disabled" points

        oneDotEnabled points =
            oneDot "enabled" points

        noPointState =
            if value > 0 then
                "enabled"

            else
                "disabled"

        noDots =
            label
                []
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "div", String.fromInt candidateId ]
                    , onInput <| \_ -> SetValue { id = candidateId, value = 0 }
                    , checked <| value == 0
                    ]
                    []
                , div
                    [ title "0"
                    , class "divide-poll-option action-unset"
                    , class noPointState
                    ]
                    [ FeatherIcons.x
                        |> FeatherIcons.withSize iconSize
                        |> FeatherIcons.toHtml
                            []
                    ]
                ]

        pointsToDot p =
            if p == 0 then
                noDots

            else if p <= value then
                oneDotEnabled p

            else
                oneDotDisabled p

        dots =
            List.range 0 5 |> List.map pointsToDot

        dotRankView =
            div [ class "divide-poll-rank" ] dots
    in
    div [ class "divide-poll-value" ]
        [ dotRankView ]


creditView : { freeCount : Int } -> Html Msg
creditView { freeCount } =
    let
        freeClass isFree =
            if isFree then
                "free"

            else
                ""

        items =
            List.range 1 5 |> List.map (\i -> oneItem (i > (5 - freeCount)))

        oneItem isFree =
            FeatherIcons.circle |> FeatherIcons.toHtml [ SAttr.class "divide-poll-credit-item", SAttr.class <| freeClass isFree ]

        label =
            div [ class "divide-poll-credit-label" ] [ text "Zbývající hlasy: " ]
    in
    div [ class "divide-poll-credit" ] (label :: items)


serialize : Model -> Json.Encode.Value
serialize model =
    Polls.Common.serializeIntDict model.values
