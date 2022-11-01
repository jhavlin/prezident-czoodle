module Candidates exposing (..)

import Array exposing (Array)


type alias Candidate =
    { id : Int
    , name : String
    , firstName : String
    , surname : String
    , imgName : String
    }


all : Array Candidate
all =
    Array.fromList
        [ { id = 0
          , name = "Andrej Babiš"
          , firstName = "Andrej"
          , surname = "Babiš"
          , imgName = "andrej_babis"
          }
        , { id = 1
          , name = "Jaroslav Bašta"
          , firstName = "Jaroslav"
          , surname = "Bašta"
          , imgName = "jaroslav_basta"
          }
        , { id = 2
          , name = "Hynek Blaško"
          , firstName = "Hynek"
          , surname = "Blaško"
          , imgName = "hynek_blasko"
          }
        , { id = 3
          , name = "Tomáš Březina"
          , firstName = "Tomáš"
          , surname = "Březina"
          , imgName = "tomas_brezina"
          }
        , { id = 4
          , name = "Karel Diviš"
          , firstName = "Karel"
          , surname = "Diviš"
          , imgName = "karel_divis"
          }
        , { id = 5
          , name = "Pavel Fischer"
          , firstName = "Pavel"
          , surname = "Fischer"
          , imgName = "pavel_fischer"
          }
        , { id = 6
          , name = "Marek Hilšer"
          , firstName = "Marek"
          , surname = "Hilšer"
          , imgName = "marek_hilser"
          }
        , { id = 7
          , name = "Karel Janeček"
          , firstName = "Karel"
          , surname = "Janeček"
          , imgName = "karel_janecek"
          }
        , { id = 8
          , name = "Jiří Kotáb"
          , firstName = "Jiří"
          , surname = "Kotáb"
          , imgName = "jiri_kotab"
          }
        , { id = 9
          , name = "Ivo Mareš"
          , firstName = "Ivo"
          , surname = "Mareš"
          , imgName = "ivo_mares"
          }
        , { id = 10
          , name = "Libor Michálek"
          , firstName = "Libor"
          , surname = "Michálek"
          , imgName = "libor_michalek"
          }
        , { id = 11
          , name = "Danuše Nerudová"
          , firstName = "Danuše"
          , surname = "Nerudová"
          , imgName = "danuse_nerudova"
          }
        , { id = 12
          , name = "Petr Pavel"
          , firstName = "Petr"
          , surname = "Pavel"
          , imgName = "petr_pavel"
          }
        , { id = 13
          , name = "Josef Skála"
          , firstName = "Josef"
          , surname = "Skála"
          , imgName = "josef_skala"
          }
        , { id = 14
          , name = "Josef Středula"
          , firstName = "Josef"
          , surname = "Středula"
          , imgName = "josef_stredula"
          }
        , { id = 15
          , name = "Alena Vitásková"
          , firstName = "Alena"
          , surname = "Vitásková"
          , imgName = "alena_vitaskova"
          }
        , { id = 16
          , name = "Tomáš Zima"
          , firstName = "Tomáš"
          , surname = "Zima"
          , imgName = "tomas_zima"
          }
        ]
