module TopGun exposing (viewConfig, viewOutput)

import Chart as C
import Chart.Attributes as CA
import Chart.Svg as CS
import Components exposing (viewSlider)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round
import Svg as S
import Svg.Attributes as SA
import Types exposing (AngleUnit(..), EnergyUnit(..), GraphVariable(..), Msg(..), TopGunModel, UnitSettings, VelocityUnit(..), WeightUnit(..))


viewConfig : UnitSettings -> TopGunModel -> Html Msg
viewConfig units model =
    let
        rifleWeightConfig =
            case units.weight of
                Pounds ->
                    { label = "Rifle Weight (lbs)", display = model.rifleWeight, min = 5, max = 20 }

                Kilograms ->
                    { label = "Rifle Weight (kg)", display = lbsToKg model.rifleWeight, min = 2.3, max = 9.1 }

        velocityConfig =
            case units.velocity of
                FPS ->
                    { label = "Muzzle Velocity (fps)", display = model.muzzleVelocity, min = 1000, max = 4000, step = 10 }

                MPS ->
                    { label = "Muzzle Velocity (m/s)", display = fpsToMps model.muzzleVelocity, min = 305, max = 1219, step = 5 }
    in
    div [ class "config-section" ]
        [ h3 [] [ text "Parameters" ]
        , viewSlider "Projectile Weight (gr)" model.projectileWeight 20 300 1 UpdateProjectileWeight
        , viewSlider velocityConfig.label velocityConfig.display velocityConfig.min velocityConfig.max velocityConfig.step UpdateMuzzleVelocity
        , viewSlider rifleWeightConfig.label rifleWeightConfig.display rifleWeightConfig.min rifleWeightConfig.max 0.5 UpdateRifleWeight
        , div [ class "input-group" ]
            [ label [] [ text "Graph Variable" ]
            , select [ onInput (graphVariableFromString >> UpdateGraphVariable) ]
                [ option [ value "rifle", selected (model.graphVariable == RifleWeight) ] [ text "Rifle Weight" ]
                , option [ value "velocity", selected (model.graphVariable == Velocity) ] [ text "Velocity" ]
                , option [ value "projectile", selected (model.graphVariable == ProjectileWeight) ] [ text "Projectile Weight" ]
                ]
            ]
        ]


viewOutput : UnitSettings -> TopGunModel -> Html Msg
viewOutput units model =
    div [ class "tool-output" ]
        [ viewChart units model
        , viewResults units model
        ]


viewResults : UnitSettings -> TopGunModel -> Html Msg
viewResults units model =
    let
        keFtLbs =
            calculateKineticEnergy model.projectileWeight model.muzzleVelocity

        ( keDisplay, keUnitLabel ) =
            case units.energy of
                FootPounds ->
                    ( keFtLbs, "ft-lbs" )

                Joules ->
                    ( ftLbsToJoules keFtLbs, "J" )

        moa =
            calculateMoa keFtLbs model.rifleWeight

        angleData =
            case units.angle of
                MOA ->
                    { accuracy = moa
                    , sigma1Low = moa * 0.694
                    , sigma1High = moa * 1.306
                    , sigma2Low = moa * 0.40
                    , sigma2High = moa * 1.60
                    , label = "MOA"
                    , target = "1 MOA"
                    }

                MIL ->
                    let
                        mil =
                            moaToMil moa
                    in
                    { accuracy = mil
                    , sigma1Low = mil * 0.694
                    , sigma1High = mil * 1.306
                    , sigma2Low = mil * 0.40
                    , sigma2High = mil * 1.60
                    , label = "MIL"
                    , target = "0.3 MIL"
                    }

        ( valueForTarget, unit ) =
            calculateValueForTarget units model
    in
    div [ class "results" ]
        [ h2 [] [ text "Results" ]
        , div [ class "results-grid" ]
            [ div [ class "result-row" ]
                [ span [ class "result-label" ] [ text "Kinetic Energy:" ]
                , span [ class "result-value" ] [ text (Round.round 1 keDisplay ++ " " ++ keUnitLabel) ]
                ]
            , div [ class "result-row" ]
                [ span [ class "result-label" ] [ text "Expected Accuracy:" ]
                , span [ class "result-value" ] [ text (Round.round 2 angleData.accuracy ++ " " ++ angleData.label) ]
                ]
            , div [ class "result-row result-confidence" ]
                [ span [ class "result-label" ] [ text "1σ (~68%):" ]
                , span [ class "result-value" ] [ text (Round.round 2 angleData.sigma1Low ++ " - " ++ Round.round 2 angleData.sigma1High ++ " " ++ angleData.label) ]
                ]
            , div [ class "result-row result-confidence" ]
                [ span [ class "result-label" ] [ text "2σ (~95%):" ]
                , span [ class "result-value" ] [ text (Round.round 2 angleData.sigma2Low ++ " - " ++ Round.round 2 angleData.sigma2High ++ " " ++ angleData.label) ]
                ]
            , div [ class "result-row" ]
                [ span [ class "result-label" ] [ text ("For " ++ angleData.target ++ " (" ++ graphVariableLabel model.graphVariable ++ "):") ]
                , span [ class "result-value" ] [ text (Round.round 1 valueForTarget ++ " " ++ unit) ]
                ]
            ]
        ]


