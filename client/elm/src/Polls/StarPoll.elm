module Polls.StarPoll exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Array exposing (Array)
import Candidates exposing (Candidate)
import Component
import Dict exposing (Dict)
import FeatherIcons
import Html exposing (Html, div, input, progress)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onFocus, onInput)
import Svg.Attributes as SAttr
import Svg.Events as SEvent
import UserInputInt exposing (UserInputInt)


type Msg
    = SetStringValue Int String
    | SetStarValue { id : Int, value : Int }
    | SetFocusable Bool


type alias Model =
    { values : Dict Int UserInputInt
    , focusable : Bool
    , explicitlyFocusable : Bool
    }


init : Model
init =
    { values = Dict.empty
    , focusable = False
    , explicitlyFocusable = False
    }


userInputConfig : UserInputInt.Config
userInputConfig =
    { min = 0
    , max = 100
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetStringValue id value ->
            let
                userInputInt =
                    UserInputInt.create userInputConfig value

                updatedValues =
                    Dict.insert id userInputInt model.values
            in
            { model | values = updatedValues }

        SetStarValue { id, value } ->
            let
                updatedValues =
                    Dict.insert id (UserInputInt.Valid value) model.values
            in
            { model | values = updatedValues }

        SetFocusable focusable ->
            { model | focusable = focusable }


view : Model -> Array Candidate -> Html Msg
view model candidates =
    let
        row candidate =
            let
                value =
                    Maybe.withDefault (UserInputInt.Valid 0) <| Dict.get candidate.id model.values
            in
            div [ class "star-poll-row" ]
                [ Component.candidateView candidate
                , rowValueView { value = value, candidateId = candidate.id }
                ]

        isCustomValue userInputInt =
            case userInputInt of
                UserInputInt.Valid v ->
                    remainderBy 20 v /= 0

                UserInputInt.Invalid _ _ ->
                    True

        isCustomPoll =
            Dict.values model.values |> List.any isCustomValue

        customClass =
            if isCustomPoll then
                "custom"

            else
                ""
    in
    div
        [ class "star-poll"
        , class customClass
        ]
        (Array.toList candidates |> List.map row)


rowValueView : { candidateId : Int, value : UserInputInt } -> Html Msg
rowValueView { candidateId, value } =
    let
        iconSize =
            32

        oneStar cls points =
            FeatherIcons.star
                |> FeatherIcons.withSize iconSize
                |> FeatherIcons.toHtml
                    [ SAttr.class "star-poll-option star-poll-star"
                    , SAttr.class cls
                    , SEvent.onClick <| SetStarValue { id = candidateId, value = points * 20 }
                    ]

        oneStarDisabled points =
            oneStar "disabled" points

        oneStarEnabled points =
            oneStar "enabled" points

        noStarState =
            case value of
                UserInputInt.Valid v ->
                    if v > 0 then
                        "enabled"

                    else
                        "disabled"

                _ ->
                    "disabled"

        noStars =
            FeatherIcons.x
                |> FeatherIcons.withSize iconSize
                |> FeatherIcons.toHtml
                    [ SAttr.class "star-poll-option star-poll-none"
                    , SAttr.class noStarState
                    , SEvent.onClick <| SetStarValue { id = candidateId, value = 0 }
                    ]

        pointsToStar p =
            if p == 0 then
                noStars

            else
                case value of
                    UserInputInt.Valid v ->
                        if p * 20 <= v then
                            oneStarEnabled p

                        else
                            oneStarDisabled p

                    _ ->
                        oneStarDisabled p

        stars =
            List.range 0 5 |> List.map pointsToStar

        starRankView =
            div [ class "star-poll-rank" ] stars

        nestedInputView =
            inputView { value = value, candidateId = candidateId }
    in
    div [ class "star-poll-value" ]
        [ nestedInputView
        , starRankView
        ]


inputView : { candidateId : Int, value : UserInputInt } -> Html Msg
inputView { candidateId, value } =
    let
        inputField =
            input
                [ Html.Attributes.value <| UserInputInt.toString value
                , type_ "number"
                , class "star-poll-input"
                , Html.Attributes.min "0"
                , Html.Attributes.max "100"
                , onInput <| SetStringValue candidateId
                , onFocus <| SetFocusable True
                ]
                []

        progressView =
            case value of
                UserInputInt.Valid v ->
                    div [ class "star-poll-progress-parent" ]
                        [ progress [ Html.Attributes.max "100", Html.Attributes.value <| String.fromInt <| v ] []
                        ]

                _ ->
                    div [] []
    in
    div [ class "star-poll-edit" ]
        [ inputField
        , progressView
        ]
