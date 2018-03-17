module VDom
    exposing
        ( Vnode(..)
        , Property(..)
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
    | Replace DomRef (Vnode msg)
    | Remove DomRef
    | SetProp DomRef (Property msg)
    | RemoveAttr DomRef String


type alias DomRef =
    JD.Value


{-| Get children of a real DOM node as an Elm List
-}
domChildNodes : DomRef -> List DomRef
domChildNodes parentNode =
    let
        -- Can't use JD.list because Node.childNodes is not strictly an instance of Array
        -- Instead have to do it recursively with firstChild and nextSibling
        firstChildResult =
            JD.decodeValue
                (JD.field "firstChild" JD.value)
                parentNode
    in
        case firstChildResult of
            Err _ ->
                []

            Ok firstChild ->
                if (firstChild == JE.null) then
                    []
                else
                    domChildNodesHelp firstChild [ firstChild ]


domChildNodesHelp : JD.Value -> List JD.Value -> List JD.Value
domChildNodesHelp prevNode reverseNodes =
    let
        nextSiblingResult =
            JD.decodeValue
                (JD.field "nextSibling" JD.value)
                prevNode
    in
        case nextSiblingResult of
            Err _ ->
                []

            Ok nextSibling ->
                if nextSibling == JE.null then
                    List.reverse reverseNodes
                else
                    domChildNodesHelp nextSibling (nextSibling :: reverseNodes)


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

            Replace domRef vnode ->
                [ ( "type", JE.string "Replace" )
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

            RemoveAttr domRef key ->
                [ ( "type", JE.string "RemoveAttr" )
                , ( "dom", domRef )
                , ( "key", JE.string key )
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


diff : DomRef -> List (Vnode msg) -> Vnode msg -> List (Patch msg)
diff containerDom oldList new =
    List.reverse <|
        diffChildren
            containerDom
            (domChildNodes containerDom)
            oldList
            [ new ]
            []


diffNode : DomRef -> Vnode msg -> Vnode msg -> List (Patch msg) -> List (Patch msg)
diffNode dom old new revPatches =
    case ( old, new ) of
        ( TextNode oldStr, TextNode newStr ) ->
            if oldStr == newStr then
                revPatches
            else
                (Replace dom new) :: revPatches

        ( Element oldRec, Element newRec ) ->
            if oldRec.tagName /= newRec.tagName then
                (Replace dom new) :: revPatches
            else
                let
                    revPatchesWithProps =
                        diffProps dom oldRec.props newRec.props revPatches
                in
                    diffChildren
                        dom
                        (domChildNodes dom)
                        oldRec.children
                        newRec.children
                        revPatchesWithProps

        _ ->
            (Replace dom new) :: revPatches


diffChildren : DomRef -> List DomRef -> List (Vnode msg) -> List (Vnode msg) -> List (Patch msg) -> List (Patch msg)
diffChildren parentDom domKids oldKids newKids revPatches =
    case ( oldKids, newKids ) of
        ( [], [] ) ->
            revPatches

        ( [], _ ) ->
            List.foldl
                (\newKid accPatches -> (AppendChild parentDom newKid) :: accPatches)
                revPatches
                newKids

        ( _, [] ) ->
            List.foldl
                (\domKid accPatches -> (Remove domKid) :: accPatches)
                revPatches
                domKids

        ( old :: oldRest, new :: newRest ) ->
            case domKids of
                dom :: domRest ->
                    diffChildren parentDom domRest oldRest newRest <|
                        (diffNode dom old new revPatches)

                [] ->
                    Debug.crash <|
                        "Virtual DOM node doesn't have a matching real DOM node:\n"
                            ++ (toString old)


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
                (RemoveAttr dom key)
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
