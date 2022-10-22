module CandidatesTest exposing (suite)

import Array
import Candidates
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Candidates"
        [ test "candidate ids and position in array matches" <|
            \_ ->
                let
                    actual =
                        Array.map (\candidate -> candidate.id) Candidates.all |> Array.toList

                    expected =
                        List.range 0 (Array.length Candidates.all - 1)
                in
                Expect.equal expected actual
        ]
