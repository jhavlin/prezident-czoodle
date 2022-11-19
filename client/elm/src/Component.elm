module Component exposing (..)

import Candidates exposing (Candidate)
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (class, src)


candidatePhoto : Candidate -> Html msg
candidatePhoto candidate =
    img [ class "candidate-photo", src <| String.concat [ "img/candidate/", candidate.imgName, ".jpg" ] ] []


candidateView : Candidate -> Html msg
candidateView candidate =
    div [ class "candidate" ]
        [ candidatePhoto candidate
        , span [ class "candidate-name" ]
            [ span [ class "candidate-first-name" ] [ text candidate.firstName ]
            , span [ class "candidate-surname" ] [ text candidate.surname ]
            ]
        ]
