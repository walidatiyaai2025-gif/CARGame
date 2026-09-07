# CARGO V2 Android Build Evidence Contract

This document defines the machine-verifiable evidence emitted by the autonomous CARGO V2 Android build path. It does not, by itself, declare the game runtime accepted.

## Authoritative closure line

- Integration branch: `cargo-v2-autonomous-closure`
- Pull request: #297
- Unity editor contract: `2022.3.75f1`
- Android package contract: `com.walka.cargov2`
- Android architecture contract: ARM64 only
- Scripting backend contract: IL2CPP
- Artifact format: APK

## Real build path

`BUILD_CARGO_V2_UNITY.bat` invokes `BUILD_CARGO_V2_UNITY.ps1`.

The PowerShell launcher:

1. verifies the pinned Unity project version;
2. discovers or consumes the configured Unity editor executable;
3. executes `CargoV2.EditorTools.SCR_CargoV2Build.ValidateBatch`;
4. executes `CargoV2.EditorTools.SCR_CargoV2Build.BuildAndroidBatch`;
5. requires a non-empty APK;
6. opens the APK as a ZIP archive and verifies the Unity/IL2CPP ARM64 payload contract;
7. computes SHA-256;
8. writes machine-readable build evidence.

The default evidence path is:

`BuildLogs/CargoV2/CARGO-V2-build-evidence.json`

`BuildLogs/` and `Builds/` are intentionally ignored repository outputs.

## APK archive contract

A verified CARGO V2 APK must contain at least:

- `AndroidManifest.xml`
- `classes.dex`
- `assets/bin/Data/globalgamemanagers`
- `lib/arm64-v8a/libmain.so`
- `lib/arm64-v8a/libunity.so`
- `lib/arm64-v8a/libil2cpp.so`

Every native `.so` entry under `lib/<abi>/` must resolve to `arm64-v8a`; an APK that also contains x86, x86_64, armeabi-v7a, or another ABI is rejected.

## Evidence JSON semantics

The JSON record includes:

- schema version;
- artifact kind and verification mode;
- expected Unity version and package identifier contract;
- absolute APK path on the machine that performed verification;
- APK size;
- lowercase SHA-256 digest;
- required archive entries;
- observed native architectures;
- source SHA when `GITHUB_SHA` is available;
- UTC verification timestamp;
- explicit `runtimeInstallExecuted=false` and `runtimeLaunchExecuted=false`.

Archive verification is intentionally narrower than runtime acceptance. It must never be interpreted as proof of APK installation, application launch, Play Mode behavior, visual quality, signing identity, device FPS, or device stability.

## CI contract test

`CARGO V2 Unity Scaffold` executes the artifact-verifier logic using synthetic APK-shaped ZIP fixtures:

- a valid ARM64-only fixture must pass and emit evidence;
- a fixture containing an extra x86_64 native library must fail.

These fixture checks prove the verifier logic is executable and fail-closed. They are not Unity build or gameplay evidence.

## Remaining runtime evidence categories

Final product closure still requires evidence produced by actual execution on the exact candidate for the relevant gate, including Unity compile/import, gameplay/Play Mode, Android build, install/launch, device smoke, and performance/visual acceptance. No CI fixture or static check substitutes for those runtime results.
