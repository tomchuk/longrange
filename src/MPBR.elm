module MPBR exposing (viewConfig, viewOutput)

import Chart as C
import Chart.Attributes as CA
import Components exposing (viewSlider, viewSliderWithPrecision)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Round
import Types exposing (..)



-- Unit conversions (matching Ballistics.elm)


inchesToCm : Float -> Float
inchesToCm inches =
    inches * 2.54


yardsToMeters : Float -> Float
yardsToMeters yards =
    yards * 0.9144


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


convertVelocity : VelocityUnit -> Float -> Float
convertVelocity unit value =
    case unit of
        FPS ->
            value

        MPS ->
            fpsToMps value



-- MPBR Calculation


gravity : Float
gravity =
    32.174


type alias MPBRResult =
    { optimalZero : Float
    , nearLimit : Float
    , farLimit : Float
    , maxOrdinate : Float
    , zeroAdjustmentMoa : Float
    }


{-| Calculate velocity at a given range using BC-based decay.
Uses a simplified drag model where velocity loss per yard depends on BC.
G7 BC is converted to equivalent G1 for consistent calculation.
-}
velocityAtRange : Float -> BCModel -> Float -> Float -> Float
velocityAtRange bc bcModel muzzleVelocity rangeYd =
    let
        -- Convert G7 to approximate G1 equivalent (G7 is ~2x G1 for typical boat-tail bullets)
        effectiveBC =
            case bcModel of
                G1 ->
                    bc

                G7 ->
                    bc * 2.0

        -- Retardation coefficient: lower BC = more drag = faster velocity loss
        -- This is a simplified model; real ballistics use standard drag functions
        dragFactor =
            0.0001 / effectiveBC

        -- Velocity decays exponentially with range
        vel =
            muzzleVelocity * e ^ (-dragFactor * rangeYd)
    in
    vel


{-| Calculate time of flight to a given range, accounting for velocity decay
-}
timeOfFlight : Float -> BCModel -> Float -> Float -> Float
timeOfFlight bc bcModel muzzleVelocity rangeYd =
    let
        -- Use average velocity for TOF approximation
        velAtRange =
            velocityAtRange bc bcModel muzzleVelocity rangeYd

        avgVelocity =
            (muzzleVelocity + velAtRange) / 2

        rangeFt =
            rangeYd * 3
    in
    rangeFt / avgVelocity


calculateDropAtRange : Float -> Float -> Float -> BCModel -> Float -> Float -> Float
calculateDropAtRange scopeHeightFt boreAngle bc bcModel muzzleVelocity rangeYd =
    let
        rangeFt =
            rangeYd * 3

        tof =
            timeOfFlight bc bcModel muzzleVelocity rangeYd

        -- Gravity drop depends on time of flight squared
        gravityDropFt =
            -0.5 * gravity * tof * tof

        -- Height relative to line of sight
        heightRelativeToLOS =
            -scopeHeightFt + boreAngle * rangeFt + gravityDropFt
    in
    heightRelativeToLOS * 12


calculateBoreAngle : Float -> Float -> Float -> BCModel -> Float -> Float
calculateBoreAngle scopeHeightFt zeroRangeFt bc bcModel muzzleVelocity =
    let
        tofAtZero =
            timeOfFlight bc bcModel muzzleVelocity (zeroRangeFt / 3)

        gravityDropAtZeroFt =
            0.5 * gravity * tofAtZero * tofAtZero
    in
    (scopeHeightFt + gravityDropAtZeroFt) / zeroRangeFt


findMaxOrdinate : Float -> Float -> Float -> BCModel -> Float -> Float -> Float
findMaxOrdinate scopeHeightIn zeroDistYd bc bcModel muzzleVelocity maxSearchRange =
    let
        scopeHeightFt =
            scopeHeightIn / 12

        zeroRangeFt =
            zeroDistYd * 3

        boreAngle =
            calculateBoreAngle scopeHeightFt zeroRangeFt bc bcModel muzzleVelocity

        ranges =
            List.range 0 (round (maxSearchRange / 5))
                |> List.map (\i -> toFloat i * 5)
    in
    ranges
        |> List.map (\r -> calculateDropAtRange scopeHeightFt boreAngle bc bcModel muzzleVelocity r)
        |> List.maximum
        |> Maybe.withDefault 0


