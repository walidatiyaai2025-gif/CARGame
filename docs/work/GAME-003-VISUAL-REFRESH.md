# GAME-003 — Premium Gameplay Operations Deck Refresh

Issue: #148
Branch: `agent/game-003-gameplay-visual-refresh`

## State

IMPLEMENTED. PR #149 passed current-main Flutter CI #718 and squash-merged to `main` as `dfd92944791a35aa3c9b194c6401b3bf17bc5626`. GAME-003 remains IMPLEMENTED until the separate GAME-012/AST-007 authored 3D board/product asset work is complete.

## Scope

Refresh the presentation layer of the active gameplay screen so it visually continues Home → World Map → Mission Control without changing the deterministic sorting engine, reward/economy truth, booster semantics, motion state machine, or result/navigation guards.

## Visual direction

- Replace the generic AppBar with a compact live-mission command bar.
- Reframe the status panel as mission telemetry with moves, cargo completion, combo, and heart/shield state.
- Present cargo and warehouses as distinct `CARGO BAY` and `SORTING DOCKS` operation zones.
- Strengthen selected-cargo state and destination affordance while preserving the existing travel-motion coordinates and widget keys.
- Replace flat booster controls with shared `GameButton` controls and `ThreeDGameIcon` assets/fallbacks.
- Use the current world colors as the ambient background so gameplay inherits the same visual identity as briefing and map.

## Contracts preserved

- Deterministic shuffled cargo order and all game-state mutations remain unchanged.
- `game-moves`, `cargo-*`, and `warehouse-*` keys remain stable.
- `_resolving`, `_finished`, `_resultVisible`, reward transaction IDs, and result-action guards remain unchanged.
- Hint, extra moves, combo shield, rewarded continuation, restart, win/loss, and persistence behavior remain unchanged.
- `GameTravelMotion` and `GameActionFeedback` remain the motion/feedback authority.

## Required verification

- changed Dart formatting and whitespace integrity;
- Analyze;
- existing gameplay responsive/motion/result/navigation regressions;
- focused operations-deck visual contract regression;
- full Flutter suite;
- Debug APK build and artifact upload;
- current-main reconciliation before merge.

## Verification evidence

- Focused branch gate: canonical formatting, gameplay responsive/motion/result/navigation regressions, the operations-deck visual contract, and Analyze passed.
- Final current-main Flutter CI #718 / run `31312628308`: formatting, whitespace, Analyze, optional-service isolation, animated GameButton, full Flutter suite, Debug APK build, and artifact upload all passed.
- Debug artifact #9037881344: 80,593,016 bytes; SHA-256 `b408561b1d6234336d180836d47ede432cdac8f4604ac4127caf84cb0ec37381`.
- Issue #148 closed Completed when PR #149 merged.
