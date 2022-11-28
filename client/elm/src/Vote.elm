module Vote exposing (..)

import Browser
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Json.Decode as D
import Polls.D21Poll
import Polls.DividePoll
import Polls.DoodlePoll
import Polls.OneRoundPoll
import Polls.OrderPoll
import Polls.StarPoll



-- MAIN


main : Program D.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { uuid : String
    , oneRoundPoll : Polls.OneRoundPoll.Model
    , dividePoll : Polls.DividePoll.Model
    , d21Poll : Polls.D21Poll.Model
    , doodlePoll : Polls.DoodlePoll.Model
    , orderPoll : Polls.OrderPoll.Model
    , starPoll : Polls.StarPoll.Model
    }


init : D.Value -> ( Model, Cmd Msg )
init jsonFlags =
    let
        uuidResult =
            D.decodeValue (D.field "uuid" D.string) jsonFlags
    in
    ( { uuid = Result.withDefault "" uuidResult
      , oneRoundPoll = Polls.OneRoundPoll.init
      , dividePoll = Polls.DividePoll.init
      , d21Poll = Polls.D21Poll.init
      , doodlePoll = Polls.DoodlePoll.init
      , orderPoll = Polls.OrderPoll.init
      , starPoll = Polls.StarPoll.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | OneRoundPollMsg Polls.OneRoundPoll.Msg
    | D21PollMsg Polls.D21Poll.Msg
    | DoodlePollMsg Polls.DoodlePoll.Msg
    | StarPollMsg Polls.StarPoll.Msg
    | OrderPollMsg Polls.OrderPoll.Msg
    | DividePollMsg Polls.DividePoll.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    case cmd of
        OneRoundPollMsg inner ->
            let
                updated =
                    Polls.OneRoundPoll.update inner model.oneRoundPoll
            in
            ( { model | oneRoundPoll = updated }, Cmd.none )

        DividePollMsg inner ->
            let
                updated =
                    Polls.DividePoll.update inner model.dividePoll
            in
            ( { model | dividePoll = updated }, Cmd.none )

        D21PollMsg inner ->
            let
                updated =
                    Polls.D21Poll.update inner model.d21Poll
            in
            ( { model | d21Poll = updated }, Cmd.none )

        DoodlePollMsg inner ->
            let
                updated =
                    Polls.DoodlePoll.update inner model.doodlePoll
            in
            ( { model | doodlePoll = updated }, Cmd.none )

        OrderPollMsg inner ->
            let
                ( updated, innerCmd ) =
                    Polls.OrderPoll.update inner model.orderPoll
            in
            ( { model | orderPoll = updated }, Cmd.map OrderPollMsg innerCmd )

        StarPollMsg inner ->
            let
                updated =
                    Polls.StarPoll.update inner model.starPoll
            in
            ( { model | starPoll = updated }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [ class "wide" ]
            [ p [] [ text "Zúčastněte se prosím malého experimentu. Porovnejte různé hlasovací systémy na příkladu volby prezidenta České republiky." ]
            ]
        , div [ class "" ] [ Html.map (\inner -> OneRoundPollMsg inner) (Polls.OneRoundPoll.view model.oneRoundPoll) ]
        , div [ class "" ] [ Html.map (\inner -> DividePollMsg inner) (Polls.DividePoll.view model.dividePoll) ]
        , div [ class "" ] [ Html.map (\inner -> D21PollMsg inner) (Polls.D21Poll.view model.d21Poll) ]
        , div [ class "" ] [ Html.map (\inner -> DoodlePollMsg inner) (Polls.DoodlePoll.view model.doodlePoll) ]
        , div [ class "" ] [ Html.map (\inner -> OrderPollMsg inner) (Polls.OrderPoll.view model.orderPoll) ]
        , div [ class "" ] [ Html.map (\inner -> StarPollMsg inner) (Polls.StarPoll.view model.starPoll) ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
