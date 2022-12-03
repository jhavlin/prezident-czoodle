module Polls.TwoRoundPoll exposing
    ( Model
    , Msg
    , init
    , serialize
    , update
    , view
    )

import FeatherIcons
import Html exposing (Html, div, p, text)
import Json.Encode
import Polls.Common exposing (PollConfig)
import Polls.SinglePoll as SinglePoll


type alias Msg =
    SinglePoll.Msg


type alias Model =
    SinglePoll.Model


init : Model
init =
    SinglePoll.init


update : Msg -> Model -> Model
update =
    SinglePoll.update


view : PollConfig -> Model -> Html Msg
view pollConfig model =
    let
        desc =
            div []
                [ p []
                    [ text "Vyberte kandidáta, kterého byste volili v\u{00A0}prvním kole "
                    , text "současného dvoukolového systému."
                    ]
                , p []
                    [ text "Výsledky případného druhého kola odvodíme z\u{00A0}hlasování řazením (viz níže)."
                    ]
                ]

        viewConfig =
            { title = "Dvoukolový systém"
            , desc = desc
            , prefix = "two-round"
            , icon = FeatherIcons.playCircle
            , pollClass = "two-round-poll"
            }
    in
    SinglePoll.view viewConfig pollConfig model


serialize : Model -> Json.Encode.Value
serialize =
    SinglePoll.serialize
