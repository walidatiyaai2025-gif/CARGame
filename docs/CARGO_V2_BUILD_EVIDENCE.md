# CARGO V2 Android Build Evidence Contract

This document defines the machine-verifiable evidence emitted by the governed CARGO V2 Android build/runtime-support paths. It does not itself declare runtime acceptance.

## Live-state rule

- Integration authority: PR #297 / `cargo-v2-autonomous-closure`.
- Runtime/build support: PR #298 / `cargo-v2-unity-runtime-ci`.
- Mutable current runtime state is recorded in live PR #298 and Issue #264.
- Execution records below are dated snapshots. A later exact-head run supersedes an older snapshot without making this contract false.
- Static/source/scaffold/Flutter evidence cannot substitute for Unity build, Play Mode, APK, device, visual, gameplay, or measured-performance evidence.

## Authoritative Android contract

- Unity editor: `2022.3.75f1`
- Android package: `com.walka.cargov2`
- Version: `2.0.0` (`versionCode=20000`)
- Minimum SDK: 23
- Orientation: Landscape Left
- Architecture: ARM64 only
- Scripting backend: IL2CPP
- Color space: Linear
- Artifact format: APK
- Unity build options: `BuildOptions.None`

These values are set by the governed live build method, not assumed from an untracked `ProjectSettings.asset`.

## Governed build path

`BUILD_CARGO_V2_UNITY.bat` invokes `BUILD_CARGO_V2_UNITY.ps1`.

The PowerShell launcher:
1. verifies `ProjectSettings/ProjectVersion.txt` pins Unity `2022.3.75f1`;
2. discovers or consumes the configured Unity executable;
3. executes `CargoV2.EditorTools.SCR_CargoV2Build.ValidateBatch`;
4. executes `CargoV2.EditorTools.SCR_CargoV2Build.BuildAndroidBatch`;
5. requires a non-empty APK;
6. verifies required Unity/IL2CPP archive entries;
7. rejects any native ABI other than `arm64-v8a`;
8. computes SHA-256;
9. writes machine-readable evidence to `BuildLogs/CargoV2/CARGO-V2-build-evidence.json` by default.

The Unity build method performs fail-closed scene/type/resource and CARGO V2 regression validation before building, writes the PlayerSettings contract above, uses APK output, and does not enable a Unity development build.

## APK archive contract

A verified CARGO V2 APK must contain at least:
- `AndroidManifest.xml`
- `classes.dex`
- `assets/bin/Data/globalgamemanagers`
- `lib/arm64-v8a/libmain.so`
- `lib/arm64-v8a/libunity.so`
- `lib/arm64-v8a/libil2cpp.so`

Every native `.so` under `lib/<abi>/` must resolve to `arm64-v8a`; an `x86_64` or other additional ABI is rejected.

The build evidence JSON includes artifact kind, Unity/package contract, APK path and size, lowercase SHA-256, required entries, observed native architectures, source SHA when available, UTC verification time, and explicit `runtimeInstallExecuted=false` / `runtimeLaunchExecuted=false` truth fields. Archive verification never implies install, launch, gameplay, FPS, signing identity, or device stability.

## Android install/launch smoke path

`SMOKE_CARGO_V2_ANDROID.ps1` re-verifies the APK contract, discovers authorized ADB targets dynamically, installs with `adb install -r`, validates the package/process/resumed activity, captures package-correlated logcat, fails on fatal/ANR/process-death markers, and writes machine-readable smoke evidence.

Synthetic APK/fake-ADB CI checks are orchestration evidence only: they are not Unity build or gameplay evidence, and they never substitute for real APK/device execution.

## Recorded runtime-support execution snapshot

Snapshot authority basis: `f74d7764323e81d2b57fdd0bb7a69c83d6115b10`.

At the snapshot, support head `3ec9a55720c29d28b7994a5657c169d5a7b10a66` had merge-base exactly that authority basis, was behind 0, and differed by exactly `.github/workflows/cargo_v2_unity_runtime.yml`.

Unity Runtime Build #11 / `34192397025` executed against PR merge candidate `de30b0ca99847b8a79e85f491ed9b0eb0191738d`.

Observed:
- checkout exact candidate: PASS;
- activation preflight: FAIL-CLOSED, exit 20;
- `UNITY_LICENSE`: not configured;
- `UNITY_SERIAL`: not configured;
- `UNITY_EMAIL`: not configured;
- `UNITY_PASSWORD`: not configured;
- secret values included in diagnostic: false;
- Unity import/C# compilation/build: SKIPPED;
- APK verification/evidence/upload: SKIPPED;
- diagnostics upload: PASS.

Diagnostic artifact:
- id `10042660895`;
- name `CARGO-V2-Unity-diagnostics-de30b0ca99847b8a79e85f491ed9b0eb0191738d`;
- artifact ZIP SHA-256 `b18ecd4053c7c9ad2ef43d1b97dd802216ad3bb68728593a36c1012584f686d5`.

Classification: external Unity activation configuration blocker. It is not a CARGO V2 code regression and the evidence does not support classifying it as transient infrastructure. An unchanged rerun cannot advance acceptance. Read live PR #298 / Issue #264 for any newer exact-head run.

## Evidence still required

A final accepted candidate still requires genuine execution evidence for Unity compile/import, Play Mode/gameplay, persistence/recovery/economy, real 3D visual import, measured performance/memory, Unity ARM64/IL2CPP APK build plus SHA-256, and available real device/emulator install/launch smoke.

No source/static/scaffold/Flutter result may be substituted for these runtime categories.
