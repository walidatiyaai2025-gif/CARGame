# TEST-002 — Level generator and solvability tests

Status: VERIFIED
Issue: #143
Parent: RC-001 #79
Priority: P0

## Goal

Turn the existing distributed level-generation, structural-solvability, and quantitative-difficulty coverage into one deterministic release contract over the exact production 150-level catalog.

## Existing verified foundations

- `LEVEL-003` owns structural/solvability validation through `LevelSolvabilityValidator`.
- `LEVEL-002` owns quantitative difficulty acceptance through `LevelDifficultyCurve` and `LevelDifficultyPolicy`.
- `level_data_test.dart` already proves deterministic generation, exact 1..150 identity, world boundaries, move-budget policy, product pairing, immutability, and range rejection.
- Detailed negative tests stay in their owning suites; TEST-002 must not duplicate validator internals.

## Implementation scope

1. Add one focused release-level regression against the production `levels` catalog.
2. Assert exact sequential identity 1..150 with no gaps or duplicates.
3. Regenerate each level and compare stable generation fields and ordered product IDs to the cached production catalog.
4. Run `LevelSolvabilityValidator.validateAll(levels)` and `LevelDifficultyCurve.validateAll(levels)` in the same gate.
5. Explicitly validate required release boundaries 1, 25, 26, and 150 through both contracts.
6. Preserve production level content unless the integrated test exposes a real defect.

## Required verification

- changed Dart formatting and whitespace integrity;
- Analyze;
- focused TEST-002 regression;
- full Flutter test suite;
- Debug APK build and artifact upload;
- current-main reconciliation before merge if another team PR advances `main`.

## Non-goals

- no generator redesign;
- no new difficulty policy;
- no duplicate negative-case matrix;
- no save/progression/economy changes;
- no UI changes.

## Final implementation

- Added one integrated release contract over the exact production 150-level catalog.
- Proves sequential identity, deterministic regeneration parity, structural solvability, quantitative difficulty acceptance, and explicit 1/25/26/150 boundaries.
- Preserved all production level content and retained detailed negative cases in their existing focused suites.

## Final verification — 2026-08-09

- Implementation PR: #144.
- Final reconciled head: `a0f1de0e14b78f090bb770643c93492cc5164ebe`.
- Current-main baseline after UI3D-007: `c6e22c1fca7e82e8c48a3d79071ff0dc515471de`.
- Flutter CI: #697 / run `31310666540` — all gates green, including full Flutter tests and Debug APK build/upload.
- Artifact: #9037363042, 80,562,923 bytes, SHA-256 `ef6c18142dc7b1925f131848217ba8db8386f534aaee24becaede3d3ed598a9b`.
- Squash merge: `d9afbb06564a08ee571ed7c9e4784adf99a7c3fe`.
- Result: `TEST-002` VERIFIED.
