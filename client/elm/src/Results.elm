module Results exposing (..)

import Array exposing (Array)
import Browser
import Candidates
import Chart as C
import Chart.Attributes as CA
import Component exposing (ariaHidden, ariaLabel)
import Dict exposing (Dict)
import Html exposing (Html, a, div, h1, h2, input, label, p, section, span, text)
import Html.Attributes exposing (checked, class, href, target, type_, value)
import Html.Events exposing (onInput)
import Http
import Json.Decode as D
import Polls.Common exposing (Summary(..), Validation(..))



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
-- MODEL


type alias Vote =
    { twoRound : Int
    , oneRound : Int
    , divide : List Int
    , d21 : List Int
    , doodle : List Int
    , order : List Int
    , star : List Int
    , emoji : List String
    }


type alias D21Counts =
    { negatives : Float
    , positives : Float
    , total : Float
    }


type alias DoodleCounts =
    { yesCount : Float
    , ifNeededCount : Float
    , total : Float
    }


type alias Model =
    { votes : List Vote
    , showAll : Bool
    }


init : D.Value -> ( Model, Cmd Msg )
init _ =
    ( { votes = [], showAll = False }, load False )


load : Bool -> Cmd Msg
load all =
    let
        url =
            if all then
                "/api/get_all_votes"

            else
                "/api/get_valid_votes"
    in
    Http.get
        { url = url
        , expect = Http.expectJson Loaded votesDecoder
        }


votesDecoder : D.Decoder (List Vote)
votesDecoder =
    let
        voteDecoder =
            D.map8 Vote
                (D.field "twoRound" D.int)
                (D.field "oneRound" D.int)
                (D.field "divide" (D.list D.int))
                (D.field "d21" (D.list D.int))
                (D.field "doodle" (D.list D.int))
                (D.field "order" (D.list D.int))
                (D.field "star" (D.list D.int))
                (D.field "emoji" (D.list D.string))
    in
    D.list voteDecoder



-- UPDATE


type Msg
    = NoOp
    | Loaded (Result Http.Error (List Vote))
    | ToggleAll


