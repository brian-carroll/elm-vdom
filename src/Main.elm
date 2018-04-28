port module Main exposing (..)

{-
   Test Virtual Dom
    Nice to test against std lib
    HTML page with two sections
        - Elm HTML
        - My HTML (updated via ports)

-}

import Html
import Task
import Types exposing (..)
import ViewStdLib
import ViewVdom
import VDom exposing (Vnode(..))
import Json.Decode as JD


port vdomOutput : JD.Value -> Cmd msg


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = (\_ -> Sub.none)
        , view = ViewStdLib.root
        }


init : ( Model, Cmd Msg )
init =
    let
        initModel =
            { count = 0
            , vdom = Nothing
            }
    in
        ( initModel
        , Task.perform (\() -> Init) (Task.succeed ())
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    let
        inc =
            case message of
                Init ->
                    0

                Increment ->
                    1

                Decrement ->
                    -1

        newModel =
            { model
                | count = model.count + inc
            }

        newVdom =
            ViewVdom.root newModel
    in
        ( { newModel
            | vdom = Just newVdom
          }
        , renderVdom model.vdom newVdom
        )


renderVdom : Maybe (Vnode msg) -> Vnode msg -> Cmd msg
renderVdom old new =
    VDom.diff old new
        |> vdomOutput
