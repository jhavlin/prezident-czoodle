module Polls.Common exposing
    ( PollConfig
    , deserializeIntDict
    , deserializeMappedIntDict
    , deserializeMappedStringDict
    , deserializeStringDict
    , serializeIntDict
    , serializeStringDict
    )

import Array
import Candidates
import Dict exposing (Dict)
import Json.Decode
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


listToDict : List a -> Dict Int a
listToDict list =
    let
        foldFn ( index, value ) acc =
            Dict.insert index value acc
    in
    List.foldl foldFn Dict.empty <| List.indexedMap Tuple.pair list


deserializeIntDict : Json.Decode.Decoder (Dict Int Int)
deserializeIntDict =
    Json.Decode.map listToDict <| Json.Decode.list Json.Decode.int


deserializeStringDict : Json.Decode.Decoder (Dict Int String)
deserializeStringDict =
    Json.Decode.map listToDict <| Json.Decode.list Json.Decode.string


deserializeMappedIntDict : (Int -> a) -> Json.Decode.Decoder (Dict Int a)
deserializeMappedIntDict mapper =
    Json.Decode.map listToDict <| Json.Decode.list (Json.Decode.map mapper Json.Decode.int)


deserializeMappedStringDict : (String -> a) -> Json.Decode.Decoder (Dict Int a)
deserializeMappedStringDict mapper =
    Json.Decode.map listToDict <| Json.Decode.list (Json.Decode.map mapper Json.Decode.string)
