module Polls.OneRoundPoll exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Array
import Candidates
import Component
import FeatherIcons
import Html exposing (Html, div, h1, h2, input, label, p, section, text)
import Html.Attributes exposing (attribute, checked, class, name, type_)
import Html.Events exposing (onClick, onInput)


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


view : Model -> Html Msg
view model =
    let
        row candidate =
            div [ class "poll-row", onClick <| SetValue candidate.id ]
                [ Component.candidateView candidate
                , rowValueView { model = model, candidate = candidate }
                ]
    in
    section [ class "poll" ]
        [ div [ class "wide" ]
            [ headerView ]
        , div [ class "narrow" ]
            [ div
                [ class "one-round-poll" ]
                (Array.toList Candidates.all |> List.map row)
            ]
        ]


headerView : Html Msg
headerView =
    let
        heading =
            h2 [] [ text "Výběr kandidáta" ]
    in
    div
        []
        [ h1 [ class "poll-heading" ] [ text "Jednokolová volba" ]
        , div [ class "poll-info one-round-poll-info" ]
            [ p []
                [ text "Vyberte kandidáta, kterého byste volili v případně jednokolového "
                , text "volebního systému."
                ]
            ]
        , div
            [ class "poll-title"
            ]
            [ heading ]
        ]


rowValueView : { candidate : Candidates.Candidate, model : Model } -> Html Msg
rowValueView { candidate, model } =
    let
        radio =
            label
                [ attribute "aria-label" candidate.name ]
                [ input
                    [ type_ "radio"
                    , name <| String.concat [ "one-round" ]
                    , Html.Attributes.value <| String.fromInt candidate.id
                    , checked <| candidate.id == model.value
                    , onInput <| \_ -> SetValue candidate.id
                    ]
                    []
                , optionSvg
                ]
    in
    div [ class "one-round-poll-value" ] [ radio ]


optionSvg : Html Msg
optionSvg =
    div [ class "one-round-option" ]
        [ FeatherIcons.check |> FeatherIcons.withSize 32 |> FeatherIcons.toHtml [] ]
