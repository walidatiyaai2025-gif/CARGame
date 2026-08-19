# GAME-015 — interruption recovery and resumable active run

## Objective
Protect unfinished missions from process/lifecycle interruption without replaying durable progression, rewards, hearts, ads, or booster grants.

## Owner gameplay contract preserved
- Level 1 remains exactly 9 cargo products distributed across 3 houses.
- Cargo count continues to increase progressively through the 150-level campaign.
- Existing level IDs, generated cargo truth, difficulty, rewards, save keys, and economy ownership remain unchanged.

## Completed checkpoints
- Added `ActiveRunSnapshot` schema v1 as an immutable, reward-neutral mission checkpoint.
- Added strict decode/compatibility validation that fails closed for malformed data, future schema versions, changed level identity/shape, unknown cargo, invalid houses, impossible duplicate counts, invalid counters, empty transaction identity, and terminal win/loss state.
- Added `ActiveRunStore` using the existing `RecoveringPreferences` boundary and a dedicated `active_run_snapshot_v1` key, isolated from `ProgressStore` durable truth.
- Invalid/stale snapshots are cleared rather than partially recovered.
- Added regression coverage for round-trip recovery, corruption, stale/future data, terminal-state rejection, cargo/house validation, and the GAME-017 9-product progressive cargo contract.
- Added `ActiveRunSession`, a reward-neutral translation boundary between a validated snapshot and `GameScreen` runtime fields. It preserves remaining cargo/house assignments, move/combo/hint/shield/wrong-move state and the existing reward transaction identity without owning durable rewards, hearts, ads, or inventory.
- Added round-trip and cross-level rejection regressions for the runtime translation boundary while retaining the GAME-017 cargo progression contract.

## Remaining GAME-015 integration
The final focused checkpoint must wire `ActiveRunStore` + `ActiveRunSession` into `GameScreen`: restore before the first playable frame, checkpoint after deterministic gameplay mutations/backgrounding, and clear after terminal result or explicit restart/abandon. That integration must prove no duplicate booster use, heart loss, ad trigger, or completion transaction before GAME-015 can be marked complete.

## Verification boundary
GAME-015 remains IN PROGRESS until the `GameScreen` runtime wiring and normal CI/build gates are green on the final head. This checkpoint deliberately narrows the mutation surface by making snapshot/runtime translation independently testable before lifecycle persistence is connected to the user-facing screen.
