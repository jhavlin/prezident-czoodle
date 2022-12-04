module Polls.OneRoundPoll exposing
    ( Model
    , Msg
    , deserialize
    , init
    , serialize
    , update
    , view
    )

import FeatherIcons
import Html exposing (Html, p, text)
import Json.Decode
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
            p []
                [ text "Vyberte kandidáta, kterého byste volili v\u{00A0}případě jednokolového "
                , text "volebního systému."
                ]

        viewConfig =
            { title = "Jednokolový systém"
            , desc = desc
            , prefix = "one-round"
            , icon = FeatherIcons.check
            , pollClass = "one-round-poll"
            }
    in
    SinglePoll.view viewConfig pollConfig model


serialize : Model -> Json.Encode.Value
serialize =
    SinglePoll.serialize


deserialize : Json.Decode.Decoder Model
deserialize =
    SinglePoll.deserialize
