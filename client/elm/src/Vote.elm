module Vote exposing (..)

import Browser
import Candidates
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Json.Decode as D
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
      , orderPoll = Polls.OrderPoll.init Candidates.all
      , starPoll = Polls.StarPoll.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | StarPollMsg Polls.StarPoll.Msg
    | OrderPollMsg Polls.OrderPoll.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    case cmd of
        OrderPollMsg inner ->
            let
                updated =
                    Polls.OrderPoll.update inner model.orderPoll
            in
            ( { model | orderPoll = updated }, Cmd.none )

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
        , div [ class "" ] [ Html.map (\inner -> OrderPollMsg inner) (Polls.OrderPoll.view model.orderPoll Candidates.all) ]
        , div [ class "" ] [ Html.map (\inner -> StarPollMsg inner) (Polls.StarPoll.view model.starPoll Candidates.all) ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
