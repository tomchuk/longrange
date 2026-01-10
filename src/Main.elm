port module Main exposing (main)

import Ballistics
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (attribute, autofocus, checked, class, id, readonly, selected, style, title, type_, value)
import Html.Events exposing (..)
import Json.Decode
import Json.Encode
import Serialize
import Styles
import TopGun
import Types exposing (..)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


-- PORTS


port copyToClipboard : String -> Cmd msg


port saveToLocalStorage : String -> Cmd msg


port loadFromLocalStorage : () -> Cmd msg


port localStorageLoaded : (String -> msg) -> Sub msg


port clipboardCopySuccess : (() -> msg) -> Sub msg


main : Program Json.Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ localStorageLoaded LoadedState
        , clipboardCopySuccess (\_ -> CopiedToClipboard)
        ]



-- INIT


init : Json.Decode.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        -- Decode flags as Maybe String, handling undefined/null gracefully
        savedState =
            flags
                |> Json.Decode.decodeValue Json.Decode.string
                |> Result.toMaybe

        -- Check URL fragment first, then savedState
        fragmentState =
            url.fragment
                |> Maybe.andThen Serialize.stateFromBase64

        localState =
            savedState
                |> Maybe.andThen Serialize.stateFromBase64

        maybeState =
            case fragmentState of
                Just s ->
                    Just s

                Nothing ->
                    localState

        origin =
            (case url.protocol of
                Url.Http ->
                    "http://"

                Url.Https ->
                    "https://"
            )
                ++ url.host
                ++ (case url.port_ of
                        Just p ->
                            ":" ++ String.fromInt p

                        Nothing ->
                            ""
                   )

        baseModel =
            { currentTool = urlToTool url
            , menuOpen = False
            , unitsExpanded = False
            , units = defaultImperialUnits
            , navKey = navKey
            , shareUrl = Nothing
            , shareCopied = False
            , origin = origin
            , topGun =
                { projectileWeight = 168
                , muzzleVelocity = 2650
                , rifleWeight = 12
                , graphVariable = RifleWeight
                }
            , ballistics = Serialize.defaultBallistics
            }

        model =
            case maybeState of
                Just state ->
                    { baseModel
                        | currentTool = state.tool
                        , units = state.units
                        , topGun = state.topGun
                        , ballistics = state.ballistics
                    }

                Nothing ->
                    baseModel
    in
    ( model
    , Cmd.none
    )



defaultImperialUnits : UnitSettings
defaultImperialUnits =
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


defaultMetricUnits : UnitSettings
defaultMetricUnits =
    { system = Metric
    , length = Centimeters
    , angle = MIL
    , temp = Celsius
    , pressure = Mbar
    , weight = Kilograms
    , range = Meters
    , energy = Joules
    , velocity = MPS
    }



-- URL ROUTING


urlToTool : Url -> Tool
urlToTool url =
    case Parser.parse routeParser url of
        Just tool ->
            tool

        Nothing ->
            TopGun


routeParser : Parser (Tool -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map TopGun Parser.top
        , Parser.map TopGun (Parser.s "topgun")
        , Parser.map TopGun (Parser.s "top")
        , Parser.map Ballistics (Parser.s "ballistics")
        ]


toolToPath : Tool -> String
toolToPath tool =
    case tool of
        TopGun ->
            "/topgun"

        Ballistics ->
            "/ballistics"



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( newModel, cmd ) =
            updateHelp msg model

        -- Save state to localStorage on every change (except NoOp and some transient messages)
        saveCmd =
            case msg of
                NoOp ->
                    Cmd.none

                UrlChanged _ ->
                    Cmd.none

                LinkClicked _ ->
                    Cmd.none

                CopiedToClipboard ->
                    Cmd.none

                LoadedState _ ->
                    Cmd.none

                _ ->
                    saveToLocalStorage (Serialize.stateToBase64 newModel)
    in
    ( newModel, Cmd.batch [ cmd, saveCmd ] )


