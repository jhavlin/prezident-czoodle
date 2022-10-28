module UserInputInt exposing (Config, UserInputInt(..), create, toString, withDefault)


type UserInputInt
    = Valid Int
    | Invalid String String


type alias Config =
    { min : Int
    , max : Int
    }


create : Config -> String -> UserInputInt
create { min, max } inputString =
    let
        maybeIntValue =
            String.toInt inputString
    in
    case maybeIntValue of
        Just i ->
            if i >= min && i <= max then
                Valid i

            else
                Invalid inputString <|
                    String.concat
                        [ "Hodnota mimo rozsah "
                        , String.fromInt min
                        , " - "
                        , String.fromInt max
                        ]

        Nothing ->
            Invalid inputString "Chybný formát čísla"


withDefault : Int -> UserInputInt -> Int
withDefault default userInputInt =
    case userInputInt of
        Valid i ->
            i

        Invalid _ _ ->
            default


toString : UserInputInt -> String
toString userInputInt =
    case userInputInt of
        Valid i ->
            String.fromInt i

        Invalid raw _ ->
            raw
