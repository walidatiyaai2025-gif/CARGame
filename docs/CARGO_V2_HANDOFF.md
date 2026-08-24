# CARGO V2 CONTINUATION HANDOFF

Updated: 2026-08-24 10:18 Kuwait time

## Integration truth

- Authoritative CARGO V2 integration branch before this handoff commit: `cargo-v2` @ `958a0a312b48f433b3b9bfafbcd10417436da521`.
- Team work targets `cargo-v2`, never `main` in this phase.
- CAPTAIN alone merges a team PR and only after QA records a verdict against the exact PR head being merged.
- No final APK/AAB build is allowed in the CARGO V2 phase.
- Never fabricate Unity Play Mode, FPS, video, CI, or QA evidence.

## Current active work

### PR #256 — ASSET_TEAM premium Art Pass
- Head: `cargo-v2-asset-team` @ `fcca9f31c8452c5db191a76203ce7c81822c3bb6`.
- Contains premium SVG sources plus real `MOD_Truck_Premium.obj/.mtl` and deterministic Unity metadata.
- Exact-head Flutter CI #1149 passed historically.
- Merge blocker: fresh exact-head Unity import/material/reference-fidelity QA is not recorded.

### PR #257 — UI_TEAM Splash + Loading Art Pass
- Head: `cargo-v2-ui-art-pass` @ `29274e4453afc0d2787bd4037d64bf17687a649a`.
- Premium runtime director, real 3D truck binding, automatic model binder, navy/gold Splash and Loading composition.
- Flutter CI #1158 = SUCCESS on this exact UI head.
- Merge blocker: Unity 2022.3 compile/Play Mode/visual QA is still required.

### PR #259 — LOGIC_TEAM WorldMap progression core
- Issue: #258.
- Head: `cargo-v2-logic-team` @ `020a8a14ea4625a93933929cc5ec8d99007d10e6`.
- Branch relation when opened: ahead 1 / behind 0 from `cargo-v2`.
- Adds pure Locked/Available/Completed progression rules, `SCR_WorldMapRouteController`, and `SCR_WorldMapMissionNode`.
- Reads mission truth from merged `SO_GameBalance`; does not duplicate balance values or mutate rewards/economy/save truth.
- Flutter CI #1159 was IN PROGRESS at handoff creation.
- Merge blocker: exact-head QA + completed CI result.

## Art Pass QA preview branch

`cargo-v2-artpass-runtime-apply` @ `39a5e2bdd3c0060c1a8c3bc2248d6e96abf05192`.

Purpose: local Unity Play Mode visual review only. It combines the current premium 3D truck/runtime Art Pass and has an editor startup helper that opens `Assets/_Project/Scenes/01_Splash.unity` instead of leaving the user in an `Untitled` scene.

This preview branch is NOT an alternative merge path and does not waive #256/#257 QA.

## Open no-downtime queue

1. **#258 LOGIC — WorldMap progression core** — IN PROGRESS via PR #259.
2. **#260 UI — WorldMap visible route integration** — READY once the #259 API is available to the UI branch. Create 20 visible mission nodes, route states, selected mission details, mobile-safe layout.
3. **#261 QA — WorldMap progression and Art Pass gate** — READY. Review exact heads; static review can proceed immediately, Unity runtime evidence when available.
4. **#262 DATA — WorldMap presentation metadata** — READY in parallel. Add only deterministic presentation metadata keyed by mission ID; never copy balance values.
5. **#263 LOGIC — SaveManager progression persistence bridge** — BLOCKED until #259 is QA-approved.
6. **#264 LEAD — Continuation handoff queue** — operational umbrella for incoming agents.

## Incoming-agent rule

Before coding:
1. Read this file.
2. Read issue #264 and the issue assigned to your team.
3. Reconcile your branch from the latest `cargo-v2`.
4. Create/retain your folder lock.
5. Work only in the locked ownership area.
6. Push one focused feature checkpoint and open/update its PR to `cargo-v2`.
7. Stop at `READY FOR QA`; do not self-merge.

If your assigned dependency is blocked, take another READY issue for your own team only. Do not invent overlapping work.

## Folder ownership

- UI_TEAM: `/Assets/_Project/UI/` and approved scene files.
- LOGIC_TEAM: `/Assets/_Project/Scripts/Logic/`.
- ASSET_TEAM: `/Assets/_Project/Generated/`.
- DATA_TEAM: `/Assets/_Project/Data/`.
- QA_TEAM: `/Assets/_Project/QA/` plus QA report evidence.
- LEAD: `/docs/`.

## Product boundary while local viewing is unavailable

The user's temporary local Unity viewing problem does not block dependency-safe programming, data preparation, static QA, tests, or PR preparation. Continue those tracks. Only claims that require actual Unity visual/runtime evidence must remain pending until observed.

## Next integration order

Recommended dependency order, subject to exact-head QA:
1. #256 premium assets.
2. #257 Splash + Loading Art Pass after reconciling approved #256.
3. #259 WorldMap progression logic.
4. #262 WorldMap presentation metadata.
5. #260 visible WorldMap integration after approved logic/data APIs.
6. #263 SaveManager persistence bridge.

CAPTAIN may change order only for a concrete technical dependency and must document the reason.
