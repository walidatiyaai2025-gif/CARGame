# WORLD-010 — AI continent campaign map

## Goal

Upgrade the verified WORLD-009 capital map into an owner-visible fantasy parchment world atlas while preserving the real 150-country/capital campaign, gameplay progression, save identity, economy, rewards, ads/privacy boundaries, and offline behavior.

## Product direction

- The map regions are continents, not the earlier harvest/forest/castle concept.
- The visual background is an AI-authored fantasy world-map asset; gameplay nodes and state remain Flutter-owned overlays.
- The campaign remains 150 levels across six 25-level chapters.
- GAME-017 remains authoritative: Level 1 starts with 9 cargo products across 3 houses and cargo count grows progressively to the existing bounded late-game maximum.

## Implemented checkpoint

- Added an offline fantasy parchment continent atlas asset.
- Replaced the flat hand-painted landmass layer with the authored atlas while keeping geographic capital projection and real level nodes interactive.
- Preserved completed/current/locked state, stars, capital labels, selection callbacks and route overlays.
- Added explicit programmable zoom-in / zoom-out controls while retaining pinch/pan via `InteractiveViewer`.
- Added bilingual Zoom to Explore guidance and current-continent context.
- Kept all progression, save/economy/reward IDs and gameplay cargo truth unchanged.

## CI hardening discovered during verification

`flutter_svg 2.3.0` is published under the MIT license, but the repository dependency-governance detector required an explicit `MIT License` heading and rejected canonical MIT text that begins directly with the copyright/permission grant. WORLD-010 therefore also hardens the generic detector to recognize canonical MIT by its permission grant, substantial-portions preservation clause, and AS-IS warranty disclaimer, with a regression test. This does not expand the license allowlist or bypass dependency review.

## Required merge gates

Do not merge until the final PR head against `main` passes:

- dependency security and governance;
- formatting and Analyze;
- focused world-map/widget/critical-path tests;
- full Flutter suite and coverage policy;
- Debug APK build;
- APK artifact-security verification and upload;
- Android release packaging smoke and applicable native-3D contract checks.

## Verification boundary

CI can verify source, tests, package safety, and installable artifacts. Physical-device visual quality and final store/device acceptance remain separate evidence and must not be fabricated.
