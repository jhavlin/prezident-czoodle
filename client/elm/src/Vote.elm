port module Vote exposing (..)

import Array
import Browser
import Candidates
import FeatherIcons
import Html exposing (Html, button, div, h1, p, section, text)
import Html.Attributes exposing (class, disabled, title)
import Html.Events exposing (onClick)
import Http
import Json.Decode as D
import Json.Encode
import Polls.Common exposing (Summary(..), Validation(..))
import Polls.D21Poll
import Polls.DividePoll
import Polls.DoodlePoll
import Polls.EmojiPoll
import Polls.OneRoundPoll
import Polls.OrderPoll
import Polls.StarPoll
import Polls.TwoRoundPoll
import Process
import Random
import RandomUtils
import Task



-- MAIN


main : Program D.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port storePolls : Json.Encode.Value -> Cmd msg


port reset : () -> Cmd msg


port reInit : (D.Value -> msg) -> Sub msg


port noncesUpdated : (D.Value -> msg) -> Sub msg



-- MODEL


type alias Model =
    { uuid : String
    , readOnly : Bool
    , candidates : List Candidates.Candidate
    , version : Int
    , nonces : List String
    , showRestoredInfo : Bool
    , twoRoundPoll : Polls.TwoRoundPoll.Model
    , oneRoundPoll : Polls.OneRoundPoll.Model
    , dividePoll : Polls.DividePoll.Model
    , d21Poll : Polls.D21Poll.Model
    , doodlePoll : Polls.DoodlePoll.Model
    , orderPoll : Polls.OrderPoll.Model
    , starPoll : Polls.StarPoll.Model
    , emojiPoll : Polls.EmojiPoll.Model
    }


init : D.Value -> ( Model, Cmd Msg )
init jsonFlags =
    let
        orderList =
            Result.withDefault [] <| D.decodeValue (D.field "order" (D.list D.int)) jsonFlags

        uuid =
            Result.withDefault "" <| D.decodeValue (D.field "uuid" D.string) jsonFlags

        readOnly =
            Result.withDefault False <| D.decodeValue (D.field "readOnly" D.bool) jsonFlags

        isNew =
            List.isEmpty orderList

        defaultModel =
            ( { uuid = uuid
              , readOnly = False
              , candidates = []
              , version = 1
              , nonces = []
              , showRestoredInfo = False
              , twoRoundPoll = Polls.TwoRoundPoll.init
              , oneRoundPoll = Polls.OneRoundPoll.init
              , dividePoll = Polls.DividePoll.init
              , d21Poll = Polls.D21Poll.init
              , doodlePoll = Polls.DoodlePoll.init
              , orderPoll = Polls.OrderPoll.init
              , starPoll = Polls.StarPoll.init
              , emojiPoll = Polls.EmojiPoll.init
              }
            , Random.generate Shuffle <| RandomUtils.shuffle (Array.length Candidates.all)
            )
    in
    if readOnly then
        let
            ( model, _ ) =
                defaultModel

            loadCmd =
                Http.get
                    { url = String.concat [ "/api/get_vote/", uuid ]
                    , expect = Http.expectJson Load storedProjectDecoder
                    }
        in
        ( { model | readOnly = True }, loadCmd )

    else if isNew then
        defaultModel

    else
        let
            candidatesInOrder =
                List.map (\i -> Array.get i Candidates.all) orderList |> List.filterMap identity

            partial =
                Model uuid False candidatesInOrder 1 [] True

            pollsDecoder =
                D.map8 partial
                    (D.field "twoRound" Polls.TwoRoundPoll.deserialize)
                    (D.field "oneRound" Polls.TwoRoundPoll.deserialize)
                    (D.field "divide" Polls.DividePoll.deserialize)
                    (D.field "d21" Polls.D21Poll.deserialize)
                    (D.field "doodle" Polls.DoodlePoll.deserialize)
                    (D.field "order" Polls.OrderPoll.deserialize)
                    (D.field "star" <| Polls.StarPoll.deserialize False)
                    (D.field "emoji" Polls.EmojiPoll.deserialize)

            decodeResult =
                D.decodeValue (D.field "polls" pollsDecoder) jsonFlags
        in
        case decodeResult of
            Err _ ->
                defaultModel

            Ok model ->
                ( model, Cmd.none )