findCrossings : Float -> Float -> Float -> BCModel -> Float -> Float -> Float -> { near : Float, far : Float }
findCrossings scopeHeightIn zeroDistYd bc bcModel muzzleVelocity targetRadius maxRange =
    let
        scopeHeightFt =
            scopeHeightIn / 12

        zeroRangeFt =
            zeroDistYd * 3

        boreAngle =
            calculateBoreAngle scopeHeightFt zeroRangeFt bc bcModel muzzleVelocity

        step =
            1

        ranges =
            List.range 0 (round (maxRange / step))
                |> List.map (\i -> toFloat i * step)

        drops =
            ranges
                |> List.map (\r -> ( r, calculateDropAtRange scopeHeightFt boreAngle bc bcModel muzzleVelocity r ))

        -- Near limit: first range where drop >= -targetRadius (enters from below)
        nearLimit =
            drops
                |> List.filter (\( _, d ) -> d >= -targetRadius)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault 0

        -- Far limit: first range where drop <= -targetRadius after being positive
        farLimit =
            drops
                |> List.filter (\( r, _ ) -> r > zeroDistYd)
                |> List.filter (\( _, d ) -> d < -targetRadius)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault maxRange
    in
    { near = nearLimit, far = farLimit }


calculateMPBR : MPBRModel -> MPBRResult
calculateMPBR model =
    let
        targetRadius =
            model.targetDiameter / 2

        maxSearchRange =
            1500

        scopeHeightFt =
            model.scopeHeight / 12

        -- Search for optimal zero by trying different values
        zeroOptions =
            List.range 10 80
                |> List.map (\i -> toFloat i * 5)

        evaluateZero zeroYd =
            let
                maxOrd =
                    findMaxOrdinate model.scopeHeight zeroYd model.bc model.bcModel model.muzzleVelocity maxSearchRange

                crossings =
                    findCrossings model.scopeHeight zeroYd model.bc model.bcModel model.muzzleVelocity targetRadius maxSearchRange

                -- Check if max ordinate exceeds target radius
                isValid =
                    maxOrd <= targetRadius
            in
            { zero = zeroYd
            , maxOrdinate = maxOrd
            , nearLimit = crossings.near
            , farLimit = crossings.far
            , range = crossings.far - crossings.near
            , isValid = isValid
            }

        results =
            zeroOptions
                |> List.map evaluateZero

        -- Find the zero with the largest valid range, or where max ordinate is closest to target radius
        optimalResult =
            results
                |> List.filter .isValid
                |> List.sortBy (\r -> -r.farLimit)
                |> List.head
                |> Maybe.withDefault
                    (results
                        |> List.sortBy (\r -> abs (r.maxOrdinate - targetRadius))
                        |> List.head
                        |> Maybe.withDefault
                            { zero = 100
                            , maxOrdinate = 0
                            , nearLimit = 0
                            , farLimit = 0
                            , range = 0
                            , isValid = False
                            }
                    )

        -- Calculate adjustment from current zero to optimal zero
        currentBoreAngle =
            calculateBoreAngle scopeHeightFt (model.currentZero * 3) model.bc model.bcModel model.muzzleVelocity

        optimalBoreAngle =
            calculateBoreAngle scopeHeightFt (optimalResult.zero * 3) model.bc model.bcModel model.muzzleVelocity

        -- Bore angle difference in radians, convert to MOA
        -- 1 radian = 3437.75 MOA
        angleAdjustmentMoa =
            (optimalBoreAngle - currentBoreAngle) * 3437.75
    in
    { optimalZero = optimalResult.zero
    , nearLimit = optimalResult.nearLimit
    , farLimit = optimalResult.farLimit
    , maxOrdinate = optimalResult.maxOrdinate
    , zeroAdjustmentMoa = angleAdjustmentMoa
    }