update : Msg -> Model -> ( Model, Cmd Msg )
update cmd model =
    case cmd of
        NoOp ->
            ( model, Cmd.none )

        Loaded result ->
            case result of
                Ok votes ->
                    ( { model | votes = votes }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        ToggleAll ->
            let
                newAll =
                    not model.showAll
            in
            ( { model | showAll = newAll }, load newAll )



-- VIEW


countValues : List Int -> Array Int
countValues list =
    let
        fn curr acc =
            Array.set curr (1 + (Maybe.withDefault 0 <| Array.get curr acc)) acc

        initial =
            Array.initialize (Array.length Candidates.all) (always 0)
    in
    List.foldl fn initial list


view : Model -> Html Msg
view model =
    let
        attributes =
            if model.showAll then
                [ class "show-all" ]

            else
                []
    in
    div attributes
        [ section [ class "show-mode-top" ]
            [ p [ class "wide" ]
                [ label []
                    [ input [ type_ "checkbox", value "all", onInput (always ToggleAll), checked model.showAll ] []
                    , text " Zohlednit i hlasy vložené po prvním kole."
                    ]
                ]
            ]
        , section [ class "wide" ]
            [ p [ class "results-text-larger" ] [ text "Děkuji za Vaše hlasy!" ]
            , p []
                [ text <|
                    String.concat
                        [ "Počet hlasů: "
                        , String.fromInt (List.length model.votes)
                        ]
                ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Struktura hlasů, jak uvidíte, bohužel zdaleka neodpovídá skutečným výsledkům. "
                        , "Přesto se je zde pokusíme zpracovat, abyste neřekli, že jsem Vás odbyl :-)"
                        ]
                ]
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Dvoukolový systém" ]
            , h2 [] [ text "První kolo" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Na dvoukolovém systému nejlépe vidíme, jak moc se liší „bublina“ hlasujících na "
                        , "prezidentském czoodlu od skutečné populace. Vyhrál Pavel Fischer, ve skutečnosti "
                        , "čtvrtý, a Andrej Babiš zde získal pouze dva hlasy."
                        ]
                ]
            , viewSingle (List.map .twoRound model.votes)
            , h2 [] [ text "Druhé kolo" ]
            , p [ class "for-valid" ] [ text "Hlasy pro druhé kolo jsou odvozeny z hlasování řazením." ]
            , viewSecondRoundResults (List.map .twoRound model.votes) (List.map .order model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Jednokolový systém" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Výsledek jednoduchého jednokolového systému se liší od dvoukolového systému, "
                        , "což bych si dovolil vyhodnotit jako jeho nevýhodu. Nutí voliče hrát „na jistotu“ "
                        , "a ještě mnohem více taktizovat."
                        ]
                ]
            , viewSingle (List.map .oneRound model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Rozdělovací hlasování" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Přestože toto hlasování dopadlo podobně jako dvoukolový systém, alespoň na předních "
                        , "příčkách, považuji jej za poměrně špatný systém. Trestá totiž lidi za váhavost a "
                        , "podobní kandidáti se mohou vzájemně „okrást“ o hlasy již v rámci jednoho hlasujícího, "
                        , "takže se i zde musí dosti taktizovat."
                        ]
                ]
            , viewDivide (List.map .divide model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Metoda D21" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Na metodě D21 je zajímavé, že je to vedle jednokolové volby jediný hlasovací systém, ve kterém "
                        , "zvítězil Petr Pavel. Jinak celkové pořadí výrazně neovlivnila. "
                        , "Janečkova metoda tedy výsledku Karla Janečka nepomohla. (Připomínám však, že to vše tvrdím na základě "
                        , "poměrně nekvalitního vzorku dat. Pří vší úctě k hlasujícím, kteří za to nemohou.)"
                        ]
                ]
            , viewD21 (List.map .d21 model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Doodle hlasování" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "V Doodle hlasování by hodně záleželo na tom, jakou váhu dáme hlasům „pokud nutno“. "
                        , "Pokud bychom jim dali stejnou váhu jako hlasům „ano“ a k typu hlasu příhlíželi pouze "
                        , "v případě rovnosti, pomohlo by to Marku Hilšerovi, který se zde dostal na třetí místo "
                        , "před Danuši Nerudovou."
                        ]
                ]
            , viewDoodle (List.map .doodle model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Hlasování řazením" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Na hlasování řazením je zajímavé, že Marek Hilšer opět předstihl Danuši Nerudovou. "
                        , "Na základě našich nekvalitních dat by se pak dalo usuzovat, že současný volební "
                        , "systém nejvíce podhodnotil právě Marka Hilšera. (Což ovšem nemá vliv na celkového "
                        , "vítěze.)"
                        ]
                ]
            , p [] [ text "Graf uvádí průměrné počty bodů udělené kandidátům." ]
            , p [] [ text "Když bude zájem, mohu hlasy vyhodnotit také metodou jednoho přenosného hlasu." ]
            , viewOrder (List.map .order model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Metoda jednoho přenosného hlasu" ]
            , p []
                [ text <|
                    String.concat
                        [ "Toto hlasování je zobecněním současné dvoukolové volby na více kol. Na rozdíl"
                        , " od hlasování řazením (Bordova hlasování) zachovává většinový charakter."
                        ]
                ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Opět vyhrál Pavel Fischer. Zajímavé je, že bylo potřeba všech devět kol,"
                        , " aby dosáhl nadpoloviční většiny hlasů."
                        ]
                ]
            , p [] [ text "Používá se metoda jednoho přenosného hlasu s vyřazováním podle Bordova hlasování (Single transferable vote with Borda elimination)." ]
            , viewSTV (List.map .order model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Hvězdičkové hlasování" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Výsledky hvězdičkové/procentuálního hlasování, ve kterém mají voliči poměrně velkou "
                        , "volnost při hodnocení kandidátů, se příliš neliší od ostatních „přísnějších“ hlasování."
                        ]
                ]
            , p [] [ text "Graf uvádí průměrné počty procent přidělené kandidátům." ]
            , viewStar (List.map .star model.votes)
            ]
        , section [ class "wide" ]
            [ h1 [] [ text "Emoji hlasování" ]
            , p [ class "for-valid" ]
                [ text <|
                    String.concat
                        [ "Nejpoužívanějšími smajlíky jsou blinkalík, různé varianty klasických smajlíků a "
                        , "mračíků, klaun, palce nahoru a dolů, přemýšlík a srdíčko. Potěšilo, že se do Top\u{00A0}5 "
                        , "dostal salutující smajlík pro pana Pavla."
                        ]
                ]
            , p [ class "for-valid" ]
                [ text "Výsledky bychom mohli vyhodnotit třeba tak, že protibabišovští voliči nevolili výrazně "
                , text "noblesnější symboly než "
                , a [ href "https://twitter.com/jiri_kubik/status/1617637913256394753", target "_blank" ] [ text "sám pan Babiš" ]
                , text "."
                ]
            , viewEmoji (List.map .emoji model.votes)
            ]
        ]


