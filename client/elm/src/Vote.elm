module Vote exposing (..)

import Array
import Browser
import Candidates
import FeatherIcons
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (class, src)
import Json.Decode as D
import Svg.Attributes as SAttr



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
    div [] [ candidateList, starRankView ]


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


starRankView : Html Msg
starRankView =
    let
        oneStar cls =
            FeatherIcons.star
                |> FeatherIcons.withSize 32
                |> FeatherIcons.toHtml [ SAttr.class cls ]

        oneStarDisabled =
            oneStar "star-poll-star"

        oneStarEnabled =
            oneStar "star-poll-star enabled"
    in
    div [ class "width" ] [ oneStarEnabled, oneStarEnabled, oneStarDisabled, oneStarDisabled, oneStarDisabled ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
