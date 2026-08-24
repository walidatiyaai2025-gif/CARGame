# CARGO V2 CONTINUATION HANDOFF

Updated: 2026-08-24 15:31 Kuwait time

## Integration truth

- Authoritative integration branch before this handoff refresh: `cargo-v2` @ `694ad625c215b614f78a7608e2ffd5d1706aaaa2`.
- Team work targets `cargo-v2`, never `main` in this phase.
- CAPTAIN alone merges a team PR and only after QA records a verdict against the exact PR head being merged.
- No final APK/AAB build is allowed in the CARGO V2 phase.
- Never fabricate Unity Play Mode, FPS, video, CI, or QA evidence.

## Active work

### Art Pass / WorldMap foundations
- PR #256 ASSET premium Art Pass @ `fcca9f31c8452c5db191a76203ce7c81822c3bb6` — Flutter CI #1149 SUCCESS; Unity import/material/reference-fidelity QA pending.
- PR #257 UI Splash + Loading @ `29274e4453afc0d2787bd4037d64bf17687a649a` — Flutter CI #1158 SUCCESS; Unity visual/runtime QA pending.
- PR #259 LOGIC WorldMap progression @ `7055f4679bbb5959d672bcdb3aecbebe89e9dfea` — STATIC PASS; Flutter CI #1160 SUCCESS; Unity progression QA pending.
- PR #265 DATA WorldMap metadata @ `feaaebcd77576addc46b100a60957c6fcb1405fc` — STATIC PASS; Flutter CI #1161 SUCCESS; Unity compile/import QA pending.
- PR #267 ASSET WorldMap markers @ `5b504709cd5505d4d0c25380a3b8d0aa7ac9ba41` — Flutter CI #1163 SUCCESS; Unity import/scale/material QA pending.
- PR #268 UI WorldMap runtime @ `1e3a01ecd4849c769762ed5eaf8bf5f6cb0d742f` — STATIC PASS; Flutter CI #1166 SUCCESS; Unity visual/runtime QA pending.

### Stacked playable-flow chain
- PR #269 LOGIC persistence stacked on #259 @ `7e1cb74584bc9c1f8b6187dd91c831ba803f35e4` — STATIC PASS; Flutter CI #1169 SUCCESS; dependency integration + Unity persistence QA pending.
- PR #271 UI deploy stacked on #268 @ `0aeabec78ea0f15c099fc2d76117765bd6d5c2bd` — STATIC PASS; Flutter CI #1171 SUCCESS; dependency integration + Unity deploy QA pending.
- PR #273 ASSET Mission pack @ `bba3567a94e4ee998235b0b20bed437e2eea2fd0` — Flutter CI #1172 SUCCESS; Unity import/scale/material QA pending.
- PR #277 LOGIC completion handoff stacked on #269 @ `841496f6c81b4cee3a2214b5b1cf2e25cd3f9e7c` — STATIC PASS; Flutter CI #1178 SUCCESS; dependency integration + Unity completion/progression QA pending.
- PR #279 ASSET Mission Resources admission stacked on #273 @ `c34d4f7ea7dd75f2fe846161ded97d6f1e8967a4` — Flutter CI #1179 SUCCESS; Unity import/Resources.Load QA pending.
- PR #275 UI playable Mission stacked on #271 @ `aaa1679d2824493ea2f5420a072964b2ef0d2f2d` — STATIC PASS / UNITY HOLD. Prior head `2a7bbae4...` passed Flutter CI #1180; fresh exact-head CI #1181 is queued.

## Latest programming checkpoint — PR #275 mobile input hardening

Static review found a real Android source gap: the playable mission still depended only on `OnMouseUpAsButton` and had no explicit Back-button path.

Exact head `aaa1679d2824493ea2f5420a072964b2ef0d2f2d` now:
- handles `TouchPhase.Ended` with a raycast from the mission camera;
- resolves cargo targets through collider/parent lookup into the same idempotent `Deliver` path;
- excludes the HUD rectangle from world touch raycasts so GUI taps cannot deliver cargo behind controls;
- preserves Editor/desktop mouse clicks;
- handles Android Back / `KeyCode.Escape` by tearing down the in-place runtime and returning to the underlying WorldMap without fabricating completion;
- retains prior duplicate-deploy, stale-handoff, pending-state and initialization guards.

## QA preview branch

`cargo-v2-artpass-runtime-apply` remains for local Play Mode review only. It is not a merge bypass and does not waive exact-head QA.

## Open no-downtime queue

1. #258 LOGIC progression — IMPLEMENTED / QA PENDING via #259.
2. #262 DATA metadata — IMPLEMENTED / QA PENDING via #265.
3. #266 ASSET WorldMap markers — IMPLEMENTED / QA PENDING via #267.
4. #260 UI WorldMap runtime — IMPLEMENTED / QA PENDING via #268.
5. #263 LOGIC persistence — IMPLEMENTED STACKED via #269.
6. #270 UI deploy — IMPLEMENTED STACKED via #271.
7. #272 ASSET Mission pack — IMPLEMENTED / QA PENDING via #273.
8. #274 UI playable Mission — IMPLEMENTED STACKED via #275; exact-head CI #1181 pending after mobile input hardening.
9. #276 LOGIC completion handoff — IMPLEMENTED STACKED via #277.
10. #278 ASSET Mission Resources admission — IMPLEMENTED STACKED via #279; CI #1179 SUCCESS.
11. #261 QA — ACTIVE across exact heads.
12. #264 LEAD — operational handoff umbrella.

## Incoming-agent rule

Before coding:
1. Read this file.
2. Read issue #264 and the issue assigned to your team.
3. Reconcile from latest `cargo-v2` unless the issue explicitly requires a stacked dependency branch.
4. Retain the folder lock and work only inside that team's ownership.
5. Do not duplicate an IMPLEMENTED task.
6. If all feature branches are blocked on Unity evidence, perform exact-head CI/static QA and fix concrete source defects found; open a new cross-feature task only for a real source gap with a clear owner and dependency chain.
7. Stop at READY FOR QA; do not self-merge.

## Folder ownership

- UI_TEAM: `/Assets/_Project/UI/` and approved scene files.
- LOGIC_TEAM: `/Assets/_Project/Scripts/Logic/`.
- ASSET_TEAM: `/Assets/_Project/Generated/` and approved runtime-admission copies under `/Assets/Resources/CargoV2/`.
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
9. #273 Mission asset pack.
10. #279 Mission Resources admission after #273 integration.
11. #275 playable Mission after #271 integration and reconciled asset availability.
12. #277 completion handoff after #269 integration; final combined QA must include #275 success handoff.

CAPTAIN may change order only for a concrete technical dependency and must document the reason.