idToLabel : Int -> String
idToLabel id =
    Array.get id Candidates.all
        |> Maybe.map (\c -> String.concat [ String.slice 0 1 c.firstName, ". ", c.surname ])
        |> Maybe.withDefault "--"


idToColor : Int -> String
idToColor id =
    Array.get id Candidates.all |> Maybe.map .color |> Maybe.withDefault "white"


idToCandidateView : Int -> Html Msg
idToCandidateView id =
    let
        candidate =
            Array.get id Candidates.all
    in
    case candidate of
        Just c ->
            Component.candidateView c

        Nothing ->
            text ""


idToGradient : Int -> List String
idToGradient id =
    case id of
        0 ->
            [ "rgb(84, 191, 1)", "white" ]

        1 ->
            [ "rgb(150, 75, 0)", "rgb(198, 139, 64)" ]

        2 ->
            [ "rgb(148, 0, 211)", "white" ]

        3 ->
            [ "rgb(68, 68, 255)", "white" ]

        4 ->
            [ "skyblue", "white" ]

        5 ->
            [ "rgb(255, 255, 0)", "white" ]

        6 ->
            [ "pink", "white" ]

        7 ->
            [ "rgb(78, 91, 49)", "white" ]

        8 ->
            [ "rgb(255, 127, 0)", "white" ]

        9 ->
            [ "rgb(255, 0, 0)", "white" ]

        _ ->
            [ "white" ]


viewSimpleChartForData : List { id : String, value : Float, gradient : List String } -> Html Msg
viewSimpleChartForData data =
    let
        chart =
            C.chart
                [ CA.height 500
                , CA.width 500
                , CA.margin { top = 50, bottom = 150, left = 50, right = 50 }
                ]
                [ C.binLabels .id
                    [ CA.moveDown 15, CA.moveRight 5, CA.rotate 90, CA.alignRight, CA.color "white", CA.fontSize 18 ]
                , C.yLabels [ CA.alignLeft, CA.withGrid, CA.moveLeft 20 ]
                , C.bars [ CA.margin 0.2 ]
                    [ C.bar .value [ CA.border "white", CA.borderWidth 1 ]
                        |> C.variation
                            (\_ d ->
                                [ CA.color <| Maybe.withDefault "white" <| List.head d.gradient
                                ]
                            )
                    ]
                    data
                , C.barLabels [ CA.color "white", CA.moveUp 15 ]
                ]

        desc =
            String.concat
                [ "Graf s hodnotami: "
                , List.map (\datum -> String.concat [ String.dropLeft 3 datum.id, " ", String.fromFloat datum.value ]) data
                    |> String.join ", "
                ]
    in
    div [ class "chart-center", ariaLabel desc ]
        [ div [ class "chart-container", ariaHidden ] [ chart ]
        ]


viewSimpleChart : Array Float -> Html Msg
viewSimpleChart counted =
    let
        data =
            Array.toList counted
                |> List.indexedMap (\i v -> { id = idToLabel i, value = v, gradient = idToGradient i })
                |> List.sortBy .value
                |> List.reverse
    in
    viewSimpleChartForData data


viewSingle : List Int -> Html Msg
viewSingle ids =
    let
        counted =
            countValues ids |> Array.map toFloat
    in
    viewSimpleChart counted


