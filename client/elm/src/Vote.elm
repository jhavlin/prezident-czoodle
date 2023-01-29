port module Vote exposing (..)

import Array
import Browser
import Candidates
import Component exposing (ariaLabel)
import FeatherIcons
import Html exposing (Html, a, button, div, h1, p, section, span, text)
import Html.Attributes exposing (class, disabled, href, title)
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


port clear : () -> Cmd msg



-- MODEL


type alias Polls =
    { twoRoundPoll : Polls.TwoRoundPoll.Model
    , oneRoundPoll : Polls.OneRoundPoll.Model
    , dividePoll : Polls.DividePoll.Model
    , d21Poll : Polls.D21Poll.Model
    , doodlePoll : Polls.DoodlePoll.Model
    , orderPoll : Polls.OrderPoll.Model
    , starPoll : Polls.StarPoll.Model
    , emojiPoll : Polls.EmojiPoll.Model
    }


type alias EditModel =
    { candidates : List Candidates.Candidate
    , version : Int
    , nonces : List String
    , showRestoredInfo : Bool
    , polls : Polls
    , lastSaveError : Maybe String
    }


type alias ShowModel =
    { candidates : List Candidates.Candidate
    , polls : Polls
    }


type State
    = InitializingNew
    | LoadingCachedFailed
    | Editing EditModel
    | Saving EditModel
    | ShowingSavedInfo
    | LoadingStored
    | LoadingStoredFailed
    | ShowingStored ShowModel
    | InvalidUUID


type alias Model =
    { uuid : String
    , state : State
    , baseUrl : String
    }


init : D.Value -> ( Model, Cmd Msg )
init jsonFlags =
    let
        orderList =
            Result.withDefault [] <| D.decodeValue (D.field "order" (D.list D.int)) jsonFlags

        uuid =
            Result.withDefault "" <| D.decodeValue (D.field "uuid" D.string) jsonFlags

        baseUrl =
            Result.withDefault "" <| D.decodeValue (D.field "baseUrl" D.string) jsonFlags

        readOnly =
            Result.withDefault False <| D.decodeValue (D.field "readOnly" D.bool) jsonFlags

        isNew =
            List.sort orderList /= (List.sort <| List.map .id <| Array.toList <| Candidates.all)
    in
    if String.length uuid /= 36 then
        ( { uuid = uuid, state = InvalidUUID, baseUrl = baseUrl }, Cmd.none )

    else if readOnly then
        let
            loadCmd =
                Http.get
                    { url = String.concat [ "/api/get_vote/", uuid ]
                    , expect = Http.expectJson Load storedProjectDecoder
                    }
        in
        ( { uuid = uuid, state = LoadingStored, baseUrl = baseUrl }, loadCmd )

    else if isNew then
        ( { uuid = uuid, state = InitializingNew, baseUrl = baseUrl }
        , Random.generate Shuffle <| RandomUtils.shuffle (Array.length Candidates.all)
        )

    else
        let
            candidatesInOrder =
                List.map (\i -> Array.get i Candidates.all) orderList |> List.filterMap identity

            decodeResult =
                D.decodeValue (pollsDecoder False) jsonFlags
        in
        case decodeResult of
            Err _ ->
                ( { uuid = uuid, state = LoadingCachedFailed, baseUrl = baseUrl }, Cmd.none )

            Ok polls ->
                let
                    editModel =
                        { candidates = candidatesInOrder
                        , polls = polls
                        , version = 1
                        , nonces = []
                        , showRestoredInfo = True
                        , lastSaveError = Nothing
                        }
                in
                ( { uuid = uuid, state = Editing editModel, baseUrl = baseUrl }, Cmd.none )


storedProjectDecoder : D.Decoder Model
storedProjectDecoder =
    let
        orderDecoder =
            D.field "order" (D.list D.int |> D.map (\list -> List.filterMap (\id -> Array.get id Candidates.all) list))

        showStateDecoder =
            D.map2 ShowModel orderDecoder (pollsDecoder True)
                |> D.map (\showModel -> ShowingStored showModel)

        modelDecoder =
            D.map3 Model
                (D.field "uuid" D.string)
                showStateDecoder
                (D.succeed "")
    in
    modelDecoder


