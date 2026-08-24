# CARGO V2 REPORT HOUR 22

## STATUS: 95%

Authoritative integration branch before this report update: `cargo-v2` @ `61b377ba041d27ae0a9e7825c4bfb3d594bb11bf`. This update is LEAD documentation only. No team PR is merged by this report commit, `cargo-v2` is not merged to `main`, and no final APK/AAB is produced.

Progress moves from 93% to 95% because mission reward settlement exact-head CI is now green and the active QA runtime probe also reached green CI on its previous head. Static review then found and fixed two concrete false-HOLD defects in that probe on a new exact head. Remaining completion is dominated by Unity 2022.3 assembled Play Mode evidence, branch reconciliation, and CAPTAIN-gated integration rather than missing first-playable-loop source code.

## ASSET_TEAM
- PR #256 — Premium Art Pass truck/logo assets — head `fcca9f31c8452c5db191a76203ce7c81822c3bb6`; Flutter CI #1149 **SUCCESS**; real OBJ/MTL; **UNITY QA HOLD**; reconcile required before merge consideration.
- PR #267 — real 3D WorldMap marker pack — head `5b504709cd5505d4d0c25380a3b8d0aa7ac9ba41`; Flutter CI #1163 **SUCCESS**; **UNITY IMPORT/VISUAL HOLD**.
- PR #273 — real Mission cargo/depot OBJ/MTL pack — head `bba3567a94e4ee998235b0b20bed437e2eea2fd0`; Flutter CI #1172 **SUCCESS**; **UNITY IMPORT/MATERIAL HOLD**.
- PR #279 — Mission 3D pack runtime-admitted under `Assets/Resources/CargoV2/Mission/` — head `c34d4f7ea7dd75f2fe846161ded97d6f1e8967a4`; Flutter CI #1179 **SUCCESS**; actual `Resources.Load` remains **UNITY HOLD**.

ASSET_TEAM status: **SOURCE IMPLEMENTED / CI GREEN / UNITY QA HOLD**.

## UI_TEAM
- PR #257 — Premium Splash + Loading — head `29274e4453afc0d2787bd4037d64bf17687a649a`; Flutter CI #1158 **SUCCESS**; **UNITY VISUAL HOLD**.
- PR #268 — 20-node WorldMap runtime — head `1e3a01ecd4849c769762ed5eaf8bf5f6cb0d742f`; Flutter CI #1166 **SUCCESS**; STATIC PASS / UNITY HOLD.
- PR #271 — WorldMap deploy gateway — head `0aeabec78ea0f15c099fc2d76117765bd6d5c2bd`; Flutter CI #1171 **SUCCESS**; STATIC PASS / STACKED UNITY HOLD.
- PR #275 — first playable in-place Mission runtime + mobile WorldMap touch + real 3D Resources binding — head `106ccb171304891790b20cb6bd7d8df408e196af`; Flutter CI #1182 **SUCCESS**; STATIC PASS / STACKED UNITY HOLD.

UI source path covers WorldMap touch selection -> Deploy -> five-cargo Mission -> timer -> success/fail/retry/back, explicit HUD touch exclusion, Android Back/Escape, transient completion handoff, real Mission model preference and primitive fallback.

UI_TEAM status: **PLAYABLE SOURCE IMPLEMENTED / CI GREEN / UNITY QA HOLD**.

## LOGIC_TEAM
- PR #259 — WorldMap progression core — head `7055f4679bbb5959d672bcdb3aecbebe89e9dfea`; Flutter CI #1160 **SUCCESS**; STATIC PASS / UNITY HOLD.
- PR #269 — progression persistence — head `7e1cb74584bc9c1f8b6187dd91c831ba803f35e4`; Flutter CI #1169 **SUCCESS**; stacked on #259; UNITY HOLD.
- PR #277 — Mission completion handoff -> authoritative progression — head `841496f6c81b4cee3a2214b5b1cf2e25cd3f9e7c`; Flutter CI #1178 **SUCCESS**; STATIC PASS / UNITY HOLD.
- PR #281 — idempotent mission Coins + XP settlement — head `eb4252363ebc25130a69664d1187d988502376d2`; Flutter CI #1183 **SUCCESS**; STATIC PASS / UNITY HOLD.

Reward truth remains conservative: first accepted mission completion settles exactly authoritative `coin1Star + xp` from `SO_GameBalance`, once per mission. Replay/restart/duplicate completion cannot double-grant; corrupt/future/negative/duplicate payloads and overflow fail closed. No invented 2-star/3-star formula is claimed.

LOGIC_TEAM status: **FIRST PLAYABLE PROGRESSION/PERSISTENCE/REWARD LOOP SOURCE-COMPLETE / CI GREEN / STACKED UNITY QA HOLD**.

## DATA_TEAM
- PR #265 — deterministic WorldMap presentation metadata — head `feaaebcd77576addc46b100a60957c6fcb1405fc`; Flutter CI #1161 **SUCCESS**; STATIC PASS / UNITY HOLD.
- Exactly 20 records, Cairo 1-10 / Dubai 11-20; presentation-only coordinates/route metadata; no mission economy duplicated.

