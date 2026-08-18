# RT3D-003 — Current-main cinematic polish refresh

Issue: #227
Priority: P0 VISUAL

## Baseline

- Refresh branch starts from exact current `main` after GAME-017 + WORLD-009.
- Preserve Filament 1.74.0, native PlatformView architecture, interaction entity IDs, world coordinates, gameplay, save/economy, ads/privacy, and cargo target truth.
- Port only the isolated deterministic cinematic GLB generator work from the stale RT3D-003 branch, regenerate the project-owned GLB, and verify zero-diff determinism before adding camera/runtime changes.

## Current checkpoint

- Cinematic GLB generator is now based on current main.
- Regenerated project-owned GLB is pinned to SHA-256 `b727b594612452a9a3723aa64423ee5d18a9b90567aba191d9a035bf888de157`.
- Validator and provenance now target the RT3D-003 cinematic node/material contract instead of the stale RT3D-002 scene.
- The contract explicitly protects emissive lamps/headlights/rear lights/beacon/signals, vehicle mirrors/bumpers, road arrows, traffic signals, pallet/skyline dressing and delivery rims while retaining stable cargo/delivery IDs.
- Native runtime now includes Filament bloom, Overview/Warehouse/Docks presets, reset/custom orbit state, frame count and FPS estimate.
- Dart bridge and accessible Visual Lab camera HUD are implemented; canonical Dart formatting is the active CI checkpoint.

## Next gates

1. Canonical Dart format and focused RT3D CI.
2. Full Flutter analyze/test/debug APK gate.
3. Android release APK/AAB packaging and artifact security.
4. Exact-main merge and retained Last verified APK evidence.
5. Owner physical-device visual play-test.