viewChart : UnitSettings -> TopGunModel -> Html Msg
viewChart units model =
    let
        ( points, xLabel, yLabel ) =
            generatePlotData units model

        -- Create SVG polygon points for confidence bands
        bandPolygon : (PlotPoint -> Float) -> (PlotPoint -> Float) -> CS.Plane -> String
        bandPolygon getLow getHigh plane =
            let
                -- Upper edge (left to right)
                upperPoints =
                    points
                        |> List.map
                            (\pt ->
                                let
                                    svgPt =
                                        CS.fromCartesian plane { x = pt.x, y = getHigh pt }
                                in
                                String.fromFloat svgPt.x ++ "," ++ String.fromFloat svgPt.y
                            )

                -- Lower edge (right to left, reversed to close polygon)
                lowerPoints =
                    points
                        |> List.reverse
                        |> List.map
                            (\pt ->
                                let
                                    svgPt =
                                        CS.fromCartesian plane { x = pt.x, y = getLow pt }
                                in
                                String.fromFloat svgPt.x ++ "," ++ String.fromFloat svgPt.y
                            )
            in
            String.join " " (upperPoints ++ lowerPoints)
    in
    div [ class "chart-container" ]
        [ C.chart
            [ CA.height 300
            , CA.width 500
            , CA.margin { top = 10, bottom = 40, left = 50, right = 20 }
            ]
            [ -- 2σ band (drawn first, behind everything)
              C.svg
                (\plane ->
                    S.polygon
                        [ SA.points (bandPolygon .sigma2Low .sigma2High plane)
                        , SA.fill "#4a9eff"
                        , SA.fillOpacity "0.075"
                        , SA.stroke "none"
                        ]
                        []
                )

            -- 1σ band
            , C.svg
                (\plane ->
                    S.polygon
                        [ SA.points (bandPolygon .sigma1Low .sigma1High plane)
                        , SA.fill "#4a9eff"
                        , SA.fillOpacity "0.125"
                        , SA.stroke "none"
                        ]
                        []
                )

            -- Grid and axes
            , C.xLabels [ CA.withGrid, CA.fontSize 9 ]
            , C.yLabels [ CA.withGrid, CA.fontSize 9 ]
            , C.xAxis []
            , C.yAxis []
            , C.xTicks []
            , C.yTicks []
            , C.labelAt CA.middle .min [ CA.moveDown 30, CA.fontSize 9 ] [ Html.text xLabel ]
            , C.labelAt .min CA.middle [ CA.rotate 90, CA.moveLeft 35, CA.fontSize 9 ] [ Html.text yLabel ]

            -- Main line (drawn last, on top)
            , C.series .x
                [ C.interpolated .y [ CA.monotone, CA.color "#4a9eff" ] []
                ]
                points
            ]
        ]


type alias PlotPoint =
    { x : Float
    , y : Float
    , sigma1Low : Float
    , sigma1High : Float
    , sigma2Low : Float
    , sigma2High : Float
    }