storedProjectDecoder : D.Decoder Model
storedProjectDecoder =
    let
        orderDecoder =
            D.list D.int |> D.map (\list -> List.filterMap (\id -> Array.get id Candidates.all) list)

        partial1 =
            D.map6 Model
                (D.field "uuid" D.string)
                (D.succeed True)
                (D.field "order" orderDecoder)
                (D.succeed 1)
                (D.succeed [])
                (D.succeed False)
    in
    D.andThen
        (\p ->
            D.map8 p
                (D.at [ "polls", "twoRound" ] Polls.TwoRoundPoll.deserialize)
                (D.at [ "polls", "oneRound" ] Polls.TwoRoundPoll.deserialize)
                (D.at [ "polls", "divide" ] Polls.DividePoll.deserialize)
                (D.at [ "polls", "d21" ] Polls.D21Poll.deserialize)
                (D.at [ "polls", "doodle" ] Polls.DoodlePoll.deserialize)
                (D.at [ "polls", "order" ] Polls.OrderPoll.deserialize)
                (D.at [ "polls", "star" ] <| Polls.StarPoll.deserialize True)
                (D.at [ "polls", "emoji" ] Polls.EmojiPoll.deserialize)
        )
        partial1



-- UPDATE


type Msg
    = NoOp
    | Shuffle (List Int)
    | Store Int
    | CloseRestoreBox
    | Reset
    | ReInit D.Value
    | NoncesUpdated D.Value
    | TwoRoundPollMsg Polls.TwoRoundPoll.Msg
    | OneRoundPollMsg Polls.OneRoundPoll.Msg
    | D21PollMsg Polls.D21Poll.Msg
    | DoodlePollMsg Polls.DoodlePoll.Msg
    | StarPollMsg Polls.StarPoll.Msg
    | OrderPollMsg Polls.OrderPoll.Msg
    | DividePollMsg Polls.DividePoll.Msg
    | EmojiPollMsg Polls.EmojiPoll.Msg
    | Vote
    | Load (Result Http.Error Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    let
        nextVersion =
            model.version + 1

        command =
            Process.sleep 1000
                |> Task.perform (\_ -> Store nextVersion)
    in
    case cmd of
        TwoRoundPollMsg inner ->
            let
                updated =
                    Polls.TwoRoundPoll.update inner model.twoRoundPoll
            in
            ( { model | twoRoundPoll = updated, version = nextVersion }, command )

        OneRoundPollMsg inner ->
            let
                updated =
                    Polls.OneRoundPoll.update inner model.oneRoundPoll
            in
            ( { model | oneRoundPoll = updated, version = nextVersion }, command )

        DividePollMsg inner ->
            let
                updated =
                    Polls.DividePoll.update inner model.dividePoll
            in
            ( { model | dividePoll = updated, version = nextVersion }, command )

        D21PollMsg inner ->
            let
                updated =
                    Polls.D21Poll.update inner model.d21Poll
            in
            ( { model | d21Poll = updated, version = nextVersion }, command )

        DoodlePollMsg inner ->
            let
                updated =
                    Polls.DoodlePoll.update inner model.doodlePoll
            in
            ( { model | doodlePoll = updated, version = nextVersion }, command )

        OrderPollMsg inner ->
            let
                ( updated, innerCmd ) =
                    Polls.OrderPoll.update inner model.orderPoll
            in
            ( { model | orderPoll = updated, version = nextVersion }, Cmd.batch [ Cmd.map OrderPollMsg innerCmd, command ] )

        StarPollMsg inner ->
            let
                updated =
                    Polls.StarPoll.update inner model.starPoll
            in
            ( { model | starPoll = updated, version = nextVersion }, command )

        EmojiPollMsg inner ->
            let
                updated =
                    Polls.EmojiPoll.update inner model.emojiPoll
            in
            ( { model | emojiPoll = updated, version = nextVersion }, command )

        Shuffle permutation ->
            let
                candidates =
                    List.map (\i -> Array.get i Candidates.all) permutation |> List.filterMap identity
            in
            ( { model | candidates = candidates }, Cmd.none )

        Store version ->
            if model.version == version then
                ( model, storePolls <| serialize False model )

            else
                ( model, Cmd.none )

        CloseRestoreBox ->
            ( { model | showRestoredInfo = False }, Cmd.none )

        Reset ->
            ( model, reset () )

        ReInit v ->
            init v

        NoncesUpdated jsonValue ->
            let
                newNonces =
                    D.decodeValue (D.list D.string) jsonValue
                        |> Result.withDefault []
            in
            ( { model | nonces = newNonces, version = nextVersion }, command )

        Vote ->
            let
                cmdPost =
                    Http.post
                        { url = "/api/add_vote"
                        , body = Http.jsonBody <| serialize True model
                        , expect = Http.expectWhatever (\_ -> NoOp)
                        }
            in
            ( model, cmdPost )

        Load result ->
            case Debug.log "result" result of
                Err _ ->
                    ( model, Cmd.none )

                Ok newModel ->
                    ( newModel, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


serialize : Bool -> Model -> Json.Encode.Value
serialize final model =
    Json.Encode.object
        [ ( "uuid", Json.Encode.string model.uuid )
        , ( "order", Json.Encode.list Json.Encode.int <| List.map .id model.candidates )
        , ( "nonces", Json.Encode.list Json.Encode.string model.nonces )
        , ( "polls"
          , Json.Encode.object
                [ ( "twoRound", Polls.TwoRoundPoll.serialize model.twoRoundPoll )
                , ( "oneRound", Polls.OneRoundPoll.serialize model.oneRoundPoll )
                , ( "divide", Polls.DividePoll.serialize model.dividePoll )
                , ( "d21", Polls.D21Poll.serialize model.d21Poll )
                , ( "doodle", Polls.DoodlePoll.serialize model.doodlePoll )
                , ( "order", Polls.OrderPoll.serialize model.orderPoll )
                , ( "star", Polls.StarPoll.serialize final model.starPoll )
                , ( "emoji", Polls.EmojiPoll.serialize model.emojiPoll )
                ]
          )
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        pollConfig =
            { candidates = model.candidates, readOnly = False }

        restoredInfo =
            if model.showRestoredInfo then
                div [ class "wide" ]
                    [ div [ class "box info" ]
                        [ button [ class "box-close-button", title "Zavřít", onClick CloseRestoreBox ]
                            [ FeatherIcons.x |> FeatherIcons.withSize 18 |> FeatherIcons.toHtml [] ]
                        , text "Obnoven poslední uložený stav."
                        , button [ class "box-action-button", onClick Reset ] [ text "Zahodit a začít znovu" ]
                        ]
                    ]

            else
                text ""
    in
    div []
        [ restoredInfo
        , section [ class "intro" ]
            [ div [ class "wide" ]
                [ p [] [ text "Zúčastněte se prosím malého experimentu. Porovnejte různé hlasovací systémy na příkladu volby prezidenta České republiky." ]
                ]
            ]
        , Html.map (\inner -> TwoRoundPollMsg inner) (Polls.TwoRoundPoll.view pollConfig model.twoRoundPoll)
        , Html.map (\inner -> OneRoundPollMsg inner) (Polls.OneRoundPoll.view pollConfig model.oneRoundPoll)
        , Html.map (\inner -> DividePollMsg inner) (Polls.DividePoll.view pollConfig model.dividePoll)
        , Html.map (\inner -> D21PollMsg inner) (Polls.D21Poll.view pollConfig model.d21Poll)
        , Html.map (\inner -> DoodlePollMsg inner) (Polls.DoodlePoll.view pollConfig model.doodlePoll)
        , Html.map (\inner -> OrderPollMsg inner) (Polls.OrderPoll.view pollConfig model.orderPoll)
        , Html.map (\inner -> StarPollMsg inner) (Polls.StarPoll.view pollConfig model.starPoll)
        , Html.map (\inner -> EmojiPollMsg inner) (Polls.EmojiPoll.view pollConfig model.emojiPoll)
        , summaries model
        ]


summaries : Model -> Html Msg
summaries model =
    let
        summaryList =
            [ Polls.TwoRoundPoll.summarize model.twoRoundPoll
            , Polls.OneRoundPoll.summarize model.oneRoundPoll
            , Polls.DividePoll.summarize model.dividePoll
            , Polls.D21Poll.summarize model.d21Poll
            , Polls.DoodlePoll.summarize model.doodlePoll
            , Polls.OrderPoll.summarize model.orderPoll
            , Polls.StarPoll.summarize model.starPoll
            , Polls.EmojiPoll.summarize model.emojiPoll
            ]

        localHtml html =
            Html.map (\_ -> NoOp) html

        icon validation =
            case validation of
                Valid ->
                    FeatherIcons.checkCircle |> FeatherIcons.withClass (validationClass validation) |> FeatherIcons.toHtml []

                Warning ->
                    FeatherIcons.alertCircle |> FeatherIcons.withClass (validationClass validation) |> FeatherIcons.toHtml []

                Error ->
                    FeatherIcons.xCircle |> FeatherIcons.withClass (validationClass validation) |> FeatherIcons.toHtml []

        validationClass validation =
            case validation of
                Valid ->
                    "valid"

                Warning ->
                    "warning"

                Error ->
                    "error"

        showSummary : Summary -> Html Msg
        showSummary (Summary validation html) =
            div [ class "summary", class <| validationClass validation ]
                [ div [ class "summary-icon" ] [ icon validation ]
                , div [ class "summary-text" ] [ localHtml html ]
                ]

        weightInfo =
            div [] [ text <| String.concat [ "Síla vašeho hlasu je ", String.fromInt <| List.length model.nonces ] ]

        voteEnabled =
            List.all (\(Summary validation _) -> validation /= Error) summaryList
    in
    section [ class "summaries" ]
        [ div [ class "wide" ]
            (h1 [] [ text "Shrnutí" ] :: List.map showSummary summaryList)
        , div [ class "wide" ]
            [ weightInfo ]
        , div [ class "wide" ]
            [ button [ onClick Vote, disabled <| not voteEnabled ] [ text "Hlasovat nanečisto" ] ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ reInit ReInit, noncesUpdated NoncesUpdated ]
