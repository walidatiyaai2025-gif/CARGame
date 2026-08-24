# CARGO V2 REPORT HOUR 21

## STATUS: 93%

Authoritative integration branch before this report update: `cargo-v2` @ `5d8c442b3ad41030982006c22f75672466d5eca9`. No team PR was merged during this cycle. This commit updates LEAD documentation only. `cargo-v2` is not merged to `main`, and no final APK/AAB is produced.

Progress moved from 90% to 93% because the previously-pending real playable Mission exact-head CI and real Mission Resources admission CI are now green, and the next concrete gameplay gap — mission completion rewards — has been implemented as a separately QA-gated LOGIC follow-up instead of being left for owner return.

## ASSET_TEAM
### PR #256 — Premium Art Pass assets
- OPEN + DRAFT.
- Head: `fcca9f31c8452c5db191a76203ce7c81822c3bb6`.
- Flutter CI #1149: **SUCCESS**.
- Real premium truck OBJ/MTL with deterministic Unity metadata.
- Unity import/material/reference-fidelity QA still missing.
- Older than current `cargo-v2`; reconcile required before final merge consideration.

Status: **IMPLEMENTED / CI PASS / UNITY QA HOLD**.

### PR #267 — Real 3D WorldMap marker pack
- Issue #266.
- Head: `5b504709cd5505d4d0c25380a3b8d0aa7ac9ba41`.
- Flutter CI #1163: **SUCCESS**.
- Actual-depth OBJ/MTL mission marker, route pylon and city beacon.
- Unity import/scale/material QA pending.

Status: **IMPLEMENTED / CI PASS / UNITY QA HOLD**.

### PR #273 — Mission gameplay 3D cargo/depot pack
- Issue #272.
- Head: `bba3567a94e4ee998235b0b20bed437e2eea2fd0`.
- Flutter CI #1172: **SUCCESS**.
- Project-original actual-depth CargoCrate, CargoCrateBand, DepotPallet, route gate and checkpoint beacon.
- Navy / Cargo Gold / Chrome / Beacon material separation and deterministic Unity metadata.
- Unity import/scale/material QA pending.

Status: **IMPLEMENTED / CI PASS / UNITY QA HOLD**.

### PR #279 — Runtime-admitted Mission 3D pack
- Issue #278.
- Stacked on PR #273.
- Exact head: `c34d4f7ea7dd75f2fe846161ded97d6f1e8967a4`.
- Flutter CI #1179: **SUCCESS**.
- Real Mission OBJ/MTL is additionally admitted under `Assets/Resources/CargoV2/Mission/` with deterministic importer GUIDs.
- Intended runtime path remains `Resources.Load<GameObject>("CargoV2/Mission/MOD_Mission_CargoDepot")`.
- Unity Resources import/load is **NOT** claimed until observed.

Status: **IMPLEMENTED / CI PASS / STACKED UNITY QA HOLD**.

## UI_TEAM
### PR #257 — Premium Splash + Loading
- OPEN + DRAFT.
- Head: `29274e4453afc0d2787bd4037d64bf17687a649a`.
- Flutter CI #1158: **SUCCESS**.
- Premium runtime Art Pass and real truck OBJ auto-binding implemented.
- Unity Play Mode visual QA pending.

Status: **IMPLEMENTED / CI PASS / UNITY QA HOLD**.

### PR #268 — WorldMap runtime visual integration
- Issue #260.
- Head: `1e3a01ecd4849c769762ed5eaf8bf5f6cb0d742f`.
- Flutter CI #1166: **SUCCESS**.
- QA: **STATIC PASS / UNITY HOLD**.
- Exactly 20 mission nodes, premium route, non-color state cues and selected-mission detail board.
- Mission values sourced directly from `SO_GameBalance`.
- Dynamically consumes DATA #265 + LOGIC #259.

Status: **IMPLEMENTED / CI PASS / UNITY QA HOLD**.

### PR #271 — WorldMap mission deploy gateway
- Issue #270.
- Head: `0aeabec78ea0f15c099fc2d76117765bd6d5c2bd`.
- Flutter CI #1171: **SUCCESS**.
- QA: **STATIC PASS / UNITY HOLD**.
- Visible deploy CTA, authoritative locked/invalid rejection, duplicate-deploy protection, scene-load lifecycle hook and safe pending-state rollback.

Status: **IMPLEMENTED / CI PASS / STACKED UNITY QA HOLD**.

