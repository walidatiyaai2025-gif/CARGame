# CARGO V2 AUTONOMOUS CLOSURE REPORT

Updated: 2026-09-08 (Kuwait)

## Current authority

PR #297 / `cargo-v2-autonomous-closure` remains the single CARGO V2 integration/closure line and targets `cargo-v2`. The implementation/evidence basis immediately before this documentation-only reconciliation is `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`; the exact live PR head is always authoritative.

PR #298 / `cargo-v2-unity-runtime-ci` remains the dedicated draft runtime/build support gate. PR #309 / `cargo-v2-worldmap-deploy-cta-polish` is the current draft UI source unit and is not eligible for integration while required runtime/visual evidence is absent. PR #249 is unrelated Flutter AST work and is outside this closure effort.

## Convergence performed

- PR #308 was normal-merged as authority commit `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`, adding fail-closed integration readiness to the governed Unity validation path.
- PR #298 was reconciled without force-push to support head `7aeff619f1421c1b4d1c1acc481867855d8d1e79`.
- Compare after reconciliation proved merge-base exactly `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`, 0 commits behind, and exactly one support delta: `.github/workflows/cargo_v2_unity_runtime.yml`.
- Open review-thread checks for PRs #297, #298 and #309 returned no unresolved inline review threads at the evidence read.
- Historical CARGO V2 gameplay/visual/persistence/reliability/smoke/economy/team branches remain contained or superseded according to the prior ancestry/semantic sweep; no duplicate implementation was started and no branch was deleted without explicit governance authorization.

## Exact source/scaffold evidence

Authority basis `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`:

- Hostile State Guard #19 / `34191496613`: SUCCESS.
- Player Experience Guard #14 / `34191496585`: SUCCESS.
- Unity Scaffold #102 / `34191496579`: SUCCESS.
- Flutter CI #1312 / `34191496576`: still executing at the evidence read; full suite and coverage had passed before the job entered debug-APK build.

PR #309 head `17302145f153f7a5b99dd60bf6da9c07fe1a20ab`:

- WorldMap Deploy CTA Guard #2 / `34191576245`: SUCCESS.
- Runtime Contract Name Guard #7 / `34191576251`: SUCCESS.
- Unity Scaffold #103 / `34191576239`: SUCCESS.
- Flutter CI #1313 / `34191576249`: still executing at the evidence read.

Source/scaffold green is not Unity Play Mode, device, visual or FPS evidence.

## Android PlayerSettings contract in live governed source

The live build method explicitly sets:

- `com.walka.cargov2`;
- version `2.0.0`, version code `20000`;
- minimum Android SDK 23;
- Landscape Left;
- ARM64 only;
- IL2CPP;
- Linear color space;
- APK rather than AAB;
- no Unity development-build flag.

The PowerShell launcher pins Unity `2022.3.75f1`, executes validation then Android build, validates the Unity/IL2CPP ARM64 APK archive contract and computes SHA-256 only for a produced artifact.

## Latest real Unity runtime/build result

Support head `7aeff619f1421c1b4d1c1acc481867855d8d1e79` triggered Unity Runtime Build #9 / `34191746281` against merge candidate `c6fe90150313f9a609db8928d48cab38d46fbd2a`.

Result: FAIL-CLOSED before Unity launched.

- checkout: PASS;
- activation preflight: FAIL;
- Unity import/build: SKIPPED;
- APK verification/upload: SKIPPED;
- diagnostics upload: PASS.

The diagnostic preflight recorded all four supported activation inputs as not configured: `UNITY_LICENSE`, `UNITY_SERIAL`, `UNITY_EMAIL`, and `UNITY_PASSWORD`. No secret values were logged.

Artifact id `10042441917`, digest `sha256:070e8c1ce015a24ca7e843d10a4ce15d2198c2350ee60de65bfab70fe397a430`.

This failure is classified as an external Unity activation-configuration blocker. It is not a code failure and not a transient runner/network failure, so an unchanged retry is not used to manufacture another result.

## Product implementation already integrated on PR #297

The authority composes the Unity 2022.3.75f1 project/build scaffold; premium truck, Mission cargo/depot and WorldMap runtime 3D assets; Splash/Loading; 20 Cairo/Dubai missions; selection/locking/progression/persistence/touch deploy; playable truck delivery loop; pickup/checkpoints/delivery; pause/retry/recovery/abandon; active-delivery autosave/resume; corrupt-state quarantine; completion handoff and idempotent rewards; company Coins/XP/rank; fleet ownership/purchase/selection/upgrades; crash-consistent company transactions; capacity-safe truck recommendations; player-experience hardening; hostile-state recovery; Android APK structure/ABI verification; and fail-closed ADB smoke orchestration.

## Remaining blockers and merge discipline

No merge to `cargo-v2` is permitted while the exact final Unity/runtime/Android evidence is missing. No merge to `main` is permitted before the repository-defined staging/release gates are satisfied.

Still required on the exact final candidate:

1. Unity import/C# compilation and governed validation.
2. Play Mode startup and complete gameplay/settlement/unlock loop.
3. Restart/crash-resume/replay/idempotency and fleet/economy runtime checks.
4. Real 3D import/material/scale/orientation/fallback visual acceptance.
5. Measured performance/FPS and memory stability.
6. ARM64/IL2CPP APK generation with SHA-256.
7. APK install/launch and available device/emulator smoke.
8. Final exact-target CI/repository convergence after integration.

Terminal pre-owner state remains `FINAL_OWNER_3D_TEST_REQUIRED`, reachable only after the automated/runtime/build chain genuinely passes and an installable final 3D test APK exists.
