module TopGun exposing (viewConfig, viewOutput)

import Chart as C
import Chart.Attributes as CA
import Components exposing (viewSlider)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round
import Types exposing (EnergyUnit(..), GraphVariable(..), Msg(..), TopGunModel, UnitSettings, VelocityUnit(..), WeightUnit(..))


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
                    { label = "Muzzle Velocity (fps)", display = model.muzzleVelocity, min = 1500, max = 4000, step = 10 }

                MPS ->
                    { label = "Muzzle Velocity (m/s)", display = fpsToMps model.muzzleVelocity, min = 457, max = 1219, step = 5 }
    in
    div [ class "config-section" ]
        [ h3 [] [ text "Parameters" ]
        , viewSlider "Projectile Weight (gr)" model.projectileWeight 50 300 1 UpdateProjectileWeight
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

        sigma1 =
            moa * 0.85

        sigma2 =
            moa * 1.15

        ( valueFor1Moa, unit ) =
            calculateValueFor1Moa units model
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
                , span [ class "result-value" ] [ text (Round.round 2 moa ++ " MOA") ]
                ]
            , div [ class "result-row result-confidence" ]
                [ span [ class "result-label" ] [ text "1σ (~68%):" ]
                , span [ class "result-value" ] [ text (Round.round 2 sigma1 ++ " - " ++ Round.round 2 sigma2 ++ " MOA") ]
                ]
            , div [ class "result-row" ]
                [ span [ class "result-label" ] [ text ("For 1 MOA (" ++ graphVariableLabel model.graphVariable ++ "):") ]
                , span [ class "result-value" ] [ text (Round.round 1 valueFor1Moa ++ " " ++ unit) ]
                ]
            ]
        ]


viewChart : UnitSettings -> TopGunModel -> Html Msg
viewChart units model =
    let
        ( points, xLabel, yLabel ) =
            generatePlotData units model
    in
    div [ class "chart-container" ]
        [ C.chart
            [ CA.height 300
            , CA.width 500
            , CA.margin { top = 10, bottom = 40, left = 50, right = 20 }
            ]
            [ C.xLabels [ CA.withGrid, CA.fontSize 9 ]
            , C.yLabels [ CA.withGrid, CA.fontSize 9 ]
            , C.xAxis []
            , C.yAxis []
            , C.xTicks []
            , C.yTicks []
            , C.labelAt CA.middle .min [ CA.moveDown 30, CA.fontSize 9 ] [ Html.text xLabel ]
            , C.labelAt .min CA.middle [ CA.rotate 90, CA.moveLeft 35, CA.fontSize 9 ] [ Html.text yLabel ]
            , C.series .x
                [ C.interpolated .y [ CA.monotone, CA.color "#4a9eff" ] []
                ]
                points
            ]
        ]


generatePlotData : UnitSettings -> TopGunModel -> ( List { x : Float, y : Float }, String, String )
generatePlotData units model =
    case model.graphVariable of
        RifleWeight ->
            let
                points =
                    List.range 5 20
                        |> List.map toFloat
                        |> List.map
                            (\weight ->
                                let
                                    ke =
                                        calculateKineticEnergy model.projectileWeight model.muzzleVelocity

                                    moa =
                                        calculateMoa ke weight

                                    xVal =
                                        case units.weight of
                                            Pounds ->
                                                weight

                                            Kilograms ->
                                                lbsToKg weight
                                in
                                { x = xVal, y = moa }
                            )

                xLabel =
                    case units.weight of
                        Pounds ->
                            "Rifle Weight (lbs)"

                        Kilograms ->
                            "Rifle Weight (kg)"
            in
            ( points, xLabel, "Expected Accuracy (MOA)" )

        Velocity ->
            let
                points =
                    List.range 15 40
                        |> List.map (\v -> toFloat v * 100)
                        |> List.map
                            (\vel ->
                                let
                                    ke =
                                        calculateKineticEnergy model.projectileWeight vel

                                    moa =
                                        calculateMoa ke model.rifleWeight

                                    xVal =
                                        case units.velocity of
                                            FPS ->
                                                vel

                                            MPS ->
                                                fpsToMps vel
                                in
                                { x = xVal, y = moa }
                            )

                xLabel =
                    case units.velocity of
                        FPS ->
                            "Muzzle Velocity (fps)"

                        MPS ->
                            "Muzzle Velocity (m/s)"
            in
            ( points, xLabel, "Expected Accuracy (MOA)" )

        ProjectileWeight ->
            let
                points =
                    List.range 50 300
                        |> List.map toFloat
                        |> List.map
                            (\weight ->
                                let
                                    ke =
                                        calculateKineticEnergy weight model.muzzleVelocity

                                    moa =
                                        calculateMoa ke model.rifleWeight
                                in
                                { x = weight, y = moa }
                            )
            in
            ( points, "Projectile Weight (gr)", "Expected Accuracy (MOA)" )



-- CALCULATIONS


calculateKineticEnergy : Float -> Float -> Float
calculateKineticEnergy grainWeight velocityFps =
    (grainWeight * velocityFps ^ 2) / 450436


calculateMoa : Float -> Float -> Float
calculateMoa kineticEnergy rifleWeight =
    kineticEnergy / 200 / rifleWeight


calculateValueFor1Moa : UnitSettings -> TopGunModel -> ( Float, String )
calculateValueFor1Moa units model =
    let
        ke =
            calculateKineticEnergy model.projectileWeight model.muzzleVelocity
    in
    case model.graphVariable of
        RifleWeight ->
            let
                lbsValue =
                    ke / 200
            in
            case units.weight of
                Pounds ->
                    ( lbsValue, "lbs" )

                Kilograms ->
                    ( lbsToKg lbsValue, "kg" )

        Velocity ->
            let
                targetKe =
                    200 * model.rifleWeight

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
                    200 * model.rifleWeight
            in
            ( targetKe * 450436 / (model.muzzleVelocity ^ 2), "gr" )



-- UNIT CONVERSIONS


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
