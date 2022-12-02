module Polls.Common exposing (PollConfig)

import Candidates


type alias PollConfig =
    { candidates : List Candidates.Candidate
    , readOnly : Bool
    }
