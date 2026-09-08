# CARGO V2 Android Build Evidence Contract

This document defines the machine-verifiable evidence emitted by the governed CARGO V2 Android build/runtime-support paths. It does not itself declare runtime acceptance.

## Authoritative contract

- Integration branch: `cargo-v2-autonomous-closure`
- Pull request: #297
- Runtime/build support: PR #298 / `cargo-v2-unity-runtime-ci`
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
9. writes machine-readable evidence.

The Unity build method performs fail-closed scene/type/resource and CARGO V2 regression validation before building, then writes the PlayerSettings contract above and uses APK output rather than an app bundle.

## APK archive contract

A verified CARGO V2 APK must contain at least:

- `AndroidManifest.xml`
- `classes.dex`
- `assets/bin/Data/globalgamemanagers`
- `lib/arm64-v8a/libmain.so`
- `lib/arm64-v8a/libunity.so`
- `lib/arm64-v8a/libil2cpp.so`

Every native `.so` under `lib/<abi>/` must resolve to `arm64-v8a`.

The build evidence JSON includes artifact kind, Unity/package contract, APK path and size, lowercase SHA-256, required entries, observed native architectures, source SHA when available, UTC verification time, and explicit install/launch truth fields. Archive verification never implies install, launch, gameplay, FPS, signing identity or device stability.

## Android install/launch smoke path

`SMOKE_CARGO_V2_ANDROID.ps1` re-verifies the APK contract, discovers authorized ADB targets dynamically, installs with `adb install -r`, validates the package/process/resumed activity, captures package-correlated logcat, fails on fatal/ANR/process-death markers, and writes machine-readable smoke evidence.

Synthetic APK/fake-ADB CI tests validate orchestration only. They are never real Unity APK or device evidence.

## Latest exact runtime-support execution

Implementation authority basis before this documentation reconciliation: `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`.

Support branch was reconciled to head `7aeff619f1421c1b4d1c1acc481867855d8d1e79`; compare showed merge-base exactly the authority basis, behind 0, and one changed support file only.

Unity Runtime Build #9 / run `34191746281` executed against PR merge candidate `c6fe90150313f9a609db8928d48cab38d46fbd2a`.

Observed result:

- checkout exact candidate: PASS;
- activation preflight: FAIL-CLOSED;
- `UNITY_LICENSE`: not configured;
- `UNITY_SERIAL`: not configured;
- `UNITY_EMAIL`: not configured;
- `UNITY_PASSWORD`: not configured;
- secret values included in diagnostic: false;
- Unity import/build: SKIPPED;
- APK verification/evidence: SKIPPED;
- APK upload: SKIPPED;
- diagnostics upload: PASS.

Diagnostic artifact:

- id: `10042441917`;
- name: `CARGO-V2-Unity-diagnostics-c6fe90150313f9a609db8928d48cab38d46fbd2a`;
- digest: `sha256:070e8c1ce015a24ca7e843d10a4ce15d2198c2350ee60de65bfab70fe397a430`.

Classification: external Unity activation configuration blocker. This is not a CARGO V2 code regression and the evidence does not support classifying it as transient infrastructure. An unchanged rerun cannot advance acceptance.

## Evidence still required

A final accepted candidate still requires genuine execution evidence for Unity compile/import, Play Mode/gameplay, persistence/recovery/economy, real 3D visual import, measured performance/memory, Unity ARM64/IL2CPP APK build plus SHA-256, and available real device/emulator install/launch smoke.

No source/static/scaffold/Flutter result may be substituted for these runtime categories.
