module Ballistics exposing (view)

import Ballistics.Trajectory as Trajectory
import Chart as C
import Chart.Attributes as CA
import Components exposing (viewSlider)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round
import Types exposing (..)


view : BallisticsModel -> Html Msg
view model =
    div [ class "tool-container-ballistics" ]
        [ div [ class "controls" ]
            [ viewParameters model
            , case model.editingLoad of
                NotEditing ->
                    text ""

                _ ->
                    viewLoadEditor model
            ]
        , div [ class "ballistics-output" ]
            [ viewChart model
            , viewTable model
            ]
        ]


viewParameters : BallisticsModel -> Html Msg
viewParameters model =
    div [ class "parameter-group" ]
        [ h2 [] [ text "Environment & Setup" ]
        , viewSlider "Scope Height (in)" model.scopeHeight 1 3 0.1 UpdateScopeHeight
        , viewSlider "Zero Distance (yd)" model.zeroDistance 25 200 5 UpdateZeroDistance
        , viewSlider "Temperature (°F)" model.temperature 0 100 5 UpdateTemperature
        , viewSlider "Pressure (inHg)" model.pressure 25 32 0.1 UpdatePressure
        , viewSlider "Wind Speed (mph)" model.windSpeed 0 30 1 UpdateWindSpeed
        , div [ class "input-group" ]
            [ div [ class "label-row" ]
                [ label [] [ text "Wind Direction (°)" ]
                , span [ class "value" ] [ text (Round.round 0 model.windDirection ++ "° (" ++ Trajectory.windDirectionLabel model.windDirection ++ ")") ]
                ]
            , input
                [ type_ "range"
                , Html.Attributes.min "0"
                , Html.Attributes.max "360"
                , Html.Attributes.step "15"
                , Html.Attributes.value (String.fromFloat model.windDirection)
                , onInput UpdateWindDirection
                ]
                []
            ]
        , h2 [] [ text "Loads" ]
        , div [ class "load-selector" ]
            (List.indexedMap (viewLoadItem model) model.loads)
        , button [ class "add-load-btn", onClick StartAddingLoad ] [ text "+ Add Load" ]
        ]


viewLoadItem : BallisticsModel -> Int -> Load -> Html Msg
viewLoadItem model idx load =
    div [ class "load-item" ]
        [ button
            [ class
                (if idx == model.selectedLoad then
                    "load-button active"

                 else
                    "load-button"
                )
            , onClick (SelectLoad idx)
            ]
            [ text load.name ]
        , button
            [ class
                (if idx == model.primaryLoadIndex then
                    "load-primary-btn active"

                 else
                    "load-primary-btn"
                )
            , onClick (SetPrimaryLoad idx)
            , title "Set as primary load"
            ]
            [ text "★" ]
        , button [ class "load-edit-btn", onClick (StartEditingLoad idx) ] [ text "✎" ]
        , if List.length model.loads > 1 then
            button [ class "load-remove-btn", onClick (RemoveLoad idx) ] [ text "✕" ]

          else
            text ""
        ]


