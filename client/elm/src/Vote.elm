module Vote exposing (..)

import Browser
import Html exposing (Html, text)
import Json.Decode as D



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
    }


init : D.Value -> ( Model, Cmd Msg )
init jsonFlags =
    let
        uuidResult =
            D.decodeValue (D.field "uuid" D.string) jsonFlags
    in
    ( { uuid = Result.withDefault "" uuidResult }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    text model.uuid



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
