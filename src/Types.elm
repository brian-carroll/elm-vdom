module Types exposing (..)

import VDom exposing (Vnode, DomRef)


type Msg
    = Increment


type alias Model =
    { count : Int
    , vdom : Vnode Msg
    , containerRoot : DomRef
    }
