module Main exposing (..)

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
    ( 0, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Increment ->
            ( model + 1
            , Cmd.none
            )
