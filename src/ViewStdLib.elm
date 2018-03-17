module ViewStdLib exposing (root)

import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (src, height)
import Types exposing (..)


root : Model -> Html Msg
root model =
    div []
        [ h1 []
            [ text "elm-lang/html" ]
        , p []
            [ text ("Count: " ++ toString model.count) ]
        , img
            [ (src (selectImage model.count))
            , height 100
            ]
            []
        , br [] []
        , button
            [ onClick Increment ]
            [ text "+1" ]
        , br [] []
        , button
            [ onClick Decrement ]
            [ text "-1" ]
        ]


selectImage : Int -> String
selectImage i =
    "./assets/img" ++ (toString (i % 2)) ++ ".jpg"
