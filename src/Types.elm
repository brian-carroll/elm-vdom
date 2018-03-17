module Types exposing (..)

import VDom exposing (Vnode, DomRef)


type Msg
    = Init
    | Increment
    | Decrement


type alias Model =
    { count : Int
    , vdomList : List (Vnode Msg)
    , containerRoot : DomRef
    }