updateHelp : Msg -> Model -> ( Model, Cmd Msg )
updateHelp msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ShareLink ->
            let
                base64State =
                    Serialize.stateToBase64 model

                shareUrl =
                    model.origin ++ toolToPath model.currentTool ++ "#" ++ base64State
            in
            ( { model | shareUrl = Just shareUrl, shareCopied = False }, copyToClipboard shareUrl )

        DismissShareUrl ->
            ( { model | shareUrl = Nothing }, Cmd.none )

        CopiedToClipboard ->
            ( { model | shareCopied = True }, Cmd.none )

        LoadedState stateStr ->
            case Serialize.stateFromBase64 stateStr of
                Just state ->
                    ( { model
                        | currentTool = state.tool
                        , units = state.units
                        , topGun = state.topGun
                        , ballistics = state.ballistics
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        UrlChanged url ->
            ( { model | currentTool = urlToTool url }, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        ToggleUnitsExpanded ->
            ( { model | unitsExpanded = not model.unitsExpanded }, Cmd.none )

        SelectTool tool ->
            ( { model | currentTool = tool }
            , Nav.pushUrl model.navKey (toolToPath tool)
            )

        -- Unit messages
        SetUnitSystem system ->
            let
                newUnits =
                    case system of
                        Imperial ->
                            defaultImperialUnits

                        Metric ->
                            defaultMetricUnits
            in
            ( { model | units = newUnits }, Cmd.none )

        SetLengthUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | length = unit } }, Cmd.none )

        SetAngleUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | angle = unit } }, Cmd.none )

        SetTempUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | temp = unit } }, Cmd.none )

        SetPressureUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | pressure = unit } }, Cmd.none )

        SetWeightUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | weight = unit } }, Cmd.none )

        SetRangeUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | range = unit } }, Cmd.none )

        SetEnergyUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | energy = unit } }, Cmd.none )

        SetVelocityUnit unit ->
            let
                units =
                    model.units
            in
            ( { model | units = { units | velocity = unit } }, Cmd.none )

        -- TOP Gun messages
        UpdateProjectileWeight str ->
            let
                topGun =
                    model.topGun
            in
            ( { model | topGun = { topGun | projectileWeight = String.toFloat str |> Maybe.withDefault topGun.projectileWeight } }, Cmd.none )

        UpdateMuzzleVelocity str ->
            let
                topGun =
                    model.topGun
            in
            ( { model | topGun = { topGun | muzzleVelocity = String.toFloat str |> Maybe.withDefault topGun.muzzleVelocity } }, Cmd.none )

        UpdateRifleWeight str ->
            let
                topGun =
                    model.topGun
            in
            ( { model | topGun = { topGun | rifleWeight = String.toFloat str |> Maybe.withDefault topGun.rifleWeight } }, Cmd.none )

        UpdateGraphVariable variable ->
            let
                topGun =
                    model.topGun
            in
            ( { model | topGun = { topGun | graphVariable = variable } }, Cmd.none )

        -- Ballistics messages
        UpdateScopeHeight str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | scopeHeight = String.toFloat str |> Maybe.withDefault ballistics.scopeHeight } }, Cmd.none )

        UpdateZeroDistance str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | zeroDistance = String.toFloat str |> Maybe.withDefault ballistics.zeroDistance } }, Cmd.none )

        UpdateTemperature str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | temperature = String.toFloat str |> Maybe.withDefault ballistics.temperature } }, Cmd.none )

        UpdatePressure str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | pressure = String.toFloat str |> Maybe.withDefault ballistics.pressure } }, Cmd.none )

        UpdateWindSpeed str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | windSpeed = String.toFloat str |> Maybe.withDefault ballistics.windSpeed } }, Cmd.none )

        UpdateWindDirection str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | windDirection = String.toFloat str |> Maybe.withDefault ballistics.windDirection } }, Cmd.none )

        UpdateTwistRate str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | twistRate = String.toFloat str |> Maybe.withDefault ballistics.twistRate } }, Cmd.none )

        UpdateTableStepSize str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | tableStepSize = String.toFloat str |> Maybe.withDefault ballistics.tableStepSize } }, Cmd.none )

        UpdateTableMaxRange str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | tableMaxRange = String.toFloat str |> Maybe.withDefault ballistics.tableMaxRange } }, Cmd.none )

        UpdateGraphMaxRange str ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | graphMaxRange = String.toFloat str |> Maybe.withDefault ballistics.graphMaxRange } }, Cmd.none )

        ToggleShowDropDistance ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | showDropDistance = not ballistics.showDropDistance } }, Cmd.none )

        ToggleShowDropAngle ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | showDropAngle = not ballistics.showDropAngle } }, Cmd.none )

        ToggleShowWindageDistance ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | showWindageDistance = not ballistics.showWindageDistance } }, Cmd.none )

        ToggleShowWindageAngle ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | showWindageAngle = not ballistics.showWindageAngle } }, Cmd.none )

        ToggleShowVelocity ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | showVelocity = not ballistics.showVelocity } }, Cmd.none )

        ToggleShowEnergy ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | showEnergy = not ballistics.showEnergy } }, Cmd.none )

        ToggleShowTof ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | showTof = not ballistics.showTof } }, Cmd.none )

        SelectLoad index ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | selectedLoad = index } }, Cmd.none )

        SetPrimaryLoad index ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | primaryLoadIndex = index } }, Cmd.none )

        StartEditingLoad index ->
            let
                ballistics =
                    model.ballistics

                load =
                    ballistics.loads
                        |> List.drop index
                        |> List.head
                        |> Maybe.withDefault ballistics.editForm
            in
            ( { model | ballistics = { ballistics | editingLoad = EditingExisting index, editForm = load } }, Cmd.none )

        StartAddingLoad ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | editingLoad = AddingNew, editForm = Serialize.defaultLoad } }, Cmd.none )

        CancelEditingLoad ->
            let
                ballistics =
                    model.ballistics
            in
            ( { model | ballistics = { ballistics | editingLoad = NotEditing } }, Cmd.none )

        SaveLoad ->
            let
                ballistics =
                    model.ballistics

                newBallistics =
                    case ballistics.editingLoad of
                        AddingNew ->
                            { ballistics
                                | loads = ballistics.loads ++ [ ballistics.editForm ]
                                , editingLoad = NotEditing
                            }

                        EditingExisting index ->
                            { ballistics
                                | loads =
                                    List.indexedMap
                                        (\i load ->
                                            if i == index then
                                                ballistics.editForm

                                            else
                                                load
                                        )
                                        ballistics.loads
                                , editingLoad = NotEditing
                            }

                        NotEditing ->
                            ballistics
            in
            ( { model | ballistics = newBallistics }, Cmd.none )

        RemoveLoad index ->
            let
                ballistics =
                    model.ballistics

                newBallistics =
                    { ballistics
                        | loads =
                            List.indexedMap (\i load -> ( i, load )) ballistics.loads
                                |> List.filter (\( i, _ ) -> i /= index)
                                |> List.map Tuple.second
                        , selectedLoad =
                            if ballistics.selectedLoad >= index && ballistics.selectedLoad > 0 then
                                ballistics.selectedLoad - 1

                            else
                                ballistics.selectedLoad
                        , primaryLoadIndex =
                            if ballistics.primaryLoadIndex >= index && ballistics.primaryLoadIndex > 0 then
                                ballistics.primaryLoadIndex - 1

                            else if ballistics.primaryLoadIndex == index then
                                0

                            else
                                ballistics.primaryLoadIndex
                    }
            in
            ( { model | ballistics = newBallistics }, Cmd.none )

        UpdateLoadName str ->
            updateEditForm model (\form -> { form | name = str })

        UpdateLoadWeight str ->
            updateEditForm model (\form -> { form | weight = String.toFloat str |> Maybe.withDefault form.weight })

        UpdateLoadBC str ->
            updateEditForm model (\form -> { form | bc = String.toFloat str |> Maybe.withDefault form.bc })

        UpdateLoadBCModel bcModel ->
            updateEditForm model (\form -> { form | bcModel = bcModel })

        UpdateLoadMV str ->
            updateEditForm model (\form -> { form | muzzleVelocity = String.toFloat str |> Maybe.withDefault form.muzzleVelocity })