viewLoadEditor : BallisticsModel -> Html Msg
viewLoadEditor model =
    let
        titleText =
            case model.editingLoad of
                AddingNew ->
                    "Add New Load"

                EditingExisting _ ->
                    "Edit Load"

                NotEditing ->
                    "Edit Load"
    in
    div [ class "load-editor" ]
        [ h2 [] [ text titleText ]
        , div [ class "input-group" ]
            [ label [] [ text "Name" ]
            , input
                [ type_ "text"
                , value model.editForm.name
                , onInput UpdateLoadName
                , class "text-input"
                ]
                []
            ]
        , viewSlider "Weight (gr)" model.editForm.weight 50 300 1 UpdateLoadWeight
        , div [ class "input-group" ]
            [ label [] [ text "BC" ]
            , input
                [ type_ "number"
                , Html.Attributes.step "0.001"
                , Html.Attributes.min "0.1"
                , Html.Attributes.max "1.0"
                , value (String.fromFloat model.editForm.bc)
                , onInput UpdateLoadBC
                , class "text-input"
                ]
                []
            ]
        , div [ class "input-group" ]
            [ label [] [ text "BC Model" ]
            , select [ onInput (bcModelFromString >> UpdateLoadBCModel) ]
                [ option [ value "G1", selected (model.editForm.bcModel == G1) ] [ text "G1" ]
                , option [ value "G7", selected (model.editForm.bcModel == G7) ] [ text "G7" ]
                ]
            ]
        , viewSlider "Muzzle Velocity (fps)" model.editForm.muzzleVelocity 1500 4000 10 UpdateLoadMV
        , viewSlider "Twist Rate (inches)" model.editForm.twistRate 7 14 0.25 UpdateLoadTwist
        , div [ class "editor-buttons" ]
            [ button [ class "save-btn", onClick SaveLoad ] [ text "Save" ]
            , button [ class "cancel-btn", onClick CancelEditingLoad ] [ text "Cancel" ]
            ]
        ]


viewChart : BallisticsModel -> Html Msg
viewChart model =
    let
        primaryLoad =
            model.loads
                |> List.drop model.primaryLoadIndex
                |> List.head
                |> Maybe.withDefault defaultLoad

        equivalentZeros =
            List.indexedMap
                (\idx load ->
                    if idx == model.primaryLoadIndex then
                        ( load, Just model.zeroDistance )

                    else
                        ( load, Trajectory.calculateEquivalentZero model primaryLoad load )
                )
                model.loads

        minRangeOfInterest =
            0

        maxRangeOfInterest =
            150

        colors =
            [ "#4a9eff", "#ff6b6b", "#51cf66", "#ffd43b", "#ff8787", "#748ffc", "#ff922b" ]

        seriesElements =
            List.indexedMap
                (\idx load ->
                    let
                        trajectory =
                            Trajectory.calculateTrajectoryForChart model primaryLoad load minRangeOfInterest maxRangeOfInterest

                        color =
                            colors
                                |> List.drop (modBy (List.length colors) idx)
                                |> List.head
                                |> Maybe.withDefault "#4a9eff"

                        points =
                            trajectory
                                |> List.map (\pt -> { x = pt.range, y = pt.drop })
                    in
                    C.series .x
                        [ C.interpolated .y [ CA.monotone, CA.color color ] [] ]
                        points
                )
                model.loads

        legendItems =
            List.indexedMap
                (\idx load ->
                    let
                        color =
                            colors
                                |> List.drop (modBy (List.length colors) idx)
                                |> List.head
                                |> Maybe.withDefault "#4a9eff"
                    in
                    div [ class "legend-item" ]
                        [ span [ class "legend-color", style "background-color" color ] []
                        , span [] [ text load.name ]
                        ]
                )
                model.loads
    in
    div [ class "ballistics-chart" ]
        [ h2 [] [ text "Trajectory Comparison" ]
        , div [ class "equivalent-zeros" ]
            (List.map viewZeroInfo equivalentZeros)
        , C.chart
            [ CA.height 350
            , CA.width 700
            , CA.range [ CA.lowest 0 CA.exactly, CA.highest 150 CA.exactly ]
            , CA.domain [ CA.lowest -2 CA.exactly, CA.highest 2 CA.exactly ]
            ]
            ([ C.xLabels [ CA.withGrid ]
             , C.yLabels [ CA.withGrid ]
             , C.xAxis []
             , C.yAxis []
             , C.xTicks []
             , C.yTicks []
             , C.labelAt CA.middle .max [ CA.moveDown 30 ] [ Html.text "Range (yards)" ]
             , C.labelAt .min CA.middle [ CA.rotate 90, CA.moveLeft 30 ] [ Html.text "Drop (inches)" ]
             ]
                ++ seriesElements
            )
        , div [ class "chart-legend" ] legendItems
        ]


