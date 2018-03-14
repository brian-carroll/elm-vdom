module ViewVdom exposing (root)

import VirtualDom exposing (..)
import Types exposing (..)


node : String -> List (Property msg) -> List (Node msg) -> Node msg
node tagName props children =
    Element
        { tagName = tagName
        , props = props
        , children = children
        }


div : List (Property msg) -> List (Node msg) -> Node msg
div =
    node "div"


h1 : List (Property msg) -> List (Node msg) -> Node msg
h1 =
    node "h1"


p : List (Property msg) -> List (Node msg) -> Node msg
p =
    node "p"


button : List (Property msg) -> List (Node msg) -> Node msg
button =
    node "button"


text : String -> Node msg
text =
    Text


root : Model -> Node Msg
root model =
    div []
        [ h1 []
            [ text "Brian's vdom" ]
        , p []
            [ text ("Count: " ++ toString model) ]
        ]
