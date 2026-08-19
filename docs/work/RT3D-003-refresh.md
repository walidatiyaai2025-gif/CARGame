# RT3D-003 — Current-main cinematic polish refresh

Issue: #227
Priority: P0 VISUAL
Status: SOURCE-CONTROLLED COMPLETE / RETAINED APK PROMOTED

## Baseline

- Refresh work was rebased onto current production history after GAME-017 + WORLD-009 rather than continuing the stale RT3D-003 branch.
- Preserve Filament 1.74.0, native PlatformView architecture, interaction entity IDs, world coordinates, gameplay, save/economy, ads/privacy, and cargo target truth.
- Keep the cinematic GLB deterministic, project-owned and provenance-pinned.

## Implemented checkpoint

- Regenerated project-owned GLB is pinned to SHA-256 `b727b594612452a9a3723aa64423ee5d18a9b90567aba191d9a035bf888de157`.
- Validator and provenance protect the RT3D-003 cinematic node/material contract.
- Added emissive lamps/headlights/rear lights/beacon/signals, vehicle mirrors/bumpers, road arrows, traffic signals, pallet/skyline dressing and delivery rims while retaining stable cargo/delivery IDs.
- Native runtime includes Filament bloom, deterministic Overview/Warehouse/Docks presets, reset/custom orbit state, reduced-motion-safe scripted camera changes, frame count and FPS estimate.
- Dart bridge, accessible Visual Lab camera HUD, camera/raycast tests, fallback widget tests, validator mutation tests and a dedicated RT3D-003 CI gate are implemented.

## Exact-head verification

Final PR head: `95f8d3fb2ab5cc907d8e7386a8b1500019eaae46`

All required PR-head gates completed successfully:

- Flutter CI run `32197137693` — SUCCESS; full suite, coverage, Debug APK build, packaged-artifact security and upload completed. Debug artifact `9346437361` (`cargame-debug-apk`) is 89,256,284 bytes with artifact digest `sha256:b0f7453142dec47d8fd2cf63397447f0dcd276349cf73600f817691dbcefa788`.
- Android Release Packaging Smoke run `32197137703` — SUCCESS; release APK smoke, release AAB smoke, artifact security and output verification all passed. Evidence artifact `9346443800` has digest `sha256:b3d44ccfcbe1e67a87daaee8489d0b4bc24ee62bc2ef9752fb1227d79a7488e6`.
- RT3D-002 Production 3D Contract run `32197137739` — SUCCESS, proving compatibility with the previous native-3D contract.
- RT3D-003 Cinematic Native 3D Contract run `32197137702` — SUCCESS, including deterministic GLB zero-diff regeneration, validators, Dart formatting/analyze and focused camera/HUD tests.

PR #237 merged to `main` as `c51a6a62edeed41da3bddd70b9a3ab87a715b410`.

## Post-merge / retained APK evidence

A later verified `main` source commit, `54917a6429f030d051be343e8c40f0b46bb88395`, is seven commits ahead of the RT3D-003 merge commit, so its source tree contains RT3D-003.

- Full Flutter CI run `32209373917` on that main source commit — SUCCESS across all normal gates, including Analyze, full tests, coverage, Debug APK build and artifact security.
- Latest Verified APK promotion run `32209999561` — SUCCESS; it verified the source belonged to current `main` history, passed dependency/release-input/security gates, built the release-mode QA APK and promoted it only after the current-main check.
- `Last verified APK/LATEST.txt` records source commit `54917a6429f030d051be343e8c40f0b46bb88395`.
- Retained QA APK: `Last verified APK/CARGame-latest-verified.apk`.
- Retained APK size: 76,621,985 bytes.
- Retained APK SHA-256: `f51e2c533f3067896185928434b7894eb0a0d9d1a267804487981e255a1b1b8c`.
- Signing: ephemeral CI signing.
- Runtime ads: disabled.
- Distribution status: QA/installable evidence only; not production/Play Store signed.

Current `main` has since advanced beyond that promoted source commit with unrelated work. The retained APK remains a governed main-history build that contains RT3D-003; no manual overwrite is performed.

## Acceptance boundary

RT3D-003 source/build/package/main/retained-APK acceptance is complete. Physical-device visual/performance acceptance is deliberately **not claimed** without owner/device evidence. A device play-test may still identify follow-up polish, but it is no longer a source-controlled closure blocker for Issue #227.
