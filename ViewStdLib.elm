module ViewStdLib exposing (root)

import Html exposing (..)
import Html.Events exposing (onClick)
import Types exposing (..)


root : Model -> Html Msg
root model =
    div []
        [ h1 []
            [ text "Elm-Lang HTML" ]
        , p []
            [ text ("Count: " ++ toString model) ]
        , button
            [ onClick Increment ]
            [ text "+1" ]
        ]
