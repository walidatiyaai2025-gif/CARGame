# CARGO V2 Premium Art Pass — UI QA

## Scope
- `Assets/_Project/Scenes/01_Splash.unity`
- `Assets/_Project/Scenes/02_Loading.unity`
- `Assets/_Project/Scenes/04_WorldMap.unity` only as the transition target
- `Assets/_Project/UI/SCR_UIManager.cs`

## Required generated art bindings
The final scene YAML must bind the generated ASSET_TEAM textures from `Assets/_Project/Generated/`:
- `IMG_Logo_Premium`
- `IMG_Truck_Premium`
- `IMG_Truck_Premium_Alt`
- `VFX_Glow_Premium`

`SCR_UIManager` logs an error when the required logo/truck/glow binding is missing and a warning when only the alternate truck is missing.

## Play Mode acceptance
1. Open `01_Splash` and enter Play Mode.
2. Confirm a clean navy premium composition, generated logo, generated glow, subtle ambient particles/light sweep, and no procedural placeholder logo/truck.
3. Confirm automatic transition to `02_Loading` after the configured splash duration.
4. Confirm Loading uses the premium truck, glow, route line, destination nodes and a smooth 0–100% progress fill.
5. Confirm the alternate premium truck is blended subtly during the latter part of Loading.
6. Confirm automatic transition to `04_WorldMap`.
7. Confirm no missing-script references and no C# compile errors.
8. Confirm Console contains no missing premium-art errors.

## Transition implementation note
The runtime path uses normal `SceneManager.LoadScene` when scenes are present in Build Settings. In Unity Editor Play Mode, `EditorSceneManager.LoadSceneInPlayMode` is used as a safe fallback when the isolated CARGO V2 branch has not yet received build-settings ownership changes. No `Packages/` or `ProjectSettings/` files are modified by UI_TEAM in this art-pass PR.
