module Serialize exposing
    ( decodeState
    , defaultBallistics
    , defaultLoad
    , defaultMPBR
    , encodeState
    , stateFromBase64
    , stateToBase64
    )

import Base64
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Types exposing (..)



-- ENCODE


encodeState : Model -> E.Value
encodeState model =
    E.object
        [ ( "tool", encodeTool model.currentTool )
        , ( "units", encodeUnits model.units )
        , ( "topGun", encodeTopGun model.topGun )
        , ( "ballistics", encodeBallistics model.ballistics )
        , ( "mpbr", encodeMPBR model.mpbr )
        ]


encodeTool : Tool -> E.Value
encodeTool tool =
    E.string
        (case tool of
            TopGun ->
                "topgun"

            Ballistics ->
                "ballistics"

            MPBR ->
                "mpbr"
        )


encodeUnits : UnitSettings -> E.Value
encodeUnits units =
    E.object
        [ ( "system", encodeUnitSystem units.system )
        , ( "length", encodeLengthUnit units.length )
        , ( "angle", encodeAngleUnit units.angle )
        , ( "temp", encodeTempUnit units.temp )
        , ( "pressure", encodePressureUnit units.pressure )
        , ( "weight", encodeWeightUnit units.weight )
        , ( "range", encodeRangeUnit units.range )
        , ( "energy", encodeEnergyUnit units.energy )
        , ( "velocity", encodeVelocityUnit units.velocity )
        ]


encodeUnitSystem : UnitSystem -> E.Value
encodeUnitSystem sys =
    E.string
        (case sys of
            Imperial ->
                "imperial"

            Metric ->
                "metric"
        )


encodeLengthUnit : LengthUnit -> E.Value
encodeLengthUnit unit =
    E.string
        (case unit of
            Inches ->
                "in"

            Centimeters ->
                "cm"
        )


encodeAngleUnit : AngleUnit -> E.Value
encodeAngleUnit unit =
    E.string
        (case unit of
            MOA ->
                "moa"

            MIL ->
                "mil"
        )


encodeTempUnit : TempUnit -> E.Value
encodeTempUnit unit =
    E.string
        (case unit of
            Fahrenheit ->
                "f"

            Celsius ->
                "c"
        )


encodePressureUnit : PressureUnit -> E.Value
encodePressureUnit unit =
    E.string
        (case unit of
            InHg ->
                "inhg"

            Mbar ->
                "mbar"
        )


encodeWeightUnit : WeightUnit -> E.Value
encodeWeightUnit unit =
    E.string
        (case unit of
            Pounds ->
                "lbs"

            Kilograms ->
                "kg"
        )


encodeRangeUnit : RangeUnit -> E.Value
encodeRangeUnit unit =
    E.string
        (case unit of
            Yards ->
                "yd"

            Meters ->
                "m"
        )


encodeEnergyUnit : EnergyUnit -> E.Value
encodeEnergyUnit unit =
    E.string
        (case unit of
            FootPounds ->
                "ftlb"

            Joules ->
                "j"
        )


encodeVelocityUnit : VelocityUnit -> E.Value
encodeVelocityUnit unit =
    E.string
        (case unit of
            FPS ->
                "fps"

            MPS ->
                "mps"
        )


encodeTopGun : TopGunModel -> E.Value
encodeTopGun model =
    E.object
        [ ( "projectileWeight", E.float model.projectileWeight )
        , ( "muzzleVelocity", E.float model.muzzleVelocity )
        , ( "rifleWeight", E.float model.rifleWeight )
        , ( "graphVariable", encodeGraphVariable model.graphVariable )
        ]


encodeGraphVariable : GraphVariable -> E.Value
encodeGraphVariable var =
    E.string
        (case var of
            RifleWeight ->
                "rifle"

            Velocity ->
                "velocity"

            ProjectileWeight ->
                "projectile"
        )


