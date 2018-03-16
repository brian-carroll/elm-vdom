module VDom
    exposing
        ( Vnode(..)
        , Property
        , DomRef
        , diff
        , encodePatches
        )

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
    = Prop String JD.Value


type Patch msg
    = AppendChild DomRef (Vnode msg)
    | InsertBefore DomRef (Vnode msg)
    | Remove DomRef
    | SetProp DomRef (Property msg)


type alias DomRef =
    JD.Value


childNodes : DomRef -> List DomRef
childNodes domRef =
    JD.decodeValue
        (JD.field "childNodes" (JD.list JD.value))
        domRef
        |> Result.withDefault []


encodePatches : List (Patch msg) -> JD.Value
encodePatches patches =
    JE.list <|
        List.map encodePatch patches


encodePatch : Patch msg -> JD.Value
encodePatch patch =
    JE.object <|
        case patch of
            AppendChild parentDom vnode ->
                [ ( "type", JE.string "AppendChild" )
                , ( "parentDom", parentDom )
                , ( "vnode", encodeVnode vnode )
                ]

            InsertBefore domRef vnode ->
                [ ( "type", JE.string "InsertBefore" )
                , ( "dom", domRef )
                , ( "vnode", encodeVnode vnode )
                ]

            Remove domRef ->
                [ ( "type", JE.string "Remove" )
                , ( "dom", domRef )
                ]

            SetProp domRef (Prop key value) ->
                [ ( "type", JE.string "SetProp" )
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
diff containerDom old new =
    List.reverse <|
        diffChildren
            containerDom
            (childNodes containerDom)
            [ old ]
            [ new ]
            []


diffNode : DomRef -> Vnode msg -> Vnode msg -> List (Patch msg) -> List (Patch msg)
diffNode dom old new revPatches =
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
                    revPatchesWithProps =
                        diffProps dom oldRec.props newRec.props revPatches
                in
                    diffChildren
                        dom
                        (childNodes dom)
                        oldRec.children
                        newRec.children
                        revPatchesWithProps

        _ ->
            replace dom new revPatches


replace : DomRef -> Vnode msg -> List (Patch msg) -> List (Patch msg)
replace dom new revPatches =
    (Remove dom)
        :: (InsertBefore dom new)
        :: revPatches


diffChildren : DomRef -> List DomRef -> List (Vnode msg) -> List (Vnode msg) -> List (Patch msg) -> List (Patch msg)
diffChildren parentDom domKids oldKids newKids revPatches =
    case ( domKids, oldKids, newKids ) of
        ( [], [], [] ) ->
            revPatches

        ( [], [], _ ) ->
            List.foldl
                (\newKid acc -> (AppendChild parentDom newKid) :: acc)
                revPatches
                newKids

        ( _, _, [] ) ->
            List.foldl
                (\domKid acc -> (Remove domKid) :: acc)
                revPatches
                domKids

        ( dom :: domRest, old :: oldRest, new :: newRest ) ->
            diffChildren parentDom domRest oldRest newRest <|
                (diffNode dom old new revPatches)

        _ ->
            Debug.crash <|
                "Virtual DOM doesn't match real DOM:\n"
                    ++ "real:\n"
                    ++ toString domKids
                    ++ "virtual:\n"
                    ++ toString oldKids


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