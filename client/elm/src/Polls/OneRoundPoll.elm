module Polls.OneRoundPoll exposing
    ( Model
    , Msg
    , deserialize
    , init
    , serialize
    , summarize
    , update
    , view
    )

import FeatherIcons
import Html exposing (Html, div, p, text)
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
            div []
                [ p []
                    [ text "Vyberte osobnost, kterou byste volili v\u{00A0}případě jednokolového "
                    , text "volebního systému."
                    ]
                , p [] [ text "Tedy kdyby se prezidentem stal rovnou vítěz prvního kola i bez nadpoloviční většiny hlasů." ]
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


summarize : Model -> Polls.Common.Summary
summarize model =
    SinglePoll.summarize "jednokolové volbě" model
