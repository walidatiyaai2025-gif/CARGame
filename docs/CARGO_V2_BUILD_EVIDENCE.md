# CARGO V2 Android Build Evidence Contract

This document defines the machine-verifiable evidence emitted by the autonomous CARGO V2 Android build and smoke paths. It does not, by itself, declare the game runtime accepted.

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

## Build evidence JSON semantics

The build JSON record includes:

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

## Android install/launch smoke path

`SMOKE_CARGO_V2_ANDROID.ps1` is the fail-closed ADB smoke harness for a real APK after the archive/ABI contract passes.

It:

1. reruns `BUILD_CARGO_V2_UNITY.ps1 -VerifyApkOnly` before touching a device;
2. discovers authorized ADB targets dynamically;
3. automatically selects only when exactly one authorized target exists, or validates an explicitly supplied `-Serial` when several are connected;
4. installs with `adb install -r` so the smoke path does not destructively uninstall saved state;
5. verifies `com.walka.cargov2` exists after installation;
6. clears pre-launch logcat, force-stops the package, and sends one bounded launcher intent;
7. verifies the package process is present and the package appears in resumed activity state;
8. captures package-correlated logcat and fails on observed fatal-exception, ANR, fatal-signal, or process-died markers;
9. writes machine-readable smoke evidence including APK SHA-256 and dynamically observed device metadata.

The default smoke evidence path is:

`BuildLogs/CargoV2/CARGO-V2-android-smoke-evidence.json`

A smoke PASS is scoped only to the APK archive contract plus the observed install and initial launch on that exact ADB target. It does **not** prove gameplay completion, control quality, visual quality, sustained FPS, thermal behavior, long-run stability, or production signing.

## CI contract tests

`CARGO V2 Unity Scaffold` exercises fail-closed build/smoke automation without fabricating Unity or device evidence:

- a valid synthetic ARM64-only APK-shaped fixture must pass the archive verifier;
- a fixture containing an extra x86_64 native library must fail;
- the Android smoke source contract verifier rejects hard-coded emulator serials, destructive uninstall, and widened PASS claims;
- a fake-ADB single-device scenario must exercise the install/launch orchestration and emit all expected truth fields;
- a fake-ADB multi-device scenario must fail before installation unless an explicit serial is supplied.

Synthetic fixture/fake-ADB checks prove the automation logic is executable and fail-closed. They are not Unity build or gameplay evidence. Their output is not a real APK build, real device run, gameplay test, or FPS measurement.

## Remaining runtime evidence categories

Final product closure still requires evidence produced by actual execution on the exact candidate for the relevant gate, including Unity compile/import, gameplay/Play Mode, Android build, install/launch on a real device/emulator, device smoke, and performance/visual acceptance. No CI fixture or static check substitutes for those runtime results.
