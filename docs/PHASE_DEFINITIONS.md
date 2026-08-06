# CARGame Execution Phase Definitions

This document defines the mandatory execution phases displayed by the Developer Portal.
`docs/FEATURE_CATALOG.md` remains the source of truth for task IDs, priorities, statuses,
dependencies, and acceptance evidence.

A phase is complete only when every required non-deferred task in its catalog section is `VERIFIED`.
`IMPLEMENTED` work contributes partial progress but is not considered fully complete.

| Phase | Name | Purpose | Exit criteria |
|---|---|---|---|
| A | Engineering foundation | Stabilize repository, startup, build toolchain, architecture, persistence, environments, secrets, diagnostics, analytics boundaries, offline isolation, developer tooling, dependencies, and CI. | Baseline is documented; builds are reproducible; startup/data are safe; environments contain no secrets; optional services fail independently; CI gates exist. |
| B | Shared 3D design system | Establish reusable 3D tokens, buttons, cards, resource chips, responsive shells, loading/error states, and visual modes. | Primary screens use the shared system without duplicate implementations, inaccessible states, or responsive overflow. |
| C | Motion and living interface | Make the application feel alive through consistent feedback, transitions, gameplay motion, rewards, lifecycle safety, and reduced-motion support. | Shared motion tokens exist; feedback is immediate; interruption/background behavior is safe; controllers are disposed; budgets pass. |
| D | 3D asset pipeline | Govern assets, naming, manifest, typed registry, fallbacks, precaching, compression, provenance, licensing, and CI validation. | Production assets load through the registry; missing assets are safe; rights records and memory/load budgets pass. |
| E | Home and navigation | Complete home, current journey, onboarding/resume, daily entries, shop/progress access, transitions, deep-link safety, and navigation guards. | Home is responsive/animated; entries work; repeated or external navigation cannot duplicate actions. |
| F | Worlds, cities, and level map | Deliver six worlds, 150 cities, map states, boss cities, unlock flow, scroll restoration, and content migrations. | Progression remains persistent and compatible across content updates; all states are responsive and navigable. |
| G | Mission briefing and loadout | Present accessible mission information and allow atomic booster/loadout selection. | Mission starts once; boosters consume once; no-hearts, accessibility summary, error, and retry states are handled. |
| H | Core gameplay | Polish sorting, state machine, objectives, moves, combos, boosters, pause, interruption recovery, anti-spam guards, tutorial, accessibility, and 3D board. | A full run is deterministic and recoverable with production visuals, feedback, lifecycle safety, and regression coverage. |
| I | Level design and content | Validate/version/balance 150 levels, difficulty bands, solvability, milestones, bosses, authoring schema, compatibility, and telemetry model. | Every level is valid/solvable; six bosses are distinct; content updates preserve progress and are measurable safely. |
| J | Results and rewards | Complete victory/failure, next-city, milestone/world rewards, 3D sequences, reward ledger, configuration, odds, and reconciliation. | Results/rewards execute once, survive interruption, reconcile correctly, and navigation remains guarded. |
| K | Economy, progress, and shop | Manage coins, hearts, XP, boosters, economy configuration, purchases, audit history, themes, achievements, and future sync/billing boundaries. | Balances never become negative; grants/purchases are atomic and versioned; persistence and transaction tests pass. |
| L | Retention and live content | Add daily/weekly systems, streaks, chests, events, remote configuration boundary, notifications, abuse safeguards, and optional social readiness. | Claims are one-time and clock-safe; offline behavior works; live configuration and notifications fail safely. |
| M | Ads and monetization | Integrate safe ad configuration, rewarded flows, pacing, consent, analytics, and no-fill/failure UX. | Ads never block startup/core play; rewards are idempotent; privacy/configuration and quality safeguards pass. |
| N | Audio and haptics | Add licensed music/SFX, haptics, settings, lifecycle behavior, loudness/accessibility rules, and event synchronization. | Feedback matches motion, settings apply immediately, lifecycle is respected, and commercial rights are recorded. |
| O | Localization | Complete Arabic/English strings, RTL/LTR, names, numbers, dates, plurals, fonts, glossary, QA, and fallback policy. | No hard-coded production text remains; locale-specific formatting and translation tests pass. |
| P | Accessibility | Add semantics, non-color cues, contrast, focus/touch targets, reduced motion, large-text/screen-reader safeguards, and release statement. | Core flow is understandable and operable with supported accessibility settings; known limits are documented. |
| Q | Performance and reliability | Optimize frame time, memory, startup, app size, network/battery use, low-end mode, build/device scripts, runtime recovery, and storage corruption handling. | Budgets and representative device matrix pass; no leaks/unbounded work; recoverable failures do not lose data. |
| R | Testing and quality gates | Build unit, widget, golden, integration, responsive, localization, persistence, economy, privacy/security, device, dashboard, smoke, and soak coverage. | CI quality gates, coverage/flaky policy, compatibility matrix, and release-candidate tests pass consistently. |
| S | Release, privacy, security, legal, and store readiness | Finalize privacy/data safety, security/threat model, legal rights/notices, versioning, signing, APK/AAB, listing assets, testing tracks, monitoring, rollback, archive, and go/no-go. | All P0 blockers are VERIFIED; signed APK/AAB pass; disclosures match behavior; rollout/rollback and release evidence are complete. |

## Plan integrity rules

1. Phase codes `A` through `S` are mandatory and must not be silently removed, merged, or reordered without a documented migration.
2. Every phase must contain at least one tracked task in `docs/FEATURE_CATALOG.md`.
3. Every task must include a unique stable ID, function, priority, status, dependencies, and measurable acceptance evidence.
4. New work must be registered in the catalog before implementation begins.
5. Only one primary task should normally be `IN PROGRESS`; tightly coupled secondary work must be documented.
6. A task can be `VERIFIED` only after applicable acceptance and verification commands pass.
7. The Developer Portal calculates counts, remaining work, and percentages directly from the catalog; no duplicate manual totals are allowed.
8. Dependencies must reference valid IDs or an explicitly documented external gate.
9. Privacy, security, legal, licensing, accessibility, analytics, monitoring, rollback, and data migration work cannot be deferred implicitly.
10. Any plan-integrity warning shown by the Developer Portal must be resolved or explicitly accepted before release.