viewSecondRoundResults : List Int -> List (List Int) -> Html Msg
viewSecondRoundResults oneRound orders =
    let
        counted =
            countValues oneRound

        roundOneWinners =
            Array.indexedMap Tuple.pair counted
                |> Array.toList
                |> List.sortBy (\i -> Tuple.second i)
                |> List.reverse
                |> List.take 2
                |> List.map (\( i, c ) -> { id = i, votes = c })

        countAPreferredOverB idA idB =
            orders
                |> List.map (\points -> Array.fromList points)
                |> List.filter (\points -> (Maybe.withDefault 0 <| Array.get idA points) > (Maybe.withDefault 0 <| Array.get idB points))
                |> List.length

        roundTwoVotes =
            case roundOneWinners of
                [ a, b ] ->
                    [ { id = a.id, votes = toFloat <| countAPreferredOverB a.id b.id }, { id = b.id, votes = toFloat <| countAPreferredOverB b.id a.id } ]
                        |> List.sortBy .votes
                        |> List.reverse

                _ ->
                    []

        data =
            roundTwoVotes
                |> List.map (\v -> { id = idToLabel v.id, value = v.votes, gradient = idToGradient v.id })
                |> List.sortBy .value
                |> List.reverse
    in
    viewSimpleChartForData data


viewDivide : List (List Int) -> Html Msg
viewDivide pointsList =
    let
        initial =
            Array.initialize (Array.length Candidates.all) (always 0)

        fnInner : ( Int, Int ) -> Array Int -> Array Int
        fnInner ( index, value ) acc =
            Array.set index (value + (Maybe.withDefault 0 <| Array.get index acc)) acc

        fn : List Int -> Array Int -> Array Int
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        counted =
            List.foldl fn initial pointsList |> Array.map toFloat
    in
    viewSimpleChart counted


viewD21 : List (List Int) -> Html Msg
viewD21 pointsList =
    let
        emptyCounts =
            { negatives = 0, positives = 0, total = 0 }

        initial =
            Array.initialize (Array.length Candidates.all) (always emptyCounts)

        updateCounts : D21Counts -> Int -> D21Counts
        updateCounts counts value =
            if value > 0 then
                { counts | positives = counts.positives + 1, total = counts.total + 1 }

            else if value < 0 then
                { counts | negatives = counts.negatives - 1, total = counts.total - 1 }

            else
                counts

        fnInner : ( Int, Int ) -> Array D21Counts -> Array D21Counts
        fnInner ( index, value ) acc =
            Array.set index (updateCounts (Maybe.withDefault emptyCounts <| Array.get index acc) value) acc

        fn : List Int -> Array D21Counts -> Array D21Counts
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        counted =
            List.foldl fn initial pointsList

        data =
            Array.toList counted
                |> List.indexedMap
                    (\i v ->
                        { name = idToLabel i
                        , id = i
                        , value = v
                        , gradient = idToGradient i
                        , positives = v.positives
                        , negatives = v.negatives
                        , total = v.total
                        }
                    )
                |> List.sortBy .total
                |> List.reverse

        chart =
            C.chart
                [ CA.height 500
                , CA.width 500
                , CA.margin { top = 50, bottom = 50, left = 50, right = 50 }
                ]
                [ C.binLabels .name
                    [ CA.moveUp 8, CA.moveLeft 10, CA.rotate 90, CA.alignLeft, CA.color "white", CA.fontSize 18 ]
                , C.yLabels [ CA.alignLeft, CA.withGrid, CA.moveLeft 30 ]
                , C.bars [ CA.margin 0.4, CA.spacing 0, CA.ungroup ]
                    [ C.bar .total [ CA.border "white", CA.color "darkgray", CA.borderWidth 1 ]
                        |> C.named "celkem"
                    , C.bar .positives [ CA.striped [ CA.spacing 3 ], CA.color "rgba(0, 255, 0, 0.5)" ]
                        |> C.named "kladné"
                    , C.bar .negatives [ CA.striped [ CA.spacing 3 ], CA.color "rgba(255, 0, 0, 0.5)" ]
                        |> C.named "záporné"
                    ]
                    data
                , C.legendsAt .min
                    .min
                    [ CA.column
                    , CA.alignLeft
                    , CA.moveUp 105
                    , CA.moveRight 20
                    ]
                    []
                ]

        desc =
            String.concat
                [ "Graf s hodnotami: "
                , List.map
                    (\datum ->
                        String.concat
                            [ String.dropLeft 3 datum.name
                            , " "
                            , String.fromFloat datum.positives
                            , " - "
                            , String.fromFloat -datum.negatives
                            , " = "
                            , String.fromFloat datum.total
                            ]
                    )
                    data
                    |> String.join ", "
                ]

        listRow datum =
            div [ class "short-result-list-item" ]
                [ div [ class "short-result-list-candidate" ]
                    [ idToCandidateView datum.id ]
                , div [ class "short-result-list-value" ]
                    [ span [ class "result-positive" ] [ text <| String.fromFloat datum.positives ]
                    , text " - "
                    , span [ class "result-negative" ] [ text <| String.fromFloat -datum.negatives ]
                    , text " = "
                    , span [ class "result-main" ] [ text <| String.fromFloat datum.total ]
                    ]
                ]

        list =
            div [ class "short-result-list", ariaHidden ] (List.map listRow data)
    in
    div []
        [ div [ class "chart-center", ariaLabel desc ]
            [ div [ class "chart-container", ariaHidden ] [ chart ]
            ]
        , list
        ]


