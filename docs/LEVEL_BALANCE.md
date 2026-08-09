# CARGame Level Difficulty Curve

This document defines the quantitative LEVEL-002 acceptance model for the deterministic 150-level generator. Structural validity remains owned by LEVEL-003.

## Difficulty dimensions

Difficulty is not represented by one number alone. The current sorting loop is measured using:

- **Declared difficulty** — the 1–10 level metadata used by presentation/reward logic.
- **Cargo items** — the number of correct placements required for a perfect clear.
- **Distinct products** — the number of warehouse targets the player must distinguish.
- **Move slack** — `moves - cargo items`; this is the number of non-perfect actions available before the base move budget is exhausted.
- **Move pressure** — `cargo items / moves`; higher values mean a larger share of the move budget must be correct placements.

World transitions intentionally reset some product variety so a new environment can introduce itself without a simultaneous complexity spike. Therefore raw product count is not required to increase at every boundary. The macro curve instead requires average move pressure to rise from each band to the next, while average cargo count may plateau but must not regress.

## Quantitative bands

| Band | Levels | Declared difficulty | Cargo items | Distinct products | Move slack |
|---|---:|---:|---:|---:|---:|
| Tutorial | 1–15 | 1 | 4–6 | 2–3 | 5–7 |
| Easy | 16–45 | 2–3 | 6–10 | 2–5 | 4–7 |
| Medium | 46–75 | 4–5 | 10–16 | 2–6 | 3–6 |
| Hard | 76–120 | 6–8 | 16 | 2–6 | 2–4 |
| Expert | 121–150 | 9–10 | 16 | 2–6 | 1–3 |

Band boundaries align with the existing 15-level declared-difficulty steps:

- Tutorial: 1–15
- Easy: 16–45
- Medium: 46–75
- Hard: 76–120
- Expert: 121–150

## Expert rebalance

Before LEVEL-002, levels 121–150 received a higher `difficulty` value but shared the same 2–4 move-slack envelope as late Hard levels. That allowed the gameplay pressure to plateau while reward metadata continued increasing.

LEVEL-002 keeps cargo density, product variety, deterministic seeds, world mapping, and progression IDs unchanged. It changes only the Expert base safety budget from two moves to one, producing 1–3 spare moves after the existing deterministic random allowance. This creates a measurable late-game pressure increase without increasing board density or changing save/progression identifiers.

## Deterministic validation

`LevelDifficultyPolicy` is the typed source of truth for band ranges and envelopes. `LevelDifficultyCurve` derives metrics directly from `LevelData` and validates:

- complete, contiguous band coverage for levels 1–150;
- strictly increasing declared-difficulty ranges;
- every generated level inside its band's cargo/product/slack envelope;
- exact complete/unique 150-level input set;
- strictly increasing average move pressure across Tutorial → Easy → Medium → Hard → Expert;
- non-regressing average cargo count across bands.

Focused regression tests explicitly cover levels 1, 15, 16, 45, 46, 75, 76, 120, 121, and 150 and include negative cases for invalid band metrics, incomplete/duplicate sets, and a macro-pressure regression that is individually inside per-level envelopes.

## Change policy

Any future level-generation change that affects cargo count, product variety, moves, band boundaries, or declared difficulty must update this document and `LevelDifficultyPolicy` in the same change. CI must reject generator drift that no longer satisfies the quantitative curve.

LEVEL-002 does not make local progress migration necessary because level numbers, unlock IDs, reward transaction IDs, world boundaries, and persistence keys are unchanged.