encodeBallistics : BallisticsModel -> E.Value
encodeBallistics model =
    E.object
        [ ( "scopeHeight", E.float model.scopeHeight )
        , ( "zeroDistance", E.float model.zeroDistance )
        , ( "twistRate", E.float model.twistRate )
        , ( "temperature", E.float model.temperature )
        , ( "pressure", E.float model.pressure )
        , ( "windSpeed", E.float model.windSpeed )
        , ( "windDirection", E.float model.windDirection )
        , ( "tableStepSize", E.float model.tableStepSize )
        , ( "tableMaxRange", E.float model.tableMaxRange )
        , ( "graphMaxRange", E.float model.graphMaxRange )
        , ( "showDropDistance", E.bool model.showDropDistance )
        , ( "showDropAngle", E.bool model.showDropAngle )
        , ( "showWindageDistance", E.bool model.showWindageDistance )
        , ( "showWindageAngle", E.bool model.showWindageAngle )
        , ( "showVelocity", E.bool model.showVelocity )
        , ( "showEnergy", E.bool model.showEnergy )
        , ( "showTof", E.bool model.showTof )
        , ( "loads", E.list encodeLoad model.loads )
        , ( "selectedLoad", E.int model.selectedLoad )
        , ( "primaryLoadIndex", E.int model.primaryLoadIndex )
        ]


encodeLoad : Load -> E.Value
encodeLoad load =
    E.object
        [ ( "name", E.string load.name )
        , ( "weight", E.float load.weight )
        , ( "bc", E.float load.bc )
        , ( "bcModel", encodeBCModel load.bcModel )
        , ( "muzzleVelocity", E.float load.muzzleVelocity )
        ]


encodeBCModel : BCModel -> E.Value
encodeBCModel model =
    E.string
        (case model of
            G1 ->
                "g1"

            G7 ->
                "g7"
        )


encodeMPBR : MPBRModel -> E.Value
encodeMPBR model =
    E.object
        [ ( "bc", E.float model.bc )
        , ( "bcModel", encodeBCModel model.bcModel )
        , ( "muzzleVelocity", E.float model.muzzleVelocity )
        , ( "scopeHeight", E.float model.scopeHeight )
        , ( "targetDiameter", E.float model.targetDiameter )
        , ( "currentZero", E.float model.currentZero )
        ]



-- DECODE


type alias DecodedState =
    { tool : Tool
    , units : UnitSettings
    , topGun : TopGunModel
    , ballistics : BallisticsModel
    , mpbr : MPBRModel
    }


decodeState : Decoder DecodedState
decodeState =
    D.map5 DecodedState
        (D.oneOf [ D.field "tool" decodeTool, D.succeed TopGun ])
        (D.oneOf [ D.field "units" decodeUnits, D.succeed defaultUnits ])
        (D.oneOf [ D.field "topGun" decodeTopGun, D.succeed defaultTopGun ])
        (D.oneOf [ D.field "ballistics" decodeBallistics, D.succeed defaultBallistics ])
        (D.oneOf [ D.field "mpbr" decodeMPBR, D.succeed defaultMPBR ])


decodeTool : Decoder Tool
decodeTool =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "topgun" ->
                        D.succeed TopGun

                    "ballistics" ->
                        D.succeed Ballistics

                    "mpbr" ->
                        D.succeed MPBR

                    _ ->
                        D.succeed TopGun
            )


decodeUnits : Decoder UnitSettings
decodeUnits =
    D.succeed UnitSettings
        |> withDefault "system" decodeUnitSystem Imperial
        |> withDefault "length" decodeLengthUnit Inches
        |> withDefault "angle" decodeAngleUnit MOA
        |> withDefault "temp" decodeTempUnit Fahrenheit
        |> withDefault "pressure" decodePressureUnit InHg
        |> withDefault "weight" decodeWeightUnit Pounds
        |> withDefault "range" decodeRangeUnit Yards
        |> withDefault "energy" decodeEnergyUnit FootPounds
        |> withDefault "velocity" decodeVelocityUnit FPS


