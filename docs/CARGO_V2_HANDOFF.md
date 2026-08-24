# CARGO V2 CONTINUATION HANDOFF

Updated: 2026-08-24 16:34 Kuwait time

## Integration truth

- Authoritative integration branch before this handoff refresh: `cargo-v2` @ `87f5b2bad9424b1a16adf9e1a335ddb120c1de3c`.
- Team PRs target `cargo-v2`, never `main` in this phase.
- CAPTAIN alone merges after QA records an exact-head PASS.
- No final APK/AAB build is allowed in this phase.
- Never fabricate Unity Play Mode, FPS, video, CI, or runtime evidence.

## Active foundations

- PR #256 ASSET premium Art Pass — Flutter CI #1149 SUCCESS; Unity QA pending.
- PR #257 UI Splash + Loading — Flutter CI #1158 SUCCESS; Unity visual/runtime QA pending.
- PR #259 LOGIC WorldMap progression @ `7055f4679bbb5959d672bcdb3aecbebe89e9dfea` — STATIC PASS; Flutter CI #1160 SUCCESS; Unity progression QA pending.
- PR #265 DATA WorldMap metadata @ `feaaebcd77576addc46b100a60957c6fcb1405fc` — STATIC PASS; Flutter CI #1161 SUCCESS; Unity compile/import QA pending.
- PR #267 ASSET WorldMap markers @ `5b504709cd5505d4d0c25380a3b8d0aa7ac9ba41` — Flutter CI #1163 SUCCESS; Unity import/material QA pending.
- PR #268 UI WorldMap runtime @ `1e3a01ecd4849c769762ed5eaf8bf5f6cb0d742f` — STATIC PASS; Flutter CI #1166 SUCCESS; Unity visual/runtime QA pending.

## Stacked playable-flow chain

- PR #269 LOGIC persistence stacked on #259 @ `7e1cb74584bc9c1f8b6187dd91c831ba803f35e4` — STATIC PASS; Flutter CI #1169 SUCCESS; dependency integration + Unity persistence QA pending.
- PR #271 UI deploy stacked on #268 @ `0aeabec78ea0f15c099fc2d76117765bd6d5c2bd` — STATIC PASS; Flutter CI #1171 SUCCESS; dependency integration + Unity deploy QA pending.
- PR #273 ASSET Mission pack @ `bba3567a94e4ee998235b0b20bed437e2eea2fd0` — Flutter CI #1172 SUCCESS; Unity import/material QA pending.
- PR #277 LOGIC completion handoff stacked on #269 @ `841496f6c81b4cee3a2214b5b1cf2e25cd3f9e7c` — STATIC PASS; Flutter CI #1178 SUCCESS; dependency integration + Unity completion/progression QA pending.
- PR #279 ASSET Mission Resources admission stacked on #273 @ `c34d4f7ea7dd75f2fe846161ded97d6f1e8967a4` — Flutter CI #1179 SUCCESS; Unity import/Resources.Load QA pending.
- PR #275 UI playable Mission stacked on #271 @ `106ccb171304891790b20cb6bd7d8df408e196af` — STATIC PASS / UNITY HOLD. Previous head `aaa1679d...` passed Flutter CI #1181; fresh exact-head CI #1182 is queued.

## Latest programming checkpoint — full Android touch path

Static QA found a second mobile gap after Mission cargo touch was hardened: WorldMap mission nodes and Deploy still depended on `OnMouseUpAsButton`.

PR #275 exact head `106ccb171304891790b20cb6bd7d8df408e196af` adds `SCR_WorldMapTouchInputBridge`:
- installs only on WorldMap scenes using lifecycle-safe scene hooks;
- handles `TouchPhase.Ended` and raycasts through an active scene camera;
- routes `MissionNode_XX` touches into the existing WorldMap selection entry point;
- routes `DeployMissionButton` touches into the existing deploy gateway;
- does not duplicate progression or economy rules;
- disables map touch routing while the in-place Mission runtime is active;
- keeps mouse callbacks for Editor/desktop.

Mission-side protections remain: explicit touch delivery, HUD exclusion, Android Back / Escape, duplicate-deploy guards, transient completion handoff and cleanup.

## QA focus for the new head

Unity exact-head QA must prove:
1. available/completed mission nodes can be selected by touch; locked nodes remain rejected;
2. Deploy touch starts exactly one mission even if Unity also simulates a mouse callback;
3. WorldMap touches cannot fire while the in-place Mission overlay is active;
4. Mission cargo touch and mouse each deliver once;
5. HUD touch does not deliver cargo behind controls;
6. Android-back-equivalent Escape exits unfinished Mission without completion;
7. success -> completion handoff -> authoritative progression -> persistence remains single-shot;
8. real Resources Mission pack loads when admitted, otherwise fallback is safe.

## Open no-downtime queue

1. #258 LOGIC progression — IMPLEMENTED / QA PENDING via #259.
2. #262 DATA metadata — IMPLEMENTED / QA PENDING via #265.
3. #266 ASSET WorldMap markers — IMPLEMENTED / QA PENDING via #267.
4. #260 UI WorldMap runtime — IMPLEMENTED / QA PENDING via #268.
5. #263 LOGIC persistence — IMPLEMENTED STACKED via #269.
6. #270 UI deploy — IMPLEMENTED STACKED via #271.
7. #272 ASSET Mission pack — IMPLEMENTED / QA PENDING via #273.
8. #274 UI playable Mission — IMPLEMENTED STACKED via #275; exact-head CI #1182 pending after WorldMap touch hardening.
9. #276 LOGIC completion handoff — IMPLEMENTED STACKED via #277.
10. #278 ASSET Mission Resources admission — IMPLEMENTED STACKED via #279.
11. #261 QA — ACTIVE across exact heads.
12. #264 LEAD — operational handoff umbrella.

## Incoming-agent rule

Before coding:
1. Read this file and issue #264.
2. Respect team folder ownership.
3. Reconcile from latest `cargo-v2` unless the work is explicitly stacked on an unmerged dependency branch.
4. Do not duplicate an IMPLEMENTED task.
5. If feature work is blocked only on Unity, inspect exact-head CI/static source and fix only concrete source defects.
6. Stop at READY FOR QA; do not self-merge.

## Folder ownership

- UI_TEAM: `/Assets/_Project/UI/` and approved scene files.
- LOGIC_TEAM: `/Assets/_Project/Scripts/Logic/`.
- ASSET_TEAM: `/Assets/_Project/Generated/` and approved `/Assets/Resources/CargoV2/` runtime-admission copies.
- DATA_TEAM: `/Assets/_Project/Data/`.
- QA_TEAM: `/Assets/_Project/QA/` plus QA evidence.
- LEAD: `/docs/`.

## Required integration order

Subject to exact-head QA:
1. #256 premium assets.
2. #257 Splash + Loading after #256 reconcile.
3. #259 progression.
4. #265 metadata.
5. #267 WorldMap markers.
6. #268 WorldMap runtime after approved logic/data/assets reconcile.
7. #269 persistence after #259 integration.
8. #271 deploy after #268 integration.
9. #273 Mission asset pack.
10. #279 Resources admission after #273 integration.
11. #275 playable Mission after #271 integration and reconciled asset availability.
12. #277 completion handoff after #269 integration; combined QA must include #275 success handoff.

CAPTAIN may change this order only for a concrete dependency and must document the reason.
