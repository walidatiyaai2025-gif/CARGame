# CARGO V2 AUTONOMOUS CLOSURE HANDOFF

Updated: 2026-09-08 (Kuwait)

## Authority and live-truth rule

- The single CARGO V2 integration/closure line is PR #297, `cargo-v2-autonomous-closure` -> `cargo-v2`.
- PR #298 / `cargo-v2-unity-runtime-ci` is the sole Unity runtime/build support line and targets PR #297. It is not a second closure candidate.
- PR #309 / `cargo-v2-worldmap-deploy-cta-polish` is the currently recovered WorldMap CTA source unit. It remains draft and must satisfy its dependency/runtime/visual gates before integration.
- `main` is not the current CARGO V2 integration target.
- Exact live GitHub refs, ancestry, review threads, exact-head checks, artifacts, PR #298, and Issue #264 are the mutable current-state record. This repository document is a durable handoff contract plus dated evidence snapshots; a newer live PR/run always supersedes an older snapshot below.

## Dated convergence snapshot

Snapshot basis before this document revision: authoritative PR #297 head `f74d7764323e81d2b57fdd0bb7a69c83d6115b10`.

That basis had:
- CARGO V2 Unity Scaffold #105 / `34192351058`: SUCCESS.
- CARGO V2 Player Experience Guard #16 / `34192351053`: SUCCESS.
- CARGO V2 Hostile State Guard #21 / `34192351028`: SUCCESS.
- Flutter CI #1317 / `34192351031`: executing when this snapshot was written; its final state must be read live, never inferred from this file.

The preceding docs-only reconciliation exposed a real scaffold contract regression in run #104 / `34192205305`. Its exact job log identified a missing `CARGO-V2-build-evidence.json` documentation token. Commit `f74d7764323e81d2b57fdd0bb7a69c83d6115b10` restored the evidence contract without weakening the validator, and exact-head Scaffold #105 passed.

At this snapshot, PR #298 had been reconciled without force-push to support head `3ec9a55720c29d28b7994a5657c169d5a7b10a66`, with merge-base exactly the authority basis, behind 0, and exactly one support delta: `.github/workflows/cargo_v2_unity_runtime.yml`.

## Recorded runtime-support snapshot

CARGO V2 Unity Runtime Build #11 / `34192397025` ran against PR #298 merge candidate `de30b0ca99847b8a79e85f491ed9b0eb0191738d`.

Observed:
- exact checkout: PASS;
- activation preflight: FAIL-CLOSED, exit 20;
- `UNITY_LICENSE`, `UNITY_SERIAL`, `UNITY_EMAIL`, `UNITY_PASSWORD`: all unconfigured;
- Unity import/C# compilation/build: SKIPPED;
- APK verification/evidence/upload: SKIPPED;
- diagnostics upload: PASS.

Diagnostic artifact id `10042660895`, artifact ZIP SHA-256 `b18ecd4053c7c9ad2ef43d1b97dd802216ad3bb68728593a36c1012584f686d5`.

This is a repeated external Unity activation-configuration blocker, not a CARGO V2 code regression and not evidence of a transient GitHub runner/network failure. Do not rerun unchanged as a transient retry. Read PR #298 and Issue #264 for the exact current support head/run after this snapshot.

## Governed Android contract

The live `SCR_CargoV2Build.cs` build path sets:
- product `CARGO V2`, company `WALKA`;
- application id `com.walka.cargov2`;
- version `2.0.0`, version code `20000`;
- minimum SDK 23;
- Landscape Left;
- ARM64 only;
- IL2CPP;
- Linear color space;
- APK output;
- `BuildOptions.None`.

`BUILD_CARGO_V2_UNITY.ps1` pins Unity `2022.3.75f1`, runs governed validation/build methods, rejects non-ARM64 native payloads, and emits SHA-256 evidence only after a real APK exists.

## Integrated product scope

PR #297 composes the Unity project/build scaffold; premium truck, cargo/depot and WorldMap runtime 3D assets; Splash/Loading; Cairo/Dubai mission map; progression/persistence/touch deploy; playable truck delivery loop; pickup/ordered checkpoints/delivery; pause/retry/recovery/abandon; active-delivery autosave/resume and corrupt-state quarantine; completion handoff and idempotent rewards; company progression/fleet purchase/upgrades; crash-consistent transaction recovery; capacity-safe recommendations; player-experience/hostile-state hardening; structural integration readiness; APK archive/ABI verification; SHA-256 evidence; and fail-closed ADB smoke orchestration.

Historical CARGO V2 implementation branches previously audited as contained or superseded must not be reimplemented or blindly merged. Branch deletion requires explicit repository governance authority after containment/supersession is proven.

## Remaining hard gates

The final exact candidate still requires genuine executed evidence for:
1. Unity 2022.3.75f1 import and C# compilation.
2. Governed Unity validation and Play Mode startup/navigation.
3. Splash -> Loading -> WorldMap -> deploy -> pickup -> checkpoints -> delivery -> settlement -> next unlock.
4. Persistence/restart/crash recovery, replay/idempotency, and fleet/economy runtime invariants.
5. Real 3D Resources import, scale/orientation/material/fallback and visual acceptance.
6. Measured performance/FPS and memory/runtime stability.
7. ARM64/IL2CPP Unity APK generation with SHA-256.
8. APK install/launch and available device/emulator smoke.
9. Final exact-target repository/CI convergence after integration.

Do not merge PR #297 to `cargo-v2` until those applicable runtime/build gates genuinely pass. Do not merge to `main` unless repository release governance explicitly permits it after staging. `FINAL_OWNER_3D_TEST_REQUIRED` is reachable only after the automated/runtime/build chain passes and an installable final 3D APK exists.