viewDoodle : List (List Int) -> Html Msg
viewDoodle pointsList =
    let
        emptyCounts : DoodleCounts
        emptyCounts =
            { yesCount = 0, ifNeededCount = 0, total = 0 }

        initial =
            Array.initialize (Array.length Candidates.all) (always emptyCounts)

        updateCounts : DoodleCounts -> Int -> DoodleCounts
        updateCounts counts value =
            if value == 2 then
                { counts | yesCount = counts.yesCount + 1, total = counts.total + 1 }

            else if value == 1 then
                { counts | ifNeededCount = counts.ifNeededCount + 1, total = counts.total + 1 }

            else
                counts

        fnInner : ( Int, Int ) -> Array DoodleCounts -> Array DoodleCounts
        fnInner ( index, value ) acc =
            Array.set index (updateCounts (Maybe.withDefault emptyCounts <| Array.get index acc) value) acc

        fn : List Int -> Array DoodleCounts -> Array DoodleCounts
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        counted =
            List.foldl fn initial pointsList

        data =
            Array.toList counted
                |> List.indexedMap
                    (\i v ->
                        { name = idToLabel i
                        , id = i
                        , value = v
                        , gradient = idToGradient i
                        , yesCount = v.yesCount
                        , ifNeededCount = v.ifNeededCount
                        , total = v.total
                        }
                    )
                |> List.sortBy .total
                |> List.reverse

        chart =
            C.chart
                [ CA.height 500
                , CA.width 500
                , CA.margin { top = 50, bottom = 150, left = 50, right = 50 }
                ]
                [ C.binLabels .name
                    [ CA.moveDown 15, CA.moveRight 5, CA.rotate 90, CA.alignRight, CA.color "white", CA.fontSize 18 ]
                , C.yLabels [ CA.alignLeft, CA.withGrid, CA.moveLeft 30 ]
                , C.bars [ CA.margin 0.2, CA.spacing 0 ]
                    [ C.stacked
                        [ C.bar .ifNeededCount [ CA.color "orange" ] |> C.named "Pokud nutno"
                        , C.bar .yesCount [ CA.color "green" ] |> C.named "Ano"
                        ]
                    ]
                    data
                , C.legendsAt .max
                    .max
                    [ CA.column
                    , CA.alignRight
                    , CA.moveUp 20
                    , CA.moveLeft 10
                    ]
                    []
                ]

        desc =
            String.concat
                [ "Graf s hodnotami. První číslo je počet hlasů Ano, druhé číslo je počet hlasů Pokud nutno:"
                , List.map
                    (\datum ->
                        String.concat
                            [ String.dropLeft 3 datum.name
                            , " "
                            , String.fromFloat datum.yesCount
                            , " + "
                            , String.fromFloat datum.ifNeededCount
                            , " = "
                            , String.fromFloat datum.total
                            ]
                    )
                    data
                    |> String.join ", "
                ]

        listRow datum =
            div [ class "short-result-list-item" ]
                [ div [ class "short-result-list-candidate" ]
                    [ idToCandidateView datum.id ]
                , div [ class "short-result-list-value" ]
                    [ span [ class "result-positive" ] [ text <| String.fromFloat datum.yesCount ]
                    , text " + "
                    , span [ class "result-if-needed" ] [ text <| String.fromFloat datum.ifNeededCount ]
                    , text " = "
                    , span [ class "result-main" ] [ text <| String.fromFloat datum.total ]
                    ]
                ]

        list =
            div [ class "short-result-list", ariaHidden ] (List.map listRow data)
    in
    div []
        [ div [ class "chart-center", ariaLabel desc ]
            [ div [ class "chart-container", ariaHidden ] [ chart ]
            ]
        , list
        ]


