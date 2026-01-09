module Types exposing
    ( BCModel(..)
    , BallisticsModel
    , EditingLoad(..)
    , GraphVariable(..)
    , Load
    , Model
    , Msg(..)
    , Tool(..)
    , TopGunModel
    , TrajectoryPoint
    )


type Tool
    = TopGun
    | Ballistics


type GraphVariable
    = RifleWeight
    | Velocity
    | ProjectileWeight


type alias TopGunModel =
    { projectileWeight : Float
    , muzzleVelocity : Float
    , rifleWeight : Float
    , graphVariable : GraphVariable
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
    , twistRate : Float
    }


type BCModel
    = G1
    | G7


type alias Model =
    { currentTool : Tool
    , menuOpen : Bool
    , topGun : TopGunModel
    , ballistics : BallisticsModel
    }


type alias TrajectoryPoint =
    { range : Float
    , drop : Float
    , wind : Float
    , spinDrift : Float
    , velocity : Float
    , tof : Float
    }


type Msg
    = ToggleMenu
    | SelectTool Tool
    | UpdateProjectileWeight String
    | UpdateMuzzleVelocity String
    | UpdateRifleWeight String
    | UpdateGraphVariable GraphVariable
    | UpdateScopeHeight String
    | UpdateZeroDistance String
    | UpdateTemperature String
    | UpdatePressure String
    | UpdateWindSpeed String
    | UpdateWindDirection String
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
    | UpdateLoadTwist String