### PR #275 — First playable in-place Mission runtime + mobile WorldMap touch + real 3D binding
- Issue #274.
- Stacked on PR #271.
- Exact head: `106ccb171304891790b20cb6bd7d8df408e196af`.
- Flutter CI #1182: **SUCCESS**.
- QA: **STATIC PASS / UNITY HOLD**.
- Runtime path: deploy -> five cargo deliveries -> timer -> success/fail -> retry/back.
- Mission cargo supports explicit touch-end camera raycasts and desktop/Editor mouse input.
- HUD touch exclusion prevents cargo delivery behind the Mission overlay.
- Android Back / Escape exits unfinished runtime without fake completion.
- `SCR_WorldMapTouchInputBridge` adds explicit mobile touch selection/deploy on WorldMap and disables map touches while Mission runtime is active.
- Runtime prefers `Resources.Load<GameObject>("CargoV2/Mission/MOD_Mission_CargoDepot")` and validates named parts before using the actual 3D pack.
- Real crate/band meshes receive explicit colliders; safe primitive fallback remains when resource admission is absent/incomplete.
- Success writes only transient `cargo_v2_completed_mission_handoff`; UI does not own progression or rewards.

Status: **IMPLEMENTED / EXACT-HEAD CI PASS / STACKED UNITY QA HOLD**.

## LOGIC_TEAM
### PR #259 — WorldMap progression core
- Head: `7055f4679bbb5959d672bcdb3aecbebe89e9dfea`.
- Flutter CI #1160: **SUCCESS**.
- QA: **STATIC PASS / UNITY HOLD**.
- Locked / Available / Completed progression, selection, gap-skip rejection and authoritative mission-node binding.

Status: **IMPLEMENTED / CI PASS / UNITY QA HOLD**.

### PR #269 — SaveManager progression persistence bridge
- Issue #263.
- Head: `7e1cb74584bc9c1f8b6187dd91c831ba803f35e4`.
- Flutter CI #1169: **SUCCESS**.
- Stacked on #259.
- Persists schema-v1 highest-completed + selected mission only.
- Corrupt/future/out-of-range state fails safely.

Status: **IMPLEMENTED / CI PASS / STACKED UNITY QA HOLD**.

### PR #277 — Mission completion handoff consumer
- Issue #276.
- Exact head: `841496f6c81b4cee3a2214b5b1cf2e25cd3f9e7c`.
- Flutter CI #1178: **SUCCESS**.
- QA: **STATIC PASS / UNITY HOLD**.
- Consumes `cargo_v2_completed_mission_handoff` through authoritative `SCR_WorldMapRouteController.TryCompleteMission` only.
- Retains valid handoff while route catalog is temporarily unavailable.
- Invalid/out-of-range/gap-skipping handoffs are rejected.
- PR #269 remains progress persistence owner.

Status: **IMPLEMENTED / CI PASS / STACKED UNITY QA HOLD**.

### PR #281 — Idempotent mission reward settlement
- New issue #280.
- Stacked on PR #277 -> #269 -> #259.
- Exact head: `eb4252363ebc25130a69664d1187d988502376d2`.
- Flutter CI #1183: **QUEUED** at this checkpoint; no PASS is claimed yet.
- Adds schema-v1 `SCR_MissionRewardStore` for mission-earned Coins + XP + rewarded mission IDs.
- Reward values are read only from authoritative `SO_GameBalance.MissionBalance`.
- First authoritative completion settles exactly the approved minimum `coin1Star + xp`; no invented 2-star/3-star scoring or multiplier.
- Reward settlement is idempotent per mission ID; replay/restart/duplicate handoff cannot double-grant.
- Corrupt/future/negative/duplicate reward payload and overflow fail closed without granting.
- Completion handoff is retained if reward persistence cannot be completed safely, allowing idempotent retry after progression has already accepted the mission.
- Invalid/non-sequential completion still grants zero.

Status: **IMPLEMENTED / EXACT-HEAD CI PENDING / STATIC QA PENDING / STACKED UNITY QA HOLD**.

## DATA_TEAM
### PR #265 — WorldMap presentation metadata
- Head: `feaaebcd77576addc46b100a60957c6fcb1405fc`.
- Flutter CI #1161: **SUCCESS**.
- QA: **STATIC PASS / UNITY HOLD**.
- Exactly 20 deterministic records: Cairo 1-10 / Dubai 11-20.
- Presentation layout only; no mission economy copied.

Status: **IMPLEMENTED / CI PASS / UNITY QA HOLD**.

## QA_TEAM
Issue #261 remains the active exact-head QA gate.

