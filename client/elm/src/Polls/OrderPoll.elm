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
import Dict exposing (Dict)
import FeatherIcons
import Html exposing (Attribute, Html, button, div, h1, h2, input, option, p, section, select, span, text)
import Html.Attributes exposing (class, disabled, selected, style, tabindex, title, type_, value)
import Html.Events exposing (onInput)
import Json.Decode as Decode
import Set
import Svg.Attributes as SAttr
import Svg.Events as SEvent
import UserInputInt exposing (UserInputInt)


type Msg
    = SetValue { order : Int, value : String }


type alias Model =
    { values : Array (Maybe Int)
    }


init : Array Candidate -> Model
init candidates =
    { values = Array.map (\_ -> Nothing) candidates
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetValue { order, value } ->
            let
                id =
                    String.toInt value

                updatedValues =
                    Array.set order id model.values
            in
            { model | values = updatedValues }


view : Model -> Array Candidate -> Html Msg
view model candidates =
    let
        assignedIds =
            Set.fromList <| List.filterMap identity <| Array.toList model.values

        freeCandidates selfId =
            candidates
                |> Array.toList
                |> List.filter (\candidate -> candidate.id == selfId || (not <| Set.member candidate.id assignedIds))

        selectedAttr candidate selfId =
            if candidate.id == selfId then
                [ selected True ]

            else
                []

        options index selfId =
            select [ onInput (\v -> SetValue { order = index, value = v }) ]
                (option [ value "-" ] [ text "Prosím vyberte" ]
                    :: List.map (\c -> option (selectedAttr c selfId ++ [ value <| String.fromInt c.id ]) [ text c.name ]) (freeCandidates selfId)
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
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView candidates ]
        , div [ class "narrow" ]
            (Array.toList model.values |> List.indexedMap row)
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
