# CARGO V2 AUTONOMOUS CLOSURE HANDOFF

Updated: 2026-09-08 (Kuwait)

## Authority

- Single authoritative integration/closure line: PR #297, branch `cargo-v2-autonomous-closure`, targeting `cargo-v2`.
- Exact authoritative head at this reconciliation: `ae395b1e271cd1795cdece521a9ff1013fe4c77d`.
- `main` is not the CARGO V2 integration target at this stage.
- PR #298 / `cargo-v2-unity-runtime-ci` is the only active Unity runtime/build support PR. It targets #297 and is not a second closure candidate.
- Live GitHub refs, ancestry, exact-head CI, artifacts, and executed runtime evidence override historical prose and stale claim text.

## Live concurrency/recovery sweep

The 2026-09-08 branch/claim sweep found no unintegrated current CARGO V2 implementation worker that should be merged before further closure work.

The previously advertised production-visual, gameplay-state-recovery, player-experience, hostile-state, delivery-recovery, Android-smoke, company-transaction, contract-capacity, mission/data/logic/world-map/runtime-asset and team branches are all exact ancestors of the authoritative line (`ahead_by=0`). Their work is already contained and must not be duplicated.

Legacy diverged branches were reviewed semantically rather than merged blindly:

- `cargo-v2-artpass-runtime-apply` and `cargo-v2-artpass-runtime-apply-v2` are identical. Their `SCR_ArtPassRuntimeDirector` and `SCR_PremiumTruck3D` blobs are exact-preserved in #297; the current `SCR_UIManager` is a later evolved implementation. The remaining editor-only auto-open preview helper is developer convenience, not product/runtime closure.
- `cargo-v2-paused-qa-sprint1` contains an old standalone FPS logger and a basic smoke component. It supplies no executed current-candidate performance evidence and is superseded by the current QA/runtime-contract infrastructure.
- `cargo-v2-ui-pre-override` contains primitive cube/cylinder intro presentation and synthetic loading progress and is superseded by the integrated premium art/runtime path.
- `cargo-v2-ui-team` is an older UI/scenes line; the authority contains later integrated UI and premium presentation work.

PR #298 remains the one legitimate unintegrated support exception. Its changed-file set is exactly `.github/workflows/cargo_v2_unity_runtime.yml` and its support head is 0 commits behind the authority.

## Current exact-head source/scaffold evidence

On authoritative head `ae395b1e271cd1795cdece521a9ff1013fe4c77d`:

- `CARGO V2 Player Experience Guard` #9 / run `34188393674`: SUCCESS.
- `CARGO V2 Hostile State Guard` #14 / run `34188393882`: SUCCESS.
- `CARGO V2 Unity Scaffold` #95 / run `34188393720`: SUCCESS.
- `Flutter CI` #1301 / run `34188393792`: SUCCESS.

These checks prove their stated source/scaffold contracts only. The Flutter debug APK produced by the repository-wide Flutter CI is not the final CARGO V2 Unity APK and cannot be used as Unity runtime evidence.

## Current Unity runtime/build evidence

PR #298 support head: `982cd09bce61d22507e6b36205c9276792dde0ca`.

`CARGO V2 Unity Runtime Build` #6 / run `34188431147` executed against PR merge candidate `889bedd426eac185eb55e9e28bdac21b8dc28364` and failed closed before Unity started:

- checkout exact candidate: PASS;
- Unity activation preflight: FAIL-CLOSED;
- Unity import/build step: SKIPPED;
- APK verification/evidence: SKIPPED;
- APK/build-evidence upload: SKIPPED;
- diagnostics upload: PASS.

Diagnostic artifact:

- id `10041326602`;
- name `CARGO-V2-Unity-diagnostics-889bedd426eac185eb55e9e28bdac21b8dc28364`;
- digest `sha256:ffe9f5b395c03c44dd867ae53c9fbb89e5bafe3b762b748c83912ae5cbdee912`.

No Unity import/C# compile, Play Mode, Unity Android APK, install/launch, device, visual, or FPS PASS is claimed from this run. No activation secret is invented or committed.

## Integrated product scope on PR #297

The authority currently composes the CARGO V2 Unity 2022.3.75f1 project/build scaffold; premium truck, Mission cargo/depot and WorldMap runtime 3D assets; Splash/Loading presentation; 20 Cairo/Dubai missions; selection/locking/progression/persistence/touch deploy; playable truck delivery loop; ordered pickup/checkpoints/delivery; pause/retry/recovery/abandon; active-delivery autosave/resume; corrupt-state quarantine; completion handoff and idempotent reward settlement; company Coins/XP/rank; fleet purchase/selection/upgrades; crash-consistent transaction recovery; capacity-safe truck recommendations; and deterministic Android APK verification/smoke tooling.

## Remaining hard gates before the final owner test

All must execute genuinely on the exact final candidate:

1. Unity 2022.3.75f1 import and C# compilation.
2. Unity validation and Play Mode startup/navigation.
3. Splash -> Loading -> WorldMap -> deploy -> pickup -> ordered checkpoints -> delivery -> settlement -> next unlock.
4. Pause/retry/recovery/abandon plus restart/crash-resume and replay/idempotency regressions.
5. Fleet purchase/upgrade runtime acceptance and non-negative economy invariants.
6. Real 3D asset import, scale/orientation/material/fallback and visual acceptance.
7. Measured current-candidate performance/FPS.
8. ARM64/IL2CPP CARGO V2 Unity APK build with SHA-256 evidence.
9. APK install/launch and available device/emulator smoke.
10. Final repository convergence and exact-target CI.

Only after every source/runtime/build/smoke gate above is green and an installable final 3D test APK exists may state become `FINAL_OWNER_3D_TEST_REQUIRED`.

## Pick-next rule

Re-read live state before every unit. Recover legitimate existing work first, preserve unrelated work, do not duplicate PR #298, and continue independent source-controlled automation/regression/evidence work while activation is unavailable. Re-check the Unity runtime gate whenever the authoritative candidate moves.