pollsDecoder : Bool -> D.Decoder Polls
pollsDecoder final =
    let
        inner =
            D.map8 Polls
                (D.field "twoRound" Polls.TwoRoundPoll.deserialize)
                (D.field "oneRound" Polls.OneRoundPoll.deserialize)
                (D.field "divide" Polls.DividePoll.deserialize)
                (D.field "d21" Polls.D21Poll.deserialize)
                (D.field "doodle" Polls.DoodlePoll.deserialize)
                (D.field "order" Polls.OrderPoll.deserialize)
                (D.field "star" <| Polls.StarPoll.deserialize final)
                (D.field "emoji" Polls.EmojiPoll.deserialize)
    in
    D.field "polls" inner



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
    | Published (Result String ())
    | Load (Result Http.Error Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    case cmd of
        TwoRoundPollMsg inner ->
            updatePolls (\polls -> { polls | twoRoundPoll = Polls.TwoRoundPoll.update inner polls.twoRoundPoll }) model

        OneRoundPollMsg inner ->
            updatePolls (\polls -> { polls | oneRoundPoll = Polls.OneRoundPoll.update inner polls.twoRoundPoll }) model

        DividePollMsg inner ->
            updatePolls (\polls -> { polls | dividePoll = Polls.DividePoll.update inner polls.dividePoll }) model

        D21PollMsg inner ->
            updatePolls (\polls -> { polls | d21Poll = Polls.D21Poll.update inner polls.d21Poll }) model

        DoodlePollMsg inner ->
            updatePolls (\polls -> { polls | doodlePoll = Polls.DoodlePoll.update inner polls.doodlePoll }) model

        OrderPollMsg inner ->
            let
                fn polls =
                    let
                        ( m, c ) =
                            Polls.OrderPoll.update inner polls.orderPoll
                    in
                    ( { polls | orderPoll = m }, Cmd.map OrderPollMsg c )
            in
            updatePollsWithInnerCmd fn model

        StarPollMsg inner ->
            updatePolls (\polls -> { polls | starPoll = Polls.StarPoll.update inner polls.starPoll }) model

        EmojiPollMsg inner ->
            updatePolls (\polls -> { polls | emojiPoll = Polls.EmojiPoll.update inner polls.emojiPoll }) model

        Shuffle permutation ->
            let
                candidates =
                    List.map (\i -> Array.get i Candidates.all) permutation |> List.filterMap identity

                polls =
                    { twoRoundPoll = Polls.TwoRoundPoll.init
                    , oneRoundPoll = Polls.OneRoundPoll.init
                    , dividePoll = Polls.DividePoll.init
                    , d21Poll = Polls.D21Poll.init
                    , doodlePoll = Polls.DoodlePoll.init
                    , orderPoll = Polls.OrderPoll.init
                    , starPoll = Polls.StarPoll.init
                    , emojiPoll = Polls.EmojiPoll.init
                    }

                editModel =
                    { candidates = candidates
                    , polls = polls
                    , version = 1
                    , nonces = []
                    , showRestoredInfo = False
                    , lastSaveError = Nothing
                    }
            in
            ( { uuid = model.uuid, state = Editing editModel, baseUrl = model.baseUrl }, Cmd.none )

        Store version ->
            case model.state of
                Editing editModel ->
                    if editModel.version == version then
                        ( model, storePolls <| serialize False model editModel )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CloseRestoreBox ->
            ( updateEditModelWithoutCacheUpdate (\editModel -> { editModel | showRestoredInfo = False }) model, Cmd.none )

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
            updateEditModel (\editModel -> { editModel | nonces = newNonces }) model

        Vote ->
            let
                responseToResult : Http.Response String -> Result String ()
                responseToResult response =
                    case response of
                        Http.BadUrl_ _ ->
                            Err "nesprávná URL"

                        Http.Timeout_ ->
                            Err "timeout"

                        Http.NetworkError_ ->
                            Err "chyba sítě"

                        Http.BadStatus_ _ body ->
                            Err body

                        Http.GoodStatus_ _ _ ->
                            Ok ()
            in
            case model.state of
                Editing editModel ->
                    let
                        cmdPost =
                            Http.post
                                { url = "/api/add_vote"
                                , body = Http.jsonBody <| serialize True model editModel
                                , expect = Http.expectStringResponse Published responseToResult
                                }
                    in
                    ( model, cmdPost )

                _ ->
                    ( model, Cmd.none )

        Published result ->
            case result of
                Err err ->
                    case model.state of
                        Editing editModel ->
                            let
                                updatedModel =
                                    { editModel | lastSaveError = Just err }
                            in
                            ( { model | state = Editing updatedModel }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Ok _ ->
                    ( { model | state = ShowingSavedInfo }, clear () )

        Load result ->
            case result of
                Err _ ->
                    ( { model | state = LoadingStoredFailed }, Cmd.none )

                Ok newModel ->
                    ( newModel, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


updateEditModel : (EditModel -> EditModel) -> Model -> ( Model, Cmd Msg )
updateEditModel fn model =
    case model.state of
        Editing editModel ->
            let
                nextVersion =
                    editModel.version + 1

                command =
                    Process.sleep 1000
                        |> Task.perform (\_ -> Store nextVersion)

                newEditModel =
                    fn editModel
            in
            ( { model | state = Editing { newEditModel | version = editModel.version + 1 } }, command )

        _ ->
            ( model, Cmd.none )


updateEditModelWithoutCacheUpdate : (EditModel -> EditModel) -> Model -> Model
updateEditModelWithoutCacheUpdate fn model =
    case model.state of
        Editing editModel ->
            let
                newEditModel =
                    fn editModel
            in
            { model | state = Editing newEditModel }

        _ ->
            model


updatePolls : (Polls -> Polls) -> Model -> ( Model, Cmd Msg )
updatePolls fn model =
    case model.state of
        Editing editModel ->
            let
                nextVersion =
                    editModel.version + 1

                command =
                    Process.sleep 1000
                        |> Task.perform (\_ -> Store nextVersion)

                newEditModel =
                    { editModel | polls = fn editModel.polls }
            in
            ( { model | state = Editing { newEditModel | version = editModel.version + 1 } }, command )

        _ ->
            ( model, Cmd.none )


updatePollsWithInnerCmd : (Polls -> ( Polls, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
updatePollsWithInnerCmd fn model =
    case model.state of
        Editing editModel ->
            let
                nextVersion =
                    editModel.version + 1

                command =
                    Process.sleep 1000
                        |> Task.perform (\_ -> Store nextVersion)

                ( newPolls, innerCmd ) =
                    fn editModel.polls

                newEditModel =
                    { editModel | polls = newPolls }
            in
            ( { model | state = Editing { newEditModel | version = editModel.version + 1 } }, Cmd.batch [ command, innerCmd ] )

        _ ->
            ( model, Cmd.none )


serialize : Bool -> Model -> EditModel -> Json.Encode.Value
serialize final model editModel =
    Json.Encode.object
        [ ( "uuid", Json.Encode.string model.uuid )
        , ( "order", Json.Encode.list Json.Encode.int <| List.map .id editModel.candidates )
        , ( "nonces", Json.Encode.list Json.Encode.string editModel.nonces )
        , ( "polls"
          , Json.Encode.object
                [ ( "twoRound", Polls.TwoRoundPoll.serialize editModel.polls.twoRoundPoll )
                , ( "oneRound", Polls.OneRoundPoll.serialize editModel.polls.oneRoundPoll )
                , ( "divide", Polls.DividePoll.serialize editModel.polls.dividePoll )
                , ( "d21", Polls.D21Poll.serialize final editModel.polls.d21Poll )
                , ( "doodle", Polls.DoodlePoll.serialize editModel.polls.doodlePoll )
                , ( "order", Polls.OrderPoll.serialize editModel.polls.orderPoll )
                , ( "star", Polls.StarPoll.serialize final editModel.polls.starPoll )
                , ( "emoji", Polls.EmojiPoll.serialize editModel.polls.emojiPoll )
                ]
          )
        ]



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        InvalidUUID ->
            div [ class "wide" ] [ text "Chybný identifikátor." ]

        Editing editModel ->
            viewEdit editModel

        InitializingNew ->
            div [] [ text "Připravuji nové hlasování" ]

        LoadingCachedFailed ->
            div [] [ text "Načtení uloženého hlasování selhalo" ]

        Saving _ ->
            div [] [ text "Načtení uloženého hlasování selholo" ]

        ShowingSavedInfo ->
            let
                address =
                    String.concat [ model.baseUrl, "/", model.uuid ]
            in
            div [ class "wide info-content" ]
                [ h1 [] [ text "Odhlasováno" ]
                , p [] [ text "Zaznamenané hlasování je dostupné zde:" ]
                , p [] [ a [ href address ] [ text address ] ]
                , p [] [ text "Tuto adresu si můžete uložit pro pozdější kontrolu. " ]
                , p []
                    [ text "Můžete ji také sdílet a zveřejnit, což ovšem neznamená, "
                    , text "že je to vždy dobrý nápad."
                    ]
                ]

        LoadingStored ->
            div [ class "wide" ] [ text "Nahrávám hlasování" ]

        LoadingStoredFailed ->
            div [] [ text "Chyba zobrazení existujícího hlasování" ]

        ShowingStored showModel ->
            div []
                (div [ class "wide" ]
                    [ h1 [] [ text <| String.concat [ "Zaznamenané hlasování číslo", " ", model.uuid ] ]
                    , p [] [ text "(Již nelze upravovat.)" ]
                    , p [] [ text "Pokud jste ještě nehlasovali, můžete ", a [ href "/" ] [ text "tak učinit zde." ] ]
                    ]
                    :: viewPolls { candidates = showModel.candidates, readOnly = True } showModel.polls
                )


viewEdit : EditModel -> Html Msg
viewEdit editModel =
    let
        pollConfig =
            { candidates = editModel.candidates, readOnly = False }

        restoredInfo =
            if editModel.showRestoredInfo then
                div [ class "wide" ]
                    [ div [ class "box info", ariaLabel "Dialog informující o obnoveném stavu" ]
                        [ button [ class "box-close-button", title "Zavřít", onClick CloseRestoreBox, ariaLabel "Zavřít dialog" ]
                            [ FeatherIcons.x |> FeatherIcons.withSize 18 |> FeatherIcons.toHtml [] ]
                        , text "Obnoven poslední uložený stav."
                        , button [ class "box-action-button", onClick Reset ] [ text "Zahodit a začít znovu" ]
                        ]
                    ]

            else
                text ""
    in
    div []
        ([ restoredInfo
         , section [ class "intro" ]
            [ div [ class "wide" ]
                [ p [] [ a [ href "vysledky.html", class "vote-button" ] [ text "Výsledky zde" ] ]
                ]
            ]
         , section [ class "intro" ]
            [ div [ class "wide" ]
                [ p [] [ text "Zúčastněte se prosím malého experimentu. Porovnejte různé hlasovací systémy na příkladu volby prezidenta České republiky." ]
                ]
            ]
         ]
            ++ viewPolls pollConfig editModel.polls
            ++ [ summaries editModel ]
        )


viewPolls : Polls.Common.PollConfig -> Polls -> List (Html Msg)
viewPolls pollConfig polls =
    [ Html.map (\inner -> TwoRoundPollMsg inner) (Polls.TwoRoundPoll.view pollConfig polls.twoRoundPoll)
    , Html.map (\inner -> OneRoundPollMsg inner) (Polls.OneRoundPoll.view pollConfig polls.oneRoundPoll)
    , Html.map (\inner -> DividePollMsg inner) (Polls.DividePoll.view pollConfig polls.dividePoll)
    , Html.map (\inner -> D21PollMsg inner) (Polls.D21Poll.view pollConfig polls.d21Poll)
    , Html.map (\inner -> DoodlePollMsg inner) (Polls.DoodlePoll.view pollConfig polls.doodlePoll)
    , Html.map (\inner -> OrderPollMsg inner) (Polls.OrderPoll.view pollConfig polls.orderPoll)
    , Html.map (\inner -> StarPollMsg inner) (Polls.StarPoll.view pollConfig polls.starPoll)
    , Html.map (\inner -> EmojiPollMsg inner) (Polls.EmojiPoll.view pollConfig polls.emojiPoll)
    ]


summaries : EditModel -> Html Msg
summaries editModel =
    let
        strengthLimit =
            5

        summaryList =
            [ Polls.TwoRoundPoll.summarize editModel.polls.twoRoundPoll
            , Polls.OneRoundPoll.summarize editModel.polls.oneRoundPoll
            , Polls.DividePoll.summarize editModel.polls.dividePoll
            , Polls.D21Poll.summarize editModel.polls.d21Poll
            , Polls.DoodlePoll.summarize editModel.polls.doodlePoll
            , Polls.OrderPoll.summarize editModel.polls.orderPoll
            , Polls.StarPoll.summarize editModel.polls.starPoll
            , Polls.EmojiPoll.summarize editModel.polls.emojiPoll
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
            let
                strength =
                    List.length editModel.nonces

                strengthClass =
                    if strength < 5 then
                        "weak"

                    else if strength < 20 then
                        "good"

                    else
                        "strong"

                wait =
                    if strength < strengthLimit then
                        text " Čekejte, prosím."

                    else
                        text ""
            in
            div []
                [ h1 [] [ text "Síla hlasu" ]
                , p []
                    [ text "Síla vašeho hlasu je "
                    , span [ class "vote-strength", class strengthClass ] [ text <| String.fromInt strength ]
                    , wait
                    ]
                , p []
                    [ text "Hodnota vyjadřuje přibližné množstí času, které jste hlasováním strávili. "
                    , text "Je požadována hodnota alespoň "
                    , text <| String.fromInt strengthLimit
                    , text ". Maximální hodnota je 100."
                    ]
                ]

        voteEnabled =
            List.all (\(Summary validation _) -> validation /= Error) summaryList && List.length editModel.nonces >= strengthLimit

        errorInfo =
            case editModel.lastSaveError of
                Just error ->
                    div [ class "wide" ]
                        [ h1 [] [ text "Chyba :-(" ]
                        , p [] [ text error ]
                        ]

                _ ->
                    text ""
    in
    section [ class "summaries" ]
        [ div [ class "wide" ]
            (h1 [] [ text "Shrnutí" ] :: List.map showSummary summaryList)
        , div [ class "wide" ]
            [ weightInfo ]
        , div [ class "wide vote-button-parent" ]
            [ button [ class "vote-button", onClick Vote, disabled <| not voteEnabled ]
                [ text "Hlasovat"
                ]
            ]
        , errorInfo
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ reInit ReInit, noncesUpdated NoncesUpdated ]
