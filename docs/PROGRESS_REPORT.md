# CARGO V2 AUTONOMOUS CLOSURE REPORT

Updated: 2026-09-07 (Kuwait)

## Current authority

PR #297 / `cargo-v2-autonomous-closure` is the single authoritative CARGO V2 integration/closure line and targets `cargo-v2`. PR #298 is its Unity runtime/build support gate, not a competing closure candidate. The unrelated Flutter AST PR #249 remains outside this CARGO V2 closure effort.

## Convergence completed in this cycle

- Reviewed and normal-merged PR #300, the crash-consistent company purchase/upgrade transaction recovery change, into PR #297 after its exact-head `verify`, `scaffold`, and `company-transaction-recovery` checks all passed.
- Closed historical CARGO V2 Draft PRs #256, #257, #259, #265, #267, #268, #269, #271, #273, #275, #277, #279, #281, #283, #285, and #287 only after GitHub compare proved each head was already an ancestor of the authoritative closure line. No duplicate merge or history discard was performed.
- After this cleanup the only open CARGO V2 PRs are #297 and #298.

## Exact executed CI evidence

The pre-documentation reconciliation head of PR #297 was `7aa3e0642d645d257b1c1539442bc4d73aea0562`.

On that exact commit:

- `Flutter CI` #1232 / run `34159261418`: SUCCESS.
- `CARGO V2 Unity Scaffold` #28 / run `34159261431`: SUCCESS.

These checks establish source/scaffold correctness only. They do not prove Unity import/compile, Play Mode, APK creation, install/launch, device behavior, FPS, or visual quality.

## Unity runtime/build evidence

PR #298 exact support head `080673f6b90b66a5cba2eafbb81709dddcd8db37` ran `CARGO V2 Unity Runtime Build` #3 / `34157646725` and failed closed during activation preflight before Unity started.

Observed activation configuration booleans were all false for `UNITY_LICENSE`, `UNITY_SERIAL`, `UNITY_EMAIL`, and `UNITY_PASSWORD`. No secret value was exposed. No Unity compile/import/build/Play Mode/install/launch/FPS claim is made from that run.

Diagnostic artifact:

- id `10031509477`;
- `CARGO-V2-Unity-diagnostics-5decf061b0402971a87cc32c140b4f6ae619c05d`;
- `sha256:c0e862aa1669dc388223c11e6f6dd29e86da90f25ac5fc4dac6da4fd4610f493`.

## Product implementation currently integrated on PR #297

### 3D presentation and assets

- Premium source-controlled truck OBJ/MTL and runtime Resources copy.
- Source-controlled Mission cargo/depot OBJ/MTL and runtime Resources copy.
- Source-controlled WorldMap marker OBJ/MTL and runtime Resources copy.
- Splash/Loading presentation and runtime art binding with safe fallbacks.
- WorldMap real marker consumption while preserving authoritative interaction colliders/state cues.

### WorldMap and mission loop

- 20 missions split across Cairo and Dubai with deterministic presentation metadata.
- Locked/available/completed mission progression and selection.
- Local progression persistence and lifecycle-safe scene installation.
- Touch selection/deploy and Android-back-equivalent handling.
- Playable truck mission with cargo pickup, checkpoints 1 -> 2 -> 3, delivery, timer, collision damage, recovery, retry, pause, and abandon.
- Checkpoints cannot be banked before cargo pickup and delivery requires the final ordered checkpoint.

### Persistence, rewards, and company systems

- Active-delivery autosave/resume with run identity and corrupt/impossible state quarantine.
- Mission completion handoff and progression unlock.
- Idempotent delivery reward settlement keyed by delivery run identity.
- Company Coins/XP/rank, fleet ownership/selection, truck purchasing, and engine/handling/durability upgrades.
- Crash-consistent purchase/upgrade journaling with stable operation identity so replay does not double-debit.

### Android build/evidence tooling

- Unity pinned to 2022.3.75f1.
- Android package `com.walka.cargov2`, version 2.0.0, min SDK 23, ARM64, IL2CPP, Linear color space.
- Deterministic Windows launcher and Unity batch build method.
- APK verifier requires Unity/IL2CPP ARM64 payload and rejects unintended ABIs.
- SHA-256/evidence JSON contract exists for a genuinely produced APK.

## Static/source audit performed in this cycle

The current mission runtime and persistence chain was inspected for the highest-risk replay/order defects. The reviewed source enforces cargo-before-checkpoints, checkpoint order, final-checkpoint-before-delivery, stable active-delivery run identity, idempotent settlement retry, and corrupt-state rejection. This is source review only and is not represented as Unity runtime verification.

## Remaining hard gates

Before the owner may receive the final physical 3D play-test candidate, the exact final candidate still needs genuine evidence for:

1. Unity 2022.3.75f1 import and C# compilation.
2. Unity validation and Play Mode execution.
3. Splash -> Loading -> WorldMap -> deploy -> pickup -> checkpoints -> delivery -> settlement -> next mission unlock.
4. Pause/retry/recovery/abandon and restart/crash-resume regressions.
5. Fleet purchase/upgrade runtime acceptance and economy invariants.
6. Real 3D Resources scale/orientation/material/fallback and visual acceptance.
7. Measured performance/FPS on an executed current candidate.
8. Android ARM64/IL2CPP APK build on the exact candidate with SHA-256 evidence.
9. APK install and launch smoke and available device/emulator smoke.
10. Final repository convergence and exact-target CI after governed integration.

## Execution rule

Continue autonomous work while any executable independent task remains. Do not create a second Unity runtime worker while PR #298 is the active support line. Never substitute static/source checks for Unity or device evidence, and never invent credentials, signing material, screenshots, FPS numbers, artifacts, or PASS states.

The terminal project state is reached only when every source, asset, gameplay, UI, persistence, Unity, Android-build, smoke, regression, and convergence gate is genuinely green and an installable final 3D test APK exists. At that point, and only at that point, the status may become `FINAL_OWNER_3D_TEST_REQUIRED`.