generateTrajectory : MPBRModel -> Float -> Float -> Float -> List { range : Float, drop : Float }
generateTrajectory model zeroDistYd minRange maxRange =
    let
        scopeHeightFt =
            model.scopeHeight / 12

        zeroRangeFt =
            zeroDistYd * 3

        boreAngle =
            calculateBoreAngle scopeHeightFt zeroRangeFt model.bc model.bcModel model.muzzleVelocity

        numPoints =
            100

        step =
            (maxRange - minRange) / toFloat numPoints
    in
    List.range 0 numPoints
        |> List.map
            (\i ->
                let
                    range =
                        minRange + toFloat i * step

                    drop =
                        calculateDropAtRange scopeHeightFt boreAngle model.bc model.bcModel model.muzzleVelocity range
                in
                { range = range, drop = drop }
            )



-- VIEW


viewConfig : UnitSettings -> MPBRModel -> Html Msg
viewConfig units model =
    let
        scopeHeightLabel =
            "Scope Height (" ++ lengthUnitLabel units.length ++ ")"

        scopeHeightDisplay =
            convertLength units.length model.scopeHeight

        ( scopeMin, scopeMax, scopeStep ) =
            case units.length of
                Inches ->
                    ( 1, 3, 0.1 )

                Centimeters ->
                    ( 2.5, 7.6, 0.25 )

        velocityLabel =
            "Muzzle Velocity (" ++ velocityUnitLabel units.velocity ++ ")"

        velocityDisplay =
            convertVelocity units.velocity model.muzzleVelocity

        ( velMin, velMax, velStep ) =
            case units.velocity of
                FPS ->
                    ( 1500, 4000, 25 )

                MPS ->
                    ( 457, 1219, 10 )

        targetLabel =
            "Target Diameter (" ++ lengthUnitLabel units.length ++ ")"

        targetDisplay =
            convertLength units.length model.targetDiameter

        ( targetMin, targetMax, targetStep ) =
            case units.length of
                Inches ->
                    ( 2, 12, 0.5 )

                Centimeters ->
                    ( 5, 30, 1 )

        currentZeroLabel =
            "Current Zero (" ++ rangeUnitLabel units.range ++ ")"

        currentZeroDisplay =
            convertRange units.range model.currentZero

        ( zeroMin, zeroMax, zeroStep ) =
            case units.range of
                Yards ->
                    ( 50, 300, 50 )

                Meters ->
                    ( 50, 275, 50 )
    in
    div [ class "config-section" ]
        [ h3 [] [ text "Projectile" ]
        , viewSliderWithPrecision "Ballistic Coefficient" model.bc 0.1 0.8 0.001 3 UpdateMPBRBC
        , div [ class "input-group" ]
            [ label [] [ text "BC Model" ]
            , select [ onInput (bcModelFromString >> UpdateMPBRBCModel) ]
                [ option [ value "g1", selected (model.bcModel == G1) ] [ text "G1" ]
                , option [ value "g7", selected (model.bcModel == G7) ] [ text "G7" ]
                ]
            ]
        , viewSlider velocityLabel velocityDisplay velMin velMax velStep UpdateMPBRMuzzleVelocity
        , h3 [] [ text "Setup" ]
        , viewSlider scopeHeightLabel scopeHeightDisplay scopeMin scopeMax scopeStep UpdateMPBRScopeHeight
        , viewSlider targetLabel targetDisplay targetMin targetMax targetStep UpdateMPBRTargetDiameter
        , viewSlider currentZeroLabel currentZeroDisplay zeroMin zeroMax zeroStep UpdateMPBRCurrentZero
        ]


bcModelFromString : String -> BCModel
bcModelFromString str =
    case String.toLower str of
        "g7" ->
            G7

        _ ->
            G1


