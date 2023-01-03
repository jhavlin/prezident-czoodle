module Polls.OrderPoll exposing
    ( Model
    , Msg
    , deserialize
    , init
    , serialize
    , summarize
    , update
    , view
    )

import Array exposing (Array)
import Candidates exposing (Candidate)
import Component
import Dict
import FeatherIcons
import Html exposing (Html, button, div, h1, h2, li, option, p, section, select, text)
import Html.Attributes exposing (class, disabled, selected, value)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig, Summary(..), Validation(..), editableClass)
import Random
import RandomUtils exposing (takeNthFromList)
import Set exposing (Set)
import Svg.Events as SEvent


type Msg
    = SetValue { order : Int, value : String }
    | Reset
    | CompleteRandomly
    | SetRandomly (List Int)
    | RevertLastAction
    | Move { index : Int, direction : Int }


type alias Model =
    { values : Array (Maybe Int)
    , toRevert : Maybe (Array (Maybe Int))
    }


init : Model
init =
    { values = Array.map (\_ -> Nothing) Candidates.all
    , toRevert = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetValue { order, value } ->
            let
                id =
                    String.toInt value

                updatedValues =
                    Array.set order id model.values

                completedValues =
                    case ( id, freeCandidates Candidates.all updatedValues Nothing ) of
                        ( Just _, c :: [] ) ->
                            -- just set an value and there is only one free candidate left
                            let
                                fill maybeId =
                                    case maybeId of
                                        Nothing ->
                                            Just c.id

                                        a ->
                                            a
                            in
                            Array.map fill updatedValues

                        _ ->
                            updatedValues
            in
            ( { model | values = completedValues, toRevert = Nothing }, Cmd.none )

        Reset ->
            ( { model | values = Array.map (\_ -> Nothing) model.values, toRevert = Just model.values }, Cmd.none )

        CompleteRandomly ->
            let
                n =
                    List.length <| freeCandidates Candidates.all model.values Nothing

                cmd =
                    Random.generate SetRandomly <| RandomUtils.decreasingRandomIntList n
            in
            ( model, cmd )

        SetRandomly randomValues ->
            let
                freeIdList =
                    freeCandidates Candidates.all model.values Nothing |> List.map (\c -> c.id)

                fn : Maybe Int -> ( List Int, List Int, List (Maybe Int) ) -> ( List Int, List Int, List (Maybe Int) )
                fn maybeValue ( random, remainingFree, values ) =
                    case maybeValue of
                        Just _ ->
                            ( random, remainingFree, maybeValue :: values )

                        Nothing ->
                            let
                                ( randomItem, newRemainingFree ) =
                                    takeNthFromList (Maybe.withDefault 0 <| List.head random) remainingFree
                            in
                            ( List.drop 1 random, newRemainingFree, randomItem :: values )

                ( _, _, completedListReversed ) =
                    Array.foldl fn ( randomValues, freeIdList, [] ) model.values

                completed =
                    Array.fromList <| List.reverse <| completedListReversed
            in
            ( { model | toRevert = Just model.values, values = completed }, Cmd.none )

        RevertLastAction ->
            ( { model | values = Maybe.withDefault model.values model.toRevert, toRevert = Nothing }, Cmd.none )

        Move { index, direction } ->
            let
                newPosition =
                    index + direction

                source : Maybe Int
                source =
                    Array.get index model.values |> Maybe.andThen identity

                target : Maybe Int
                target =
                    Array.get newPosition model.values |> Maybe.andThen identity
            in
            if newPosition < 0 || newPosition >= Array.length Candidates.all then
                ( model, Cmd.none )

            else
                case ( source, target ) of
                    ( Just _, Just _ ) ->
                        let
                            newValues =
                                model.values
                                    |> Array.set newPosition source
                                    |> Array.set index target
                        in
                        ( { model | values = newValues, toRevert = Nothing }, Cmd.none )

                    ( Just _, Nothing ) ->
                        let
                            newValues =
                                model.values
                                    |> Array.set index Nothing
                                    |> Array.set newPosition source
                        in
                        ( { model | values = newValues, toRevert = Nothing }, Cmd.none )

                    _ ->
                        ( model, Cmd.none )


assignedIds : Array (Maybe Int) -> Set Int
assignedIds values =
    Set.fromList <| List.filterMap identity <| Array.toList values


freeCandidates : Array Candidate -> Array (Maybe Int) -> Maybe Int -> List Candidate
freeCandidates candidates values selfId =
    candidates
        |> Array.toList
        |> List.filter (\candidate -> Just candidate.id == selfId || (not <| Set.member candidate.id (assignedIds values)))


view : PollConfig -> Model -> Html Msg
view pollConfig model =
    let
        assigned =
            assignedIds model.values

        selectedAttr candidate selfId =
            if candidate.id == selfId then
                [ selected True ]

            else
                []

        options index selfId =
            let
                opt c =
                    option (selectedAttr c selfId ++ [ value <| String.fromInt c.id ]) [ text <| String.concat [ c.name ] ]
            in
            select [ onInput (\v -> SetValue { order = index, value = v }) ]
                (option [ value "-" ] [ text "Prosím vyberte" ]
                    :: List.map opt (freeCandidates (Array.fromList pollConfig.candidates) model.values (Just selfId))
                )

        optionsOrStatic index selfId =
            if pollConfig.readOnly then
                text <| Maybe.withDefault "" <| Maybe.map .name <| Array.get selfId Candidates.all

            else
                options index selfId

        row index candidateIdMaybe =
            let
                candidateMaybe =
                    Maybe.andThen (\candidateId -> Array.get candidateId Candidates.all) candidateIdMaybe

                photoOrPlaceholder =
                    case candidateMaybe of
                        Just candidate ->
                            Component.candidatePhoto candidate

                        Nothing ->
                            div [ class "order-poll-row-photo-placeholder" ]
                                [ FeatherIcons.user
                                    |> FeatherIcons.withSize 32
                                    |> FeatherIcons.toHtml
                                        [ SEvent.onClick <| SetValue { order = index, value = "-" }
                                        ]
                                ]

                enabledClass condition =
                    if condition then
                        "enabled"

                    else
                        "disabled"

                assignedState =
                    case candidateMaybe of
                        Just _ ->
                            "assigned"

                        _ ->
                            "unassigned"
            in
            li [ class "order-poll-row", editableClass pollConfig ]
                [ div [ class "order-poll-row-order", class assignedState ]
                    [ text <| String.fromInt (index + 1), text "." ]
                , photoOrPlaceholder
                , div [ class "order-poll-row-select" ]
                    [ optionsOrStatic index <| Maybe.withDefault -1 <| Maybe.map (\c -> c.id) candidateMaybe ]
                , div [ class "order-poll-row-actions" ]
                    [ div [ class "order-poll-row-buttons", class assignedState, editableClass pollConfig ]
                        [ div
                            [ class "order-poll-row-button"
                            , class "up"
                            , class <| enabledClass (index > 0)
                            ]
                            [ FeatherIcons.chevronUp
                                |> FeatherIcons.withSize 36
                                |> FeatherIcons.toHtml
                                    [ SEvent.onClick <| Move { index = index, direction = -1 }
                                    ]
                            ]
                        , div
                            [ class "order-poll-row-button"
                            , class "down"
                            , class <| enabledClass (index + 1 < Array.length Candidates.all)
                            ]
                            [ FeatherIcons.chevronDown
                                |> FeatherIcons.withSize 36
                                |> FeatherIcons.toHtml
                                    [ SEvent.onClick <| Move { index = index, direction = 1 }
                                    ]
                            ]
                        ]
                    , div [ class "order-poll-row-points", class assignedState, editableClass pollConfig ]
                        [ text "("
                        , text <| String.fromInt (Array.length Candidates.all - index)
                        , text " b)"
                        ]
                    ]
                ]

        buttonSize =
            16

        refreshButton =
            button
                [ disabled <| Set.isEmpty assigned
                , onClick Reset
                ]
                [ FeatherIcons.refreshCw
                    |> FeatherIcons.withSize buttonSize
                    |> FeatherIcons.toHtml []
                , div [] [ text "Začít znovu" ]
                ]

        completeRandomlyButton =
            button
                [ disabled <| Set.size assigned == Array.length Candidates.all || Set.isEmpty assigned
                , onClick CompleteRandomly
                ]
                [ FeatherIcons.skipForward
                    |> FeatherIcons.withSize buttonSize
                    |> FeatherIcons.toHtml []
                , div [] [ text "Doplnit náhodně" ]
                ]

        revertButton =
            button
                [ onClick RevertLastAction
                , class "no-chrome"
                ]
                [ FeatherIcons.arrowLeft
                    |> FeatherIcons.withSize buttonSize
                    |> FeatherIcons.toHtml []
                , div [] [ text "Vzít zpět" ]
                ]

        buttons =
            case model.toRevert of
                Just _ ->
                    [ revertButton ]

                Nothing ->
                    [ refreshButton, completeRandomlyButton ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ Html.Keyed.ol [ class "poll-rows" ]
                (Array.toList model.values |> List.indexedMap (\i v -> ( "order-poll-" ++ String.fromInt i, row i v )))
            ]
        , div [ class "narrow" ]
            [ if pollConfig.readOnly then
                text ""

              else
                div [ class "poll-buttons" ]
                    buttons
            ]
        ]