Current truthful evidence:
- #256: **CI SUCCESS / UNITY QA HOLD**.
- #257: **CI SUCCESS / UNITY QA HOLD**.
- #259: **STATIC PASS + CI SUCCESS / UNITY HOLD**.
- #265: **STATIC PASS + CI SUCCESS / UNITY HOLD**.
- #267: **CI SUCCESS / UNITY IMPORT-VISUAL QA HOLD**.
- #268: **STATIC PASS + CI SUCCESS / UNITY HOLD**.
- #269: **CI SUCCESS / STACKED UNITY HOLD**.
- #271: **STATIC PASS + CI SUCCESS / STACKED UNITY HOLD**.
- #273: **REAL 3D MISSION ASSETS + CI SUCCESS / UNITY IMPORT QA HOLD**.
- #275 exact head `106ccb171...`: **STATIC PASS + CI #1182 SUCCESS / UNITY HOLD**.
- #277: **STATIC PASS + CI #1178 SUCCESS / STACKED UNITY HOLD**.
- #279 exact head `c34d4f7e...`: **REAL RESOURCES 3D ADMISSION + CI #1179 SUCCESS / UNITY Resources.Load HOLD**.
- #281 exact head `eb425236...`: **SOURCE IMPLEMENTED / CI #1183 QUEUED / UNITY HOLD**.
- FPS: **NOT MEASURED**.
- Current-head Unity runtime video: **NOT AVAILABLE**.

### QA bugs / source defects resolved to date
- Splash/Loading SVG import was removed as a hard blocker for the authoritative 3D truck path; real OBJ remains the truck authority.
- Persistence/deploy/completion installers were hardened against Splash -> Loading -> WorldMap lifecycle misses using scene-load hooks.
- Mission completion handoff is retained while authoritative route data is not ready.
- Mobile Mission input no longer depends only on `OnMouseUpAsButton`; explicit touch raycast + HUD exclusion + Android Back are source-covered.
- Mobile WorldMap selection/deploy no longer depends only on mouse callbacks; explicit touch routing is source-covered and blocked behind the active Mission overlay.
- Reward gap identified this cycle: progression completion previously unlocked the next mission but granted no Coins/XP. PR #281 now implements the minimum approved idempotent reward settlement from `SO_GameBalance`; CI/Unity evidence remains pending.

No QA PASS is inherited from older SHAs. No FPS, video, Unity import, Resources.Load or runtime evidence is fabricated.

## PLAYABLE PATH
Source-controlled implementation now covers:

`Splash/Loading (#257 + #256) -> WorldMap route (#268 + #267) -> mission metadata (#265) -> progression (#259) -> progression persistence (#269) -> DEPLOY (#271) -> playable touch/click Mission (#275) -> completion handoff (#277) -> Mission completed / next mission available -> minimum approved Coins + XP settlement (#281)`, with real Mission 3D geometry from #273 and runtime Resources admission in #279.

The current source boundary is materially playable, but final truth still depends on Unity Play Mode evidence for actual import/render/input/runtime composition. The reward step intentionally uses only the approved `coin1Star + xp` values; higher-star scoring remains unimplemented rather than invented.

## BLOCKERS
1. No Unity 2022.3 exact-head runtime QA PASS yet for the integrated CARGO V2 chain.
2. Direct LEAD/report commits keep advancing `cargo-v2`; team PRs must be reconciled before final CAPTAIN merge consideration.
3. Stacked dependencies remain: #269 -> #259; #277 -> #269; #281 -> #277; #271 -> #268; #275 -> #271; #279 -> #273. No child may bypass its parent gate.
4. PR #281 exact-head Flutter CI #1183 is queued; no source-green claim yet.
5. Actual OBJ scale/orientation/materials, `Resources.Load`, collider readability, touch behavior and full runtime composition require Unity Play Mode observation.
6. No authoritative higher-star scoring/result calculation exists yet; this cycle deliberately grants only the approved minimum completion reward rather than inventing a scoring formula.
7. No measured FPS evidence exists.
8. No trustworthy current-head Unity Play Mode video exists.

## NEXT ACTIONS
1. Read exact-head CI #1183 for PR #281; if source failure appears, fix it on the same LOGIC branch before any further feature work.
2. Static-QA PR #281 for idempotency/fail-closed behavior, then retain Unity HOLD until actual Play Mode observation.
3. Build a reconciled CAPTAIN QA preview only — not a merge bypass — containing the approved current heads needed for `Splash -> Loading -> WorldMap -> Deploy -> real 3D Mission -> completion -> Mission 2 unlock -> persistence -> Coins/XP once`.
4. Unity QA must verify real Mission Resources load, actual crate colliders, touch/click delivery, HUD exclusion, Android-back-equivalent behavior, success/fail/retry/back cleanup, completion replay idempotency and reward replay idempotency.
5. Verify restart restores progression and that a previously rewarded mission does not grant Coins/XP again.
6. Record FPS only from measured current-head Play Mode evidence and video only from a real current-head recording.
7. CAPTAIN alone merges exact-head QA-PASS team PRs into `cargo-v2`.

## CAPTAIN GOVERNANCE
**CAPTAIN alone may merge team PRs into `cargo-v2`, and only after QA evidence is recorded against the exact head being merged.**

No merge of `cargo-v2` to `main`. No final APK/AAB build.

## VIDEO
**PENDING — no trustworthy current-head Unity Play Mode recording exists, so no video link is claimed.**

## FPS
**PENDING — no measured current-head Unity Play Mode FPS evidence exists.**
