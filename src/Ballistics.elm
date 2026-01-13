module Ballistics exposing (viewConfig, viewOutput)

import Ballistics.Trajectory as Trajectory
import Chart as C
import Chart.Attributes as CA
import Components exposing (viewSlider)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round
import Types exposing (..)


windSpeedUnitLabel : WindSpeedUnit -> String
windSpeedUnitLabel unit =
    case unit of
        MPH ->
            "mph"

        KPH ->
            "kph"


mphToKph : Float -> Float
mphToKph mph =
    mph * 1.60934


convertWindSpeed : WindSpeedUnit -> Float -> Float
convertWindSpeed unit value =
    case unit of
        MPH ->
            value

        KPH ->
            mphToKph value



-- UNIT CONVERSIONS


inchesToCm : Float -> Float
inchesToCm inches =
    inches * 2.54


yardsToMeters : Float -> Float
yardsToMeters yards =
    yards * 0.9144


fahrenheitToCelsius : Float -> Float
fahrenheitToCelsius f =
    (f - 32) * 5 / 9


inHgToMbar : Float -> Float
inHgToMbar inhg =
    inhg * 33.8639


moaToMil : Float -> Float
moaToMil moa =
    moa * 0.2909


fpsToMps : Float -> Float
fpsToMps fps =
    fps * 0.3048


lengthUnitLabel : LengthUnit -> String
lengthUnitLabel unit =
    case unit of
        Inches ->
            "in"

        Centimeters ->
            "cm"


rangeUnitLabel : RangeUnit -> String
rangeUnitLabel unit =
    case unit of
        Yards ->
            "yd"

        Meters ->
            "m"


angleUnitLabel : AngleUnit -> String
angleUnitLabel unit =
    case unit of
        MOA ->
            "MOA"

        MIL ->
            "MIL"


tempUnitLabel : TempUnit -> String
tempUnitLabel unit =
    case unit of
        Fahrenheit ->
            "F"

        Celsius ->
            "C"


pressureUnitLabel : PressureUnit -> String
pressureUnitLabel unit =
    case unit of
        InHg ->
            "inHg"

        Mbar ->
            "mbar"


velocityUnitLabel : VelocityUnit -> String
velocityUnitLabel unit =
    case unit of
        FPS ->
            "fps"

        MPS ->
            "m/s"


convertLength : LengthUnit -> Float -> Float
convertLength unit value =
    case unit of
        Inches ->
            value

        Centimeters ->
            inchesToCm value


convertRange : RangeUnit -> Float -> Float
convertRange unit value =
    case unit of
        Yards ->
            value

        Meters ->
            yardsToMeters value


convertAngle : AngleUnit -> Float -> Float
convertAngle unit value =
    case unit of
        MOA ->
            value

        MIL ->
            moaToMil value


convertTemp : TempUnit -> Float -> Float
convertTemp unit value =
    case unit of
        Fahrenheit ->
            value

        Celsius ->
            fahrenheitToCelsius value


convertPressure : PressureUnit -> Float -> Float
convertPressure unit value =
    case unit of
        InHg ->
            value

        Mbar ->
            inHgToMbar value


convertVelocity : VelocityUnit -> Float -> Float
convertVelocity unit value =
    case unit of
        FPS ->
            value

        MPS ->
            fpsToMps value


