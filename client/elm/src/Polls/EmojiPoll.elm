module Polls.EmojiPoll exposing
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
import Candidates
import Component
import Dict exposing (Dict)
import Html exposing (Html, div, h1, h2, input, section, text)
import Html.Attributes exposing (class, maxlength, type_)
import Html.Events exposing (onInput)
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig, Summary(..), Validation(..))


type Msg
    = SetValue Int String


type alias Model =
    { values : Dict Int String
    }


init : Model
init =
    { values = Dict.empty
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetValue id string ->
            { model | values = Dict.insert id string model.values }


view : PollConfig -> Model -> Html Msg
view pollConfig model =
    let
        row candidate =
            div [ class "poll-row" ]
                [ Component.candidateView candidate
                , rowValueView { model = model, candidate = candidate }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ div
                [ class "emoji-poll" ]
                (List.map row pollConfig.candidates)
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
        [ h1 [ class "poll-heading" ] [ text "Bonus: Emoji Hlasování" ]
        , div [ class "poll-info emoji-poll-info" ]
            [ text "Přiřaďte každé osobnosti emoji nebo textového smajlíka (až 3 znaky)."
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


rowValueView : { candidate : Candidates.Candidate, model : Model } -> Html Msg
rowValueView { candidate, model } =
    let
        field =
            input
                [ type_ "text"
                , Html.Attributes.value <| Maybe.withDefault "" <| Dict.get candidate.id model.values
                , onInput <| SetValue candidate.id
                , maxlength 3
                , class "emoji-poll-input"
                ]
                []
    in
    div [ class "emoji-poll-value" ] [ field ]


serialize : Model -> Json.Encode.Value
serialize model =
    Polls.Common.serializeStringDict model.values


deserialize : Json.Decode.Decoder Model
deserialize =
    Json.Decode.map Model <| Polls.Common.deserializeStringDict


summarize : Model -> Polls.Common.Summary
summarize model =
    let
        validValueCount =
            Dict.values model.values
                |> List.map String.trim
                |> List.filter (not << String.isEmpty)
                |> List.length

        ( warningText, status ) =
            if validValueCount /= Array.length Candidates.all then
                ( " Některým kandidátům nebylo emoji přidělno.", Warning )

            else
                ( "", Valid )

        items =
            Dict.toList model.values
                |> List.filter (\( _, v ) -> not <| String.isEmpty <| String.trim v)
                |> List.filterMap (\( k, v ) -> Maybe.map (\c -> ( c, v )) (Array.get k Candidates.all))
                |> List.sortBy (\( c, _ ) -> c.surname)
                |> List.map (\( c, v ) -> String.concat [ c.name, "\u{00A0}", v ])
                |> Component.itemsString ", " " a "

        summaryText =
            String.concat
                [ "V emoji hlasování jste přidělili tyto smajlíky:  "
                , items
                , "."
                , warningText
                ]

        html =
            div [] [ text summaryText ]
    in
    if validValueCount == 0 then
        Summary Warning <| div [] [ text "Emoji hlasování není vyplněno (dobrovolné)." ]

    else
        Summary status html
