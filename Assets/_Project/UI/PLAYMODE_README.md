# CARGO V2 UI P0 Play Mode

This checkpoint is intentionally source-complete and does not include a final build.

## Open in Unity
1. Checkout `cargo-v2-ui-team`.
2. Open the repository folder in Unity Hub with Unity 2022.3 LTS. If Hub offers a compatible newer 2022.3 patch, use it.
3. Let Unity import `Assets/_Project/UI`, `Assets/_Project/Generated`, and `Assets/_Project/Scenes`.
4. Open `Assets/_Project/Scenes/01_Splash.unity`.
5. Press Play.

## Expected five-second capture
- 0-3s: Navy `#0A1A2F` background, extruded Gold `#FFC107` CARGO V2 logo, gold point-glow and particles.
- At ~3s: automatic transition to `02_Loading`.
- 3-5s: gold `IMG_Truck_3D` prefab travels left-to-right while progress bar advances.
- At loading completion: automatic transition to `04_WorldMap` placeholder checkpoint.

## Record
Use Unity Recorder or OS screen capture for at least five seconds starting before Play. Do not record an APK/AAB; this is Editor Play Mode evidence only.

## If a scene transition is blocked
Open File > Build Settings and verify 01_Splash, 02_Loading, and 04_WorldMap are enabled in this order. `ProjectSettings/EditorBuildSettings.asset` already contains the expected configuration.
