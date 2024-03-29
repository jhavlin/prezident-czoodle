module Polls.StarPoll exposing
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
import Html exposing (Attribute, Html, button, div, h1, h2, input, li, p, section, span, text)
import Html.Attributes exposing (class, disabled, style, tabindex, title, type_)
import Html.Events exposing (keyCode, on, onClick, onFocus, onInput)
import Html.Keyed
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig, Summary(..), Validation(..), editableClass)
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
    on "keyup" (Json.Decode.map tagger keyCode)


view : PollConfig -> Model -> Html Msg
view pollConfig model =
    let
        row candidate =
            let
                value =
                    Maybe.withDefault (UserInputInt.Valid 0) <| Dict.get candidate.id model.values
            in
            li [ class "poll-row" ]
                [ Component.candidateView candidate
                , rowValueView pollConfig { value = value, candidate = candidate }
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
            [ headerView pollConfig isCustomPoll model ]
        , div [ class "narrow" ]
            [ Html.Keyed.ul
                (onKeyUpHandler
                    ++ [ class "star-poll poll-rows"
                       , class customClass
                       ]
                )
                (List.map (\c -> ( "star-poll-" ++ String.fromInt c.id, row c )) pollConfig.candidates)
            ]
        ]


headerView : PollConfig -> Bool -> Model -> Html Msg
headerView pollConfig isCustomPoll model =
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
                "Přepnout do procentuálního režimu"

            else if model.editMode && not isCustomPoll then
                "Přepnout do hvězdičkového režimu"

            else
                "Nelze přepnout do hvězdičkového režimu, některé hodnoty nejsou dělitelné 20"

        switchButton =
            if pollConfig.readOnly then
                text ""

            else
                button
                    [ tabindex -1
                    , disabled isCustomPoll
                    , title tooltip
                    , onClick <| SetEditMode <| not model.editMode
                    , ariaHidden
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
                        [ "Přidělte každé osobnosti 0 až 5 hvězdiček. "
                        , "Jedna hvězdička představuje 20\u{00A0}% vašeho hodnocení."
                        ]
                ]
            , p []
                [ text <|
                    String.concat
                        [ "Můžete také přepnout do procentuálního režimu "
                        , "a zadat hodnoty s\u{00A0}přesností na jednotky procent. Tento režim se zapne automaticky "
                        , "při ovládání klávesnicí."
                        ]
                ]
            ]
        , div
            [ class "poll-title"
            ]
            [ heading, switchButton ]
        ]


rowValueView : PollConfig -> { candidate : Candidate, value : UserInputInt } -> Html Msg
rowValueView pollConfig { candidate, value } =
    let
        candidateId =
            candidate.id

        iconSize =
            32

        oneStar cls points =
            span
                [ title <| String.concat [ String.fromInt (points * 20), "%" ]
                , class "star-poll-option star-poll-star"
                , editableClass pollConfig
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

        range =
            if pollConfig.readOnly then
                List.range 1 5

            else
                List.range 0 5

        stars =
            List.map pointsToStar range

        starRankView =
            div [ class "star-poll-rank", editableClass pollConfig, ariaHidden ] stars

        nestedInputView =
            inputView { value = value, candidate = candidate }
    in
    div [ class "star-poll-value" ]
        [ nestedInputView
        , starRankView
        ]


inputView : { candidate : Candidate, value : UserInputInt } -> Html Msg
inputView { candidate, value } =
    let
        inputField =
            input
                [ Html.Attributes.value <| UserInputInt.toString value
                , type_ "number"
                , class "star-poll-input"
                , Html.Attributes.min "0"
                , Html.Attributes.max "100"
                , onInput <| SetStringValue candidate.id
                , onFocus <| SetEditMode True
                , ariaLabel candidate.name
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
                        , ariaHidden
                        ]
                        []

                _ ->
                    div [ class "star-poll-percent-bar" ] [ text "Není %" ]
    in
    div [ class "star-poll-edit" ]
        [ progressView
        , inputField
        ]


serialize : Bool -> Model -> Json.Encode.Value
serialize final model =
    if final then
        let
            userInputToInt userInput =
                case userInput of
                    UserInputInt.Valid v ->
                        v

                    UserInputInt.Invalid _ _ ->
                        0
        in
        Polls.Common.serializeIntDict <| Dict.map (\_ v -> userInputToInt v) model.values

    else
        let
            userInputToString userInput =
                case userInput of
                    UserInputInt.Valid v ->
                        String.fromInt v

                    UserInputInt.Invalid s _ ->
                        s
        in
        Polls.Common.serializeStringDict <| Dict.map (\_ v -> userInputToString v) model.values


deserialize : Bool -> Json.Decode.Decoder Model
deserialize final =
    if final then
        let
            mapper int =
                UserInputInt.Valid int
        in
        Json.Decode.map2 Model
            (Polls.Common.deserializeMappedIntDict mapper)
            (Json.Decode.succeed False)

    else
        let
            mapper str =
                let
                    trimmed =
                        String.trim str
                in
                if String.isEmpty trimmed then
                    UserInputInt.Valid 0

                else
                    UserInputInt.create userInputConfig trimmed
        in
        Json.Decode.map2 Model
            (Polls.Common.deserializeMappedStringDict mapper)
            (Json.Decode.succeed False)


summarize : Model -> Polls.Common.Summary
summarize model =
    let
        values =
            Dict.values model.values

        isValidInput userInput =
            case userInput of
                UserInputInt.Valid _ ->
                    True

                _ ->
                    False

        allValid =
            List.all isValidInput values

        hasValue userInput =
            case userInput of
                UserInputInt.Valid v ->
                    v > 0 && v <= 100

                _ ->
                    False

        hasFullValue userInput =
            case userInput of
                UserInputInt.Valid v ->
                    v == 100

                _ ->
                    False

        someHasVallue =
            List.any hasValue values

        someHasFullValue =
            List.any hasFullValue values

        userInputToOption userInput =
            case userInput of
                UserInputInt.Valid v ->
                    if v > 0 && v <= 100 then
                        Just v

                    else
                        Nothing

                _ ->
                    Nothing
    in
    if not allValid then
        let
            html =
                div [] [ text "Hvězdičkové (procentuální) hlasování obsahuje nesprávné hodnoty." ]
        in
        Summary Error html

    else if not someHasVallue then
        let
            html =
                div [] [ text "V\u{00A0}hvězdičkovém (procentuálním) hlasovování nebylo pro nikoho hlasováno." ]
        in
        Summary Error html

    else
        let
            ( warningText, status ) =
                if not someHasFullValue then
                    ( " Nikdo nebyl ohodnocen sty procenty. Tím můžete oslabit svůj hlas.", Warning )

                else
                    ( "", Valid )

            percents =
                Dict.toList model.values
                    |> List.filterMap (\( k, v ) -> Maybe.map2 Tuple.pair (Array.get k Candidates.all) (userInputToOption v))
                    |> List.sortBy (\( _, v ) -> v)
                    |> List.reverse
                    |> List.map (\( k, v ) -> String.concat [ k.name, "\u{00A0}", String.fromInt v, "\u{00A0}%" ])
                    |> Component.itemsString ", " " a "

            summaryText =
                String.concat
                    [ "Ve hvězdičkovém hlasování jste svou důvěru ke kandidátům ohodnotili takto:  "
                    , percents
                    , "."
                    , warningText
                    ]

            html =
                div [] [ text summaryText ]
        in
        Summary status html
