# CARGO V2 REPORT HOUR 23

## STATUS: 96%

Authoritative integration branch before this report update: `cargo-v2` @ `c5dfbfaf7af255d70a25b3c80d6f4da6478f71fe`.

No team PR is merged by this report commit. `cargo-v2` is not merged to `main`. No final APK/AAB is produced. The first playable-loop source chain remains materially implemented; the remaining acceptance gap is dominated by assembled Unity 2022.3 Play Mode evidence, exact-head reconciliation and CAPTAIN-gated integration.

## ASSET_TEAM
- PR #256 — Premium Art Pass truck/logo — `fcca9f31c8452c5db191a76203ce7c81822c3bb6`; Flutter CI #1149 **SUCCESS**; real OBJ/MTL; Unity import/material/reference QA pending; reconcile required.
- PR #267 — real 3D WorldMap marker pack — `5b504709cd5505d4d0c25380a3b8d0aa7ac9ba41`; Flutter CI #1163 **SUCCESS**; Unity import/scale/material QA pending.
- PR #273 — real Mission cargo/depot OBJ/MTL pack — `bba3567a94e4ee998235b0b20bed437e2eea2fd0`; Flutter CI #1172 **SUCCESS**; Unity import/scale/material QA pending.
- PR #279 — runtime-admitted Mission 3D Resources — `c34d4f7ea7dd75f2fe846161ded97d6f1e8967a4`; Flutter CI #1179 **SUCCESS**; actual `Resources.Load` observation pending.
- **NEW PR #285 / Issue #284** — runtime-admitted WorldMap marker pack — `59a879502b50b500c1f3e3439eec05075749419c`; adds `Assets/Resources/CargoV2/WorldMap/MOD_WorldMap_MarkerPack.obj/.mtl` with fresh deterministic Unity GUIDs. Source-controlled runtime address is now `Resources.Load<GameObject>("CargoV2/WorldMap/MOD_WorldMap_MarkerPack")`. Flutter CI #1187 is **QUEUED**; Unity import/Resources.Load/scale/material QA pending.

Status: **REAL 3D SOURCE + RUNTIME ASSET ADDRESSES IMPLEMENTED / UNITY QA HOLD**.

## UI_TEAM
- PR #257 — Premium Splash + Loading — `29274e4453afc0d2787bd4037d64bf17687a649a`; Flutter CI #1158 **SUCCESS**; Unity visual/runtime QA pending.
- PR #268 — 20-node WorldMap runtime — `1e3a01ecd4849c769762ed5eaf8bf5f6cb0d742f`; Flutter CI #1166 **SUCCESS**; STATIC PASS / UNITY HOLD.
- PR #271 — WorldMap deploy gateway — `0aeabec78ea0f15c099fc2d76117765bd6d5c2bd`; Flutter CI #1171 **SUCCESS**; STATIC PASS / stacked Unity HOLD.
- PR #275 — playable in-place Mission + mobile WorldMap touch + real Mission Resources binding — `106ccb171304891790b20cb6bd7d8df408e196af`; Flutter CI #1182 **SUCCESS**; STATIC PASS / stacked Unity HOLD.

UI source path covers WorldMap touch selection -> Deploy -> five cargo deliveries -> timer -> success/fail -> retry/back, HUD touch exclusion, Android Back/Escape, transient completion handoff, real Mission model preference and safe primitive fallback. PR #285 now closes the missing source-controlled Resources address for the real WorldMap marker model; UI still requires reconciled integration/Unity observation before claiming actual marker use.

Status: **PLAYABLE SOURCE IMPLEMENTED / CI GREEN ON RECORDED HEADS / UNITY QA HOLD**.

## LOGIC_TEAM
- PR #259 — WorldMap progression core — `7055f4679bbb5959d672bcdb3aecbebe89e9dfea`; Flutter CI #1160 **SUCCESS**; STATIC PASS / UNITY HOLD.
- PR #269 — progression persistence — `7e1cb74584bc9c1f8b6187dd91c831ba803f35e4`; Flutter CI #1169 **SUCCESS**; stacked on #259; Unity HOLD.
- PR #277 — Mission completion handoff -> authoritative progression — `841496f6c81b4cee3a2214b5b1cf2e25cd3f9e7c`; Flutter CI #1178 **SUCCESS**; STATIC PASS / Unity HOLD.
- PR #281 — idempotent mission Coins + XP settlement — `eb4252363ebc25130a69664d1187d988502376d2`; Flutter CI #1183 **SUCCESS**; STATIC PASS / Unity HOLD.

Reward behavior remains conservative and authoritative: first accepted completion settles exactly `coin1Star + xp` from `SO_GameBalance`, once per mission. Replay/restart/duplicate completion cannot double-grant; corrupt/future/negative/duplicate payloads and overflow fail closed. No invented higher-star scoring formula is claimed.

Status: **FIRST PLAYABLE PROGRESSION/PERSISTENCE/REWARD LOOP SOURCE-COMPLETE / CI GREEN / STACKED UNITY QA HOLD**.

## DATA_TEAM
- PR #265 — deterministic WorldMap presentation metadata — `feaaebcd77576addc46b100a60957c6fcb1405fc`; Flutter CI #1161 **SUCCESS**; STATIC PASS / Unity compile-integration HOLD.
- Exactly 20 records: Cairo 1-10 / Dubai 11-20; no mission economy duplicated.

Status: **IMPLEMENTED / CI GREEN / UNITY HOLD**.

