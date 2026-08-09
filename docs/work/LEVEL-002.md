# LEVEL-002 — Difficulty curve

Status: IN PROGRESS  
Tracking: issue #134 / RC-001 #79

## Problem

The 150-level generator is deterministic and LEVEL-003 now proves structural solvability, but difficulty progression is still implicit in generator formulas. The catalog requires explicit tutorial/easy/medium/hard/expert quantitative targets and deterministic acceptance evidence.

## Current generator audit

Current `generateLevel(number)` progression inputs:

- 150 levels, six worlds of 25 levels.
- deterministic seed: `number * 7919 + 2026`.
- difficulty rating: `min(10, 1 + ((number - 1) ~/ 15))`.
- distinct product-type target rises every five positions inside each world from 2 toward 6, intentionally resetting at a new world.
- pair count rises globally every 12 levels from 2 up to 8; cargo count is twice the pair count.
- move slack is `max(2, 6 - world) + random(0..2)`, so late worlds are tighter even when product variety resets.

The current design therefore has several independent difficulty dimensions; requiring every raw metric to increase at every level/world boundary would incorrectly reject intentional world onboarding/reset behavior.

## Implementation direction

- Add a typed difficulty-band model: tutorial, easy, medium, hard, expert.
- Map contiguous level ranges to exactly one band.
- Derive deterministic per-level balance metrics from `LevelData`: declared difficulty rating, cargo count, distinct product count, move slack, and normalized pressure/tightness.
- Define quantitative envelopes per band broad enough to preserve the shipped deterministic generator unless a real progression defect is exposed.
- Validate macro progression with band-level aggregate floors/ceilings rather than false per-level monotonicity.
- Add explicit boundary regression coverage at levels 1, 15, 16, 45, 46, 75, 76, 120, 121, and 150.
- Keep structural validity in LEVEL-003 and balance quality in LEVEL-002 as separate concerns.

## Proposed band boundaries

- Tutorial: levels 1–15 / declared difficulty 1.
- Easy: levels 16–45 / declared difficulty 2–3.
- Medium: levels 46–75 / declared difficulty 4–5.
- Hard: levels 76–120 / declared difficulty 6–8.
- Expert: levels 121–150 / declared difficulty 9–10.

These boundaries align exactly with the generator's existing 15-level difficulty steps and introduce no save/progression migration.

## Acceptance

- Every level 1..150 maps to exactly one documented band; no gap/overlap.
- Band ranges and quantitative envelopes are typed and testable.
- Every generated level satisfies its assigned band envelope.
- Macro difficulty metrics do not regress across bands even when a new world intentionally resets product variety.
- Boundary levels 1, 15, 16, 45, 46, 75, 76, 120, 121, and 150 are explicitly asserted.
- Any generator change, if required, is deliberate/minimal and regression-tested; no opportunistic content rebalance.
- Format, Analyze, focused tests, full Flutter suite, Debug APK build and artifact upload pass before merge.
