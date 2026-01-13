module Ballistics.Trajectory exposing
    ( calculateEquivalentZero
    , calculateTrajectory
    , calculateTrajectoryForChart
    , windDirectionLabel
    )

import Types exposing (BallisticsModel, Load, TrajectoryPoint)


gravity : Float
gravity =
    32.174


calculateTrajectory : BallisticsModel -> Load -> Load -> List TrajectoryPoint
calculateTrajectory model primaryLoad load =
    let
        scopeHeightFt =
            model.scopeHeight / 12

        zeroRangeFt =
            model.zeroDistance * 3

        windFps =
            model.windSpeed * 5280 / 3600

        windAngleRad =
            model.windDirection * pi / 180

        crosswindFps =
            windFps * sin windAngleRad

        -- Use PRIMARY load for bore angle calculation (scope is zeroed for primary)
        gravityDropAtZeroFt =
            0.5 * gravity * zeroRangeFt * zeroRangeFt / (primaryLoad.muzzleVelocity * primaryLoad.muzzleVelocity)

        boreAngle =
            (scopeHeightFt + gravityDropAtZeroFt) / zeroRangeFt
        numSteps =
            round (model.tableMaxRange / model.tableStepSize)
    in
    List.range 0 numSteps
        |> List.map (\i -> toFloat i * model.tableStepSize)
        |> List.map (calculatePoint scopeHeightFt boreAngle crosswindFps load model.twistRate)


calculateTrajectoryForChart : BallisticsModel -> Load -> Load -> Float -> Float -> List TrajectoryPoint
calculateTrajectoryForChart model primaryLoad load minRange maxRange =
    let
        scopeHeightFt =
            model.scopeHeight / 12

        zeroRangeFt =
            model.zeroDistance * 3

        windFps =
            model.windSpeed * 5280 / 3600

        windAngleRad =
            model.windDirection * pi / 180

        crosswindFps =
            windFps * sin windAngleRad

        -- Use PRIMARY load for bore angle calculation
        gravityDropAtZeroFt =
            0.5 * gravity * zeroRangeFt * zeroRangeFt / (primaryLoad.muzzleVelocity * primaryLoad.muzzleVelocity)

        boreAngle =
            (scopeHeightFt + gravityDropAtZeroFt) / zeroRangeFt

        numPoints =
            ceiling ((maxRange - minRange) / 5)

        startPoint =
            floor (minRange / 5)
    in
    List.range startPoint (startPoint + numPoints)
        |> List.map (\i -> toFloat i * 5)
        |> List.filter (\range -> range >= minRange && range <= maxRange)
        |> List.map (calculatePoint scopeHeightFt boreAngle crosswindFps load model.twistRate)


calculatePoint : Float -> Float -> Float -> Load -> Float -> Float -> TrajectoryPoint
calculatePoint scopeHeightFt boreAngle crosswindFps load twistRate rangeYd =
    let
        rangeFt =
            rangeYd * 3

        gravityDropFt =
            -0.5 * rangeFt * rangeFt / (load.muzzleVelocity * load.muzzleVelocity) * gravity

        heightRelativeToLOS =
            -scopeHeightFt + boreAngle * rangeFt + gravityDropFt

        drop =
            heightRelativeToLOS * 12

        tof =
            rangeFt / load.muzzleVelocity

        -- Wind deflection in inches
        windDeflection =
            crosswindFps * rangeFt / load.muzzleVelocity * 12

        -- Spin drift calculation (Litz formula approximation)
        sg =
            30 / twistRate

        spinDrift =
            1.25 * (sg + 1.2) * (tof ^ 1.83)

        -- Combined windage (wind + spin drift) in inches
        windage =
            windDeflection + spinDrift

        -- Velocity at range (simple approximation - loses ~5% per 100 yards for typical rifle)
        velocityAtRange =
            load.muzzleVelocity * (0.95 ^ (rangeYd / 100))

        -- Energy in ft-lbs: (grains * fps^2) / 450436
        energy =
            (load.weight * velocityAtRange * velocityAtRange) / 450436
    in
    { range = rangeYd
    , drop = drop
    , windage = windage
    , velocity = velocityAtRange
    , energy = energy
    , tof = tof
    }


calculateEquivalentZero : BallisticsModel -> Load -> Load -> Maybe Float
calculateEquivalentZero model primaryLoad secondaryLoad =
    let
        scopeHeightFt =
            model.scopeHeight / 12

        zeroRangeFt =
            model.zeroDistance * 3

        -- Calculate bore angle based on PRIMARY load
        primaryGravityDropAtZeroFt =
            0.5 * gravity * zeroRangeFt * zeroRangeFt / (primaryLoad.muzzleVelocity * primaryLoad.muzzleVelocity)

        boreAngle =
            (scopeHeightFt + primaryGravityDropAtZeroFt) / zeroRangeFt

        -- Solve quadratic for SECONDARY load: 0.5*g*R²/v² - boreAngle*R + scopeHeight = 0
        a =
            0.5 * gravity / (secondaryLoad.muzzleVelocity * secondaryLoad.muzzleVelocity)

        b =
            -boreAngle

        c =
            scopeHeightFt

        discriminant =
            b * b - 4 * a * c
    in
    if discriminant < 0 then
        Nothing

    else
        let
            sqrtD =
                sqrt discriminant

            -- Far zero (the larger root)
            r2 =
                (-b + sqrtD) / (2 * a) / 3
        in
        if r2 > 0 then
            Just r2

        else
            Nothing


windDirectionLabel : Float -> String
windDirectionLabel degrees =
    let
        normalized =
            degrees
                |> (\d -> d + 22.5)
                |> (\d ->
                        if d >= 360 then
                            d - 360

                        else
                            d
                   )
                |> (\d -> floor (d / 45))
    in
    case normalized of
        0 ->
            "Headwind"

        1 ->
            "R Front"

        2 ->
            "R Cross"

        3 ->
            "R Rear"

        4 ->
            "Tailwind"

        5 ->
            "L Rear"

        6 ->
            "L Cross"

        7 ->
            "L Front"

        _ ->
            "Headwind"
