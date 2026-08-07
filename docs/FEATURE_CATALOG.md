# CARGame Feature Catalog

This file is the single source of truth for all product functions and engineering work.
Codex must update it before and after every implementation task.

## Status values

- `PLANNED`: Accepted scope, not started.
- `READY`: Requirements and dependencies are clear.
- `IN PROGRESS`: Actively being implemented. Only one primary feature should normally have this status.
- `BLOCKED`: Cannot continue; blocker and required resolution must be recorded.
- `IMPLEMENTED`: Code is complete but full verification is not finished.
- `VERIFIED`: Acceptance criteria, analysis, tests, and applicable build passed.
- `DEFERRED`: Intentionally postponed with a documented reason.

## Priority values

- `P0`: Build stability, crashes, data integrity, security, or core gameplay.
- `P1`: Required for the first production release.
- `P2`: Important polish, retention, content, analytics, or monetization.
- `P3`: Later enhancement.

## Mandatory workflow

For every task, Codex must:

1. Read `AGENTS.md`, `docs/STATUS.md`, this catalog, and the relevant design document.
2. Select the highest-priority unblocked feature whose dependencies are satisfied.
3. Change that feature to `IN PROGRESS` before editing production code.
4. Add a concise implementation note, affected areas, and measurable acceptance criteria if missing.
5. Implement the feature as a professional Flutter engineer, preserving architecture and saved data.
6. Run formatting, analysis, tests, and the applicable Android build.
7. Set the feature to `VERIFIED`, `IMPLEMENTED`, or `BLOCKED` according to evidence.
8. Update `docs/STATUS.md`, dashboard compatibility, and the feature evidence field.
9. Commit one coherent change.

Codex must not mark a feature complete merely because UI code exists.

---

# A. Engineering foundation

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| ENG-001 | Repository audit and baseline | P0 | VERIFIED | None | `docs/BASELINE_AUDIT.md` and dashboard baseline JSON evidence architecture, 111 tracked files, commands/tooling, zero binary assets, 28 storage-key families, and a prioritized risk register; catalog/dashboard integrity passed 2026-08-07. |
| ENG-002 | Stable Android build toolchain | P0 | IMPLEMENTED | ENG-001 | Shared scripts provide dynamic device discovery, JDK validation, Kotlin cache recovery, and reproducible debug/release commands; final Windows device verification remains. |
| ENG-003 | Startup resilience | P0 | IMPLEMENTED | ENG-001 | App opens when ads, logger, orientation, or storage is slow; final device verification remains. |
| ENG-004 | Error logging and copyable diagnostics | P0 | IMPLEMENTED | ENG-003 | Runtime errors are logged and can be viewed/copied without blocking normal use. |
| ENG-005 | Clean architecture boundaries | P1 | PLANNED | ENG-001 | Presentation, domain, application, storage, assets, motion, analytics, and services are separated and documented. |
| ENG-006 | Dependency and package governance | P1 | PLANNED | ENG-001 | Dependencies are reviewed, pinned sensibly, licensed, and upgrade policy is documented. |
| ENG-007 | CI verification workflow | P1 | PLANNED | ENG-002 | CI runs format, analyze, tests, dashboard parser validation, debug build, and protected release checks. |
| ENG-008 | Migration-safe local persistence | P0 | IMPLEMENTED | ENG-001 | Existing keys remain readable and new schema versions have tested safe defaults/migrations. |
| ENG-009 | Environment and build configuration | P0 | PLANNED | ENG-002 | Debug/staging/release configuration is typed, documented, and contains no local paths or production secrets. |
| ENG-010 | Secret and credential handling | P0 | PLANNED | ENG-009 | No secret is committed; local/CI injection, rotation, and redaction rules are documented and tested. |
| ENG-011 | Developer tooling and documentation | P1 | PLANNED | ENG-001 | Setup, run, repair, dashboard, release, and troubleshooting workflows are reproducible on a clean machine. |
| ENG-012 | Analytics event schema and privacy gating | P1 | PLANNED | ENG-005, PRIV-001 | Versioned event names/properties exist; collection is disabled until consent/config permits it. |
| ENG-013 | Crash reporting and non-fatal diagnostics | P1 | PLANNED | ENG-004, PRIV-001 | Release-safe crash/non-fatal capture is privacy-gated, strips sensitive data, and supports symbol/version correlation. |
| ENG-014 | Offline-first service isolation | P0 | IMPLEMENTED | ENG-005, ENG-008 | Offline core opens before Mobile Ads; optional services use isolated timeout, deduplicated initialization, bounded attempts, lifecycle retry, observable failure state, and focused tests. Flutter/device offline verification remains. |

