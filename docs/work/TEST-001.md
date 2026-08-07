# TEST-001 — Progress/economy unit tests

Status: IN PROGRESS
Started: 2026-08-07
Owner: active engineering team

## Goal

Lock down the persisted progress/economy invariants before deeper content, monetization, reward-ledger, and migration work proceeds.

## Scope

Add deterministic tests around `ProgressStore` for:

- coins never becoming negative through supported purchase/spend flows;
- hearts staying within 0..max and refill behavior remaining bounded;
- booster inventories never becoming negative;
- level stars remaining 0..3 and best-star upgrades being monotonic;
- milestone and world-completion bonuses being first-clear only;
- world/level unlock progression remaining bounded at level 150;
- duplicate reward/claim guards already represented by the current store API;
- persisted values loading with safe clamps/defaults where the implementation promises them.

## Acceptance

- Tests use the in-memory SharedPreferences async platform and do not depend on wall-clock sleeps or a physical device.
- Existing saved-data keys and production behavior are preserved unless a test exposes a real invariant bug.
- Focused TEST-001 tests, Flutter Analyze, the full test suite, and Debug APK pass before closure.
