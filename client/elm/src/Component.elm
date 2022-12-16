module Component exposing (candidatePhoto, candidateView, itemsString)

import Candidates exposing (Candidate)
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (class, list, src)


itemsString : String -> String -> List String -> String
itemsString delimiter lastDelimiter list =
    let
        l =
            List.length list
    in
    if l == 1 then
        String.join "" list

    else
        String.concat
            [ List.take (l - 1) list |> String.join delimiter
            , lastDelimiter
            , List.drop (l - 1) list |> String.join ""
            ]


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