viewZeroInfo : ( Load, Maybe Float ) -> Html Msg
viewZeroInfo ( load, maybeZero ) =
    case maybeZero of
        Just zero ->
            div [ class "zero-info" ]
                [ span [ class "zero-load" ] [ text (load.name ++ ": ") ]
                , span [ class "zero-value" ] [ text (Round.round 1 zero ++ " yd") ]
                ]

        Nothing ->
            div [ class "zero-info" ]
                [ span [ class "zero-load" ] [ text (load.name ++ ": ") ]
                , span [ class "zero-value warning" ] [ text "No crossing" ]
                ]


viewTable : BallisticsModel -> Html Msg
viewTable model =
    let
        selectedLoad =
            model.loads
                |> List.drop model.selectedLoad
                |> List.head
                |> Maybe.withDefault defaultLoad

        primaryLoad =
            model.loads
                |> List.drop model.primaryLoadIndex
                |> List.head
                |> Maybe.withDefault defaultLoad

        trajectory =
            Trajectory.calculateTrajectory model selectedLoad

        equivalentZero =
            if model.selectedLoad == model.primaryLoadIndex then
                Nothing

            else
                Trajectory.calculateEquivalentZero model primaryLoad selectedLoad
    in
    div [ class "ballistics-table" ]
        [ h2 [] [ text selectedLoad.name ]
        , p []
            [ text
                (String.fromFloat selectedLoad.weight
                    ++ "gr, BC="
                    ++ String.fromFloat selectedLoad.bc
                    ++ " ("
                    ++ bcModelToString selectedLoad.bcModel
                    ++ "), MV="
                    ++ String.fromFloat selectedLoad.muzzleVelocity
                    ++ " fps, Twist="
                    ++ String.fromFloat selectedLoad.twistRate
                    ++ "\""
                )
            ]
        , viewEquivalentZeroText model equivalentZero
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "Range (yd)" ]
                    , th [] [ text "Drop (in)" ]
                    , th [] [ text "Drop (MOA)" ]
                    , th [] [ text "Wind (in)" ]
                    , th [] [ text "Spin (in)" ]
                    , th [] [ text "Vel (fps)" ]
                    , th [] [ text "TOF (s)" ]
                    ]
                ]
            , tbody []
                (List.map viewTrajectoryRow trajectory)
            ]
        ]


viewEquivalentZeroText : BallisticsModel -> Maybe Float -> Html Msg
viewEquivalentZeroText model equivalentZero =
    case equivalentZero of
        Just zero ->
            p [ class "equivalent-zero-text" ] [ text ("Equivalent zero: " ++ Round.round 1 zero ++ " yards") ]

        Nothing ->
            if model.selectedLoad == model.primaryLoadIndex then
                p [ class "equivalent-zero-text" ] [ text ("Primary load - zeroed at " ++ String.fromFloat model.zeroDistance ++ " yards") ]

            else
                p [ class "equivalent-zero-text warning" ] [ text "No equivalent zero found" ]


viewTrajectoryRow : TrajectoryPoint -> Html Msg
viewTrajectoryRow point =
    let
        dropMoa =
            if point.range > 0 then
                point.drop / (point.range * 1.047 / 100)

            else
                0
    in
    tr []
        [ td [] [ text (String.fromInt (round point.range)) ]
        , td [] [ text (Round.round 2 point.drop) ]
        , td [] [ text (Round.round 2 dropMoa) ]
        , td [] [ text (Round.round 2 point.wind) ]
        , td [] [ text (Round.round 2 point.spinDrift) ]
        , td [] [ text (String.fromInt (round point.velocity)) ]
        , td [] [ text (Round.round 3 point.tof) ]
        ]



-- HELPERS


defaultLoad : Load
defaultLoad =
    { name = "Unknown"
    , weight = 150
    , bc = 0.4
    , bcModel = G1
    , muzzleVelocity = 2800
    , twistRate = 10
    }


bcModelToString : BCModel -> String
bcModelToString model =
    case model of
        G1 ->
            "G1"

        G7 ->
            "G7"


bcModelFromString : String -> BCModel
bcModelFromString str =
    case str of
        "G7" ->
            G7

        _ ->
            G1
