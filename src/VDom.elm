module VDom
    exposing
        ( Vnode(..)
        , Property(..)
        , diff
        )

import Json.Decode as JD
import Json.Encode as JE


type Vnode msg
    = Element
        { tagName : String
        , props : List (Property msg)
        , childNodes : List (Vnode msg)
        }
    | TextNode String


type Property msg
    = Prop String JD.Value


type Patch msg
    = AppendChild (Vnode msg)
    | Replace (Vnode msg)
    | RemoveChildren Int
    | SetProp (Property msg)
    | RemoveAttr String


type PatchTree msg
    = PatchTree
        { patches : List (Patch msg)
        , recurse : List ( Int, PatchTree msg )
        }


emptyPatchTree : PatchTree msg
emptyPatchTree =
    PatchTree
        { patches = []
        , recurse = []
        }


encodePatchTree : PatchTree msg -> JE.Value
encodePatchTree (PatchTree tree) =
    Debug.log "Elm patch tree" <|
        JE.object
            [ ( "patches"
              , JE.list <|
                    List.map encodePatch tree.patches
              )
            , ( "recurse"
              , JE.object <|
                    List.map
                        (\( idx, childTree ) ->
                            ( toString idx, encodePatchTree childTree )
                        )
                        tree.recurse
              )
            ]


encodePatch : Patch msg -> JD.Value
encodePatch patch =
    JE.object <|
        case patch of
            AppendChild vnode ->
                [ ( "type", JE.string "AppendChild" )
                , ( "vnode", encodeVnode vnode )
                ]

            Replace vnode ->
                [ ( "type", JE.string "Replace" )
                , ( "vnode", encodeVnode vnode )
                ]

            RemoveChildren number ->
                [ ( "type", JE.string "RemoveChildren" )
                , ( "number", JE.int number )
                ]

            SetProp (Prop key value) ->
                [ ( "type", JE.string "SetProp" )
                , ( "key", JE.string key )
                , ( "value", value )
                ]

            RemoveAttr key ->
                [ ( "type", JE.string "RemoveAttr" )
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

        Element { tagName, props, childNodes } ->
            JE.object
                [ ( "tagName", JE.string tagName )
                , ( "props", encodeProps props )
                , ( "childNodes", JE.list (List.map encodeVnode childNodes) )
                ]


encodeProps : List (Property msg) -> JD.Value
encodeProps props =
    JE.object <|
        List.map
            (\(Prop key value) -> ( key, value ))
            props


diff : Maybe (Vnode msg) -> Vnode msg -> JE.Value
diff old new =
    let
        oldList =
            case old of
                Nothing ->
                    []

                Just x ->
                    [ x ]
    in
        encodePatchTree <|
            diffChildren 0
                oldList
                [ new ]
                emptyPatchTree


diffNode : Vnode msg -> Vnode msg -> PatchTree msg
diffNode old new =
    case ( old, new ) of
        ( TextNode oldStr, TextNode newStr ) ->
            if oldStr == newStr then
                emptyPatchTree
            else
                PatchTree
                    { patches = [ Replace new ]
                    , recurse = []
                    }

        ( Element oldRec, Element newRec ) ->
            if oldRec.tagName /= newRec.tagName then
                PatchTree
                    { patches = [ Replace new ]
                    , recurse = []
                    }
            else
                let
                    patchTreeWithProps =
                        PatchTree
                            { patches = diffProps oldRec.props newRec.props []
                            , recurse = []
                            }
                in
                    diffChildren 0
                        oldRec.childNodes
                        newRec.childNodes
                        patchTreeWithProps

        _ ->
            PatchTree
                { patches = [ Replace new ]
                , recurse = []
                }


diffChildren : Int -> List (Vnode msg) -> List (Vnode msg) -> PatchTree msg -> PatchTree msg
diffChildren idx oldKids newKids ((PatchTree tree) as pt) =
    case oldKids of
        [] ->
            PatchTree
                { tree
                    | patches =
                        List.foldr
                            (\newKid acc -> AppendChild newKid :: acc)
                            tree.patches
                            newKids
                }

        old :: oldRest ->
            case newKids of
                [] ->
                    PatchTree
                        { tree
                            | patches =
                                RemoveChildren (List.length oldKids)
                                    :: tree.patches
                        }

                new :: newRest ->
                    let
                        childPatchTree =
                            diffNode old new

                        accPatchTree =
                            if childPatchTree == emptyPatchTree then
                                pt
                            else
                                PatchTree
                                    { tree
                                        | recurse =
                                            ( idx
                                            , childPatchTree
                                            )
                                                :: tree.recurse
                                    }
                    in
                        diffChildren (idx + 1) oldRest newRest accPatchTree


diffProps : List (Property msg) -> List (Property msg) -> List (Patch msg) -> List (Patch msg)
diffProps oldProps newProps revPatches =
    case ( oldProps, newProps ) of
        ( [], [] ) ->
            revPatches

        ( [], new :: newRest ) ->
            diffProps [] newRest <|
                (SetProp new)
                    :: revPatches

        ( (Prop key value) :: oldRest, [] ) ->
            diffProps oldRest [] <|
                (RemoveAttr key)
                    :: revPatches

        ( _, ((Prop newKey newVal) as newProp) :: newRest ) ->
            let
                ( mOldVal, oldRest ) =
                    extractFirstMatchingProp newKey oldProps
            in
                if mOldVal == Just newVal then
                    diffProps oldRest newRest revPatches
                else
                    diffProps oldRest newRest <|
                        (SetProp newProp)
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
