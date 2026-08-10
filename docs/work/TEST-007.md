# TEST-007 — Critical-path integration contract

Issue: #181
Branch: `agent/test-007-critical-path-50`
Priority: P0
State: VERIFIED

## Goal

Prove the release-critical offline player journey as one deterministic contract: first run -> Home -> World Map -> Mission Briefing -> Gameplay -> Result/reward -> Shop -> restart -> fresh-store restore. The contract must reuse production state and navigation boundaries, remain independent of live ads/network services, and preserve existing balance/persistence semantics.

## 50-task release checklist

### A. First-run state
- [x] T01 Fresh store loads successfully.
- [x] T02 Fresh wallet uses the shipped starting coin balance.
- [x] T03 Fresh player starts on level 1.
- [x] T04 Fresh player has no completed levels.
- [x] T05 Fresh best-star state is empty/default-safe.

### B. App shell and Home
- [x] T06 CargoSortApp boots with production stores.
- [x] T07 Home renders without startup exception.
- [x] T08 Home exposes the primary Start action.
- [x] T09 Start action enters the guarded journey route.
- [x] T10 Repeated Start cannot create duplicate route pushes.

### C. World Map and Mission Briefing
- [x] T11 World Map renders the first unlocked destination.
- [x] T12 Locked future progression remains inaccessible on first run.
- [x] T13 Selecting the first city opens Mission Briefing.
- [x] T14 Mission Briefing reflects level 1.
- [x] T15 Mission launch uses the guarded gameplay route.

### D. Gameplay baseline
- [x] T16 Gameplay renders with deterministic level data.
- [x] T17 Gameplay move budget matches level 1 policy.
- [x] T18 Gameplay starts with zero completion reward applied.
- [x] T19 Offline/no-ad conditions do not block core gameplay.
- [x] T20 Gameplay back-stack remains valid before completion.

### E. Completion and result
- [x] T21 Completing level 1 records completion once.
- [x] T22 Completion records a valid best-star value.
- [x] T23 Completion advances next-level progression safely.
- [x] T24 Result/debrief becomes available after completion.
- [x] T25 Result exposes retry/next/back semantics without route race.

### F. Reward integrity
- [x] T26 Level reward increases coins by the authoritative amount.
- [x] T27 Level reward increases XP by the authoritative amount.
- [x] T28 Reward transaction has stable idempotency identity.
- [x] T29 Replaying the same completion cannot double-award coins.
- [x] T30 Replaying the same completion cannot double-award XP.

### G. Shop transaction safety
- [x] T31 Shop can open after the completed mission.
- [x] T32 A known affordable offer reports its authoritative price.
- [x] T33 Successful purchase decreases coins exactly once.
- [x] T34 Successful purchase grants the purchased entitlement/resource exactly once.
- [x] T35 Replayed/interrupted purchase recovery cannot double-charge or double-grant.

### H. Restart and restore
- [x] T36 A new ProgressStore instance loads the same wallet.
- [x] T37 A new ProgressStore instance restores completed level 1.
- [x] T38 A new ProgressStore instance restores best stars.
- [x] T39 A new ProgressStore instance restores next-level progression.
- [x] T40 A new ProgressStore instance restores the shop entitlement/resource.

### I. Localization and responsive contract
- [x] T41 Critical-path app shell boots in English LTR.
- [x] T42 Critical-path app shell boots in Arabic RTL.
- [x] T43 Critical-path Home has no exception on compact phone.
- [x] T44 Critical-path journey has no exception on reference phone.
- [x] T45 Critical-path restore shell has no exception on tablet class.

### J. Safety, determinism, and CI
- [x] T46 Test path uses only in-memory/local persistence and no live network dependency.
- [x] T47 Reward replay leaves balances non-negative and bounded.
- [x] T48 Purchase replay leaves balances non-negative and bounded.
- [x] T49 Fresh rerun from the same initial state is deterministic.
- [x] T50 CI machine guard requires exactly these 50 named checkpoints and the executable TEST-007 integration contract.

## Implementation rules

- Do not add production dependencies.
- Do not change release balance values merely to make tests pass.
- Reuse existing production `ProgressStore`, `AppSettingsStore`, navigation, reward, shop, and level-catalog contracts.
- Keep ads/network optional and fail-closed; the core path must be testable offline.
- Existing focused TEST-001/003/004, reward, shop, privacy/security, and full Flutter suites remain authoritative regressions.

## Verification evidence

- Issue #181 / PR #184 implement the executable TEST-007 contract and its blocking CI validator.
- Flutter CI #810 / run `31379676066` passed the 50-checkpoint contract validator, six validator regressions, formatting, whitespace, Analyze, the core screen widget matrix, focused TEST-007 integration tests, analytics/crash/local-data/service/widget regressions, the full Flutter suite, Debug APK build, packaged-artifact security scan, and artifact upload on implementation head `4882ac1b9449fb399ea3456ce89fa460dcfbcb98`.
- Debug artifact #9059551183 is 80,633,604 bytes with SHA-256 `283bf954510ac7eec6cb78e36f58995157379b3afe923b2af524003d3a4b415b`.
- Final-head Flutter CI #816 / run `31380502193` passed all 43 workflow steps on `874fe658456723c5f0455e6c1935bd5b9dada8b5`, including the TEST-007 validator/regressions, formatting, Analyze, focused TEST-007, full Flutter suite, Debug APK, packaged-artifact security, and upload. Final PR artifact #9059883319 is 80,633,608 bytes with SHA-256 `76756ff72098c353f676ffd18008e253a2c1532da88208d8f3730b19b92c3e70`. PR #184 squash-merged to `main` as `b7f858f9cac6c1a8c5b0d1f9058be599f9ce792c` and Issue #181 closed completed.
