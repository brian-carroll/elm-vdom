module VirtualDom exposing (..)

import Json.Decode as JD
import Json.Encode as JE
import TraverseDom exposing (DomRef, parentNode, childNodes)


type Vnode msg
    = Element
        { tagName : String
        , props : List (Property msg)
        , children : List (Vnode msg)
        }
    | TextNode String


type Property msg
    = Prop String JD.Value


type Patch msg
    = Append DomRef (Vnode msg)
    | Remove DomRef
    | SetProp DomRef (Property msg)


encodePatch : Patch msg -> JD.Value
encodePatch patch =
    case patch of
        Append domRef vnode ->
            JE.object
                [ ( "type", JE.string "append" )
                , ( "dom", domRef )
                , ( "vnode", encodeVnode vnode )
                ]

        Remove domRef ->
            JE.object
                [ ( "type", JE.string "remove" )
                , ( "dom", domRef )
                ]

        SetProp domRef (Prop key value) ->
            JE.object
                [ ( "type", JE.string "append" )
                , ( "dom", domRef )
                , ( "key", JE.string key )
                , ( "value", value )
                ]


encodeVnode : Vnode msg -> JD.Value
encodeVnode vnode =
    case vnode of
        TextNode str ->
            JE.object
                [ ( "tagName", JE.string "TEXT" )
                , ( "text", JE.string str )
                ]

        Element { tagName, props, children } ->
            JE.object
                [ ( "tagName", JE.string tagName )
                , ( "props", encodeProps props )
                , ( "children", JE.list (List.map encodeVnode children) )
                ]


encodeProps : List (Property msg) -> JD.Value
encodeProps props =
    JE.object <|
        List.map
            (\(Prop key value) -> ( key, value ))
            props


diff : DomRef -> Vnode msg -> Vnode msg -> List (Patch msg)
diff dom old new =
    diffHelp dom old new []
        |> List.reverse


diffHelp : DomRef -> Vnode msg -> Vnode msg -> List (Patch msg) -> List (Patch msg)
diffHelp dom old new revPatches =
    case ( old, new ) of
        ( TextNode oldStr, TextNode newStr ) ->
            if oldStr == newStr then
                revPatches
            else
                replace dom new revPatches

        ( Element oldRec, Element newRec ) ->
            if oldRec.tagName /= newRec.tagName then
                replace dom new revPatches
            else
                let
                    propPatches =
                        diffProps dom oldRec.props newRec.props revPatches
                in
                    diffChildren dom oldRec.children newRec.children propPatches

        _ ->
            replace dom new revPatches


diffChildren : DomRef -> List (Vnode msg) -> List (Vnode msg) -> List (Patch msg) -> List (Patch msg)
diffChildren parentDom oldKids newKids revPatches =
    -- TODO
    []


replace : DomRef -> Vnode msg -> List (Patch msg) -> List (Patch msg)
replace dom new revPatches =
    (Append (parentNode dom) new)
        :: (Remove dom)
        :: revPatches


diffProps : DomRef -> List (Property msg) -> List (Property msg) -> List (Patch msg) -> List (Patch msg)
diffProps dom oldProps newProps revPatches =
    case ( oldProps, newProps ) of
        ( [], [] ) ->
            revPatches

        ( [], new :: newRest ) ->
            diffProps dom [] newRest <|
                (SetProp dom new)
                    :: revPatches

        ( (Prop key value) :: oldRest, [] ) ->
            diffProps dom oldRest [] <|
                (SetProp dom (Prop key JE.null))
                    :: revPatches

        ( _, ((Prop newKey newVal) as newProp) :: newRest ) ->
            let
                ( mOldVal, oldRest ) =
                    extractFirstMatchingProp newKey oldProps
            in
                if mOldVal == Just newVal then
                    diffProps dom oldRest newRest revPatches
                else
                    diffProps dom oldRest newRest <|
                        (SetProp dom newProp)
                            :: revPatches


{-| Remove the first matching Property from the list, and get its value
-}
extractFirstMatchingProp : String -> List (Property msg) -> ( Maybe JD.Value, List (Property msg) )
extractFirstMatchingProp key pairs =
    case pairs of
        [] ->
            ( Nothing, [] )

        (Prop k v) :: rest ->
            if k == key then
                ( Just v, rest )
            else
                let
                    ( found, leftovers ) =
                        extractFirstMatchingProp key rest
                in
                    ( found, (Prop k v) :: leftovers )



{-
   Event handlers:
       Can't pass function through Port, need to create handler on JS side
       Function on JS side needs to tag the event and send it through with the payload
       Then decode that event on the other side
       Basically building a synthetic event system
       Taggers couldn't be curried functions, just strings

-}
