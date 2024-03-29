module Candidates exposing (..)

import Array exposing (Array)


type alias Candidate =
    { id : Int
    , name : String
    , firstName : String
    , surname : String
    , imgName : String
    , p3 : String
    , p4 : String
    , color : String
    }


all : Array Candidate
all =
    Array.fromList
        [ { id = 0
          , name = "Andrej Babiš"
          , firstName = "Andrej"
          , surname = "Babiš"
          , imgName = "andrej_babis"
          , p3 = "Andreji Babišovi"
          , p4 = "Andreje Babiše"
          , color = "white"
          }
        , { id = 1
          , name = "Jaroslav Bašta"
          , firstName = "Jaroslav"
          , surname = "Bašta"
          , imgName = "jaroslav_basta"
          , p3 = "Jaroslavu Baštovi"
          , p4 = "Jaroslava Baštu"
          , color = "blue"
          }
        , { id = 2
          , name = "Karel Diviš"
          , firstName = "Karel"
          , surname = "Diviš"
          , imgName = "karel_divis"
          , p3 = "Karlu Divišovi"
          , p4 = "Karla Diviše"
          , color = "red"
          }
        , { id = 3
          , name = "Pavel Fischer"
          , firstName = "Pavel"
          , surname = "Fischer"
          , imgName = "pavel_fischer"
          , p3 = "Pavlu Fischerovi"
          , p4 = "Pavla Fischera"
          , color = "green"
          }
        , { id = 4
          , name = "Marek Hilšer"
          , firstName = "Marek"
          , surname = "Hilšer"
          , imgName = "marek_hilser"
          , p3 = "Marku Hilšerovi"
          , p4 = "Marka Hilšera"
          , color = "yellow"
          }
        , { id = 5
          , name = "Karel Janeček"
          , firstName = "Karel"
          , surname = "Janeček"
          , imgName = "karel_janecek"
          , p3 = "Karlu Janečkovi"
          , p4 = "Karla Janečka"
          , color = "oliveGreen"
          }
        , { id = 6
          , name = "Danuše Nerudová"
          , firstName = "Danuše"
          , surname = "Nerudová"
          , imgName = "danuse_nerudova"
          , p3 = "Danuši Nerudové"
          , p4 = "Dabnuši Nerudovou"
          , color = "royalBlue"
          }
        , { id = 7
          , name = "Petr Pavel"
          , firstName = "Petr"
          , surname = "Pavel"
          , imgName = "petr_pavel"
          , p3 = "Petru Pavlovi"
          , p4 = "Petra Pavla"
          , color = "ping"
          }
        , { id = 8
          , name = "Josef Středula"
          , firstName = "Josef"
          , surname = "Středula"
          , imgName = "josef_stredula"
          , p3 = "Josefu Středulovi"
          , p4 = "Josefa Středulu"
          , color = "violet"
          }
        , { id = 9
          , name = "Tomáš Zima"
          , firstName = "Tomáš"
          , surname = "Zima"
          , imgName = "tomas_zima"
          , p3 = "Tomáši Zimovi"
          , p4 = "Tomáše Zimu"
          , color = "orange"
          }
        ]
