module Polls.Common exposing (PollConfig, serializeIntDict, serializeStringDict)

import Array
import Candidates
import Dict exposing (Dict)
import Json.Encode


type alias PollConfig =
    { candidates : List Candidates.Candidate
    , readOnly : Bool
    }


serializeIntDict : Dict Int Int -> Json.Encode.Value
serializeIntDict dict =
    let
        vals =
            Array.map (\c -> Maybe.withDefault 0 <| Dict.get c.id dict) Candidates.all
    in
    Json.Encode.array Json.Encode.int vals


serializeStringDict : Dict Int String -> Json.Encode.Value
serializeStringDict dict =
    let
        vals =
            Array.map (\c -> Maybe.withDefault "" <| Dict.get c.id dict) Candidates.all
    in
    Json.Encode.array Json.Encode.string vals
