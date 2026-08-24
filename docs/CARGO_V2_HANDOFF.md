# CARGO V2 CONTINUATION HANDOFF

Updated: 2026-08-24 14:29 Kuwait time

## Integration truth

- Authoritative integration branch before this handoff refresh: `cargo-v2` @ `0de7f41abeae20d9b68c3048f5c523968e9cd6dc`.
- Team work targets `cargo-v2`, never `main` in this phase.
- CAPTAIN alone merges a team PR and only after QA records a verdict against the exact PR head being merged.
- No final APK/AAB build is allowed in the CARGO V2 phase.
- Never fabricate Unity Play Mode, FPS, video, CI, or QA evidence.

## Current active work

### PR #256 — ASSET_TEAM premium Art Pass
- Head: `fcca9f31c8452c5db191a76203ce7c81822c3bb6`.
- Flutter CI #1149 SUCCESS.
- Blocker: exact-head Unity import/material/reference-fidelity QA.

### PR #257 — UI_TEAM Splash + Loading Art Pass
- Head: `29274e4453afc0d2787bd4037d64bf17687a649a`.
- Flutter CI #1158 SUCCESS.
- Blocker: Unity compile/Play Mode/visual QA.

### PR #259 — LOGIC_TEAM WorldMap progression
- Issue #258; head `7055f4679bbb5959d672bcdb3aecbebe89e9dfea`.
- STATIC PASS; Flutter CI #1160 SUCCESS.
- Blocker: Unity progression QA.

### PR #265 — DATA_TEAM WorldMap presentation metadata
- Issue #262; head `feaaebcd77576addc46b100a60957c6fcb1405fc`.
- STATIC PASS; Flutter CI #1161 SUCCESS.
- Blocker: Unity compile/import QA.

### PR #267 — ASSET_TEAM real WorldMap marker pack
- Issue #266; head `5b504709cd5505d4d0c25380a3b8d0aa7ac9ba41`.
- Flutter CI #1163 SUCCESS.
- Blocker: Unity OBJ/MTL import, scale, orientation and material QA.

### PR #268 — UI_TEAM WorldMap runtime
- Issue #260; head `1e3a01ecd4849c769762ed5eaf8bf5f6cb0d742f`.
- STATIC PASS; Flutter CI #1166 SUCCESS.
- Blocker: Unity visual/runtime QA.

### PR #269 — LOGIC_TEAM progression persistence — stacked on #259
- Issue #263; head `7e1cb74584bc9c1f8b6187dd91c831ba803f35e4`.
- STATIC PASS; Flutter CI #1169 SUCCESS.
- Blocker: #259 integration, reconcile/retarget, Unity transition/restart persistence QA.

### PR #271 — UI_TEAM mission deploy — stacked on #268
- Issue #270; head `0aeabec78ea0f15c099fc2d76117765bd6d5c2bd`.
- STATIC PASS; Flutter CI #1171 SUCCESS.
- Lifecycle hardening installs through later Splash/Loading -> WorldMap scene loads and rolls back failed transitions.
- Blocker: #268 integration, reconcile/retarget, Unity deploy transition QA.

### PR #273 — ASSET_TEAM first Mission 3D cargo/depot pack
- Issue #272; head `bba3567a94e4ee998235b0b20bed437e2eea2fd0`.
- Flutter CI #1172 SUCCESS.
- Blocker: Unity OBJ/MTL import, scale/orientation and material QA.

### PR #275 — UI_TEAM first playable in-place Mission runtime — stacked on #271
- Issue #274; head `6d0748205f2792e2eff54399e5b44274a23ad569`.
- STATIC PASS after fixing duplicate-deploy/pending-handoff lifecycle defects.
- Previous head `4d217da...` Flutter CI #1173 SUCCESS; exact-head Flutter CI #1176 IN PROGRESS.
- Runtime now rejects duplicate deploy while active, clears stale completion on fresh launch, clears pending mission state on teardown, caches active runtime state, and guards pre-initialization paths.
- Blocker: exact-head CI, #271/#268 integration chain, Unity playable-flow QA.

### PR #277 — LOGIC_TEAM Mission completion handoff consumer — stacked on #269
- Issue #276; head `841496f6c81b4cee3a2214b5b1cf2e25cd3f9e7c`.
- STATIC PASS; Flutter CI #1178 QUEUED.
- Consumes `cargo_v2_completed_mission_handoff` only through authoritative `TryCompleteMission`, relies on #269 persistence, rejects gap-skips/out-of-range handoffs, and preserves valid handoff while route catalog is temporarily unavailable.
- Blocker: exact-head CI, #269/#259 integration chain, Unity completion->progression/persistence QA.

## QA preview branch

`cargo-v2-artpass-runtime-apply` is for local Play Mode review only. It is not a merge bypass and does not waive exact-head QA.

## Open no-downtime queue

1. #258 LOGIC — IMPLEMENTED / QA PENDING via #259.
2. #262 DATA — IMPLEMENTED / QA PENDING via #265.
3. #266 ASSET — IMPLEMENTED / QA PENDING via #267.
4. #260 UI — IMPLEMENTED / QA PENDING via #268.
5. #263 LOGIC persistence — IMPLEMENTED STACKED FOLLOW-UP via #269.
6. #270 UI deploy — IMPLEMENTED STACKED FOLLOW-UP via #271.
7. #272 ASSET Mission pack — IMPLEMENTED / QA PENDING via #273.
8. #274 UI playable Mission — IMPLEMENTED STACKED FOLLOW-UP via #275.
9. #276 LOGIC completion handoff — IMPLEMENTED STACKED FOLLOW-UP via #277.
10. #261 QA — ACTIVE across exact heads.
11. #264 LEAD — operational handoff umbrella.

## Incoming-agent rule

Before coding:
1. Read this file.
2. Read issue #264 and the issue assigned to your team.
3. Reconcile from latest `cargo-v2` unless the issue explicitly requires a stacked dependency branch.
4. Retain the folder lock and work only inside that team's ownership.
5. Do not duplicate an IMPLEMENTED task.
6. If all feature branches are blocked on Unity evidence, perform exact-head CI/static QA and fix concrete source defects found; a newly exposed cross-feature gap may be opened only when it has a clear owner and dependency chain.
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
5. #267 WorldMap markers.
6. #268 WorldMap runtime after approved logic/data/assets reconcile.
7. #269 persistence after #259 integration.
8. #271 mission deploy after #268 integration.
9. #273 Mission asset pack when its Unity import QA passes; its fallback is not a blocker for #275 source work.
10. #275 playable Mission after #271 integration.
11. #277 completion handoff after #269 integration; final combined QA must include #275 success handoff.

CAPTAIN may change order only for a concrete technical dependency and must document the reason.
