module Polls.SinglePoll exposing
    ( Model
    , Msg
    , deserialize
    , init
    , serialize
    , update
    , view
    )

import Candidates
import Component
import FeatherIcons
import Html exposing (Html, div, h1, h2, input, label, section, text)
import Html.Attributes exposing (attribute, checked, class, name, type_)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig)


type Msg
    = SetValue Int


type alias Model =
    { value : Int
    }


init : Model
init =
    { value = 0
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetValue id ->
            { model | value = id }


type alias ViewConfig =
    { title : String
    , desc : Html Msg
    , prefix : String
    , icon : FeatherIcons.Icon
    , pollClass : String
    }


view : ViewConfig -> PollConfig -> Model -> Html Msg
view viewConfig pollConfig model =
    let
        row candidate =
            div [ class "poll-row", onClick <| SetValue candidate.id ]
                [ Component.candidateView candidate
                , rowValueView viewConfig { model = model, candidate = candidate }
                ]
    in
    section [ class "poll", class viewConfig.pollClass ]
        [ div [ class "wide" ]
            [ headerView viewConfig ]
        , div [ class "narrow" ]
            [ div
                [ class "single-poll" ]
                (List.map row pollConfig.candidates)
            ]
        ]


headerView : ViewConfig -> Html Msg
headerView viewConfig =
    let
        heading =
            h2 [] [ text "Výběr kandidáta" ]
    in
    div
        []
        [ h1 [ class "poll-heading" ] [ text viewConfig.title ]
        , div [ class "poll-info single-poll-info" ]
            [ viewConfig.desc
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


rowValueView : ViewConfig -> { candidate : Candidates.Candidate, model : Model } -> Html Msg
rowValueView viewConfig { candidate, model } =
    let
        radio =
            label
                [ attribute "aria-label" candidate.name ]
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ viewConfig.prefix ]
                    , Html.Attributes.value <| String.fromInt candidate.id
                    , checked <| candidate.id == model.value
                    , onInput <| \_ -> SetValue candidate.id
                    ]
                    []
                , optionSvg viewConfig
                ]
    in
    div [ class "single-poll-value" ] [ radio ]


optionSvg : ViewConfig -> Html Msg
optionSvg viewConfig =
    div [ class "single-poll-option" ]
        [ viewConfig.icon |> FeatherIcons.withSize 32 |> FeatherIcons.toHtml [] ]


serialize : Model -> Json.Encode.Value
serialize model =
    Json.Encode.int model.value


deserialize : Json.Decode.Decoder Model
deserialize =
    Json.Decode.map Model Json.Decode.int
