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


ul =
    node "ul"


li =
    node "li"


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
        , viewImage model.count
        , ul []
            (List.range 0 model.count
                |> List.map (listItem model.count)
            )
        ]


listItem : Int -> Int -> Vnode Msg
listItem count i =
    let
        x =
            if i % 2 == 0 then
                i
            else
                i + count
    in
        li []
            [ text <|
                toString x
            ]


viewImage : Int -> Vnode Msg
viewImage i =
    let
        odd =
            (i % 2)

        url =
            "./assets/img" ++ (toString odd) ++ ".jpg"

        props =
            if odd == 0 then
                [ src url
                , height 100
                ]
            else
                [ height 100
                , src url
                ]
    in
        img props []
