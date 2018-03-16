port module Main exposing (..)

{-
   Test Virtual Dom
    Nice to test against std lib
    HTML page with two sections
        - Elm HTML
        - My HTML (updated via ports)

-}

import Html
import Types exposing (..)
import ViewStdLib
import ViewVdom
import VDom exposing (Vnode(..), DomRef)
import Json.Decode as JD


port vdomOutput : JD.Value -> Cmd msg


main : Program DomRef Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = (\_ -> Sub.none)
        , view = ViewStdLib.root
        }


init : DomRef -> ( Model, Cmd Msg )
init containerRoot =
    ( { count = 0
      , vdom = TextNode ""
      , containerRoot = containerRoot
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Increment ->
            let
                newModel =
                    { model
                        | count = model.count + 1
                    }
            in
                ( newModel
                , ViewVdom.root newModel
                    |> VDom.diff model.containerRoot model.vdom
                    |> VDom.encodePatches
                    |> vdomOutput
                )