generatePlotData : UnitSettings -> TopGunModel -> ( List PlotPoint, String, String )
generatePlotData units model =
    let
        yLabel =
            case units.angle of
                MOA ->
                    "Expected Accuracy (MOA)"

                MIL ->
                    "Expected Accuracy (MIL)"

        convertAngle moa =
            case units.angle of
                MOA ->
                    moa

                MIL ->
                    moaToMil moa
    in
    case model.graphVariable of
        RifleWeight ->
            let
                points =
                    List.range 50 200
                        |> List.map (\w -> toFloat w / 10)
                        |> List.map
                            (\weight ->
                                let
                                    ke =
                                        calculateKineticEnergy model.projectileWeight model.muzzleVelocity

                                    moa =
                                        calculateMoa ke weight

                                    y =
                                        convertAngle moa

                                    xVal =
                                        case units.weight of
                                            Pounds ->
                                                weight

                                            Kilograms ->
                                                lbsToKg weight
                                in
                                { x = xVal
                                , y = y
                                , sigma1Low = y * 0.694
                                , sigma1High = y * 1.306
                                , sigma2Low = y * 0.40
                                , sigma2High = y * 1.60
                                }
                            )

                xLabel =
                    case units.weight of
                        Pounds ->
                            "Rifle Weight (lbs)"

                        Kilograms ->
                            "Rifle Weight (kg)"
            in
            ( points, xLabel, yLabel )

        Velocity ->
            let
                points =
                    List.range 100 400
                        |> List.map (\v -> toFloat v * 10)
                        |> List.map
                            (\vel ->
                                let
                                    ke =
                                        calculateKineticEnergy model.projectileWeight vel

                                    moa =
                                        calculateMoa ke model.rifleWeight

                                    y =
                                        convertAngle moa

                                    xVal =
                                        case units.velocity of
                                            FPS ->
                                                vel

                                            MPS ->
                                                fpsToMps vel
                                in
                                { x = xVal
                                , y = y
                                , sigma1Low = y * 0.694
                                , sigma1High = y * 1.306
                                , sigma2Low = y * 0.40
                                , sigma2High = y * 1.60
                                }
                            )

                xLabel =
                    case units.velocity of
                        FPS ->
                            "Muzzle Velocity (fps)"

                        MPS ->
                            "Muzzle Velocity (m/s)"
            in
            ( points, xLabel, yLabel )

        ProjectileWeight ->
            let
                points =
                    List.range 20 300
                        |> List.map toFloat
                        |> List.map
                            (\weight ->
                                let
                                    ke =
                                        calculateKineticEnergy weight model.muzzleVelocity

                                    moa =
                                        calculateMoa ke model.rifleWeight

                                    y =
                                        convertAngle moa
                                in
                                { x = weight
                                , y = y
                                , sigma1Low = y * 0.694
                                , sigma1High = y * 1.306
                                , sigma2Low = y * 0.40
                                , sigma2High = y * 1.60
                                }
                            )
            in
            ( points, "Projectile Weight (gr)", yLabel )



-- CALCULATIONS


calculateKineticEnergy : Float -> Float -> Float
calculateKineticEnergy grainWeight velocityFps =
    (grainWeight * velocityFps ^ 2) / 450436


calculateMoa : Float -> Float -> Float
calculateMoa kineticEnergy rifleWeight =
    kineticEnergy / 200 / rifleWeight


calculateValueForTarget : UnitSettings -> TopGunModel -> ( Float, String )
calculateValueForTarget units model =
    let
        ke =
            calculateKineticEnergy model.projectileWeight model.muzzleVelocity

        -- Target is 1 MOA, or 0.3 MIL (which is ~1.03 MOA)
        targetMoa =
            case units.angle of
                MOA ->
                    1.0

                MIL ->
                    0.3 / 0.2909
    in
    case model.graphVariable of
        RifleWeight ->
            let
                -- For target MOA: targetMoa = ke / 200 / rifleWeight
                -- So: rifleWeight = ke / 200 / targetMoa
                lbsValue =
                    ke / 200 / targetMoa
            in
            case units.weight of
                Pounds ->
                    ( lbsValue, "lbs" )

                Kilograms ->
                    ( lbsToKg lbsValue, "kg" )

        Velocity ->
            let
                -- For target MOA: targetMoa = ke / 200 / rifleWeight
                -- So: ke = targetMoa * 200 * rifleWeight
                targetKe =
                    targetMoa * 200 * model.rifleWeight

                fpsValue =
                    sqrt (targetKe * 450436 / model.projectileWeight)
            in
            case units.velocity of
                FPS ->
                    ( fpsValue, "fps" )

                MPS ->
                    ( fpsToMps fpsValue, "m/s" )

        ProjectileWeight ->
            let
                targetKe =
                    targetMoa * 200 * model.rifleWeight
            in
            ( targetKe * 450436 / (model.muzzleVelocity ^ 2), "gr" )



-- UNIT CONVERSIONS


moaToMil : Float -> Float
moaToMil moa =
    moa * 0.2909


lbsToKg : Float -> Float
lbsToKg lbs =
    lbs * 0.453592


kgToLbs : Float -> Float
kgToLbs kg =
    kg / 0.453592


ftLbsToJoules : Float -> Float
ftLbsToJoules ftlbs =
    ftlbs * 1.35582


fpsToMps : Float -> Float
fpsToMps fps =
    fps * 0.3048


mpsToFps : Float -> Float
mpsToFps mps =
    mps / 0.3048



-- HELPERS


graphVariableFromString : String -> GraphVariable
graphVariableFromString str =
    case str of
        "velocity" ->
            Velocity

        "projectile" ->
            ProjectileWeight

        _ ->
            RifleWeight


graphVariableLabel : GraphVariable -> String
graphVariableLabel variable =
    case variable of
        RifleWeight ->
            "rifle weight"

        Velocity ->
            "velocity"

        ProjectileWeight ->
            "projectile weight"
