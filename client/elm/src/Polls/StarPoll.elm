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
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Svg.Attributes as SAttr
import Svg.Events as SEvent


type Msg
    = SetValue { id : Int, value : Int }


type alias Model =
    { values : Dict Int Int
    , count : Int
    }


init : Model
init =
    { values = Dict.empty
    , count = 0
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


view : Model -> Array Candidate -> Html Msg
view model candidates =
    let
        row candidate =
            let
                value =
                    Maybe.withDefault 0 <| Dict.get candidate.id model.values
            in
            div [ class "star-poll-row" ]
                [ Component.candidateView candidate
                , starRankView { value = value, candidateId = candidate.id }
                ]
    in
    div []
        (Array.toList candidates |> List.map row)


starRankView : { candidateId : Int, value : Int } -> Html Msg
starRankView { candidateId, value } =
    let
        oneStar cls points =
            FeatherIcons.star
                |> FeatherIcons.withSize 32
                |> FeatherIcons.toHtml [ SAttr.class cls, SEvent.onClick <| SetValue { id = candidateId, value = points } ]

        oneStarDisabled points =
            oneStar "star-poll-star" points

        oneStarEnabled points =
            oneStar "star-poll-star enabled" points

        pointsToStar p =
            if p <= value then
                oneStarEnabled p

            else
                oneStarDisabled p

        stars =
            List.range 1 5 |> List.map pointsToStar
    in
    div [ class "star-poll-rank" ] stars
