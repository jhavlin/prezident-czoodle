module Candidates exposing (..)

import Array exposing (Array)


type alias Candidate =
    { id : Int
    , name : String
    , firstName : String
    , surname : String
    , imgName : String
    , p4 : String
    }


all : Array Candidate
all =
    Array.fromList
        [ { id = 0
          , name = "Andrej Babiš"
          , firstName = "Andrej"
          , surname = "Babiš"
          , imgName = "andrej_babis"
          , p4 = "Andreje Babiše"
          }
        , { id = 1
          , name = "Jaroslav Bašta"
          , firstName = "Jaroslav"
          , surname = "Bašta"
          , imgName = "jaroslav_basta"
          , p4 = "Jaroslava Baštu"
          }
        , { id = 2
          , name = "Karel Diviš"
          , firstName = "Karel"
          , surname = "Diviš"
          , imgName = "karel_divis"
          , p4 = "Karla Diviše"
          }
        , { id = 3
          , name = "Pavel Fischer"
          , firstName = "Pavel"
          , surname = "Fischer"
          , imgName = "pavel_fischer"
          , p4 = "Pavla Fischera"
          }
        , { id = 4
          , name = "Marek Hilšer"
          , firstName = "Marek"
          , surname = "Hilšer"
          , imgName = "marek_hilser"
          , p4 = "Marka Hilšera"
          }
        , { id = 5
          , name = "Danuše Nerudová"
          , firstName = "Danuše"
          , surname = "Nerudová"
          , imgName = "danuse_nerudova"
          , p4 = "Danuši Nerudovou"
          }
        , { id = 6
          , name = "Petr Pavel"
          , firstName = "Petr"
          , surname = "Pavel"
          , imgName = "petr_pavel"
          , p4 = "Petra Pavla"
          }
        , { id = 7
          , name = "Josef Středula"
          , firstName = "Josef"
          , surname = "Středula"
          , imgName = "josef_stredula"
          , p4 = "Josefa Středulu"
          }
        , { id = 8
          , name = "Tomáš Zima"
          , firstName = "Tomáš"
          , surname = "Zima"
          , imgName = "tomas_zima"
          , p4 = "Tomáše Zimu"
          }
        ]
