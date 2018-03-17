module Types exposing (..)

import VDom exposing (Vnode, DomRef)


type Msg
    = Increment


type alias Model =
    { count : Int
    , vdomList : List (Vnode Msg)
    , containerRoot : DomRef
    }