updateEditForm : Model -> (Load -> Load) -> ( Model, Cmd Msg )
updateEditForm model updateFn =
    let
        ballistics =
            model.ballistics

        newForm =
            updateFn ballistics.editForm
    in
    ( { model | ballistics = { ballistics | editForm = newForm } }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = toolTitle model.currentTool
    , body =
        [ div [ class "app" ]
            [ viewHeader model
            , div [ class "app-body" ]
                [ if model.menuOpen then
                    viewSidebar model

                  else
                    text ""
                , viewContent model
                ]
            ]
        , Styles.viewStyles
        ]
    }


toolTitle : Tool -> String
toolTitle tool =
    case tool of
        TopGun ->
            "TOP - Theory of Precision Calculator"

        Ballistics ->
            "Ballistics Solver"


viewHeader : Model -> Html Msg
viewHeader model =
    header [ class "header" ]
        [ button [ class "menu-button", onClick ToggleMenu ]
            [ div [ class "hamburger" ]
                [ span [] []
                , span [] []
                , span [] []
                ]
            ]
        , h1 [ class "title" ] [ text (toolTitle model.currentTool) ]
        , div [ class "share-container" ]
            [ button [ class "share-button", onClick ShareLink, title "Copy share link to clipboard" ]
                [ text "Share" ]
            , case model.shareUrl of
                Just url ->
                    div [ class "share-popup" ]
                        [ div [ class "share-popup-header" ]
                            [ span []
                                [ text
                                    (if model.shareCopied then
                                        "Copied to clipboard!"

                                     else
                                        "Share Link"
                                    )
                                ]
                            , button [ class "share-popup-close", onClick DismissShareUrl ] [ text "×" ]
                            ]
                        , input
                            [ type_ "text"
                            , value url
                            , class "share-url-input"
                            , readonly True
                            , id "share-url-input"
                            , autofocus True
                            , attribute "onfocus" "this.select()"
                            ]
                            []
                        ]

                Nothing ->
                    text ""
            ]
        ]


