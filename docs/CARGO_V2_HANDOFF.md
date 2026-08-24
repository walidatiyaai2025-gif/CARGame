# CARGO V2 CONTINUATION HANDOFF

Updated: 2026-08-24 19:29 Kuwait time

## Integration truth

- Authoritative integration branch before this refresh: `cargo-v2` @ `7f26eb0e32d7ce961e5e88cfe10cb394e5495506`.
- Team PRs target `cargo-v2` or their explicit dependency branch; never `main` in this phase.
- CAPTAIN alone merges after QA records an exact-head PASS.
- No final APK/AAB build is allowed in this phase.
- Never fabricate Unity Play Mode, FPS, video, CI, or runtime evidence.

## Current dependency-safe checkpoint

### PR #285 — ASSET WorldMap Resources admission
- Issue #284.
- Exact head `59a879502b50b500c1f3e3439eec05075749419c`.
- Flutter CI #1187: SUCCESS.
- Adds `Assets/Resources/CargoV2/WorldMap/MOD_WorldMap_MarkerPack.obj/.mtl` as the runtime-addressable copy of the project-original marker pack.
- Unity import / `Resources.Load` / scale / material QA remains pending.

### PR #287 — UI real WorldMap marker consumption
- Issue #286.
- Stacked on PR #268 / `cargo-v2-ui-worldmap`.
- Exact head `3b662df54557bcc4426c8ea6838c0fe37dbe8e99`.
- Relation to UI base: ahead 1 / behind 0.
- Loads `CargoV2/WorldMap/MOD_WorldMap_MarkerPack` once, validates MissionMarker parts, and instantiates real project-original marker geometry for all 20 mission nodes when available.
- Non-mission renderers in the imported pack are disabled per node so route pylons/city beacons are not duplicated.
- Imported colliders are disabled; the existing mission-node collider/state halo remains the interaction authority and complete fallback.
- Static source review: PASS / UNITY HOLD.
- Exact-head CI has not reported a run yet at this refresh; do not inherit #1187 or #1166.

## Existing source-complete playable chain

- PR #256 ASSET premium Art Pass — CI #1149 SUCCESS; Unity QA pending.
- PR #257 UI Splash + Loading — CI #1158 SUCCESS; Unity QA pending.
- PR #259 LOGIC WorldMap progression — CI #1160 SUCCESS; Unity QA pending.
- PR #265 DATA WorldMap metadata — CI #1161 SUCCESS; Unity QA pending.
- PR #267 ASSET WorldMap Generated marker pack — CI #1163 SUCCESS; Unity QA pending.
- PR #268 UI WorldMap runtime — CI #1166 SUCCESS; Unity QA pending.
- PR #269 LOGIC persistence — CI #1169 SUCCESS; dependency integration + Unity QA pending.
- PR #271 UI deploy — CI #1171 SUCCESS; dependency integration + Unity QA pending.
- PR #273 ASSET Mission pack — CI #1172 SUCCESS; Unity QA pending.
- PR #277 LOGIC completion handoff — CI #1178 SUCCESS; dependency integration + Unity QA pending.
- PR #279 ASSET Mission Resources admission — CI #1179 SUCCESS; Unity QA pending.
- PR #281 LOGIC one-time mission Coins/XP settlement — CI #1183 SUCCESS; dependency integration + Unity QA pending.
- PR #283 QA read-only runtime/readiness tooling — latest exact-head CI must be read independently; structural output never substitutes for Play Mode QA.

## Pick-next rule

1. Read this file and issue #264.
2. Respect folder ownership.
3. Do not duplicate an IMPLEMENTED slice.
4. If PR #287 exact-head CI fails, fix only the concrete UI-source defect on the same branch.
5. If PR #287 CI passes, keep UNITY HOLD and advance only another concrete dependency-safe source gap or QA tooling gap.
6. Do not merge any team PR without exact-head QA PASS.

## Required Unity evidence still missing

The assembled preview must eventually prove on exact integrated heads:
- Splash -> Loading -> WorldMap;
- 20 real WorldMap marker instances loaded from Resources with correct scale/orientation/materials;
- touch selection/deploy with locked-node rejection and no duplicate callbacks;
- playable Mission touch/HUD/Back behavior;
- Resources-backed Mission asset loading with safe fallback;
- success -> completion -> unlock -> persistence -> one-time Coins/XP settlement;
- replay/idempotency and cleanup;
- actual FPS only if measured and current-head video only if genuinely recorded.

## Folder ownership

- UI_TEAM: `/Assets/_Project/UI/` and approved scene files.
- LOGIC_TEAM: `/Assets/_Project/Scripts/Logic/`.
- ASSET_TEAM: `/Assets/_Project/Generated/` and approved `/Assets/Resources/CargoV2/` runtime copies.
- DATA_TEAM: `/Assets/_Project/Data/`.
- QA_TEAM: `/Assets/_Project/QA/` plus QA evidence.
- LEAD: `/docs/`.
