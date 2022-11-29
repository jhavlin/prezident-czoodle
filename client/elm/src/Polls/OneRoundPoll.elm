module Polls.OneRoundPoll exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import FeatherIcons
import Html exposing (Html, p, text)
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
            p []
                [ text "Vyberte kandidáta, kterého byste volili v případně jednokolového "
                , text "volebního systému."
                ]

        viewConfig =
            { title = "Jednokolová volba"
            , desc = desc
            , prefix = "one-round"
            , icon = FeatherIcons.check
            , pollClass = "one-round-poll"
            }
    in
    SinglePoll.view viewConfig model
