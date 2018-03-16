module ViewVdom exposing (root)

import VDom exposing (..)
import Types exposing (..)


node : String -> List (Property msg) -> List (Vnode msg) -> Vnode msg
node tagName props children =
    Element
        { tagName = tagName
        , props = props
        , children = children
        }


div : List (Property msg) -> List (Vnode msg) -> Vnode msg
div =
    node "div"


h1 : List (Property msg) -> List (Vnode msg) -> Vnode msg
h1 =
    node "h1"


p : List (Property msg) -> List (Vnode msg) -> Vnode msg
p =
    node "p"


button : List (Property msg) -> List (Vnode msg) -> Vnode msg
button =
    node "button"


text : String -> Vnode msg
text =
    TextNode


root : Model -> Vnode Msg
root model =
    div []
        [ h1 []
            [ text "Brian's vdom" ]
        , p []
            [ text ("Count: " ++ toString model.count) ]
        ]
