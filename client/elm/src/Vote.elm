module Vote exposing (..)

import Browser
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Json.Decode as D
import Polls.DoodlePoll
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
      , doodlePoll = Polls.DoodlePoll.init
      , orderPoll = Polls.OrderPoll.init
      , starPoll = Polls.StarPoll.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | DoodlePollMsg Polls.DoodlePoll.Msg
    | StarPollMsg Polls.StarPoll.Msg
    | OrderPollMsg Polls.OrderPoll.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    case cmd of
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
        , div [ class "" ] [ Html.map (\inner -> DoodlePollMsg inner) (Polls.DoodlePoll.view model.doodlePoll) ]
        , div [ class "" ] [ Html.map (\inner -> OrderPollMsg inner) (Polls.OrderPoll.view model.orderPoll) ]
        , div [ class "" ] [ Html.map (\inner -> StarPollMsg inner) (Polls.StarPoll.view model.starPoll) ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
