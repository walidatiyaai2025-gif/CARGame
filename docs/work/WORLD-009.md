# WORLD-009 — Real world capital map

Issue: #233  
PR: #234  
Priority: P0 product direction

## Goal

Replace the fictional grid-based level selector with an offline geographic world map where the 150 campaign identities are real countries and their capitals, without changing numeric level identity, progression, economy, rewards, or the GAME-017 cargo/house contract.

## Implemented checkpoint

- 150 deterministic `CapitalStage` records with bilingual Arabic/English country and capital names and latitude/longitude.
- Six 25-stage geographic route chapters while preserving Level 1..150 identity.
- Offline `CapitalWorldMap` with projected coordinates, recognizable landmass geometry, route segments, pan/zoom, completed/current/locked states, and accessible capital labels.
- Level selection now uses the real map instead of the fictional city GridView.
- Selected-stage card shows capital, country, stage number, stars, difficulty, cargo count, and house count.
- Briefing, gameplay command bar, and result debrief consume localized capital/country and geographic route labels.
- Compact selected-stage metadata uses a wrapping layout to prevent narrow-phone horizontal overflow.
- Existing briefing navigation and GAME-017 9-to-23 cargo / 3-to-6 houses progression remain unchanged.

## Verification contract

Do not mark visually complete at source level alone. Required sequence is:

1. PR #234 full Flutter CI green.
2. Integrate into the GAME-017 parent branch.
3. Parent PR #232 full combined CI green.
4. Merge to `main`.
5. Exact-main Flutter CI green.
6. Governed `Last verified APK` promotion from the exact merged source commit.
7. Owner play-test of the retained APK.

Physical-device visual opinion is intentionally deferred to the owner play-test after retained APK promotion.
