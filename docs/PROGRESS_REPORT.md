# CARGO V2 AUTONOMOUS CLOSURE REPORT

Updated: 2026-09-08 (Kuwait)

## Live-state policy

PR #297 / `cargo-v2-autonomous-closure` is the single CARGO V2 closure authority and targets `cargo-v2`. PR #298 is its sole Unity runtime/build support dependency. PR #309 is the recovered WorldMap CTA source unit. PR #249 is unrelated Flutter AST work.

This file is intentionally a dated progress snapshot, not a self-updating SHA ledger. For the exact current head, support merge candidate, CI conclusion, activation state, and artifact ids, read the live PR #297 / PR #298 metadata and Issue #264. Live GitHub state supersedes an older snapshot here.

## Convergence snapshot

Evidence basis before this document revision: PR #297 head `f74d7764323e81d2b57fdd0bb7a69c83d6115b10`.

Completed convergence through that basis:
- PR #308 was normal-merged as `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`, adding fail-closed Integration Preview readiness to the governed Unity validation path.
- Canonical CARGO V2 evidence documents were reconciled, then exact-head Scaffold #104 / `34192205305` found a real documentation-contract regression.
- The exact log identified missing `CARGO-V2-build-evidence.json` contract text; the root cause was fixed in `f74d7764323e81d2b57fdd0bb7a69c83d6115b10` without weakening the validator.
- Corrected exact-head Unity Scaffold #105 / `34192351058`: SUCCESS.
- Corrected exact-head Player Experience Guard #16 / `34192351053`: SUCCESS.
- Corrected exact-head Hostile State Guard #21 / `34192351028`: SUCCESS.
- Flutter CI #1317 / `34192351031` was still executing at snapshot time and must be checked live for its final conclusion.

PR #309 source head `17302145f153f7a5b99dd60bf6da9c07fe1a20ab` had source/scaffold CI green at the latest read: WorldMap CTA Guard #2, Runtime Contract Name Guard #7, Unity Scaffold #103, and Flutter CI #1313 all succeeded. It remained draft, stale relative to the moving authority, and without Unity visual/runtime acceptance.

Historical CARGO V2 implementation branches already established as contained/superseded remain non-authoritative. No duplicate implementation was started and no branch was deleted without explicit governance authorization.

## Android PlayerSettings contract

The governed Unity build method sets:
- `com.walka.cargov2`;
- `2.0.0`, version code `20000`;
- minimum Android SDK 23;
- Landscape Left;
- ARM64 only;
- IL2CPP;
- Linear color space;
- APK output;
- no Unity development-build flag (`BuildOptions.None`).

The launcher pins Unity `2022.3.75f1`, validates before building, verifies the Unity/IL2CPP ARM64 APK archive contract, and computes SHA-256 only for a produced artifact.

## Recorded runtime-support snapshot

At this snapshot PR #298 support head was `3ec9a55720c29d28b7994a5657c169d5a7b10a66`, merge-base exactly the authority basis, behind 0, and one changed support file only.

Unity Runtime Build #11 / `34192397025` against merge candidate `de30b0ca99847b8a79e85f491ed9b0eb0191738d` failed closed before Unity launched:
- checkout PASS;
- activation preflight FAIL, exit 20;
- `UNITY_LICENSE`, `UNITY_SERIAL`, `UNITY_EMAIL`, `UNITY_PASSWORD` all unconfigured;
- Unity import/build and APK verification/upload SKIPPED;
- diagnostics upload PASS.

Diagnostic artifact id `10042660895`; artifact ZIP SHA-256 `b18ecd4053c7c9ad2ef43d1b97dd802216ad3bb68728593a36c1012584f686d5`.

Classification: repeated external Unity activation configuration blocker, not a source/code regression and not a transient runner/network failure. An unchanged rerun cannot advance runtime acceptance. PR #298 / Issue #264 contain the mutable current runtime record after this snapshot.

## Remaining closure gates

No merge to `cargo-v2` is permitted while exact final Unity/runtime/Android evidence is missing. No merge to `main` is permitted before the staging/release governance says so.

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
