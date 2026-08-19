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
- Added `ActiveRunCoordinator` and a narrow `ActiveRunPersistence` contract. Persistence writes are serialized so older asynchronous checkpoints cannot overwrite newer gameplay mutations, terminal clear prevents snapshot resurrection, and restart/abandon clear permits a fresh attempt afterward.
- Added coordinator regressions for restore, ordered concurrent checkpoints, terminal clear, restart clear, and the GAME-017 cargo progression contract.
- Wired `ActiveRunCoordinator` directly into `GameScreen`.
- `GameScreen` now blocks interaction until restore resolves, then either rehydrates the exact compatible unfinished session or starts and checkpoints a clean attempt.
- Checkpoints are written after non-terminal cargo mutations, prepared-hint consumption, extra-move activation, combo-shield activation, and lifecycle backgrounding.
- Terminal win/loss paths clear the active-run checkpoint before durable completion/heart-loss side effects, preventing a late queued checkpoint from resurrecting a finished mission.
- Explicit restart and back/abandon clear the stale checkpoint before resetting or leaving the route; restart then writes a fresh attempt with a new reward transaction identity.
- Retry/rewarded continuation after a terminal result creates a fresh coordinator generation before checkpointing the resumed attempt.
- `dispose()` flushes queued persistence work without turning checkpoint I/O into a gameplay blocker.
- Added `GameScreen` widget regressions proving restore is non-playable until ready, reward/heart/ad state is not replayed by restore, a post-mutation checkpoint survives simulated process recreation, lifecycle backgrounding persists the unfinished run, and explicit restart clears the stale run before a fresh checkpoint.
- Focused GAME-015 verification passed: formatting, focused Analyze with no issues, and 22/22 recovery/pause/coordinator/session/snapshot tests.

## Remaining release gates
The source-controlled runtime gap is closed. GAME-015 remains IN PROGRESS only until the final cleaned PR head passes the repository-wide Flutter CI/build/security gates, merges to current `main`, and a governed `Last verified APK` is promoted from a `main` source commit that contains GAME-015.

## Verification boundary
Do not claim completion from the focused tests alone. Closure requires final-head CI evidence, merge evidence, post-merge/main-history evidence, and retained-APK promotion evidence. Physical-device behavior may still be manually checked later, but no device result is fabricated here.
