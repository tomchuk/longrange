module Types exposing
    ( AngleUnit(..)
    , BCModel(..)
    , BallisticsModel
    , EditingLoad(..)
    , EnergyUnit(..)
    , GraphVariable(..)
    , LengthUnit(..)
    , Load
    , MPBRModel
    , Model
    , Msg(..)
    , PressureUnit(..)
    , RangeUnit(..)
    , TempUnit(..)
    , Tool(..)
    , TopGunModel
    , TrajectoryPoint
    , UnitSettings
    , UnitSystem(..)
    , VelocityUnit(..)
    , WeightUnit(..)
    )

import Browser
import Browser.Navigation as Nav
import Url exposing (Url)


type Tool
    = TopGun
    | Ballistics
    | MPBR


type GraphVariable
    = RifleWeight
    | Velocity
    | ProjectileWeight



-- UNIT TYPES


type UnitSystem
    = Metric
    | Imperial


type LengthUnit
    = Inches
    | Centimeters


type AngleUnit
    = MOA
    | MIL


type TempUnit
    = Fahrenheit
    | Celsius


type PressureUnit
    = InHg
    | Mbar


type WeightUnit
    = Pounds
    | Kilograms


type RangeUnit
    = Yards
    | Meters


type EnergyUnit
    = FootPounds
    | Joules


type VelocityUnit
    = FPS
    | MPS


type alias UnitSettings =
    { system : UnitSystem
    , length : LengthUnit
    , angle : AngleUnit
    , temp : TempUnit
    , pressure : PressureUnit
    , weight : WeightUnit
    , range : RangeUnit
    , energy : EnergyUnit
    , velocity : VelocityUnit
    }



-- MODEL TYPES


type alias TopGunModel =
    { projectileWeight : Float
    , muzzleVelocity : Float
    , rifleWeight : Float
    , graphVariable : GraphVariable
    }


type alias MPBRModel =
    { bc : Float
    , bcModel : BCModel
    , muzzleVelocity : Float
    , scopeHeight : Float
    , targetDiameter : Float
    , currentZero : Float
    }


type EditingLoad
    = NotEditing
    | AddingNew
    | EditingExisting Int


type alias BallisticsModel =
    { scopeHeight : Float
    , zeroDistance : Float
    , twistRate : Float
    , temperature : Float
    , pressure : Float
    , windSpeed : Float
    , windDirection : Float
    , tableStepSize : Float
    , tableMaxRange : Float
    , graphMaxRange : Float
    , showDropDistance : Bool
    , showDropAngle : Bool
    , showWindageDistance : Bool
    , showWindageAngle : Bool
    , showVelocity : Bool
    , showEnergy : Bool
    , showTof : Bool
    , loads : List Load
    , selectedLoad : Int
    , primaryLoadIndex : Int
    , editingLoad : EditingLoad
    , editForm : Load
    }


type alias Load =
    { name : String
    , weight : Float
    , bc : Float
    , bcModel : BCModel
    , muzzleVelocity : Float
    }


type BCModel
    = G1
    | G7


type alias Model =
    { currentTool : Tool
    , menuOpen : Bool
    , unitsExpanded : Bool
    , units : UnitSettings
    , topGun : TopGunModel
    , ballistics : BallisticsModel
    , mpbr : MPBRModel
    , navKey : Nav.Key
    , shareUrl : Maybe String
    , shareCopied : Bool
    , origin : String
    }


type alias TrajectoryPoint =
    { range : Float
    , drop : Float
    , windage : Float
    , velocity : Float
    , energy : Float
    , tof : Float
    }


type Msg
    = NoOp
    | UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | ToggleMenu
    | ToggleUnitsExpanded
    | SelectTool Tool
      -- Unit messages
    | SetUnitSystem UnitSystem
    | SetLengthUnit LengthUnit
    | SetAngleUnit AngleUnit
    | SetTempUnit TempUnit
    | SetPressureUnit PressureUnit
    | SetWeightUnit WeightUnit
    | SetRangeUnit RangeUnit
    | SetEnergyUnit EnergyUnit
    | SetVelocityUnit VelocityUnit
      -- TOP Gun messages
    | UpdateProjectileWeight String
    | UpdateMuzzleVelocity String
    | UpdateRifleWeight String
    | UpdateGraphVariable GraphVariable
      -- Ballistics messages
    | UpdateScopeHeight String
    | UpdateZeroDistance String
    | UpdateTemperature String
    | UpdatePressure String
    | UpdateWindSpeed String
    | UpdateWindDirection String
    | UpdateTwistRate String
    | SelectLoad Int
    | SetPrimaryLoad Int
    | StartEditingLoad Int
    | StartAddingLoad
    | CancelEditingLoad
    | SaveLoad
    | RemoveLoad Int
    | UpdateLoadName String
    | UpdateLoadWeight String
    | UpdateLoadBC String
    | UpdateLoadBCModel BCModel
    | UpdateLoadMV String
    | UpdateTableStepSize String
    | UpdateTableMaxRange String
    | UpdateGraphMaxRange String
    | ToggleShowDropDistance
    | ToggleShowDropAngle
    | ToggleShowWindageDistance
    | ToggleShowWindageAngle
    | ToggleShowVelocity
    | ToggleShowEnergy
    | ToggleShowTof
      -- MPBR messages
    | UpdateMPBRBC String
    | UpdateMPBRBCModel BCModel
    | UpdateMPBRMuzzleVelocity String
    | UpdateMPBRScopeHeight String
    | UpdateMPBRTargetDiameter String
    | UpdateMPBRCurrentZero String
      -- Share/Persistence messages
    | ShareLink
    | DismissShareUrl
    | CopiedToClipboard
    | LoadedState String
