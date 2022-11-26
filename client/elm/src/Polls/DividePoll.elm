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
import Html exposing (Attribute, Html, button, div, h1, h2, input, p, section, span, text)
import Html.Attributes exposing (class, disabled, style, tabindex, title, type_)
import Html.Events exposing (keyCode, on, onClick, onFocus, onInput)
import Svg.Attributes as SAttr
import Svg.Events as SEvent
import UserInputInt exposing (UserInputInt)


type Msg
    = SetValue { id : Int, value : Int }


type alias Model =
    { values : Dict Int UserInputInt
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
                    Dict.insert id (UserInputInt.Valid value) model.values
            in
            { model | values = updatedValues }


view : Model -> Html Msg
view model =
    let
        row candidate =
            let
                value =
                    Maybe.withDefault (UserInputInt.Valid 0) <| Dict.get candidate.id model.values
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


rowValueView : { candidateId : Int, value : UserInputInt } -> Html Msg
rowValueView { candidateId, value } =
    let
        iconSize =
            32

        oneDot cls points =
            span
                [ title <| String.concat [ String.fromInt (points * 20), "%" ]
                , class "divide-poll-option divide-poll-dot"
                , class cls
                ]
                [ FeatherIcons.circle
                    |> FeatherIcons.withSize iconSize
                    |> FeatherIcons.toHtml
                        [ SAttr.title <| String.concat [ String.fromInt points ]
                        , SEvent.onClick <| SetValue { id = candidateId, value = points * 20 }
                        ]
                ]

        oneDotDisabled points =
            oneDot "disabled" points

        oneDotEnabled points =
            oneDot "enabled" points

        noPointState =
            case value of
                UserInputInt.Valid v ->
                    if v > 0 then
                        "enabled"

                    else
                        "disabled"

                _ ->
                    "disabled"

        noDots =
            span
                [ title "0%"
                , class "divide-poll-option action-unset"
                , class noPointState
                ]
                [ FeatherIcons.x
                    |> FeatherIcons.withSize iconSize
                    |> FeatherIcons.toHtml
                        [ SEvent.onClick <| SetValue { id = candidateId, value = 0 }
                        , SAttr.title "0%"
                        ]
                ]

        pointsToDot p =
            if p == 0 then
                noDots

            else
                case value of
                    UserInputInt.Valid v ->
                        if p * 20 <= v then
                            oneDotEnabled p

                        else
                            oneDotDisabled p

                    _ ->
                        oneDotDisabled p

        dots =
            List.range 0 5 |> List.map pointsToDot

        dotRankView =
            div [ class "divide-poll-rank" ] dots
    in
    div [ class "divide-poll-value" ]
        [ dotRankView ]