## QA_TEAM
- Issue #261 remains the integrated exact-head QA gate.
- Issue #282 / PR #283 owns the read-only runtime contract probe and Editor readiness report.
- Corrected probe head `77e3312389cc4f4e406c3dedba566ad37302cb47`: Flutter CI #1185 **SUCCESS**.
- Current reconciled PR #283 head `3808a36620f18d67dc1ca21b452e3e4fe29dc2fb`: Flutter CI #1186 **SUCCESS**.
- Current QA tooling checks enabled Splash/Loading/WorldMap build scenes, actual completion bridge type, actual Mission Resources path and required named Mission 3D parts without mutating PlayerPrefs/progression/rewards.
- Structural PASS/READY from the tool is explicitly not Unity Play Mode, visual, FPS, gameplay or release acceptance.

Status: **QA SOURCE TOOLING CI GREEN / UNITY PLAY MODE HOLD**.

## PLAYABLE PATH
Source-controlled branches now cover:

`Splash/Loading (#257 + #256) -> WorldMap 20-node route (#268 + #267 + #265 + runtime-addressable marker pack #285) -> authoritative progression (#259) -> progression persistence (#269) -> touch select/DEPLOY (#271/#275) -> playable five-cargo Mission using real 3D Resources (#275 + #273/#279) -> completion handoff (#277) -> Mission 2 unlock + persistence -> one-time approved Coins + XP settlement (#281)`.

The source path is materially complete for the first playable loop. Final acceptance is not claimed until Unity observes the assembled dependency chain.

## QA BUGS / SOURCE DEFECTS RESOLVED
- Splash/Loading SVG hard-block reduced while preserving real OBJ truck authority.
- Persistence/deploy/completion installers hardened for Splash -> Loading -> WorldMap scene lifecycle.
- Completion handoff retained while authoritative route data is temporarily unavailable.
- Explicit Mission touch raycast, HUD exclusion and Android Back/Escape added.
- Explicit WorldMap touch selection/deploy added and blocked behind active Mission overlay.
- Idempotent completion/reward settlement added.
- QA runtime probe corrected to actual completion class and actual Mission Resources path; named real-3D parts are checked.
- QA Editor readiness command added and exact-head CI #1186 is green.
- **New:** real WorldMap marker OBJ/MTL now has a source-controlled Unity Resources address via PR #285 instead of remaining Generated-only.

## CURRENT EVIDENCE
- Flutter CI #1149, #1158, #1160, #1161, #1163, #1166, #1169, #1171, #1172, #1178, #1179, #1182, #1183, #1185, #1186: **SUCCESS** on their recorded exact heads.
- PR #285 exact-head Flutter CI #1187: **QUEUED** at this report update; no PASS is inherited.
- Unity 2022.3 integrated runtime PASS: **NOT AVAILABLE**.
- FPS: **NOT MEASURED**.
- Current-head Unity runtime video: **NOT AVAILABLE**.

No older QA PASS is inherited by a changed head. No Unity import, runtime, FPS or video evidence is fabricated.

## BLOCKERS
1. PR #285 exact-head CI #1187 must complete and be read independently.
2. No Unity 2022.3 assembled Play Mode run has proven the full dependency chain.
3. Team branches are stacked/diverged because report commits advance `cargo-v2`; every final candidate requires reconciliation before CAPTAIN integration.
4. Unity must prove actual OBJ scale/orientation/materials, both runtime resource paths (`CargoV2/WorldMap/MOD_WorldMap_MarkerPack` and `CargoV2/Mission/MOD_Mission_CargoDepot`), WorldMap touch, Deploy, Mission touch/click, timeout/retry/back/cleanup, Mission 2 unlock, restart persistence and reward replay idempotency.
5. WorldMap UI must be reconciled with PR #285 before actual real-marker runtime use can be claimed; source address exists but Play Mode use is not yet evidence.
6. Higher-star scoring is deliberately not invented; only approved minimum 1-star Coins + XP is implemented.
7. No measured FPS evidence exists.
8. No trustworthy current-head Unity Play Mode video exists.

## NEXT ACTIONS
1. Read exact-head CI #1187 and fix only concrete source failures if present.
2. Reconcile the WorldMap UI path with the runtime marker resource address so the real marker pack can replace primitive fallback in an assembled QA preview.
3. Build/reconcile a CAPTAIN QA preview branch containing the current dependency chain for Play Mode only; never use it as a merge bypass.
4. Execute PR #283 readiness/probe tooling on the assembled preview and record exact-preview-SHA PASS/HOLD output.
5. Unity verify Splash -> Loading -> WorldMap -> real marker Resources load -> touch select -> Deploy -> real 3D Mission -> five deliveries -> completion -> Mission 2 unlock -> restart restore -> Coins/XP exactly once.
6. Record FPS only from measured current-head Play Mode evidence and video only from a real current-head recording.
7. CAPTAIN alone merges reconciled team PRs into `cargo-v2` after exact-head QA PASS in dependency order.

## CAPTAIN GOVERNANCE
**CAPTAIN alone may merge team PRs into `cargo-v2`, and only after QA evidence is recorded against the exact head being merged.**

No merge of `cargo-v2` to `main`. No final APK/AAB build.

## VIDEO
**PENDING — no trustworthy current-head Unity Play Mode recording exists, so no video link is claimed.**

## FPS
**PENDING — no measured current-head Unity Play Mode FPS evidence exists.**