viewConfig : UnitSettings -> BallisticsModel -> Html Msg
viewConfig units model =
    let
        scopeHeightLabel =
            "Scope Height (" ++ lengthUnitLabel units.length ++ ")"

        scopeHeightDisplay =
            convertLength units.length model.scopeHeight

        zeroDistLabel =
            "Zero Distance (" ++ rangeUnitLabel units.range ++ ")"

        zeroDistDisplay =
            convertRange units.range model.zeroDistance

        tempLabel =
            "Temperature (°" ++ tempUnitLabel units.temp ++ ")"

        tempDisplay =
            convertTemp units.temp model.temperature

        pressureLabel =
            "Pressure (" ++ pressureUnitLabel units.pressure ++ ")"

        pressureDisplay =
            convertPressure units.pressure model.pressure

        ( pressureMin, pressureMax ) =
            case units.pressure of
                InHg ->
                    ( 25, 32 )

                Mbar ->
                    ( 847, 1084 )

        ( tempMin, tempMax ) =
            case units.temp of
                Fahrenheit ->
                    ( 0, 100 )

                Celsius ->
                    ( -18, 38 )

        windSpeedLabel =
            "Wind Speed (" ++ windSpeedUnitLabel units.windSpeed ++ ")"

        windSpeedDisplay =
            convertWindSpeed units.windSpeed model.windSpeed

        ( windMin, windMax ) =
            case units.windSpeed of
                MPH ->
                    ( 0, 30 )

                KPH ->
                    ( 0, 48 )
    in
    div [ class "config-section" ]
        [ h3 [] [ text "Firearm" ]
        , viewSlider scopeHeightLabel scopeHeightDisplay 1 3 0.1 UpdateScopeHeight
        , viewSlider zeroDistLabel zeroDistDisplay 25 200 5 UpdateZeroDistance
        , viewSlider "Twist Rate (in)" model.twistRate 3 14 0.5 UpdateTwistRate
        , h3 [] [ text "Environment" ]
        , viewSlider tempLabel tempDisplay tempMin tempMax 1 UpdateTemperature
        , viewSlider pressureLabel pressureDisplay pressureMin pressureMax 0.1 UpdatePressure
        , viewSlider windSpeedLabel windSpeedDisplay windMin windMax 1 UpdateWindSpeed
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
        , h3 [] [ text "Settings" ]
        , viewSlider "Graph Max Range (yd)" model.graphMaxRange 100 1500 50 UpdateGraphMaxRange
        , viewSlider "Table Step Size (yd)" model.tableStepSize 25 200 25 UpdateTableStepSize
        , viewSlider "Table Max Range (yd)" model.tableMaxRange 200 2000 100 UpdateTableMaxRange
        , div [ class "column-toggles" ]
            [ label [] [ text "Table Columns:" ]
            , div [ class "toggle-grid" ]
                [ viewToggle "Drop (" model.showDropDistance ToggleShowDropDistance (lengthUnitLabel units.length ++ ")")
                , viewToggle "Drop (" model.showDropAngle ToggleShowDropAngle (angleUnitLabel units.angle ++ ")")
                , viewToggle "Windage (" model.showWindageDistance ToggleShowWindageDistance (lengthUnitLabel units.length ++ ")")
                , viewToggle "Windage (" model.showWindageAngle ToggleShowWindageAngle (angleUnitLabel units.angle ++ ")")
                , viewToggle "Velocity" model.showVelocity ToggleShowVelocity ""
                , viewToggle "Energy" model.showEnergy ToggleShowEnergy ""
                , viewToggle "TOF" model.showTof ToggleShowTof ""
                ]
            ]
        , h3 [] [ text "Loads" ]
        , div [ class "load-selector" ]
            (List.indexedMap (viewLoadItem model) model.loads)
        , button [ class "add-load-btn", onClick StartAddingLoad ] [ text "+ Add Load" ]
        , case model.editingLoad of
            NotEditing ->
                text ""

            _ ->
                viewLoadEditor model
        ]


viewToggle : String -> Bool -> Msg -> String -> Html Msg
viewToggle labelText isChecked msg suffix =
    label [ class "toggle-label" ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
            , onClick msg
            ]
            []
        , text (labelText ++ suffix)
        ]


viewOutput : UnitSettings -> BallisticsModel -> Html Msg
viewOutput units model =
    div [ class "tool-output" ]
        [ viewChart units model
        , viewTable units model
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
            [ text "◎" ]
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
        , viewSlider "Weight (gr)" model.editForm.weight 20 300 1 UpdateLoadWeight
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
        , viewSlider "Muzzle Velocity (fps)" model.editForm.muzzleVelocity 1000 4000 10 UpdateLoadMV
        , div [ class "editor-buttons" ]
            [ button [ class "save-btn", onClick SaveLoad ] [ text "Save" ]
            , button [ class "cancel-btn", onClick CancelEditingLoad ] [ text "Cancel" ]
            ]
        ]


