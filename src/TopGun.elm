module TopGun exposing (view)

import Chart as C
import Chart.Attributes as CA
import Components exposing (viewSlider)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round
import Types exposing (GraphVariable(..), Msg(..), TopGunModel)


view : TopGunModel -> Html Msg
view model =
    div [ class "tool-container" ]
        [ div [ class "controls" ]
            [ viewParameters model
            , viewResults model
            ]
        , div [ class "chart-container" ]
            [ viewChart model ]
        ]


viewParameters : TopGunModel -> Html Msg
viewParameters model =
    div [ class "parameter-group" ]
        [ h2 [] [ text "Parameters" ]
        , viewSlider "Projectile Weight (gr)" model.projectileWeight 50 300 1 UpdateProjectileWeight
        , viewSlider "Muzzle Velocity (fps)" model.muzzleVelocity 1500 4000 10 UpdateMuzzleVelocity
        , viewSlider "Rifle Weight (lbs)" model.rifleWeight 5 20 0.5 UpdateRifleWeight
        , div [ class "input-group" ]
            [ label [] [ text "Graph Variable" ]
            , select [ onInput (graphVariableFromString >> UpdateGraphVariable) ]
                [ option [ value "rifle", selected (model.graphVariable == RifleWeight) ] [ text "Rifle Weight" ]
                , option [ value "velocity", selected (model.graphVariable == Velocity) ] [ text "Velocity" ]
                , option [ value "projectile", selected (model.graphVariable == ProjectileWeight) ] [ text "Projectile Weight" ]
                ]
            ]
        ]


viewResults : TopGunModel -> Html Msg
viewResults model =
    let
        ke =
            calculateKineticEnergy model.projectileWeight model.muzzleVelocity

        moa =
            calculateMoa ke model.rifleWeight

        sigma1 =
            moa * 0.85

        sigma2 =
            moa * 1.15

        ( valueFor1Moa, unit ) =
            calculateValueFor1Moa model
    in
    div [ class "results" ]
        [ h2 [] [ text "Results" ]
        , div [ class "result-row" ]
            [ span [ class "result-label" ] [ text "Kinetic Energy:" ]
            , span [ class "result-value" ] [ text (Round.round 1 ke ++ " ft-lbs") ]
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


viewChart : TopGunModel -> Html Msg
viewChart model =
    let
        ( points, xLabel, yLabel ) =
            generatePlotData model
    in
    C.chart
        [ CA.height 400
        , CA.width 700
        ]
        [ C.xLabels [ CA.withGrid ]
        , C.yLabels [ CA.withGrid ]
        , C.xAxis []
        , C.yAxis []
        , C.xTicks []
        , C.yTicks []
        , C.labelAt CA.middle .max [ CA.moveDown 30 ] [ Html.text xLabel ]
        , C.labelAt .min CA.middle [ CA.rotate 90, CA.moveLeft 30 ] [ Html.text yLabel ]
        , C.series .x
            [ C.interpolated .y [ CA.monotone, CA.color "#4a9eff" ] []
            ]
            points
        ]


generatePlotData : TopGunModel -> ( List { x : Float, y : Float }, String, String )
generatePlotData model =
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
                                in
                                { x = weight, y = moa }
                            )
            in
            ( points, "Rifle Weight (lbs)", "Expected Accuracy (MOA)" )

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
                                in
                                { x = vel, y = moa }
                            )
            in
            ( points, "Muzzle Velocity (fps)", "Expected Accuracy (MOA)" )

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


calculateValueFor1Moa : TopGunModel -> ( Float, String )
calculateValueFor1Moa model =
    let
        ke =
            calculateKineticEnergy model.projectileWeight model.muzzleVelocity
    in
    case model.graphVariable of
        RifleWeight ->
            ( ke / 200, "lbs" )

        Velocity ->
            let
                targetKe =
                    200 * model.rifleWeight
            in
            ( sqrt (targetKe * 450436 / model.projectileWeight), "fps" )

        ProjectileWeight ->
            let
                targetKe =
                    200 * model.rifleWeight
            in
            ( targetKe * 450436 / (model.muzzleVelocity ^ 2), "gr" )



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
