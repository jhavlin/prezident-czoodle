module Polls.DividePoll exposing
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
import Candidates exposing (Candidate)
import Component exposing (ariaHidden, ariaLabel)
import Dict exposing (Dict)
import FeatherIcons
import Html exposing (Html, div, h1, h2, input, label, li, p, section, text)
import Html.Attributes exposing (checked, class, disabled, name, title, type_)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig, Summary(..), Validation(..), editableClass)
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


sumFree : Model -> Int
sumFree model =
    5 - (List.sum <| Dict.values model.values)


view : PollConfig -> Model -> Html Msg
view pollConfig model =
    let
        free =
            sumFree model

        row candidate =
            let
                value =
                    Maybe.withDefault 0 <| Dict.get candidate.id model.values
            in
            li [ class "poll-row" ]
                [ Component.candidateView candidate
                , rowValueView pollConfig { value = value, candidate = candidate, free = free }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ if pollConfig.readOnly then
                text ""

              else
                creditView { freeCount = free }
            ]
        , div [ class "narrow" ]
            [ Html.Keyed.ul [ class "divide-poll poll-rows" ]
                (List.map (\c -> ( "divide-poll" ++ String.fromInt c.id, row c )) pollConfig.candidates)
            ]
        ]


pointsToString : Int -> String
pointsToString p =
    if p == 1 then
        "1\u{00A0}bod"

    else if p > 1 && p < 5 then
        String.concat [ String.fromInt p, "\u{00A0}", "body" ]

    else
        String.concat [ String.fromInt p, "\u{00A0}", "bodů" ]


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


rowValueView : PollConfig -> { candidate : Candidate, value : Int, free : Int } -> Html Msg
rowValueView pollConfig { candidate, value, free } =
    let
        candidateId =
            candidate.id

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
                SetValue { id = candidate.id, value = min points (free + value) }

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
                    , ariaLabel <| String.concat [ pointsToString points, " ", candidate.p3 ]
                    ]
                    []
                , div
                    [ title <| String.concat [ String.fromInt points ]
                    , class "divide-poll-option divide-poll-dot"
                    , class cls
                    , class <| offClass points
                    , editableClass pollConfig
                    , onClick <| onClickHandler points
                    , ariaHidden
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
                    , ariaLabel <| String.concat [ "Nic ", candidate.p3 ]
                    ]
                    []
                , div
                    [ title "0"
                    , class "divide-poll-option action-unset"
                    , class noPointState
                    , ariaHidden
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

        range =
            if pollConfig.readOnly then
                List.range 1 5

            else
                List.range 0 5

        dots =
            List.map pointsToDot range

        dotRankView =
            div [ class "divide-poll-rank", editableClass pollConfig, ariaLabel candidate.name ] dots
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
            List.range 1 5 |> List.reverse |> List.map (\i -> oneItem (i > (5 - freeCount)))

        oneItem isFree =
            FeatherIcons.circle |> FeatherIcons.toHtml [ SAttr.class "divide-poll-credit-item", SAttr.class <| freeClass isFree, ariaHidden ]

        label =
            div [ class "divide-poll-credit-label", ariaHidden ] [ text "Zbývající hlasy: " ]
    in
    div [ class "divide-poll-credit", ariaLabel <| String.concat [ "Zbývající hlasy: ", String.fromInt freeCount ] ] (label :: items)


serialize : Model -> Json.Encode.Value
serialize model =
    Polls.Common.serializeIntDict model.values


deserialize : Json.Decode.Decoder Model
deserialize =
    Json.Decode.map Model Polls.Common.deserializeIntDict


summarize : Model -> Polls.Common.Summary
summarize model =
    let
        free =
            sumFree model
    in
    if free > 0 then
        let
            html =
                div [] [ text "V\u{00A0}rozdělovacím hlasování jste neudělili všech pět bodů." ]
        in
        Summary Error html

    else
        let
            items =
                Dict.toList model.values
                    |> List.filter (\( _, v ) -> v > 0)
                    |> List.filterMap (\( k, v ) -> Array.get k Candidates.all |> Maybe.map (\c -> ( c, v )))
                    |> List.sortBy Tuple.second
                    |> List.reverse
                    |> List.map (\( c, v ) -> String.concat [ pointsToString v, " ", c.p3 ])
                    |> Component.itemsString ", " " a "

            summaryText =
                String.concat
                    [ "V rozdělovacím hlasování jste udělili "
                    , items
                    , "."
                    ]

            html =
                div [] [ text summaryText ]
        in
        Summary Valid html
