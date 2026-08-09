# TEST-002 — Level generator and solvability tests

Status: IN PROGRESS
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
