# LEVEL-003 — Level solvability validator

Status: VERIFIED  
Tracking: issue #132 / RC-001 #79  
Historical implementation commit: `c06e23ec272a8800a039d99cbdcb02a4b0391670` (`feat(levels): add solvability validator`)

## Current-main audit

`LevelSolvabilityValidator` already exists in `lib/features/game/level_validator.dart` and validates both individual levels and the complete generated level set.

Current structural/solvability invariants:

- level number must be 1..150;
- world must match the level-number boundary across six 25-level worlds;
- difficulty must remain 1..10;
- cargo cannot be empty;
- every cargo product must exist in the canonical catalog and preserve canonical name/category metadata;
- at least two product types must be present;
- every present product type must occur at least twice, preventing orphan targets;
- move budget must be positive and at least the cargo-item count;
- complete validation rejects duplicate level numbers and requires the exact 1..150 level set.

## Regression coverage

`test/features/game/level_validator_test.dart` currently proves:

- all 150 generated levels satisfy the validator;
- representative world boundaries 1, 25, 26, 50, 51, 125, 126, and 150 validate;
- insufficient moves are rejected;
- empty and single-target layouts are rejected;
- orphan and unknown products are rejected;
- world, difficulty, and product-metadata mismatches are rejected;
- duplicate or incomplete level sets are rejected.

`lib/features/game/level_data.dart` deterministically generates exactly 150 levels from stable level-number-derived inputs, so the validator regression is deterministic rather than dependent on runtime randomness.

## Current verification evidence

- Flutter CI #659 / run `31301158763` on the AST-011 reconciliation checkpoint passed the full 240-test Flutter suite containing the LEVEL-003 regressions, plus Analyze, Debug APK build, and artifact upload.
- Debug artifact #9034604961 is 80,544,511 bytes with SHA-256 `79d61a1977614296dd06a38a850e7960a730c6d632890801e77d99d5983ac6b6`.
- Current audit found no missing LEVEL-003 acceptance invariant that requires duplicate production code. The stale catalog state should be reconciled to VERIFIED.
- This tracking-only branch receives its own fresh full CI before issue #132 is closed.

## Boundary

LEVEL-003 validates structural solvability/sanity for the current sorting model. It does not claim the separate LEVEL-002 quantitative difficulty curve is balanced; LEVEL-002 remains the next unblocked P0 content-design task.