# B. Shared 3D design system

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| UI3D-001 | Central colors, gradients, shadows, spacing, typography | P0 | IMPLEMENTED | ENG-001 | Shared design tokens exist and are used by core screens; consolidation review remains. |
| UI3D-002 | Reusable 3D icon component | P0 | IMPLEMENTED | UI3D-001 | Hearts, coins, stars, rewards, cities, bosses, and boosters have reusable 3D widgets. |
| UI3D-003 | Reusable 3D button system | P1 | IMPLEMENTED | UI3D-001, MOT-001 | Shared `GameButton` provides depth, spring release, hover, disabled/loading states, ripple, haptics, sound hook, async tap guard, RTL, semantics, theme inputs, and focused widget tests; full CTA adoption remains. |
| UI3D-004 | Reusable 3D card and panel system | P1 | PLANNED | UI3D-001 | Unified depth, highlights, border, clipping, skeleton, error, and interaction states exist. |
| UI3D-005 | Resource chips | P1 | IMPLEMENTED | UI3D-002 | Heart, coin, star, XP, and booster chips use shared rules; full-screen adoption remains. |
| UI3D-006 | Responsive screen shell and safe areas | P0 | IN PROGRESS | UI3D-001 | Shared `GameFitView` keeps bounded screens visible without scroll and is adopted by Home and Mission Briefing; 360x640/412x915 regression coverage, tablets, large text, keyboard, cutouts, and remaining short screens still require validation. |
| UI3D-007 | Reduced motion and low-performance visual mode | P1 | PLANNED | MOT-001 | User setting and automatic graceful degradation affect all shared visual effects. |
| UI3D-008 | Remove production emoji and primary flat icons | P1 | PLANNED | AST-001 | Primary game visuals use approved 3D assets/components with accessible fallbacks. |
| UI3D-009 | Loading, empty, error, and retry visual states | P1 | PLANNED | UI3D-004 | Shared states are consistent, localized, responsive, and do not block offline core play. |