viewSidebar : Model -> Html Msg
viewSidebar model =
    div [ class "sidebar" ]
        [ div [ class "sidebar-section" ]
            [ h2 [] [ text "Tools" ]
            , button
                [ class
                    (if model.currentTool == TopGun then
                        "menu-item active"

                     else
                        "menu-item"
                    )
                , onClick (SelectTool TopGun)
                ]
                [ text "TOP Gun Calculator" ]
            , button
                [ class
                    (if model.currentTool == Ballistics then
                        "menu-item active"

                     else
                        "menu-item"
                    )
                , onClick (SelectTool Ballistics)
                ]
                [ text "Ballistics Solver" ]
            ]
        , viewUnitsSection model
        , div [ class "sidebar-section" ]
            [ case model.currentTool of
                TopGun ->
                    TopGun.viewConfig model.units model.topGun

                Ballistics ->
                    Ballistics.viewConfig model.units model.ballistics
            ]
        ]





viewUnitsSection : Model -> Html Msg
viewUnitsSection model =
    div [ class "units-section" ]
        [ button [ class "units-header", onClick ToggleUnitsExpanded ]
            [ span [] [ text "Units" ]
            , span [ class "units-expand-icon" ]
                [ text
                    (if model.unitsExpanded then
                        "▼"

                     else
                        "▶"
                    )
                ]
            ]
        , viewUnitSystemSelector model.units
        , if model.unitsExpanded then
            viewUnitDropdowns model.units

          else
            text ""
        ]


