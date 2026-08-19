# GAME-009 — deterministic pause/resume and lifecycle-safe gameplay

Status: IN PROGRESS — implementation complete on feature branch, pending required CI gates.

## Production contract

- Manual pause freezes gameplay motion and blocks player input.
- App lifecycle states other than `resumed` freeze gameplay tickers and input.
- Returning to the foreground resumes lifecycle-owned pauses only; a manual pause remains authoritative until the player explicitly resumes.
- In-flight cargo travel and action feedback are suspended by `TickerMode` instead of being completed, duplicated, or skipped while backgrounded.
- Back, restart, cargo selection, warehouse placement, and boosters are disabled while paused.
- No level catalog, gameplay identity, save schema, reward identity, economy values, or progression rules are changed.
- GAME-017 remains authoritative: Level 1 starts with 9 products distributed among houses, and cargo count increases progressively across the campaign.

## Verification

Focused widget regressions cover manual-pause authority across lifecycle changes and lifecycle suspension of an in-flight cargo move. Merge is allowed only after formatting, Analyze, focused/full Flutter tests, coverage, Debug APK, artifact security, and applicable Android/package gates are green on the final head.