decodeUnitSystem : Decoder UnitSystem
decodeUnitSystem =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "metric" ->
                        D.succeed Metric

                    _ ->
                        D.succeed Imperial
            )


decodeLengthUnit : Decoder LengthUnit
decodeLengthUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "cm" ->
                        D.succeed Centimeters

                    _ ->
                        D.succeed Inches
            )


decodeAngleUnit : Decoder AngleUnit
decodeAngleUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "mil" ->
                        D.succeed MIL

                    _ ->
                        D.succeed MOA
            )


decodeTempUnit : Decoder TempUnit
decodeTempUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "c" ->
                        D.succeed Celsius

                    _ ->
                        D.succeed Fahrenheit
            )


decodePressureUnit : Decoder PressureUnit
decodePressureUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "mbar" ->
                        D.succeed Mbar

                    _ ->
                        D.succeed InHg
            )


decodeWeightUnit : Decoder WeightUnit
decodeWeightUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "kg" ->
                        D.succeed Kilograms

                    _ ->
                        D.succeed Pounds
            )


decodeRangeUnit : Decoder RangeUnit
decodeRangeUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "m" ->
                        D.succeed Meters

                    _ ->
                        D.succeed Yards
            )


decodeEnergyUnit : Decoder EnergyUnit
decodeEnergyUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "j" ->
                        D.succeed Joules

                    _ ->
                        D.succeed FootPounds
            )


decodeVelocityUnit : Decoder VelocityUnit
decodeVelocityUnit =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "mps" ->
                        D.succeed MPS

                    _ ->
                        D.succeed FPS
            )


decodeTopGun : Decoder TopGunModel
decodeTopGun =
    D.succeed TopGunModel
        |> withDefault "projectileWeight" D.float 168
        |> withDefault "muzzleVelocity" D.float 2650
        |> withDefault "rifleWeight" D.float 12
        |> withDefault "graphVariable" decodeGraphVariable RifleWeight


decodeGraphVariable : Decoder GraphVariable
decodeGraphVariable =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "velocity" ->
                        D.succeed Velocity

                    "projectile" ->
                        D.succeed ProjectileWeight

                    _ ->
                        D.succeed RifleWeight
            )


decodeBallistics : Decoder BallisticsModel
decodeBallistics =
    D.succeed BallisticsModel
        |> withDefault "scopeHeight" D.float 1.9
        |> withDefault "zeroDistance" D.float 100
        |> withDefault "twistRate" D.float 10
        |> withDefault "temperature" D.float 60
        |> withDefault "pressure" D.float 29.92
        |> withDefault "windSpeed" D.float 10
        |> withDefault "windDirection" D.float 90
        |> withDefault "tableStepSize" D.float 100
        |> withDefault "tableMaxRange" D.float 1000
        |> withDefault "graphMaxRange" D.float 150
        |> withDefault "showDropDistance" D.bool True
        |> withDefault "showDropAngle" D.bool True
        |> withDefault "showWindageDistance" D.bool True
        |> withDefault "showWindageAngle" D.bool True
        |> withDefault "showVelocity" D.bool True
        |> withDefault "showEnergy" D.bool True
        |> withDefault "showTof" D.bool True
        |> withDefault "loads" (D.list decodeLoad) defaultLoads
        |> withDefault "selectedLoad" D.int 0
        |> withDefault "primaryLoadIndex" D.int 0
        |> withDefault "editingLoad" (D.succeed NotEditing) NotEditing
        |> withDefault "editForm" decodeLoad defaultLoad


