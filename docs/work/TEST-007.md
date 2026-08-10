# TEST-007 — Critical-path integration contract

Issue: #181
Branch: `agent/test-007-critical-path-50`
Priority: P0
State: IN PROGRESS

## Goal

Prove the release-critical offline player journey as one deterministic contract: first run -> Home -> World Map -> Mission Briefing -> Gameplay -> Result/reward -> Shop -> restart -> fresh-store restore. The contract must reuse production state and navigation boundaries, remain independent of live ads/network services, and preserve existing balance/persistence semantics.

## 50-task release checklist

### A. First-run state
- [ ] T01 Fresh store loads successfully.
- [ ] T02 Fresh wallet uses the shipped starting coin balance.
- [ ] T03 Fresh player starts on level 1.
- [ ] T04 Fresh player has no completed levels.
- [ ] T05 Fresh best-star state is empty/default-safe.

### B. App shell and Home
- [ ] T06 CargoSortApp boots with production stores.
- [ ] T07 Home renders without startup exception.
- [ ] T08 Home exposes the primary Start action.
- [ ] T09 Start action enters the guarded journey route.
- [ ] T10 Repeated Start cannot create duplicate route pushes.

### C. World Map and Mission Briefing
- [ ] T11 World Map renders the first unlocked destination.
- [ ] T12 Locked future progression remains inaccessible on first run.
- [ ] T13 Selecting the first city opens Mission Briefing.
- [ ] T14 Mission Briefing reflects level 1.
- [ ] T15 Mission launch uses the guarded gameplay route.

### D. Gameplay baseline
- [ ] T16 Gameplay renders with deterministic level data.
- [ ] T17 Gameplay move budget matches level 1 policy.
- [ ] T18 Gameplay starts with zero completion reward applied.
- [ ] T19 Offline/no-ad conditions do not block core gameplay.
- [ ] T20 Gameplay back-stack remains valid before completion.

### E. Completion and result
- [ ] T21 Completing level 1 records completion once.
- [ ] T22 Completion records a valid best-star value.
- [ ] T23 Completion advances next-level progression safely.
- [ ] T24 Result/debrief becomes available after completion.
- [ ] T25 Result exposes retry/next/back semantics without route race.

### F. Reward integrity
- [ ] T26 Level reward increases coins by the authoritative amount.
- [ ] T27 Level reward increases XP by the authoritative amount.
- [ ] T28 Reward transaction has stable idempotency identity.
- [ ] T29 Replaying the same completion cannot double-award coins.
- [ ] T30 Replaying the same completion cannot double-award XP.

### G. Shop transaction safety
- [ ] T31 Shop can open after the completed mission.
- [ ] T32 A known affordable offer reports its authoritative price.
- [ ] T33 Successful purchase decreases coins exactly once.
- [ ] T34 Successful purchase grants the purchased entitlement/resource exactly once.
- [ ] T35 Replayed/interrupted purchase recovery cannot double-charge or double-grant.

### H. Restart and restore
- [ ] T36 A new ProgressStore instance loads the same wallet.
- [ ] T37 A new ProgressStore instance restores completed level 1.
- [ ] T38 A new ProgressStore instance restores best stars.
- [ ] T39 A new ProgressStore instance restores next-level progression.
- [ ] T40 A new ProgressStore instance restores the shop entitlement/resource.

### I. Localization and responsive contract
- [ ] T41 Critical-path app shell boots in English LTR.
- [ ] T42 Critical-path app shell boots in Arabic RTL.
- [ ] T43 Critical-path Home has no exception on compact phone.
- [ ] T44 Critical-path journey has no exception on reference phone.
- [ ] T45 Critical-path restore shell has no exception on tablet class.

### J. Safety, determinism, and CI
- [ ] T46 Test path uses only in-memory/local persistence and no live network dependency.
- [ ] T47 Reward replay leaves balances non-negative and bounded.
- [ ] T48 Purchase replay leaves balances non-negative and bounded.
- [ ] T49 Fresh rerun from the same initial state is deterministic.
- [ ] T50 CI machine guard requires exactly these 50 named checkpoints and the executable TEST-007 integration contract.

## Implementation rules

- Do not add production dependencies.
- Do not change release balance values merely to make tests pass.
- Reuse existing production `ProgressStore`, `AppSettingsStore`, navigation, reward, shop, and level-catalog contracts.
- Keep ads/network optional and fail-closed; the core path must be testable offline.
- Existing focused TEST-001/003/004, reward, shop, privacy/security, and full Flutter suites remain authoritative regressions.

## Verification evidence

Pending implementation and exact-head GitHub Actions evidence.