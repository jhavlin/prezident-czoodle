module RandomUtils exposing (..)

import Random exposing (Generator)


decreasingRandomIntList : Int -> Generator (List Int)
decreasingRandomIntList n =
    let
        counts =
            -- keep reversed here, it will be reversed back in randomList inner fn
            List.range 0 (n - 1)

        randomList : Generator (List Int)
        randomList =
            let
                fn : Int -> Generator (List Int) -> Generator (List Int)
                fn limit acc =
                    Random.andThen (\r -> Random.map (\i -> i :: r) (Random.int 0 limit)) acc
            in
            -- Random.andThen (\v -> Random.int 0 m)
            List.foldl fn (Random.constant []) counts
    in
    randomList


takeNthFromList : Int -> List a -> ( Maybe a, List a )
takeNthFromList n list =
    let
        before =
            List.take n list

        rest =
            List.drop n list
    in
    ( List.head rest, before ++ List.drop 1 rest )


shuffle : Int -> Generator (List Int)
shuffle n =
    let
        range : List Int
        range =
            List.range 0 (n - 1)

        folding : Int -> { done : List Int, remaining : List Int } -> { done : List Int, remaining : List Int }
        folding nextIndex { done, remaining } =
            let
                ( taken, newRemaining ) =
                    takeNthFromList nextIndex remaining

                newDone =
                    case taken of
                        Just t ->
                            t :: done

                        Nothing ->
                            done
            in
            { done = newDone, remaining = newRemaining }

        fn : List Int -> List Int
        fn nextIndexes =
            (List.foldl folding { done = [], remaining = range } nextIndexes).done
    in
    Random.map fn (decreasingRandomIntList n)
