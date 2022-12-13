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
          , name = "Karel Diviš"
          , firstName = "Karel"
          , surname = "Diviš"
          , imgName = "karel_divis"
          }
        , { id = 3
          , name = "Pavel Fischer"
          , firstName = "Pavel"
          , surname = "Fischer"
          , imgName = "pavel_fischer"
          }
        , { id = 4
          , name = "Marek Hilšer"
          , firstName = "Marek"
          , surname = "Hilšer"
          , imgName = "marek_hilser"
          }
        , { id = 5
          , name = "Danuše Nerudová"
          , firstName = "Danuše"
          , surname = "Nerudová"
          , imgName = "danuse_nerudova"
          }
        , { id = 6
          , name = "Petr Pavel"
          , firstName = "Petr"
          , surname = "Pavel"
          , imgName = "petr_pavel"
          }
        , { id = 7
          , name = "Josef Středula"
          , firstName = "Josef"
          , surname = "Středula"
          , imgName = "josef_stredula"
          }
        , { id = 8
          , name = "Tomáš Zima"
          , firstName = "Tomáš"
          , surname = "Zima"
          , imgName = "tomas_zima"
          }
        ]
