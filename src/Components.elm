module Components exposing (viewSlider, viewSliderWithPrecision)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round


viewSlider : String -> Float -> Float -> Float -> Float -> (String -> msg) -> Html msg
viewSlider labelText val minVal maxVal stepVal msg =
    viewSliderWithPrecision labelText val minVal maxVal stepVal 1 msg


viewSliderWithPrecision : String -> Float -> Float -> Float -> Float -> Int -> (String -> msg) -> Html msg
viewSliderWithPrecision labelText val minVal maxVal stepVal precision msg =
    div [ class "input-group" ]
        [ div [ class "label-row" ]
            [ label [] [ text labelText ]
            , input
                [ type_ "number"
                , class "value-input"
                , Html.Attributes.min (String.fromFloat minVal)
                , Html.Attributes.max (String.fromFloat maxVal)
                , Html.Attributes.step (String.fromFloat stepVal)
                , value (Round.round precision val)
                , onInput msg
                ]
                []
            ]
        , input
            [ type_ "range"
            , Html.Attributes.min (String.fromFloat minVal)
            , Html.Attributes.max (String.fromFloat maxVal)
            , Html.Attributes.step (String.fromFloat stepVal)
            , Html.Attributes.value (String.fromFloat val)
            , onInput msg
            ]
            []
        ]
