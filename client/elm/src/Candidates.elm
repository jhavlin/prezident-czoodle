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
          , name = "Hynek Blaško"
          , firstName = "Hynek"
          , surname = "Blaško"
          , imgName = "hynek_blasko"
          }
        , { id = 2
          , name = "Tomáš Březina"
          , firstName = "Tomáš"
          , surname = "Březina"
          , imgName = "tomas_brezina"
          }
        , { id = 3
          , name = "Karel Diviš"
          , firstName = "Karel"
          , surname = "Diviš"
          , imgName = "karel_divis"
          }
        , { id = 4
          , name = "Pavel Fischer"
          , firstName = "Pavel"
          , surname = "Fischer"
          , imgName = "pavel_fischer"
          }
        , { id = 5
          , name = "Marek Hilšer"
          , firstName = "Marek"
          , surname = "Hilšer"
          , imgName = "marek_hilser"
          }
        , { id = 6
          , name = "Karel Janeček"
          , firstName = "Karel"
          , surname = "Janeček"
          , imgName = "karel_janecek"
          }
        , { id = 7
          , name = "Jiří Kotáb"
          , firstName = "Jiří"
          , surname = "Kotáb"
          , imgName = "jiri_kotab"
          }
        , { id = 8
          , name = "Ivo Mareš"
          , firstName = "Ivo"
          , surname = "Mareš"
          , imgName = "ivo_mares"
          }
        , { id = 9
          , name = "Danuše Nerudová"
          , firstName = "Danuše"
          , surname = "Nerudová"
          , imgName = "danuse_nerudova"
          }
        , { id = 10
          , name = "Petr Pavel"
          , firstName = "Petr"
          , surname = "Pavel"
          , imgName = "petr_pavel"
          }
        , { id = 11
          , name = "Josef Skála"
          , firstName = "Josef"
          , surname = "Skála"
          , imgName = "josef_skala"
          }
        , { id = 12
          , name = "Josef Středula"
          , firstName = "Josef"
          , surname = "Středula"
          , imgName = "josef_stredula"
          }
        , { id = 13
          , name = "Alena Vitásková"
          , firstName = "Alena"
          , surname = "Vitásková"
          , imgName = "alena_vitaskova"
          }
        , { id = 14
          , name = "Tomáš Zima"
          , firstName = "Tomáš"
          , surname = "Zima"
          , imgName = "tomas_zima"
          }
        ]
