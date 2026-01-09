module Main exposing (main)

import Ballistics
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Styles
import TopGun
import Types exposing (..)


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentTool = TopGun
      , menuOpen = False
      , topGun =
            { projectileWeight = 168
            , muzzleVelocity = 2650
            , rifleWeight = 12
            , graphVariable = RifleWeight
            }
      , ballistics =
            { scopeHeight = 1.9
            , zeroDistance = 100
            , twistRate = 10
            , temperature = 60
            , pressure = 29.92
            , windSpeed = 10
            , windDirection = 90
            , loads =
                [ { name = "NAS3 175Gr LRX", weight = 175, bc = 0.254, bcModel = G7, muzzleVelocity = 2725, twistRate = 11.25 }
                , { name = "NAS3 150 TTSX", weight = 150, bc = 0.440, bcModel = G1, muzzleVelocity = 2950, twistRate = 10 }
                , { name = "Barnes 130Gr TTSX", weight = 130, bc = 0.350, bcModel = G1, muzzleVelocity = 3125, twistRate = 10 }
                , { name = "Barnes 150Gr TTSX", weight = 150, bc = 0.440, bcModel = G1, muzzleVelocity = 2900, twistRate = 10 }
                , { name = "Barnes 168Gr TTSX", weight = 168, bc = 0.470, bcModel = G1, muzzleVelocity = 2700, twistRate = 11.25 }
                ]
            , selectedLoad = 0
            , primaryLoadIndex = 0
            , editingLoad = NotEditing
            , editForm = defaultLoad
            }
      }
    , Cmd.none
    )


defaultLoad : Load
defaultLoad =
    { name = "New Load"
    , weight = 150
    , bc = 0.400
    , bcModel = G1
    , muzzleVelocity = 2800
    , twistRate = 10
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        SelectTool tool ->
            ( { model | currentTool = tool, menuOpen = False }, Cmd.none )

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
            ( { model | ballistics = { ballistics | editingLoad = AddingNew, editForm = defaultLoad } }, Cmd.none )

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

        UpdateLoadTwist str ->
            updateEditForm model (\form -> { form | twistRate = String.toFloat str |> Maybe.withDefault form.twistRate })


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
            , viewContent model
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
        , if model.menuOpen then
            viewMenu model.currentTool

          else
            text ""
        ]


viewMenu : Tool -> Html Msg
viewMenu currentTool =
    div [ class "menu-overlay", onClick ToggleMenu ]
        [ div [ class "menu" ]
            [ h2 [] [ text "Tools" ]
            , button
                [ class
                    (if currentTool == TopGun then
                        "menu-item active"

                     else
                        "menu-item"
                    )
                , onClick (SelectTool TopGun)
                ]
                [ text "TOP Gun Calculator" ]
            , button
                [ class
                    (if currentTool == Ballistics then
                        "menu-item active"

                     else
                        "menu-item"
                    )
                , onClick (SelectTool Ballistics)
                ]
                [ text "Ballistics Solver" ]
            ]
        ]


viewContent : Model -> Html Msg
viewContent model =
    main_ [ class "content" ]
        [ case model.currentTool of
            TopGun ->
                TopGun.view model.topGun

            Ballistics ->
                Ballistics.view model.ballistics
        ]
