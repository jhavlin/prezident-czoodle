module Vote exposing (..)

import Array
import Browser
import Candidates
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (class, src)
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
view _ =
    candidateList


candidateList : Html Msg
candidateList =
    let
        candidateToView : Candidates.Candidate -> Html Msg
        candidateToView candidate =
            div []
                [ img [ class "candidate-photo", src <| String.concat [ "img/candidate/", candidate.imgName, ".jpg" ] ] []
                , span [ class "candidate-first-name" ] [ text candidate.firstName ]
                , text " "
                , span [ class "candidate-surname" ] [ text candidate.surname ]
                ]
    in
    div [ class "width" ] <| Array.toList <| Array.map candidateToView Candidates.all



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
