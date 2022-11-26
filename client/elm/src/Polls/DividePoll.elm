module Polls.DividePoll exposing
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
import Html.Attributes exposing (checked, class, disabled, name, title, type_)
import Html.Events exposing (onInput)
import Svg.Attributes as SAttr
import Svg.Events as SEvent


type Msg
    = SetValue { id : Int, value : Int }


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


view : Model -> Html Msg
view model =
    let
        row candidate =
            let
                value =
                    Maybe.withDefault 0 <| Dict.get candidate.id model.values
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
                [ class "divide-poll"
                ]
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


rowValueView : { candidateId : Int, value : Int } -> Html Msg
rowValueView { candidateId, value } =
    let
        iconSize =
            32

        oneDot cls points =
            label
                []
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "div", String.fromInt candidateId ]
                    , Html.Attributes.value <| String.fromInt points
                    , onInput <| \_ -> SetValue { id = candidateId, value = points }
                    , checked <| points == value
                    ]
                    []
                , div
                    [ title <| String.concat [ String.fromInt points ]
                    , class "divide-poll-option divide-poll-dot"
                    , class cls
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
                            [ SEvent.onClick <| SetValue { id = candidateId, value = 0 }
                            ]
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