DATA_TEAM status: **IMPLEMENTED / CI GREEN / UNITY COMPILE-INTEGRATION HOLD**.

## QA_TEAM
- Issue #261 remains the authoritative integrated QA gate.
- Issue #282 / PR #283 adds the read-only runtime contract probe.
- Previous PR #283 head `3af3cce0983d7e48d67e8dc5f364b95d1795f10d`: Flutter CI #1184 **SUCCESS**; STATIC PASS / UNITY HOLD.
- Static review found two real probe defects after that green run: it checked nonexistent completion type `SCR_MissionCompletionHandoffConsumer` instead of actual `SCR_MissionCompletionHandoffBridge`, and it checked nonexistent split Mission resource paths instead of the real `CargoV2/Mission/MOD_Mission_CargoDepot` path.
- Both defects are fixed on new PR #283 exact head `77e3312389cc4f4e406c3dedba566ad37302cb47`.
- The corrected probe now checks the actual Mission resource and required named 3D parts: `CargoCrate`, `CargoCrateBand`, `DepotPallet`, `RouteGateLeft`, `RouteGateRight`, `RouteGateTop`, `CheckpointBeacon`.
- Corrected-head CI: **NOT YET VISIBLE at this checkpoint**; previous #1184 success is not inherited.
- Probe remains read-only and cannot substitute for visual/FPS/gameplay acceptance.

QA bugs/source defects fixed to date include Splash/Loading lifecycle handling, persistence/deploy/completion scene-load installation, delayed route readiness, explicit mobile Mission and WorldMap touch routing, HUD exclusion, Android Back/Escape, idempotent completion/reward behavior, and now QA probe contract/resource-path correctness.

QA_TEAM status: **STATIC TOOLING ACTIVE / CORRECTED HEAD CI PENDING / UNITY PLAY MODE HOLD**.

## PLAYABLE PATH
Source-controlled branches now cover:

`Splash/Loading (#257 + #256) -> WorldMap 20-node route (#268 + #267 + #265) -> authoritative progression (#259) -> local progression persistence (#269) -> touch selection/DEPLOY (#271/#275) -> playable five-cargo Mission using real 3D Resources when admitted (#275 + #273/#279) -> completion handoff (#277) -> Mission 2 unlock + persistence -> one-time approved Coins + XP settlement (#281)`.

The source path is materially complete for the first playable loop. Final acceptance is not claimed until Unity observes the assembled dependency chain.

## CURRENT QA EVIDENCE
- CI #1149, #1158, #1160, #1161, #1163, #1166, #1169, #1171, #1172, #1178, #1179, #1182, #1183: **SUCCESS** on their recorded exact heads.
- QA probe previous head CI #1184: **SUCCESS**, but superseded by corrected probe head `77e331238...`.
- Corrected probe exact-head CI: **PENDING / NOT YET VISIBLE**.
- Unity 2022.3 integrated runtime PASS: **NOT AVAILABLE**.
- FPS: **NOT MEASURED**.
- Current-head Unity runtime video: **NOT AVAILABLE**.

No older QA PASS is inherited by a changed head. No Unity import, runtime, FPS or video evidence is fabricated.

## BLOCKERS
1. Corrected QA probe head `77e331238...` needs its own exact-head CI result.
2. No Unity 2022.3 assembled Play Mode run has yet proven the complete dependency chain.
3. Team branches are stacked/diverged because direct LEAD report commits advance `cargo-v2`; every candidate must be reconciled before final CAPTAIN merge.
4. Unity must prove real OBJ scale/orientation/materials, `Resources.Load<GameObject>("CargoV2/Mission/MOD_Mission_CargoDepot")`, required named parts/colliders, WorldMap mobile touch, Deploy, Mission touch/click, timeout/retry/back/cleanup, Mission 2 unlock, restart persistence and reward replay idempotency.
5. No authoritative higher-star scoring formula is implemented; minimum approved 1-star Coins + XP only is intentional.
6. No measured FPS or trustworthy current-head Unity video exists.

## NEXT ACTIONS
1. Read corrected PR #283 exact-head CI; fix only concrete source failures if any.
2. Build/reconcile a CAPTAIN QA preview branch containing the current dependency chain for Play Mode only; this must not bypass team PR gates or merge into `cargo-v2`.
3. Run PR #283 probe on the assembled WorldMap/Mission runtime and record PASS/HOLD output against the exact preview SHA.
4. Unity Play Mode verify Splash -> Loading -> WorldMap -> touch select -> Deploy -> real 3D Mission -> five deliveries -> completion -> Mission 2 unlock -> restart restore -> Coins/XP once.
5. Record FPS only if measured and video only if a real current-head recording exists.
6. CAPTAIN alone may merge each reconciled team PR into `cargo-v2` after exact-head QA PASS, dependency order respected.

## CAPTAIN GOVERNANCE
**CAPTAIN alone may merge team PRs into `cargo-v2`, and only after QA evidence is recorded against the exact head being merged.**

No merge of `cargo-v2` to `main`. No final APK/AAB build.

## VIDEO
**PENDING — no trustworthy current-head Unity Play Mode recording exists, so no video link is claimed.**

## FPS
**PENDING — no measured current-head Unity Play Mode FPS evidence exists.**