decodeLoad : Decoder Load
decodeLoad =
    D.map5 Load
        (D.oneOf [ D.field "name" D.string, D.succeed "Unknown" ])
        (D.oneOf [ D.field "weight" D.float, D.succeed 150 ])
        (D.oneOf [ D.field "bc" D.float, D.succeed 0.4 ])
        (D.oneOf [ D.field "bcModel" decodeBCModel, D.succeed G1 ])
        (D.oneOf [ D.field "muzzleVelocity" D.float, D.succeed 2800 ])


decodeBCModel : Decoder BCModel
decodeBCModel =
    D.string
        |> D.andThen
            (\s ->
                case String.toLower s of
                    "g7" ->
                        D.succeed G7

                    _ ->
                        D.succeed G1
            )


decodeMPBR : Decoder MPBRModel
decodeMPBR =
    D.map6 MPBRModel
        (D.oneOf [ D.field "bc" D.float, D.succeed 0.4 ])
        (D.oneOf [ D.field "bcModel" decodeBCModel, D.succeed G1 ])
        (D.oneOf [ D.field "muzzleVelocity" D.float, D.succeed 2800 ])
        (D.oneOf [ D.field "scopeHeight" D.float, D.succeed 1.9 ])
        (D.oneOf [ D.field "targetDiameter" D.float, D.succeed 6 ])
        (D.oneOf [ D.field "currentZero" D.float, D.succeed 100 ])



-- HELPERS


withDefault : String -> Decoder a -> a -> Decoder (a -> b) -> Decoder b
withDefault field decoder default =
    D.map2 (|>)
        (D.oneOf [ D.field field decoder, D.succeed default ])



-- BASE64


stateToBase64 : Model -> String
stateToBase64 model =
    encodeState model
        |> E.encode 0
        |> Base64.encode


stateFromBase64 : String -> Maybe DecodedState
stateFromBase64 str =
    case Base64.decode str of
        Ok json ->
            case D.decodeString decodeState json of
                Ok state ->
                    Just state

                Err _ ->
                    Nothing

        Err _ ->
            Nothing



-- DEFAULTS


defaultUnits : UnitSettings
defaultUnits =
    { system = Imperial
    , length = Inches
    , angle = MOA
    , temp = Fahrenheit
    , pressure = InHg
    , weight = Pounds
    , range = Yards
    , energy = FootPounds
    , velocity = FPS
    }


defaultTopGun : TopGunModel
defaultTopGun =
    { projectileWeight = 168
    , muzzleVelocity = 2650
    , rifleWeight = 12
    , graphVariable = RifleWeight
    }


defaultBallistics : BallisticsModel
defaultBallistics =
    { scopeHeight = 1.9
    , zeroDistance = 100
    , twistRate = 10
    , temperature = 60
    , pressure = 29.92
    , windSpeed = 10
    , windDirection = 90
    , tableStepSize = 100
    , tableMaxRange = 1000
    , graphMaxRange = 150
    , showDropDistance = True
    , showDropAngle = True
    , showWindageDistance = True
    , showWindageAngle = True
    , showVelocity = True
    , showEnergy = True
    , showTof = True
    , loads = defaultLoads
    , selectedLoad = 0
    , primaryLoadIndex = 0
    , editingLoad = NotEditing
    , editForm = defaultLoad
    }


defaultLoads : List Load
defaultLoads =
    [ { name = "NAS3 175Gr LRX", weight = 175, bc = 0.254, bcModel = G7, muzzleVelocity = 2725 }
    , { name = "NAS3 150 TTSX", weight = 150, bc = 0.44, bcModel = G1, muzzleVelocity = 2950 }
    ]


defaultLoad : Load
defaultLoad =
    { name = "New Load"
    , weight = 150
    , bc = 0.4
    , bcModel = G1
    , muzzleVelocity = 2800
    }


defaultMPBR : MPBRModel
defaultMPBR =
    { bc = 0.4
    , bcModel = G1
    , muzzleVelocity = 2800
    , scopeHeight = 1.9
    , targetDiameter = 6
    , currentZero = 100
    }
