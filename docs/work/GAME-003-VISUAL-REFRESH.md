# GAME-003 — Premium Gameplay Operations Deck Refresh

Issue: #148
Branch: `agent/game-003-gameplay-visual-refresh`

## State

IN PROGRESS. Final status will be reconciled with the primary catalog after the parallel TEST-002 tracking PR lands.

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