viewOrder : List (List Int) -> Html Msg
viewOrder pointsList =
    let
        initial =
            Array.initialize (Array.length Candidates.all) (always 0)

        fnInner : ( Int, Int ) -> Array Int -> Array Int
        fnInner ( index, value ) acc =
            Array.set index (value + (Maybe.withDefault 0 <| Array.get index acc)) acc

        fn : List Int -> Array Int -> Array Int
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        n =
            max 1 (List.length pointsList)

        counted =
            List.foldl fn initial pointsList
                |> Array.map toFloat
                |> Array.map (\v -> toFloat (round ((v * 100) / toFloat n)) / 100)
    in
    viewSimpleChart counted


viewSTV : List (List Int) -> Html Msg
viewSTV pointsList =
    let
        majority =
            ((List.length pointsList |> toFloat) / 2 |> floor) + 1

        round : Array Bool -> { firstPlaces : List ( Int, Int ), totalPoints : List ( Int, Int ) }
        round active =
            let
                fn :
                    List Int
                    -> { firstPlacesDict : Dict Int Int, totalPointsDict : Dict Int Int }
                    -> { firstPlacesDict : Dict Int Int, totalPointsDict : Dict Int Int }
                fn votes { firstPlacesDict, totalPointsDict } =
                    let
                        order =
                            List.indexedMap Tuple.pair votes
                                |> List.filter (\( i, _ ) -> (Array.get i active |> Maybe.withDefault False) == True)
                                |> List.sortBy Tuple.second
                                |> List.map Tuple.first
                                |> List.indexedMap (\i id -> ( id, i ))
                                |> List.reverse

                        winner =
                            List.head order |> Maybe.map Tuple.first |> Maybe.withDefault -1

                        increase increment current =
                            case current of
                                Nothing ->
                                    Just increment

                                Just v ->
                                    Just (v + increment)

                        updatedFirstPlaces =
                            Dict.update winner (increase 1) firstPlacesDict

                        updateTotalInner ( id, points ) dict =
                            Dict.update id (increase points) dict

                        updatedTotalPoints =
                            List.foldl updateTotalInner totalPointsDict order
                    in
                    { totalPointsDict = updatedTotalPoints, firstPlacesDict = updatedFirstPlaces }

                dicts =
                    List.foldl fn { firstPlacesDict = Dict.empty, totalPointsDict = Dict.empty } pointsList
            in
            { firstPlaces = Dict.toList dicts.firstPlacesDict |> List.sortBy Tuple.second |> List.reverse
            , totalPoints = Dict.toList dicts.totalPointsDict |> List.sortBy Tuple.second
            }

        solve : Int -> Array Bool -> List { firstPlaces : List ( Int, Int ), totalPoints : List ( Int, Int ) }
        solve roundsLeft active =
            let
                results =
                    round active

                dropOut =
                    List.head results.totalPoints |> Maybe.map Tuple.first |> Maybe.withDefault -1

                updatedActive =
                    Array.set dropOut False active

                roundResult =
                    { firstPlaces = results.firstPlaces, totalPoints = results.totalPoints }
            in
            if roundsLeft > 1 then
                roundResult :: solve (roundsLeft - 1) updatedActive

            else
                [ roundResult ]

        firstView ( id, points ) =
            let
                cls =
                    if points >= majority then
                        class "stv-winner"

                    else
                        class ""
            in
            span [ cls ] [ text <| String.concat [ idToLabel id, ": ", String.fromInt points ] ]

        totalView ( id, points ) =
            span [] [ text <| String.concat [ idToLabel id, ": ", String.fromInt points ] ]

        firstPlaces roundResults =
            List.map firstView roundResults.firstPlaces

        totals roundResults =
            List.map totalView roundResults.totalPoints

        roundView index roundResults =
            div []
                [ div [ class "stv-round" ] [ text <| String.concat [ String.fromInt (index + 1), ". kolo " ] ]
                , div [ class "stv-row-order" ] (List.intersperse (text ", ") <| firstPlaces roundResults)
                , div [ class "stv-row-total" ] (List.intersperse (text ", ") <| List.reverse <| totals roundResults)
                ]
    in
    div []
        (div []
            [ text <|
                String.concat
                    [ "Pro výhru je nutné získat alespoň ", String.fromInt majority, " hlasů na prvním místě v daném kole." ]
            ]
            :: List.indexedMap
                (\i r -> roundView i r)
                (solve (Array.length Candidates.all - 1)
                    (Array.initialize (Array.length Candidates.all) (always True))
                )
        )