viewOutput : UnitSettings -> MPBRModel -> Html Msg
viewOutput units model =
    let
        result =
            calculateMPBR model
    in
    div [ class "tool-output" ]
        [ viewChart units model result
        , viewResults units model result
        ]


viewResults : UnitSettings -> MPBRModel -> MPBRResult -> Html Msg
viewResults units model result =
    let
        rangeUnit =
            rangeUnitLabel units.range

        lengthUnit =
            lengthUnitLabel units.length

        optimalZeroDisplay =
            Round.round 0 (convertRange units.range result.optimalZero)

        nearLimitDisplay =
            Round.round 0 (convertRange units.range result.nearLimit)

        farLimitDisplay =
            Round.round 0 (convertRange units.range result.farLimit)

        maxOrdinateDisplay =
            Round.round 2 (convertLength units.length result.maxOrdinate)

        targetRadiusDisplay =
            Round.round 2 (convertLength units.length (model.targetDiameter / 2))

        mpbrDisplay =
            Round.round 0 (convertRange units.range result.farLimit)

        angleUnit =
            case units.angle of
                MOA ->
                    "MOA"

                MIL ->
                    "MIL"

        adjustmentValue =
            case units.angle of
                MOA ->
                    result.zeroAdjustmentMoa

                MIL ->
                    result.zeroAdjustmentMoa * 0.2909

        adjustmentDisplay =
            (if adjustmentValue >= 0 then
                "+"

             else
                ""
            )
                ++ Round.round 2 adjustmentValue

        adjustmentDirection =
            if adjustmentValue >= 0 then
                "UP"

            else
                "DOWN"

        adjustmentAbsolute =
            Round.round 2 (abs adjustmentValue)

        currentZeroDisplay =
            Round.round 0 (convertRange units.range model.currentZero)
    in
    div [ class "mpbr-results" ]
        [ h2 [] [ text "MPBR Results" ]
        , div [ class "results-grid" ]
            [ div [ class "result-item" ]
                [ span [ class "result-label" ] [ text "Optimal Zero" ]
                , span [ class "result-value" ] [ text (optimalZeroDisplay ++ " " ++ rangeUnit) ]
                ]
            , div [ class "result-item" ]
                [ span [ class "result-label" ] [ text "Near Limit" ]
                , span [ class "result-value" ] [ text (nearLimitDisplay ++ " " ++ rangeUnit) ]
                ]
            , div [ class "result-item" ]
                [ span [ class "result-label" ] [ text "Far Limit (MPBR)" ]
                , span [ class "result-value" ] [ text (farLimitDisplay ++ " " ++ rangeUnit) ]
                ]
            , div [ class "result-item" ]
                [ span [ class "result-label" ] [ text "Max Rise" ]
                , span [ class "result-value" ] [ text (maxOrdinateDisplay ++ " " ++ lengthUnit) ]
                ]
            , div [ class "result-item" ]
                [ span [ class "result-label" ] [ text "Target Radius" ]
                , span [ class "result-value" ] [ text ("+/- " ++ targetRadiusDisplay ++ " " ++ lengthUnit) ]
                ]
            , div [ class "result-item" ]
                [ span [ class "result-label" ] [ text ("Adjustment from " ++ currentZeroDisplay ++ " " ++ rangeUnit ++ " zero") ]
                , span [ class "result-value" ] [ text (adjustmentDisplay ++ " " ++ angleUnit) ]
                ]
            ]
        , p [ class "mpbr-explanation" ]
            [ text "Zero at "
            , strong [] [ text (optimalZeroDisplay ++ " " ++ rangeUnit) ]
            , text " to hit within your target from "
            , strong [] [ text (nearLimitDisplay ++ " to " ++ farLimitDisplay ++ " " ++ rangeUnit) ]
            , text " without holdover. Adjust your scope elevation "
            , strong [] [ text (adjustmentAbsolute ++ " " ++ angleUnit ++ " " ++ adjustmentDirection) ]
            , text (" to attain a " ++ optimalZeroDisplay ++ " " ++ rangeUnit ++ " zero.")
            ]
        ]


