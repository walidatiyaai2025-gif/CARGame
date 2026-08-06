# CARGame Execution Phase Definitions

This document defines the mandatory execution phases displayed by the Developer Portal.
`docs/FEATURE_CATALOG.md` remains the source of truth for task IDs, priorities, statuses,
dependencies, and acceptance evidence.

A phase is complete only when every required task in its catalog section is `VERIFIED`.
`IMPLEMENTED` work contributes partial progress but is not considered fully complete.

| Phase | Name | Purpose | Exit criteria |
|---|---|---|---|
| A | Engineering foundation | Stabilize repository, startup, build toolchain, architecture, persistence, diagnostics, dependency policy, and CI. | Baseline is documented; debug/release build path is reproducible; startup and saved data are safe; CI gates exist. |
| B | Shared 3D design system | Establish reusable 3D tokens, buttons, cards, resource chips, responsive shells, and visual modes. | Primary screens use the shared system without duplicate design implementations or responsive overflow. |
| C | Motion and living interface | Make the application feel alive through consistent motion, feedback, transitions, parallax, rewards, and reduced-motion support. | Motion tokens are shared; interaction feedback is immediate; controllers are disposed; performance budgets pass. |
| D | 3D asset pipeline | Govern 3D assets, naming, manifest, typed registry, fallbacks, precaching, compression, and memory policy. | Production assets load through the registry, missing assets are safe, and memory/load budgets pass. |
| E | Home and navigation | Complete the home experience, current journey, start action, daily entries, shop/progress access, and navigation guards. | Home is responsive and animated; every entry works; repeated navigation is prevented. |
| F | Worlds, cities, and level map | Deliver six worlds, 150 cities, map states, boss cities, unlock flow, and map position persistence. | World progression is persistent, responsive, correctly locked/unlocked, and fully navigable. |
| G | Mission briefing and loadout | Present mission information and allow safe booster/loadout selection before gameplay. | Mission starts atomically; boosters are consumed once; no-hearts and retry states are handled. |
| H | Core gameplay | Implement and polish sorting interaction, objectives, moves, combos, hints, boosters, pause, restart, guards, tutorial, and 3D board. | A full level can be played reliably with production 3D visuals, motion, feedback, and regression coverage. |
| I | Level design and content | Validate and balance 150 levels, difficulty bands, solvability, milestones, bosses, and telemetry model. | Every level is valid and solvable; difficulty curve and six distinct bosses pass design validation. |
| J | Results and rewards | Complete victory, failure, next-city, milestone, world reward, and 3D reward sequences. | Rewards grant once, results cannot duplicate, and navigation is guarded and animated. |
| K | Economy, progress, and shop | Manage coins, hearts, XP, boosters, purchases, pricing, transactions, and progress views. | Balances never become negative, purchases are atomic, persistence and transaction tests pass. |
| L | Retention | Add daily rewards, daily/weekly missions, achievements, streaks, mystery rewards, and event-ready structure. | Claims are one-time, reset timing is safe, and retention loops work offline. |
| M | Ads | Integrate test/production ad configuration, rewarded ads, interstitial policy, consent hooks, and failure isolation. | Ads never block startup or core play; rewards are idempotent; release configuration contains no secrets. |
| N | Audio and haptics | Add music, sound effects, haptics, settings, lifecycle behavior, and event synchronization. | Audio/haptics match motion events, settings persist, and background lifecycle is respected. |
| O | Localization | Complete Arabic and English localization, RTL/LTR, names, numbers, and text scaling. | No production hard-coded user text remains; both languages pass screen and overflow checks. |
| P | Accessibility | Add semantics, non-color cues, focus/touch targets, reduced motion, and large-text safeguards. | Core user flow is understandable and operable with accessibility settings enabled. |
| Q | Performance | Optimize images, rebuilds, animation lifecycle, startup, memory, loading, and lower-end device behavior. | Performance budgets, memory checks, and representative device matrix pass. |
| R | Testing | Build unit, widget, regression, responsive, localization, persistence, economy, and release gate coverage. | Required tests and CI verification pass consistently with documented evidence. |
| S | Release | Finalize versioning, signing guidance, icons, splash, privacy hooks, APK/AAB, store documentation, and release checklist. | Signed release procedure is documented; APK and AAB build successfully; release checklist is complete. |

## Plan integrity rules

1. Phase codes `A` through `S` are mandatory and must not be silently removed.
2. Every phase must contain at least one tracked task in `docs/FEATURE_CATALOG.md`.
3. Every task must include ID, function, priority, status, dependencies, and acceptance evidence.
4. New work must be registered in the catalog before implementation begins.
5. Only one primary task should normally be `IN PROGRESS`.
6. A task can be `VERIFIED` only after its applicable acceptance and verification commands pass.
7. The Developer Portal calculates task counts, remaining work, and phase percentages directly from the catalog.
8. Any plan-integrity warning shown by the Developer Portal must be resolved or explicitly documented before release.
