# CARGO V2 AUTONOMOUS CLOSURE REPORT

Updated: 2026-09-08 (Kuwait)

## Current authority

PR #297 / `cargo-v2-autonomous-closure` remains the single CARGO V2 integration/closure line and targets `cargo-v2`. Exact head at this report: `ae395b1e271cd1795cdece521a9ff1013fe4c77d`.

PR #298 / `cargo-v2-unity-runtime-ci` remains a separate draft support gate and must not be merged as runtime acceptance until Unity actually executes successfully. Unrelated Flutter work such as PR #249 remains outside this closure effort.

## Convergence completed through the current authority

The authority now contains the legitimate previously parallel CARGO V2 work, including Android smoke automation, player-experience hardening, hostile-state/persistence recovery, company transaction recovery, completion/reward recovery, premium/runtime 3D assets and presentation, and the capacity-safe contract recommendation fix from PR #305.

PR #305 was normal-merged after its exact head passed Contract Capacity Guard, Hostile State, Unity Scaffold and Flutter CI. It corrected the case where heavy Dubai contracts could recommend a truck whose capacity was below the cargo weight and added a 20-mission fail-closed regression.

A full 2026-09-08 concurrency sweep then compared the surviving CARGO V2 branches against the authority. The old production-visual, gameplay-recovery, player-experience, reliability, smoke, mission/data/logic/world-map and team lines are already contained (`ahead_by=0`). No duplicate implementation was started.

Legacy divergent branches were not merged merely because they had unique historical commits. Their useful runtime/art files were either exact-preserved or superseded by newer authority code; obsolete primitive intro UI, editor auto-preview convenience and old standalone QA logging were left out deliberately.

## Exact executed source/scaffold evidence

Authoritative head `ae395b1e271cd1795cdece521a9ff1013fe4c77d`:

- Player Experience Guard #9 / `34188393674`: SUCCESS.
- Hostile State Guard #14 / `34188393882`: SUCCESS.
- Unity Scaffold #95 / `34188393720`: SUCCESS.
- Flutter CI #1301 / `34188393792`: SUCCESS.

This is source/scaffold/repository evidence. It is not Unity Editor, Play Mode, CARGO V2 Unity APK, device, visual or FPS evidence.

## Unity runtime/build support state

PR #298 head `982cd09bce61d22507e6b36205c9276792dde0ca` is 0 commits behind the authority and changes exactly one file: `.github/workflows/cargo_v2_unity_runtime.yml`.

Unity Runtime Build #6 / `34188431147` failed closed at activation preflight before Unity launched. Checkout succeeded; Unity build and APK verification/upload were skipped; diagnostics upload succeeded.

Diagnostic artifact:

- id `10041326602`;
- `CARGO-V2-Unity-diagnostics-889bedd426eac185eb55e9e28bdac21b8dc28364`;
- `sha256:ffe9f5b395c03c44dd867ae53c9fbb89e5bafe3b762b748c83912ae5cbdee912`.

No Unity compile/import, Play Mode, APK, install/launch, device, visual or FPS PASS exists from this run. No credential or signing material has been fabricated.

## Product implementation currently integrated on PR #297

### 3D presentation and assets

- Premium source-controlled truck OBJ/MTL plus runtime Resources copy.
- Mission cargo/depot OBJ/MTL plus runtime Resources copy.
- WorldMap marker OBJ/MTL plus runtime Resources copy.
- Splash/Loading premium presentation and runtime binding with safe fallbacks.
- WorldMap runtime marker consumption while preserving interaction/state behavior.

### WorldMap, missions and player experience

- 20 Cairo/Dubai missions with deterministic metadata.
- Locked/available/completed progression, selection and persistence.
- Touch deploy and player-facing mobile input/back/pause handling.
- Playable truck mission with pickup, ordered checkpoints, delivery, timer, damage, recovery, retry, pause and abandon.
- Safe-area/responsive UI, persisted language/accessibility settings, reduced-motion behavior and player feedback hooks.

### Persistence, rewards and company

- Active-delivery autosave/resume with stable run identity.
- Corrupt/impossible/future-state fail-closed handling and recovery regressions.
- Completion handoff and next-mission progression.
- Idempotent delivery reward settlement.
- Company Coins/XP/rank, fleet ownership/selection, purchases and upgrades.
- Crash-consistent purchase/upgrade journaling.
- Capacity-aware contract truck recommendations; every generated mission recommendation must be able to carry its contract.

### Android/build evidence automation

- Unity pinned to 2022.3.75f1.
- Package `com.walka.cargov2`, version 2.0.0, min SDK 23, ARM64, IL2CPP, Linear color space.
- Deterministic build launcher and Unity batch build method.
- APK archive/ABI verifier and SHA-256 evidence contract.
- Fail-closed ADB install/launch smoke harness with synthetic/fake-ADB source regressions.

## Remaining hard gates

Before owner physical 3D play-test, the exact final candidate still needs genuine executed evidence for:

1. Unity import and C# compilation.
2. Unity validation and Play Mode execution.
3. Full startup/gameplay/settlement/unlock loop.
4. Runtime persistence/restart/crash/idempotency regressions.
5. Fleet/economy runtime behavior.
6. Real 3D import/material/scale/orientation/fallback and visual quality.
7. Measured performance/FPS.
8. CARGO V2 Unity ARM64/IL2CPP APK build and SHA-256.
9. APK install/launch and device/emulator smoke.
10. Final exact-target repository convergence.

## Execution rule

Continue autonomous closure while any independent source-controlled work can reduce final risk. PR #298 remains the sole Unity runtime support line; activation diagnostics never substitute for runtime acceptance. The terminal project state is reached only when every required gate is genuinely green and an installable final 3D APK exists. Only then may status become `FINAL_OWNER_3D_TEST_REQUIRED`.