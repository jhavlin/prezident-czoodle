module Component exposing (..)

import Candidates exposing (Candidate)
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (class, src)


candidateView : Candidate -> Html msg
candidateView candidate =
    div [ class "candidate" ]
        [ img [ class "candidate-photo", src <| String.concat [ "img/candidate/", candidate.imgName, ".jpg" ] ] []
        , span [ class "candidate-name" ]
            [ span [ class "candidate-first-name" ] [ text candidate.firstName ]
            , span [ class "candidate-surname" ] [ text candidate.surname ]
            ]
        ]