viewUnitSystemSelector : UnitSettings -> Html Msg
viewUnitSystemSelector units =
    div [ class "unit-system-selector" ]
        [ button
            [ class
                (if units.system == Imperial then
                    "unit-system-btn active"

                 else
                    "unit-system-btn"
                )
            , onClick (SetUnitSystem Imperial)
            ]
            [ text "Imperial" ]
        , button
            [ class
                (if units.system == Metric then
                    "unit-system-btn active"

                 else
                    "unit-system-btn"
                )
            , onClick (SetUnitSystem Metric)
            ]
            [ text "Metric" ]
        ]


viewUnitDropdowns : UnitSettings -> Html Msg
viewUnitDropdowns units =
    div [ class "unit-dropdowns" ]
        [ viewUnitDropdown "Range" units.range rangeUnitOptions SetRangeUnit
        , viewUnitDropdown "Drop/Wind" units.length lengthUnitOptions SetLengthUnit
        , viewUnitDropdown "Angle" units.angle angleUnitOptions SetAngleUnit
        , viewUnitDropdown "Temperature" units.temp tempUnitOptions SetTempUnit
        , viewUnitDropdown "Pressure" units.pressure pressureUnitOptions SetPressureUnit
        , viewUnitDropdown "Weight" units.weight weightUnitOptions SetWeightUnit
        , viewUnitDropdown "Energy" units.energy energyUnitOptions SetEnergyUnit
        , viewUnitDropdown "Velocity" units.velocity velocityUnitOptions SetVelocityUnit
        ]


viewUnitDropdown : String -> a -> List ( a, String ) -> (a -> Msg) -> Html Msg
viewUnitDropdown labelText currentValue options toMsg =
    div [ class "unit-dropdown" ]
        [ label [] [ text labelText ]
        , select
            [ onInput
                (\str ->
                    options
                        |> List.filter (\( _, s ) -> s == str)
                        |> List.head
                        |> Maybe.map (\( v, _ ) -> toMsg v)
                        |> Maybe.withDefault ToggleMenu
                )
            ]
            (List.map
                (\( val, str ) ->
                    option [ value str, selected (val == currentValue) ] [ text str ]
                )
                options
            )
        ]


rangeUnitOptions : List ( RangeUnit, String )
rangeUnitOptions =
    [ ( Yards, "Yards" )
    , ( Meters, "Meters" )
    ]


lengthUnitOptions : List ( LengthUnit, String )
lengthUnitOptions =
    [ ( Inches, "Inches" )
    , ( Centimeters, "Centimeters" )
    ]


angleUnitOptions : List ( AngleUnit, String )
angleUnitOptions =
    [ ( MOA, "MOA" )
    , ( MIL, "MIL" )
    ]


tempUnitOptions : List ( TempUnit, String )
tempUnitOptions =
    [ ( Fahrenheit, "Fahrenheit" )
    , ( Celsius, "Celsius" )
    ]


pressureUnitOptions : List ( PressureUnit, String )
pressureUnitOptions =
    [ ( InHg, "inHg" )
    , ( Mbar, "mbar" )
    ]


weightUnitOptions : List ( WeightUnit, String )
weightUnitOptions =
    [ ( Pounds, "Pounds" )
    , ( Kilograms, "Kilograms" )
    ]


energyUnitOptions : List ( EnergyUnit, String )
energyUnitOptions =
    [ ( FootPounds, "ft-lbs" )
    , ( Joules, "Joules" )
    ]


velocityUnitOptions : List ( VelocityUnit, String )
velocityUnitOptions =
    [ ( FPS, "fps" )
    , ( MPS, "m/s" )
    ]


viewContent : Model -> Html Msg
viewContent model =
    main_ [ class "content" ]
        [ case model.currentTool of
            TopGun ->
                TopGun.viewOutput model.units model.topGun

            Ballistics ->
                Ballistics.viewOutput model.units model.ballistics
        ]