viewChart : UnitSettings -> BallisticsModel -> Html Msg
viewChart units model =
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
            model.graphMaxRange

        colors =
            [ "#4a9eff", "#ff6b6b", "#51cf66", "#ffd43b", "#ff8787", "#748ffc", "#ff922b" ]

        -- Calculate all trajectories first so we can determine the Y-axis extent
        allTrajectories =
            List.map
                (\load ->
                    Trajectory.calculateTrajectoryForChart model primaryLoad load minRangeOfInterest maxRangeOfInterest
                )
                model.loads

        -- Find the maximum absolute drop across all trajectories
        maxAbsDrop =
            allTrajectories
                |> List.concatMap identity
                |> List.map (\pt -> abs pt.drop)
                |> List.maximum
                |> Maybe.withDefault 2
                |> (\d -> Basics.max d 1)
                |> (\d -> d * 1.1)

        seriesElements =
            List.indexedMap
                (\idx load ->
                    let
                        trajectory =
                            allTrajectories
                                |> List.drop idx
                                |> List.head
                                |> Maybe.withDefault []

                        color =
                            colors
                                |> List.drop (modBy (List.length colors) idx)
                                |> List.head
                                |> Maybe.withDefault "#4a9eff"

                        points =
                            trajectory
                                |> List.map
                                    (\pt ->
                                        { x = convertRange units.range pt.range
                                        , y = convertLength units.length pt.drop
                                        }
                                    )
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

        rangeLabel =
            "Range (" ++ rangeUnitLabel units.range ++ ")"

        dropLabel =
            "Drop (" ++ lengthUnitLabel units.length ++ ")"

        maxRangeDisplay =
            convertRange units.range maxRangeOfInterest

        maxDropDisplay =
            convertLength units.length maxAbsDrop
    in
    div [ class "ballistics-chart" ]
        [ h2 [] [ text "Trajectory Comparison" ]
        , C.chart
            [ CA.height 300
            , CA.width 500
            , CA.margin { top = 10, bottom = 40, left = 50, right = 20 }
            , CA.range [ CA.lowest 0 CA.exactly, CA.highest maxRangeDisplay CA.exactly ]
            , CA.domain [ CA.lowest -maxDropDisplay CA.exactly, CA.highest maxDropDisplay CA.exactly ]
            ]
            ([ C.xLabels [ CA.withGrid, CA.fontSize 9, CA.pinned .min ]
             , C.yLabels [ CA.withGrid, CA.fontSize 9 ]
             , C.xAxis []
             , C.yAxis []
             , C.xTicks [ CA.pinned .min ]
             , C.yTicks []
             , C.labelAt CA.middle .min [ CA.moveDown 30, CA.fontSize 9 ] [ Html.text rangeLabel ]
             , C.labelAt .min CA.middle [ CA.rotate 90, CA.moveLeft 35, CA.fontSize 9 ] [ Html.text dropLabel ]
             ]
                ++ seriesElements
            )
        , div [ class "chart-legend" ] legendItems
        ]


viewZeroInfo : UnitSettings -> ( Load, Maybe Float ) -> Html Msg
viewZeroInfo units ( load, maybeZero ) =
    case maybeZero of
        Just zero ->
            div [ class "zero-info" ]
                [ span [ class "zero-load" ] [ text (load.name ++ ": ") ]
                , span [ class "zero-value" ] [ text (Round.round 1 (convertRange units.range zero) ++ " " ++ rangeUnitLabel units.range) ]
                ]

        Nothing ->
            div [ class "zero-info" ]
                [ span [ class "zero-load" ] [ text (load.name ++ ": ") ]
                , span [ class "zero-value warning" ] [ text "No crossing" ]
                ]


viewTable : UnitSettings -> BallisticsModel -> Html Msg
viewTable units model =
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
            Trajectory.calculateTrajectory model primaryLoad selectedLoad

        equivalentZero =
            if model.selectedLoad == model.primaryLoadIndex then
                Nothing

            else
                Trajectory.calculateEquivalentZero model primaryLoad selectedLoad

        rangeHeader =
            "Range (" ++ rangeUnitLabel units.range ++ ")"

        dropHeader =
            "Drop (" ++ lengthUnitLabel units.length ++ ")"

        angleHeader =
            "Drop (" ++ angleUnitLabel units.angle ++ ")"

        windHeader =
            "Wind (" ++ lengthUnitLabel units.length ++ ")"

        windageDistHeader =
            "Windage (" ++ lengthUnitLabel units.length ++ ")"

        windageAngleHeader =
            "Windage (" ++ angleUnitLabel units.angle ++ ")"

        velHeader =
            "Vel (" ++ velocityUnitLabel units.velocity ++ ")"

        energyHeader =
            "Energy (ft-lb)"
    in
    div [ class "ballistics-table" ]
        [ div [ class "load-tabs" ]
            (List.indexedMap
                (\idx load ->
                    button
                        [ class
                            (if idx == model.selectedLoad then
                                "load-tab active"

                             else
                                "load-tab"
                            )
                        , onClick (SelectLoad idx)
                        ]
                        [ text load.name ]
                )
                model.loads
            )
        , p []
            [ text
                (String.fromFloat selectedLoad.weight
                    ++ "gr, BC="
                    ++ String.fromFloat selectedLoad.bc
                    ++ " ("
                    ++ bcModelToString selectedLoad.bcModel
                    ++ "), MV="
                    ++ String.fromFloat selectedLoad.muzzleVelocity
                    ++ " fps"
                )
            ]
        , viewEquivalentZeroText units model equivalentZero
        , table []
            [ thead []
                [ tr []
                    ([ th [] [ text rangeHeader ] ]
                        ++ (if model.showDropDistance then
                                [ th [] [ text dropHeader ] ]

                            else
                                []
                           )
                        ++ (if model.showDropAngle then
                                [ th [] [ text angleHeader ] ]

                            else
                                []
                           )
                        ++ (if model.showWindageDistance then
                                [ th [] [ text windageDistHeader ] ]

                            else
                                []
                           )
                        ++ (if model.showWindageAngle then
                                [ th [] [ text windageAngleHeader ] ]

                            else
                                []
                           )
                        ++ (if model.showVelocity then
                                [ th [] [ text velHeader ] ]

                            else
                                []
                           )
                        ++ (if model.showEnergy then
                                [ th [] [ text energyHeader ] ]

                            else
                                []
                           )
                        ++ (if model.showTof then
                                [ th [] [ text "TOF (s)" ] ]

                            else
                                []
                           )
                    )
                ]
            , tbody []
                (List.map (viewTrajectoryRow units model) trajectory)
            ]
        ]


viewEquivalentZeroText : UnitSettings -> BallisticsModel -> Maybe Float -> Html Msg
viewEquivalentZeroText units model equivalentZero =
    case equivalentZero of
        Just zero ->
            p [ class "equivalent-zero-text" ] [ text ("Equivalent zero: " ++ Round.round 1 (convertRange units.range zero) ++ " " ++ rangeUnitLabel units.range) ]

        Nothing ->
            if model.selectedLoad == model.primaryLoadIndex then
                p [ class "equivalent-zero-text" ] [ text ("Primary load - zeroed at " ++ Round.round 1 (convertRange units.range model.zeroDistance) ++ " " ++ rangeUnitLabel units.range) ]

            else
                p [ class "equivalent-zero-text warning" ] [ text "No equivalent zero found" ]


viewTrajectoryRow : UnitSettings -> BallisticsModel -> TrajectoryPoint -> Html Msg
viewTrajectoryRow units model point =
    let
        dropMoa =
            if point.range > 0 then
                point.drop / (point.range * 1.047 / 100)

            else
                0

        dropAngle =
            convertAngle units.angle dropMoa

        rangeDisplay =
            convertRange units.range point.range

        dropDisplay =
            convertLength units.length point.drop

        windageDisplay =
            convertLength units.length point.windage

        windageMoa =
            if point.range > 0 then
                point.windage / (point.range * 1.047 / 100)

            else
                0

        windageAngle =
            convertAngle units.angle windageMoa

        velDisplay =
            convertVelocity units.velocity point.velocity
    in
    tr []
        ([ td [] [ text (String.fromInt (round rangeDisplay)) ] ]
            ++ (if model.showDropDistance then
                    [ td [] [ text (Round.round 2 dropDisplay) ] ]

                else
                    []
               )
            ++ (if model.showDropAngle then
                    [ td [] [ text (Round.round 2 dropAngle) ] ]

                else
                    []
               )
            ++ (if model.showWindageDistance then
                    [ td [] [ text (Round.round 2 windageDisplay) ] ]

                else
                    []
               )
            ++ (if model.showWindageAngle then
                    [ td [] [ text (Round.round 2 windageAngle) ] ]

                else
                    []
               )
            ++ (if model.showVelocity then
                    [ td [] [ text (String.fromInt (round velDisplay)) ] ]

                else
                    []
               )
            ++ (if model.showEnergy then
                    [ td [] [ text (String.fromInt (round point.energy)) ] ]

                else
                    []
               )
            ++ (if model.showTof then
                    [ td [] [ text (Round.round 3 point.tof) ] ]

                else
                    []
               )
        )



-- HELPERS


defaultLoad : Load
defaultLoad =
    { name = "Unknown"
    , weight = 150
    , bc = 0.4
    , bcModel = G1
    , muzzleVelocity = 2800
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
