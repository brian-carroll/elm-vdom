module VirtualDom exposing (..)

import Json.Decode as JD
import Json.Encode as JE


type Vnode msg
    = Element
        { tagName : String
        , props : List (Property msg)
        , children : List (Vnode msg)
        }
    | TextNode String


type Property msg
    = Property
        { key : String
        , value : JD.Value
        }


type Patch msg
    = Append DomRef (List (Vnode msg))
    | Remove DomRef
    | SetProps DomRef (List (Property msg))


type alias DomRef =
    JD.Value


{-| Decode JUST ENOUGH of the DOM node to traverse it
Only used to get references
All info about properties comes from old VNode
-}
type alias DomNode =
    { parentNode : DomRef
    , childNodes : List DomRef
    , firstChild : Maybe DomRef
    , nextSibling : Maybe DomRef
    }


decodeDomNode : JD.Decoder DomNode
decodeDomNode =
    JD.map4 DomNode
        (JD.field "parentNode" JD.value)
        (JD.field "childNodes" (JD.list JD.value))
        (JD.field "firstChild" (JD.nullable JD.value))
        (JD.field "nextSibling" (JD.nullable JD.value))


diff : Vnode msg -> Vnode msg -> JD.Decoder (List (Patch msg))
diff old new =
    diffHelp old new (JD.succeed [])


diffHelp : Vnode msg -> Vnode msg -> JD.Decoder (List (Patch msg)) -> JD.Decoder (List (Patch msg))
diffHelp old new patches =
    case old of
        TextNode s ->
            {- Check if new
               is a text node (tagName)
               and has the same value
            -}
            JD.list (JD.map Remove JD.value)

        Element { tagName, props, children } ->
            JD.list (JD.map Remove JD.value)


decodeTextNodePatch : Vnode msg -> Vnode msg -> JD.Decoder (Patch msg)
decodeTextNodePatch old new =
    case old of
        Element _ ->
            JD.succeed (Remove JE.null)

        option2 ->
            JD.succeed (Remove JE.null)



{-
   How to keep track of DOM node references?
    Do we need to pass them back from JS?
    Or can we use a patch tree with a NoOp constructor, and traverse in JS?
        Doesn't sound very fast.

    We need root node as JS value anyway
    Can structure the vdom diff as a nested Json Decoder


    diff : Node msg -> JD.Decoder (List (Patch msg))
    diff vdom =
        ...

    patchesDecoder = diff vdom
    patches = JD.decodeValue patchesDecoder dom


    going to need lots of JD.andThen
    append to a set of patches
    recurse down a tree

    Completely flatten patches to a List?
        Hard to do with a whole new sub-tree? One layer down, we have no ref for parent
        => at least Create has to be recursive on JS side

    May need to dynamically decode fields!
        field myFieldName JD.value

    Event handlers:
        Can't pass function through Port, need to create handler on JS side
        Function on JS side needs to tag the event and send it through with the payload
        Then decode that event on the other side
        Basically building a synthetic event system
        Taggers couldn't be curried functions, just strings

-}