viewChart : UnitSettings -> MPBRModel -> MPBRResult -> Html Msg
viewChart units model result =
    let
        targetRadius =
            model.targetDiameter / 2

        maxRange =
            result.farLimit * 1.15

        trajectory =
            generateTrajectory model result.optimalZero 0 maxRange

        trajectoryPoints =
            trajectory
                |> List.map
                    (\pt ->
                        { x = convertRange units.range pt.range
                        , y = convertLength units.length pt.drop
                        }
                    )

        upperBoundPoints =
            [ { x = 0, y = convertLength units.length targetRadius }
            , { x = convertRange units.range maxRange, y = convertLength units.length targetRadius }
            ]

        lowerBoundPoints =
            [ { x = 0, y = convertLength units.length -targetRadius }
            , { x = convertRange units.range maxRange, y = convertLength units.length -targetRadius }
            ]

        zeroLinePoints =
            [ { x = 0, y = 0 }
            , { x = convertRange units.range maxRange, y = 0 }
            ]

        maxRangeDisplay =
            convertRange units.range maxRange

        targetRadiusDisplay =
            convertLength units.length targetRadius

        yExtent =
            targetRadiusDisplay * 2.5

        rangeLabel =
            "Range (" ++ rangeUnitLabel units.range ++ ")"

        dropLabel =
            "Drop (" ++ lengthUnitLabel units.length ++ ")"

        nearLimitX =
            convertRange units.range result.nearLimit

        farLimitX =
            convertRange units.range result.farLimit
    in
    div [ class "mpbr-chart" ]
        [ h2 [] [ text "MPBR Trajectory" ]
        , C.chart
            [ CA.height 300
            , CA.width 500
            , CA.margin { top = 10, bottom = 40, left = 50, right = 20 }
            , CA.range [ CA.lowest 0 CA.exactly, CA.highest maxRangeDisplay CA.exactly ]
            , CA.domain [ CA.lowest -yExtent CA.exactly, CA.highest yExtent CA.exactly ]
            ]
            [ C.xLabels [ CA.withGrid, CA.fontSize 9, CA.pinned .min ]
            , C.yLabels [ CA.withGrid, CA.fontSize 9 ]
            , C.xAxis []
            , C.yAxis []
            , C.xTicks [ CA.pinned .min ]
            , C.yTicks []
            , C.labelAt CA.middle .min [ CA.moveDown 30, CA.fontSize 9 ] [ Html.text rangeLabel ]
            , C.labelAt .min CA.middle [ CA.rotate 90, CA.moveLeft 35, CA.fontSize 9 ] [ Html.text dropLabel ]

            -- Target zone bounds
            , C.series .x
                [ C.interpolated .y [ CA.color "#ff6b6b", CA.dashed [ 5, 5 ], CA.width 1.5 ] [] ]
                upperBoundPoints
            , C.series .x
                [ C.interpolated .y [ CA.color "#ff6b6b", CA.dashed [ 5, 5 ], CA.width 1.5 ] [] ]
                lowerBoundPoints

            -- Line of sight
            , C.series .x
                [ C.interpolated .y [ CA.color "#888888", CA.dashed [ 2, 4 ], CA.width 1 ] [] ]
                zeroLinePoints

            -- Trajectory
            , C.series .x
                [ C.interpolated .y [ CA.monotone, CA.color "#4a9eff", CA.width 2 ] [] ]
                trajectoryPoints
            ]
        , div [ class "chart-legend" ]
            [ div [ class "legend-item" ]
                [ span [ class "legend-color", style "background-color" "#4a9eff" ] []
                , span [] [ text "Trajectory" ]
                ]
            , div [ class "legend-item" ]
                [ span [ class "legend-line", style "border-color" "#ff6b6b" ] []
                , span [] [ text "Target Zone" ]
                ]
            ]
        ]
