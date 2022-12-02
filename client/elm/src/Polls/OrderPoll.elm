module Polls.OrderPoll exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Array exposing (Array)
import Candidates exposing (Candidate)
import Component
import FeatherIcons
import Html exposing (Html, button, div, h1, h2, option, p, section, select, text)
import Html.Attributes exposing (class, disabled, selected, value)
import Html.Events exposing (onClick, onInput)
import Polls.Common exposing (PollConfig)
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
            in
            ( { model | values = updatedValues, toRevert = Nothing }, Cmd.none )

        Reset ->
            ( { model | values = Array.map (\_ -> Nothing) model.values, toRevert = Just model.values }, Cmd.none )

        CompleteRandomly ->
            let
                n =
                    List.length <| freeCandidates model.values Nothing

                cmd =
                    Random.generate SetRandomly <| RandomUtils.decreasingRandomIntList n
            in
            ( model, cmd )

        SetRandomly randomValues ->
            let
                freeIdList =
                    freeCandidates model.values Nothing |> List.map (\c -> c.id)

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


assignedIds : Array (Maybe Int) -> Set Int
assignedIds values =
    Set.fromList <| List.filterMap identity <| Array.toList values


freeCandidates : Array (Maybe Int) -> Maybe Int -> List Candidate
freeCandidates values selfId =
    Candidates.all
        |> Array.toList
        |> List.filter (\candidate -> Just candidate.id == selfId || (not <| Set.member candidate.id (assignedIds values)))


view : PollConfig -> Model -> Html Msg
view _ model =
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
                    option (selectedAttr c selfId ++ [ value <| String.fromInt c.id ]) [ text <| String.concat [ c.surname, " ", c.firstName ] ]
            in
            select [ onInput (\v -> SetValue { order = index, value = v }) ]
                (option [ value "-" ] [ text "Prosím vyberte" ]
                    :: List.map opt (freeCandidates model.values (Just selfId))
                )

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

                unsetState =
                    case candidateMaybe of
                        Just _ ->
                            "enabled"

                        _ ->
                            "disabled"

                assignedState =
                    case candidateMaybe of
                        Just _ ->
                            "assigned"

                        _ ->
                            "unassigned"
            in
            div [ class "order-poll-row" ]
                [ div [ class "order-poll-row-order", class assignedState ]
                    [ text <| String.fromInt (index + 1), text "." ]
                , photoOrPlaceholder
                , div [ class "order-poll-row-select" ]
                    [ options index <| Maybe.withDefault -1 <| Maybe.map (\c -> c.id) candidateMaybe ]
                , div [ class "order-poll-row-points", class assignedState ]
                    [ text "("
                    , text <| String.fromInt (Array.length Candidates.all - index)
                    , text " b)"
                    ]
                , div [ class "action-unset", class unsetState ]
                    [ FeatherIcons.x
                        |> FeatherIcons.withSize 32
                        |> FeatherIcons.toHtml
                            [ SEvent.onClick <| SetValue { order = index, value = "-" }
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
            (Array.toList model.values |> List.indexedMap row)
        , div [ class "narrow" ]
            [ div [ class "poll-buttons" ]
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
