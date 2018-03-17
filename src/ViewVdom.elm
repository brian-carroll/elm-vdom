module ViewVdom exposing (root)

import VDom exposing (..)
import Types exposing (..)
import Json.Encode as JE


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


img : List (Property msg) -> List (Vnode msg) -> Vnode msg
img =
    node "img"


src : String -> Property msg
src url =
    Prop "src" (JE.string url)


width : Int -> Property msg
width w =
    Prop "width" (JE.int w)


height : Int -> Property msg
height h =
    Prop "height" (JE.int h)


root : Model -> Vnode Msg
root model =
    div []
        [ h1 []
            [ text "my vdom" ]
        , p []
            [ text ("Count: " ++ toString model.count) ]
        , img
            [ src (selectImage model.count)
            , height 100
            ]
            []
        ]


selectImage : Int -> String
selectImage i =
    "./assets/img" ++ (toString (i % 2)) ++ ".jpg"
