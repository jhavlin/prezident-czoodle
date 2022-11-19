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
import Random exposing (Generator)
import Set exposing (Set)
import Svg.Events as SEvent


type Msg
    = SetValue { order : Int, value : String }
    | Reset
    | CompleteRandomly
    | SetRandomly (List Int)


type alias Model =
    { values : Array (Maybe Int)
    , toRevert : Maybe (Array (Maybe Int))
    }


init : Array Candidate -> Model
init candidates =
    { values = Array.map (\_ -> Nothing) candidates
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
            ( { model | values = updatedValues }, Cmd.none )

        Reset ->
            ( { model | values = Array.map (\_ -> Nothing) model.values, toRevert = Just model.values }, Cmd.none )

        CompleteRandomly ->
            let
                n =
                    List.length <| freeCandidates Candidates.all model.values Nothing

                counts =
                    List.range 0 (n - 1) -- keep reversed here, it will be reversed back in randomList inner fn

                randomList : Generator (List Int)
                randomList =
                    let
                        fn : Int -> Generator (List Int) -> Generator (List Int)
                        fn limit acc =
                            Random.andThen (\r -> Random.map (\i -> i :: r) (Random.int 0 limit)) acc
                    in
                    -- Random.andThen (\v -> Random.int 0 m)
                    List.foldl fn (Random.constant []) counts

                cmd =
                    Random.generate SetRandomly randomList
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


takeNthFromList : Int -> List a -> ( Maybe a, List a )
takeNthFromList n list =
    let
        before =
            List.take n list

        rest =
            List.drop n list
    in
    ( List.head rest, before ++ List.drop 1 rest )


assignedIds : Array (Maybe Int) -> Set Int
assignedIds values =
    Set.fromList <| List.filterMap identity <| Array.toList values


freeCandidates : Array Candidate -> Array (Maybe Int) -> Maybe Int -> List Candidate
freeCandidates candidates values selfId =
    candidates
        |> Array.toList
        |> List.filter (\candidate -> Just candidate.id == selfId || (not <| Set.member candidate.id (assignedIds values)))


view : Model -> Array Candidate -> Html Msg
view model candidates =
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
                    option (selectedAttr c selfId ++ [ value <| String.fromInt c.id ]) [ text c.name ]
            in
            select [ onInput (\v -> SetValue { order = index, value = v }) ]
                (option [ value "-" ] [ text "Prosím vyberte" ]
                    :: List.map opt (freeCandidates candidates model.values (Just selfId))
                )

        row index candidateIdMaybe =
            let
                candidateMaybe =
                    Maybe.andThen (\candidateId -> Array.get candidateId candidates) candidateIdMaybe

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
            in
            div [ class "order-poll-row" ]
                [ div [ class "order-poll-row-order" ] [ text <| String.fromInt (index + 1), text "." ]
                , photoOrPlaceholder
                , div [ class "order-poll-row-select" ]
                    [ options index <| Maybe.withDefault -1 <| Maybe.map (\c -> c.id) candidateMaybe ]
                , div [ class "order-poll-row-points" ]
                    [ text "("
                    , text <| String.fromInt (Array.length candidates - index)
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

        refreshButton =
            button
                [ disabled <| Set.isEmpty assigned
                , onClick Reset
                ]
                [ FeatherIcons.refreshCw
                    |> FeatherIcons.withSize 16
                    |> FeatherIcons.toHtml []
                , div [] [ text "Začít znovu" ]
                ]

        finishButton =
            button
                [ disabled <| Set.size assigned == Array.length candidates || Set.isEmpty assigned
                , onClick CompleteRandomly
                ]
                [ FeatherIcons.skipForward
                    |> FeatherIcons.withSize 16
                    |> FeatherIcons.toHtml []
                , div [] [ text "Doplnit náhodně" ]
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView candidates ]
        , div [ class "narrow" ]
            (Array.toList model.values |> List.indexedMap row)
        , div [ class "narrow" ]
            [ div [ class "poll-buttons" ]
                [ refreshButton, finishButton ]
            ]
        ]


headerView : Array Candidate -> Html Msg
headerView candidates =
    let
        heading =
            h2 [] [ text "Pořadí kandidátů" ]
    in
    div
        []
        [ h1 [ class "star-poll-heading" ] [ text "Hlasování řazením" ]
        , div [ class "star-poll-info" ]
            [ p []
                [ text <|
                    String.concat
                        [ "Seřaďte kandidáty podle důvěry, kterou jim přisuzujete. Nejdůvěrohodnějšího kandidáta "
                        , "zvolte na prvním místě (získá "
                        , String.fromInt <| Array.length candidates
                        , " bodů) a nejméně důvěryhodného kandidáta umístěte na poslední místo (získá 1 bod)."
                        ]
                ]
            ]
        , div
            [ class "star-poll-title"
            ]
            [ heading ]
        ]
