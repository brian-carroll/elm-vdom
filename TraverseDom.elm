module TraverseDom exposing (..)

import Json.Decode as JD


type alias DomRef =
    JD.Value


parentNode : DomRef -> DomRef
parentNode domRef =
    JD.decodeValue
        (JD.field "parentNode" JD.value)
        domRef
        |> Result.withDefault
            (Debug.crash ("DOM node has no parentNode:" ++ toString domRef))


childNodes : DomRef -> List DomRef
childNodes domRef =
    JD.decodeValue
        (JD.field "childNodes" (JD.list JD.value))
        domRef
        |> Result.withDefault []