# C. Motion and living interface

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| MOT-001 | Motion tokens and reusable animation primitives | P0 | IMPLEMENTED | UI3D-001 | Central duration budgets, curves, spring descriptions, distance/scale amplitude, and MediaQuery-driven reduced-motion profile exist and are integrated into GameButton with focused tests. |
| MOT-002 | Button press and release feedback primitive | P0 | IMPLEMENTED | UI3D-003 | `GameButton` responds within 100 ms, springs on release, and guards delayed or duplicate async taps; wider screen adoption remains under MOT-003. |
| MOT-003 | Universal Button Motion System | P0 | IMPLEMENTED | UI3D-003, MOT-002 | Major Start, mission launch, Next, Retry, rewarded continuation, heart/booster/theme purchase, and settings actions use shared `GameButton`; focused tests and CI verification exist, while physical-device motion review remains. |
| MOT-004 | Screen transitions | P1 | PLANNED | MOT-001 | Shared-axis/fade-through transitions are guarded, interruptible, and RTL-aware. |
| MOT-005 | Ambient home/world motion | P1 | IMPLEMENTED | MOT-001, UI3D-007 | Home and World Map share one core ambient painter with gradient lighting, parallax glows, drifting clouds, road depth, repaint isolation, reduced-motion freeze, and lifecycle-safe ticker disposal. Focused tests are included; CI and physical-device review remain. |
| MOT-006 | Product pickup, travel, placement, settle | P0 | IMPLEMENTED | GAME-003, MOT-001 | Existing cargo/warehouse motion primitives and shared curved source-to-target travel now form one integrated flow; duplicate cargo instances resolve by index, all gameplay/booster/restart/back input is locked during resolution, reduced motion completes without a ticker, and focused widget tests cover completion and anti-spam. Flutter CI/device verification remains. |
| MOT-007 | Correct/wrong/combo feedback | P0 | IMPLEMENTED | GAME-003, MOT-001 | Reusable synchronized correct/wrong overlay provides sparkle, bounce, recoil, combo escalation capped at intensity 8 without truncating game state, one-shot settings-aware haptics, a typed sound hook, localized live-region/non-color cues, Reduced Motion without a ticker, guarded completion, and anti-spam coverage. Flutter CI verified 32/32 tests plus the debug APK; centralized audio-service integration remains tracked by AV-001/AV-006 and physical-device review remains. |
| MOT-008 | Reward flight and reveal sequences | P1 | PLANNED | REW-001, MOT-001 | Coins fly to wallet, stars reveal, XP interpolates, and rewards remain idempotent. |
| MOT-009 | Boss/world completion cinematic | P2 | PLANNED | WORLD-006, MOT-008 | Sequence lasts 1.2–2.5 seconds, is skippable after first view, and never duplicates rewards. |
| MOT-010 | Animation lifecycle and interruption safety | P0 | IMPLEMENTED | MOT-001 | `MotionLifecycleScope` disables descendant tickers during background, ancestor-hidden, or reduced-motion states and resumes once when active; splash and app routes are integrated with focused lifecycle tests. Physical-device review remains. |
| MOT-011 | Resource value interpolation and pulse | P1 | PLANNED | MOT-001, UI3D-005 | Coins, hearts, XP, and stars animate accurately from old to new values without changing wallet truth or duplicating rewards. |

# D. 3D asset pipeline

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| AST-001 | Asset folder taxonomy and naming standard | P0 | VERIFIED | ENG-001 | `docs/ASSET_CATALOG.md` and `assets/3d/README.md` define runtime/source/provenance paths, stable filename/ID grammar, four locked camera profiles, upper-left lighting/material rules, WebP export budgets, accessibility and provenance handoff; mechanical standard/dashboard checks passed 2026-08-07. |
| AST-002 | Asset manifest and typed registry | P0 | IMPLEMENTED | AST-001 | Typed descriptor/registry validates stable IDs, governed runtime paths, category/profile/world/rarity, semantics, fallbacks, dimensions and duplicate IDs; bundle loader reads `assets/3d/manifest.json`; focused registry tests exist. Full Flutter CI/build evidence for the completed implementation is still pending. |
| AST-003 | Missing-asset fallback | P0 | PLANNED | AST-002 | Missing/corrupt assets never crash or leave invisible gameplay objects. |
| AST-004 | Precache and memory policy | P1 | PLANNED | AST-002 | Only near-future assets are precached and caches are bounded/observable. |
| AST-005 | 3D UI resource asset pack | P1 | PLANNED | AST-001 | Production heart, coin, star, XP, chest, gift, lock, and badge assets meet style/size rules. |
| AST-006 | 3D booster asset pack | P1 | PLANNED | AST-001 | Hint, moves, shield, and future boosters use one visual direction. |
| AST-007 | 100+ 3D cargo product pack | P1 | PLANNED | AST-002 | At least 100 distinct products across documented categories are used in real levels. |
| AST-008 | World and city asset pack | P1 | PLANNED | AST-002, WORLD-001 | Six world heroes and 150 city representations/reusable kits are available. |
| AST-009 | Boss and reward asset pack | P2 | PLANNED | AST-002 | Boss gate/chest/trophy and milestone/world reward assets exist. |
| AST-010 | Asset performance validation | P1 | PLANNED | AST-004 | Compression, dimensions, memory, decode, and load-time budgets pass. |
| AST-011 | Asset licensing and provenance | P0 | PLANNED | AST-001 | Every external/generated asset has source, license, authoring prompt/file, and commercial-use record. |
| AST-012 | Asset build validation | P1 | PLANNED | AST-002, AST-011 | CI detects missing manifest entries, duplicate IDs, oversized files, and unsupported formats. |
