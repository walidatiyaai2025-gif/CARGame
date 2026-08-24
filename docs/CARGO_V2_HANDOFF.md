# CARGO V2 CONTINUATION HANDOFF

Updated: 2026-08-24 13:24 Kuwait time

## Integration truth

- Authoritative integration branch before this handoff refresh: `cargo-v2` @ `095b5f990fa4b3526d2e440565c361e9ae5f84f8`.
- Team work targets `cargo-v2`, never `main` in this phase.
- CAPTAIN alone merges a team PR and only after QA records a verdict against the exact PR head being merged.
- No final APK/AAB build is allowed in the CARGO V2 phase.
- Never fabricate Unity Play Mode, FPS, video, CI, or QA evidence.

## Current active work

### PR #256 — ASSET_TEAM premium Art Pass
- Head: `fcca9f31c8452c5db191a76203ce7c81822c3bb6`.
- Flutter CI #1149 SUCCESS.
- Blocker: fresh exact-head Unity import/material/reference-fidelity QA.

### PR #257 — UI_TEAM Splash + Loading Art Pass
- Head: `29274e4453afc0d2787bd4037d64bf17687a649a`.
- Flutter CI #1158 SUCCESS.
- Blocker: Unity 2022.3 compile/Play Mode/visual QA.

### PR #259 — LOGIC_TEAM WorldMap progression
- Issue #258.
- Head: `7055f4679bbb5959d672bcdb3aecbebe89e9dfea`.
- STATIC PASS; Flutter CI #1160 SUCCESS.
- Blocker: Unity compile/import + progression Play Mode QA.

### PR #265 — DATA_TEAM WorldMap presentation metadata
- Issue #262.
- Head: `feaaebcd77576addc46b100a60957c6fcb1405fc`.
- STATIC PASS; Flutter CI #1161 SUCCESS.
- Blocker: Unity compile/import QA.

### PR #267 — ASSET_TEAM real WorldMap 3D marker pack
- Issue #266.
- Head: `5b504709cd5505d4d0c25380a3b8d0aa7ac9ba41`.
- Flutter CI #1163 SUCCESS.
- Blocker: Unity OBJ/MTL import, scale, orientation and material QA.

### PR #268 — UI_TEAM WorldMap runtime
- Issue #260.
- Head: `1e3a01ecd4849c769762ed5eaf8bf5f6cb0d742f`.
- STATIC PASS; Flutter CI #1166 SUCCESS.
- Blocker: Unity compile/Play Mode visual/runtime QA.

### PR #269 — LOGIC_TEAM progression persistence — stacked on #259
- Issue #263.
- Head: `7e1cb74584bc9c1f8b6187dd91c831ba803f35e4`.
- STATIC PASS; Flutter CI #1169 SUCCESS.
- Lifecycle hardening already fixes Splash/Loading -> later WorldMap installation through a de-duplicated `SceneManager.sceneLoaded` hook.
- Blocker: #259 integration, then reconcile/retarget and Unity transition/restart persistence QA.

### PR #271 — UI_TEAM mission deploy gateway — stacked on #268
- Issue #270.
- Head: `0aeabec78ea0f15c099fc2d76117765bd6d5c2bd`.
- STATIC PASS after a concrete lifecycle fix. Previous head `c22fe8a...` passed Flutter CI #1170; exact-head CI for `0aeabec...` is pending/not yet visible at this refresh.
- Current head registers a de-duplicated pre-load `SceneManager.sceneLoaded` hook so Splash/Loading cannot prevent later WorldMap CTA installation; it also cleans runtime material lifetime and rolls back transient handoff state if scene loading throws.
- Blocker: exact-head CI, #268 integration, reconcile/retarget, then Unity deploy transition QA.

## QA preview branch

`cargo-v2-artpass-runtime-apply` is for local Play Mode review only. It is not a merge bypass and does not waive #256/#257 exact-head QA.

## Open no-downtime queue

1. #258 LOGIC — IMPLEMENTED / QA PENDING via #259.
2. #262 DATA — IMPLEMENTED / QA PENDING via #265.
3. #266 ASSET — IMPLEMENTED / QA PENDING via #267.
4. #260 UI — IMPLEMENTED / QA PENDING via #268.
5. #263 LOGIC persistence — IMPLEMENTED STACKED FOLLOW-UP via #269.
6. #270 UI deploy — IMPLEMENTED STACKED FOLLOW-UP via #271.
7. #261 QA — ACTIVE across exact heads.
8. #264 LEAD — operational handoff umbrella.

## Incoming-agent rule

Before coding:
1. Read this file.
2. Read issue #264 and the issue assigned to your team.
3. Reconcile the team branch from latest `cargo-v2` unless the issue explicitly requires a stacked dependency branch.
4. Retain the folder lock and work only inside that team's ownership.
5. Do not duplicate an IMPLEMENTED task.
6. If all feature branches are blocked on Unity evidence, perform exact-head CI/static QA and fix concrete source defects found.
7. Stop at `READY FOR QA`; do not self-merge.

## Folder ownership

- UI_TEAM: `/Assets/_Project/UI/` and approved scene files.
- LOGIC_TEAM: `/Assets/_Project/Scripts/Logic/`.
- ASSET_TEAM: `/Assets/_Project/Generated/`.
- DATA_TEAM: `/Assets/_Project/Data/`.
- QA_TEAM: `/Assets/_Project/QA/` plus QA report evidence.
- LEAD: `/docs/`.

## Required integration order

Subject to exact-head QA:
1. #256 premium assets.
2. #257 Splash + Loading after approved #256 reconcile.
3. #259 WorldMap progression.
4. #265 presentation metadata.
5. #267 real WorldMap markers.
6. #268 WorldMap runtime after approved logic/data/assets reconcile.
7. #269 persistence after #259 integration.
8. #271 mission deploy after #268 integration.

CAPTAIN may change order only for a concrete technical dependency and must document the reason.
