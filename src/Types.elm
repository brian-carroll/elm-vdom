module Types exposing (..)

import VDom exposing (Vnode)


type Msg
    = Init
    | Increment
    | Decrement


type alias Model =
    { count : Int
    , vdom : Maybe (Vnode Msg)
    }