viewStar : List (List Int) -> Html Msg
viewStar pointsList =
    let
        initial =
            Array.initialize (Array.length Candidates.all) (always 0)

        fnInner : ( Int, Int ) -> Array Int -> Array Int
        fnInner ( index, value ) acc =
            Array.set index (value + (Maybe.withDefault 0 <| Array.get index acc)) acc

        fn : List Int -> Array Int -> Array Int
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        n =
            max 1 (List.length pointsList)

        counted =
            List.foldl fn initial pointsList
                |> Array.map toFloat
                |> Array.map (\v -> toFloat (round (v / toFloat n)))
    in
    viewSimpleChart counted


viewEmoji : List (List String) -> Html Msg
viewEmoji emojisList =
    let
        initial =
            Array.initialize (Array.length Candidates.all) (always Dict.empty)

        updateDict : String -> Dict String Int -> Dict String Int
        updateDict str dict =
            let
                updater existingMaybe =
                    case existingMaybe of
                        Just v ->
                            Just (v + 1)

                        Nothing ->
                            Just 1
            in
            Dict.update (String.trim str) updater dict

        fnInner : ( Int, String ) -> Array (Dict String Int) -> Array (Dict String Int)
        fnInner ( index, value ) acc =
            Array.set index (updateDict value (Maybe.withDefault Dict.empty <| Array.get index acc)) acc

        fn : List String -> Array (Dict String Int) -> Array (Dict String Int)
        fn points acc =
            List.indexedMap Tuple.pair points |> List.foldl fnInner acc

        counted =
            List.foldl fn initial emojisList |> Array.toList |> List.indexedMap Tuple.pair

        top dict =
            Dict.toList dict
                |> List.filter (\( k, _ ) -> not <| String.isEmpty k)
                |> List.sortBy (\( _, v ) -> v)
                |> List.reverse
                |> List.take 5

        desc id topList =
            String.concat
                [ String.dropLeft 3 <| idToLabel id
                , ": "
                , String.join ", " <|
                    List.map
                        (\( emoji, count ) -> String.concat [ String.fromInt count, " x ", emoji ])
                        topList
                ]

        topPair ( emoji, count ) =
            span [ class "emoji-result-pair" ]
                [ span [ class "emoji-result-symbol" ] [ text emoji ]
                , text " "
                , span [ class "emoji-result-count" ] [ text <| String.fromInt count ]
                ]

        showTop topList =
            div [ class "emoji-result-list" ]
                (List.map topPair <| topList)

        listRow ( id, dict ) =
            let
                topList =
                    top dict
            in
            div [ class "short-result-list-item", ariaLabel <| desc id topList ]
                [ div [ class "short-result-list-candidate", ariaHidden ]
                    [ idToCandidateView id ]
                , div [ class "short-result-list-value longer", ariaHidden ]
                    [ showTop topList
                    ]
                ]

        list =
            div [ class "emoji-results short-result-list" ] (List.map listRow counted)
    in
    list



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
