module Polls.TwoRoundPoll exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import FeatherIcons
import Html exposing (Html, div, p, text)
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


view : Model -> Html Msg
view model =
    let
        desc =
            div []
                [ p []
                    [ text "Vyberte kandidáta, kterého byste volili v prvním kole "
                    , text "současného dvoukolového systému."
                    ]
                , p []
                    [ text "Výsledky případného druhého kola odvodíme z hlasování řazením (viz níže)."
                    ]
                ]

        viewConfig =
            { title = "Dvoukolová volba volba"
            , desc = desc
            , prefix = "two-round"
            , icon = FeatherIcons.playCircle
            , pollClass = "two-round-poll"
            }
    in
    SinglePoll.view viewConfig model