headerView : Html Msg
headerView =
    let
        heading =
            h2 [] [ text "Pořadí kandidátů" ]
    in
    div
        []
        [ h1 [ class "poll-heading" ] [ text "Hlasování řazením" ]
        , div [ class "poll-info" ]
            [ p []
                [ text <|
                    String.concat
                        [ "Seřaďte kandidáty podle důvěry, kterou jim přisuzujete. Nejdůvěrohodnějšího kandidáta "
                        , "zvolte na prvním místě (získá "
                        , String.fromInt <| Array.length Candidates.all
                        , " bodů) a nejméně důvěryhodného kandidáta umístěte na poslední místo (získá 1 bod)."
                        ]
                ]
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


serialize : Model -> Json.Encode.Value
serialize model =
    let
        len =
            Array.length Candidates.all

        candidatesAndPoints =
            Array.toList model.values
                |> List.indexedMap (\i mId -> ( mId, len - i ))
                |> List.filterMap (\( mId, p ) -> Maybe.map (\cId -> ( cId, p )) mId)
                |> Dict.fromList

        points =
            Candidates.all
                |> Array.map (\candidate -> Dict.get candidate.id candidatesAndPoints)
                |> Array.map (Maybe.withDefault -1)
    in
    Json.Encode.array Json.Encode.int points


deserialize : Json.Decode.Decoder Model
deserialize =
    let
        len =
            Array.length Candidates.all

        pointsToOrder : Array Int -> Array (Maybe Int)
        pointsToOrder points =
            let
                ordersAndCandidates =
                    Array.toList points
                        |> List.indexedMap (\i p -> ( i, p ))
                        |> List.filter (\( _, p ) -> p > 0)
                        |> List.map (\( i, p ) -> ( len - p, i ))
                        |> Dict.fromList
            in
            Candidates.all
                |> Array.indexedMap (\i _ -> Dict.get i ordersAndCandidates)
    in
    Json.Decode.map2 Model
        (Json.Decode.map pointsToOrder <| Json.Decode.array Json.Decode.int)
        (Json.Decode.succeed Nothing)


summarize : Model -> Polls.Common.Summary
summarize model =
    let
        assignedSet =
            Array.toList model.values
                |> List.filterMap identity
                |> Set.fromList

        fullyAssigned =
            Array.toList Candidates.all
                |> List.all (\c -> Set.member c.id assignedSet)
    in
    if not fullyAssigned then
        let
            html =
                div [] [ text "V\u{00A0}hlasování řazením nebyly zařazeny všechny osoby." ]
        in
        Summary Error html

    else
        let
            surnames =
                Array.toList model.values
                    |> List.map (\v -> Maybe.andThen (\id -> Array.get id Candidates.all) v)
                    |> List.filterMap identity
                    |> List.map .surname
                    |> Component.itemsString ", " " a "

            summaryText =
                String.concat
                    [ "V hlasování řazením jste zvolili pořadí  "
                    , surnames
                    , "."
                    ]

            html =
                div [] [ text summaryText ]
        in
        Summary Valid html
