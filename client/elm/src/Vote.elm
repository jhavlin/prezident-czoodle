module Vote exposing (..)

import Browser
import Candidates
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Json.Decode as D
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
    , starPoll : Polls.StarPoll.Model
    }


init : D.Value -> ( Model, Cmd Msg )
init jsonFlags =
    let
        uuidResult =
            D.decodeValue (D.field "uuid" D.string) jsonFlags
    in
    ( { uuid = Result.withDefault "" uuidResult
      , starPoll = Polls.StarPoll.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | StarPollMsg Polls.StarPoll.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    case cmd of
        StarPollMsg inner ->
            let
                updated =
                    Polls.StarPoll.update inner model.starPoll
            in
            ( { model | starPoll = updated }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [ class "wide" ]
            [ p [] [ text "Zúčastněte se prosím malého experimentu. Porovnejte různé hlasovací systémy na příkladu volby prezidenta České republiky." ]
            ]
        , div [ class "" ] [ Html.map (\inner -> StarPollMsg inner) (Polls.StarPoll.view model.starPoll Candidates.all) ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
