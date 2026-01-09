module Components exposing (viewSlider)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round


viewSlider : String -> Float -> Float -> Float -> Float -> (String -> msg) -> Html msg
viewSlider labelText value minVal maxVal step msg =
    div [ class "input-group" ]
        [ div [ class "label-row" ]
            [ label [] [ text labelText ]
            , span [ class "value" ] [ text (Round.round 1 value) ]
            ]
        , input
            [ type_ "range"
            , Html.Attributes.min (String.fromFloat minVal)
            , Html.Attributes.max (String.fromFloat maxVal)
            , Html.Attributes.step (String.fromFloat step)
            , Html.Attributes.value (String.fromFloat value)
            , onInput msg
            ]
            []
        ]
