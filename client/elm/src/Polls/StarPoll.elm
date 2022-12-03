module Polls.StarPoll exposing
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
import Html exposing (Attribute, Html, button, div, h1, h2, input, p, section, span, text)
import Html.Attributes exposing (class, disabled, style, tabindex, title, type_)
import Html.Events exposing (keyCode, on, onClick, onFocus, onInput)
import Json.Decode as Decode
import Json.Encode
import Polls.Common exposing (PollConfig)
import Svg.Attributes as SAttr
import Svg.Events as SEvent
import UserInputInt exposing (UserInputInt)


type Msg
    = SetStringValue Int String
    | SetStarValue { id : Int, value : Int }
    | SetEditMode Bool
    | KeyPressed Int


type alias Model =
    { values : Dict Int UserInputInt
    , editMode : Bool
    }


init : Model
init =
    { values = Dict.empty
    , editMode = False
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

        SetEditMode editMode ->
            { model | editMode = editMode }

        KeyPressed keyCode ->
            if keyCode == 27 then
                { model | editMode = False }

            else
                model


onKeyUp : (Int -> msg) -> Attribute msg
onKeyUp tagger =
    on "keyup" (Decode.map tagger keyCode)


view : PollConfig -> Model -> Html Msg
view pollConfig model =
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

        isCustomValue userInputInt =
            case userInputInt of
                UserInputInt.Valid v ->
                    remainderBy 20 v /= 0

                UserInputInt.Invalid _ _ ->
                    True

        isCustomPoll =
            Dict.values model.values |> List.any isCustomValue

        customClass =
            if isCustomPoll || model.editMode then
                "custom"

            else
                ""

        onKeyUpHandler =
            if isCustomPoll then
                []

            else
                [ onKeyUp KeyPressed ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView isCustomPoll model ]
        , div [ class "narrow" ]
            [ div
                (onKeyUpHandler
                    ++ [ class "star-poll"
                       , class customClass
                       ]
                )
                (List.map row pollConfig.candidates)
            ]
        ]


headerView : Bool -> Model -> Html Msg
headerView isCustomPoll model =
    let
        heading =
            h2 [] [ text "Hodnocení kandidátů" ]

        icon =
            if isCustomPoll || model.editMode then
                FeatherIcons.star |> FeatherIcons.toHtml []

            else
                FeatherIcons.percent |> FeatherIcons.toHtml []

        tooltip =
            if not model.editMode then
                "Přepnout do precentuálního režimu"

            else if model.editMode && not isCustomPoll then
                "Přepnout do hvězdičkového režimu"

            else
                "Nelze přepnout do hvězdičkového režimu, některé hodnoty nejsou dělitelné 20"

        switchButton =
            button
                [ tabindex -1
                , disabled isCustomPoll
                , title tooltip
                , onClick <| SetEditMode <| not model.editMode
                ]
                [ icon
                ]
    in
    div
        []
        [ h1 [ class "poll-heading" ] [ text "Hvězdičkové hlasování" ]
        , div [ class "poll-info" ]
            [ p []
                [ text <|
                    String.concat
                        [ "V tomto hlasování každému kandidátovi přidělíte 0 až 5 hvězdiček. "
                        , "Jedna hvězdička představuje 20 % vaší důvěry. Můžete také přepnout do procentuálního režimu "
                        , "a zadat hodnoty s přesností na jednotky procent. Tento režim se zapne také automaticky "
                        , "při ovládání klávesnicí."
                        ]
                ]
            ]
        , div
            [ class "poll-title"
            ]
            [ heading, switchButton ]
        ]


rowValueView : { candidateId : Int, value : UserInputInt } -> Html Msg
rowValueView { candidateId, value } =
    let
        iconSize =
            32

        oneStar cls points =
            span
                [ title <| String.concat [ String.fromInt (points * 20), "%" ]
                , class "star-poll-option star-poll-star"
                , class cls
                ]
                [ FeatherIcons.star
                    |> FeatherIcons.withSize iconSize
                    |> FeatherIcons.toHtml
                        [ SAttr.title <| String.concat [ String.fromInt (points * 20), "%" ]
                        , SEvent.onClick <| SetStarValue { id = candidateId, value = points * 20 }
                        ]
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
            span
                [ title "0%"
                , class "star-poll-option action-unset"
                , class noStarState
                ]
                [ FeatherIcons.x
                    |> FeatherIcons.withSize iconSize
                    |> FeatherIcons.toHtml
                        [ SEvent.onClick <| SetStarValue { id = candidateId, value = 0 }
                        , SAttr.title "0%"
                        ]
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
                , onFocus <| SetEditMode True
                ]
                []

        progressView =
            case value of
                UserInputInt.Valid v ->
                    div
                        [ class "star-poll-percent-bar"
                        , style "background" <|
                            String.concat
                                [ "linear-gradient(to right, yellow 0, yellow "
                                , String.fromInt v
                                , "%, #555 "
                                , String.fromInt v
                                , "%, #555 100%)"
                                ]
                        ]
                        []

                _ ->
                    div [ class "star-poll-percent-bar" ] [ text "Není %" ]
    in
    div [ class "star-poll-edit" ]
        [ progressView
        , inputField
        ]


serialize : Model -> Json.Encode.Value
serialize model =
    let
        userInputToString userInput =
            case userInput of
                UserInputInt.Valid v ->
                    String.fromInt v

                UserInputInt.Invalid s _ ->
                    s
    in
    Polls.Common.serializeStringDict <| Dict.map (\_ v -> userInputToString v) model.values
