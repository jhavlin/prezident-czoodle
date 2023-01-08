module Polls.SinglePoll exposing
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
import Component exposing (ariaHidden, ariaLabel)
import FeatherIcons
import Html exposing (Html, div, h1, h2, input, label, li, section, text)
import Html.Attributes exposing (checked, class, name, type_)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import Json.Decode
import Json.Encode
import Polls.Common exposing (PollConfig, Summary(..), Validation(..), editableClass)


type Msg
    = SetValue Int


type alias Model =
    { value : Int
    }


init : Model
init =
    { value = -1
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
            li [ class "poll-row", editableClass pollConfig, onClick <| SetValue candidate.id ]
                [ Component.candidateView candidate
                , rowValueView viewConfig { model = model, candidate = candidate }
                ]
    in
    section [ class "poll", class viewConfig.pollClass ]
        [ div [ class "wide" ]
            [ headerView viewConfig ]
        , div [ class "narrow" ]
            [ Html.Keyed.ul [ class "single-poll poll-rows", editableClass pollConfig ]
                (List.map (\c -> ( viewConfig.pollClass ++ String.fromInt c.id, row c )) pollConfig.candidates)
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
                []
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ viewConfig.prefix ]
                    , Html.Attributes.value <| String.fromInt candidate.id
                    , checked <| candidate.id == model.value
                    , onInput <| \_ -> SetValue candidate.id
                    , ariaLabel candidate.name
                    ]
                    []
                , optionSvg viewConfig
                ]
    in
    div [ class "single-poll-value" ] [ radio ]


optionSvg : ViewConfig -> Html Msg
optionSvg viewConfig =
    div [ class "single-poll-option", ariaHidden ]
        [ viewConfig.icon |> FeatherIcons.withSize 32 |> FeatherIcons.toHtml [] ]


serialize : Model -> Json.Encode.Value
serialize model =
    Json.Encode.int model.value


deserialize : Json.Decode.Decoder Model
deserialize =
    Json.Decode.map Model Json.Decode.int


summarize : String -> Model -> Polls.Common.Summary
summarize pollName model =
    if model.value >= 0 && model.value < Array.length Candidates.all then
        let
            candidateName =
                Array.get model.value Candidates.all |> Maybe.map .p4 |> Maybe.withDefault "-"

            html =
                div [] [ text <| String.concat [ "V\u{00A0}", pollName, " jste zvolili ", candidateName, "." ] ]
        in
        Summary Valid html

    else
        let
            html =
                div [] [ text <| String.concat [ "V\u{00A0}", pollName, " jste nikoho nezvolili." ] ]
        in
        Summary Error html
