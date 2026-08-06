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

- `P0`: Build stability, crashes, data integrity, or core gameplay.
- `P1`: Required for the first production release.
- `P2`: Important polish, retention, content, or monetization.
- `P3`: Later enhancement.

## Mandatory workflow

For every task, Codex must:

1. Read `AGENTS.md`, `docs/STATUS.md`, this catalog, and the relevant design document.
2. Select the highest-priority unblocked feature whose dependencies are satisfied.
3. Change that feature to `IN PROGRESS` before editing production code.
4. Add a concise implementation note, affected areas, and acceptance criteria if missing.
5. Implement the feature as a professional Flutter engineer, preserving architecture and saved data.
6. Run formatting, analysis, tests, and the applicable Android build.
7. Set the feature to:
   - `VERIFIED` only when required verification passes.
   - `IMPLEMENTED` when code is complete but external verification is unavailable.
   - `BLOCKED` when a real dependency prevents completion.
8. Update `docs/STATUS.md` and the feature's evidence field.
9. Commit one coherent change.

Codex must not mark a feature complete merely because UI code exists.

---

# A. Engineering foundation

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| ENG-001 | Repository audit and baseline | P0 | READY | None | Architecture, debt, baseline commands, and risks documented. |
| ENG-002 | Stable Android build toolchain | P0 | IN PROGRESS | ENG-001 | Debug and release scripts use dynamic device discovery and resilient Kotlin cache repair. |
| ENG-003 | Startup resilience | P0 | IMPLEMENTED | ENG-001 | App opens even when ads, logger, orientation, or storage is slow. Needs final device verification. |
| ENG-004 | Error logging and copyable diagnostics | P0 | IMPLEMENTED | ENG-003 | Runtime errors are logged and can be copied/viewed without blocking normal use. |
| ENG-005 | Clean architecture boundaries | P1 | PLANNED | ENG-001 | Presentation, domain, application, storage, assets, motion, and services are separated. |
| ENG-006 | Dependency and package governance | P1 | PLANNED | ENG-001 | Dependencies are reviewed, pinned sensibly, and documented. |
| ENG-007 | CI verification workflow | P1 | PLANNED | ENG-002 | Format, analyze, test, debug build, and release checks run in CI. |
| ENG-008 | Migration-safe local persistence | P0 | IMPLEMENTED | ENG-001 | Existing SharedPreferences keys preserved; new values have safe defaults. Needs tests. |

# B. Shared 3D design system

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| UI3D-001 | Central colors, gradients, shadows, spacing, typography | P0 | IMPLEMENTED | ENG-001 | Shared design tokens exist and are used by core screens. Needs consolidation review. |
| UI3D-002 | Reusable 3D icon component | P0 | IMPLEMENTED | UI3D-001 | Hearts, coins, stars, rewards, city, boss, and boosters have reusable 3D widgets. |
| UI3D-003 | Reusable 3D button system | P1 | PLANNED | UI3D-001, MOT-001 | Press depth, disabled, loading, focus, RTL, and responsive states. |
| UI3D-004 | Reusable 3D card and panel system | P1 | PLANNED | UI3D-001 | Unified depth, highlights, border, clipping, and interaction states. |
| UI3D-005 | Resource chips | P1 | IMPLEMENTED | UI3D-002 | Heart, coin, star, XP, and booster chips use shared visual rules. Needs full-screen adoption. |
| UI3D-006 | Responsive screen shell and safe areas | P0 | PLANNED | UI3D-001 | Works on narrow phones, tall phones, tablets, large text, RTL/LTR, and cutouts. |
| UI3D-007 | Reduced motion and low-performance visual mode | P1 | PLANNED | MOT-001 | User setting and automatic graceful degradation are implemented. |
| UI3D-008 | Remove production emoji and primary flat icons | P1 | PLANNED | AST-001 | Primary game visuals use approved 3D assets/components with fallbacks. |

# C. Motion and living interface

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| MOT-001 | Motion tokens and reusable animation primitives | P0 | READY | UI3D-001 | Central durations, curves, springs, stagger, reduced-motion behavior. |
| MOT-002 | Button press and release feedback | P0 | PLANNED | MOT-001, UI3D-003 | Visible response within 100 ms; no delayed or duplicate tap. |
| MOT-003 | Resource value interpolation and pulse | P1 | PLANNED | MOT-001, UI3D-005 | Coins, hearts, XP, and stars animate from old to new values. |
| MOT-004 | Screen transitions | P1 | PLANNED | MOT-001 | Shared-axis/fade-through transitions and guarded navigation. |
| MOT-005 | Ambient home/world motion | P1 | PLANNED | MOT-001, UI3D-007 | Low-density particles, parallax, light sweep; paused off-screen. |
| MOT-006 | Product pickup, travel, placement, settle | P0 | PLANNED | GAME-003, MOT-001 | Every gameplay action clearly shows cause and result. |
| MOT-007 | Correct/wrong/combo feedback | P0 | PLANNED | GAME-003, MOT-001 | Sparkle, bounce, recoil, capped combo escalation, synced haptics/audio. |
| MOT-008 | Reward flight and reveal sequences | P1 | PLANNED | REW-001, MOT-001 | Coins fly to wallet, stars reveal, XP interpolates, chests open. |
| MOT-009 | Boss/world completion cinematic | P2 | PLANNED | WORLD-006, MOT-008 | 1.2–2.5 second sequence, skippable after first view. |

# D. 3D asset pipeline

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| AST-001 | Asset folder taxonomy and naming standard | P0 | READY | ENG-001 | `assets/3d` structure and naming conventions documented. |
| AST-002 | Asset manifest and typed registry | P0 | PLANNED | AST-001 | Stable IDs, path, category, semantic label, fallback, size, rarity, world. |
| AST-003 | Missing-asset fallback | P0 | PLANNED | AST-002 | Missing/corrupt assets never crash or leave invisible gameplay objects. |
| AST-004 | Precache and memory policy | P1 | PLANNED | AST-002 | Only near-future assets are precached; caches are bounded. |
| AST-005 | 3D UI resource asset pack | P1 | PLANNED | AST-001 | Production heart, coin, star, XP, chest, gift, lock, and badge assets. |
| AST-006 | 3D booster asset pack | P1 | PLANNED | AST-001 | Hint, moves, shield, undo/future boosters use one visual direction. |
| AST-007 | 100+ 3D cargo product pack | P1 | PLANNED | AST-002 | At least 100 distinct products across documented categories. |
| AST-008 | World and city asset pack | P1 | PLANNED | AST-002, WORLD-001 | Six world heroes, 150 city representations or reusable city kits. |
| AST-009 | Boss and reward asset pack | P2 | PLANNED | AST-002 | Boss gate/chest/trophy and milestone/world reward assets. |
| AST-010 | Asset performance validation | P1 | PLANNED | AST-004 | Compression, dimensions, memory, and load-time budgets pass. |

# E. Home and navigation

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| HOME-001 | Premium 3D home screen | P1 | IMPLEMENTED | UI3D-002 | Hero, resources, cards, and start CTA exist. Needs final assets and motion. |
| HOME-002 | Responsive Start button | P0 | IMPLEMENTED | HOME-001 | No overflow; guarded against repeated navigation. Needs device matrix test. |
| HOME-003 | Current world and next-city hero | P1 | IMPLEMENTED | WORLD-001 | Shows current journey and next target. Needs production city assets. |
| HOME-004 | Daily reward entry | P1 | IMPLEMENTED | RET-001 | Entry exists and reflects availability. Needs animated claim flow. |
| HOME-005 | Daily mission entry | P1 | IMPLEMENTED | RET-002 | Progress and claim state visible. Needs final design/motion. |
| HOME-006 | Shop and progress navigation | P1 | IMPLEMENTED | SHOP-001, PROG-001 | Navigation exists and must use shared transitions. |
| NAV-001 | Navigation guard framework | P0 | IMPLEMENTED | ENG-003 | Prevents double push/pop and result action races. Needs regression tests. |
| NAV-002 | Unified animated route transitions | P1 | PLANNED | MOT-004 | All main routes use a single transition policy. |

# F. Worlds, cities, and level map

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| WORLD-001 | Six-world data model | P0 | IMPLEMENTED | ENG-008 | Six worlds and 25 cities per world are represented. |
| WORLD-002 | Responsive world/city map | P0 | IMPLEMENTED | WORLD-001 | Dynamic columns/extents prevent overflows. Needs device verification. |
| WORLD-003 | Locked/open/completed city states | P1 | IMPLEMENTED | WORLD-001 | States and star progress are visible. |
| WORLD-004 | 3D city nodes | P1 | IMPLEMENTED | UI3D-002 | Procedural 3D-style city widgets exist. Needs production asset integration. |
| WORLD-005 | Boss city presentation | P1 | IMPLEMENTED | WORLD-001 | Every 25th level has boss visual treatment. |
| WORLD-006 | World unlock and completion flow | P1 | PLANNED | REW-003, MOT-009 | New world opens once with persistent state and animated reveal. |
| WORLD-007 | Preserve map scroll position | P2 | PLANNED | WORLD-002 | Returning from gameplay restores relevant world/city position. |

# G. Mission briefing and loadout

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| BRIEF-001 | Mission briefing screen | P0 | IMPLEMENTED | WORLD-002 | City, objective, moves, difficulty, previous stars, wallet visible. |
| BRIEF-002 | Responsive 3D booster selection | P0 | IMPLEMENTED | UI3D-002 | Hint, extra moves, shield selection works on narrow screens. |
| BRIEF-003 | Atomic booster consumption | P0 | IMPLEMENTED | ENG-008 | Boosters are consumed only after mission launch succeeds. Needs transaction tests. |
| BRIEF-004 | No-hearts handling | P0 | IMPLEMENTED | ECON-002 | Start disabled and clear state shown. Needs recovery/offer flow. |
| BRIEF-005 | Animated briefing-to-game transition | P1 | PLANNED | MOT-004 | Selected city/loadout visually carries into gameplay. |

# H. Core gameplay

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| GAME-001 | Deterministic level model | P0 | IMPLEMENTED | WORLD-001 | Same level number produces stable, valid content. Needs design audit. |
| GAME-002 | Cargo product domain model | P0 | IMPLEMENTED | GAME-001 | Stable product IDs and categories supported. Needs 100-asset integration. |
| GAME-003 | Core sorting interaction | P0 | IMPLEMENTED | GAME-001 | Player can sort cargo and win/lose. Needs production interaction rewrite/polish. |
| GAME-004 | Moves and objective tracking | P0 | IMPLEMENTED | GAME-003 | HUD and end conditions operate correctly. Needs tests. |
| GAME-005 | Combo system | P1 | IMPLEMENTED | GAME-003 | Combo count and best combo work. Needs visual/audio escalation. |
| GAME-006 | Smart Hint | P1 | IMPLEMENTED | GAME-003 | Free/loadout hints work without invalid consumption. Needs test coverage. |
| GAME-007 | Extra Moves | P1 | IMPLEMENTED | GAME-004 | Starts with +5 moves only when selected and consumed. |
| GAME-008 | Combo Shield | P1 | IMPLEMENTED | GAME-005 | Protects first mistake and cannot be re-granted on restart. |
| GAME-009 | Pause and resume | P1 | PLANNED | GAME-003 | Timers/animation/audio pause safely and resume consistently. |
| GAME-010 | Restart safety | P0 | IMPLEMENTED | GAME-003 | No duplicate booster grant or completion. Needs regression test. |
| GAME-011 | Action and result guards | P0 | IMPLEMENTED | NAV-001 | No input after result; result cannot execute/open twice. Needs tests. |
| GAME-012 | 3D board, crates, shelves, products | P0 | PLANNED | AST-007, UI3D-004 | Primary gameplay contains no production emoji/flat placeholders. |
| GAME-013 | Gameplay tutorial | P1 | PLANNED | GAME-003 | Interactive first-level tutorial and contextual onboarding. |
| GAME-014 | Accessibility feedback | P2 | PLANNED | GAME-003 | Semantics, non-color cues, large text safeguards, reduced motion. |

# I. Level design and content

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| LEVEL-001 | 150 playable levels | P0 | IMPLEMENTED | GAME-001 | 150 generated level entries exist. Needs validation and balancing. |
| LEVEL-002 | Difficulty curve | P0 | PLANNED | LEVEL-001 | Tutorial/easy/medium/hard/expert bands meet documented targets. |
| LEVEL-003 | Level solvability validator | P0 | PLANNED | LEVEL-001 | Automated checks reject impossible or invalid level configurations. |
| LEVEL-004 | Boss mechanics | P1 | PLANNED | LEVEL-002 | Each world boss introduces a distinct mechanic, not only fewer moves. |
| LEVEL-005 | Milestone levels | P1 | IMPLEMENTED | LEVEL-001 | Every fifth city grants a one-time milestone reward. Needs tests. |
| LEVEL-006 | Content balancing telemetry model | P2 | PLANNED | LEVEL-002 | Completion, fail reason, moves left, booster use can be measured locally/optionally remotely. |

# J. Results and rewards

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| REW-001 | Victory result flow | P0 | IMPLEMENTED | GAME-011 | Stars, coins, XP, replay/map action exist. Needs final 3D animation. |
| REW-002 | Failure result flow | P0 | IMPLEMENTED | GAME-011 | Retry and return flow exists; heart loss cannot duplicate. Needs final design. |
| REW-003 | One-time world reward | P0 | IMPLEMENTED | WORLD-005 | Boss/world reward granted once and persisted. Needs regression tests. |
| REW-004 | Milestone reward | P1 | IMPLEMENTED | LEVEL-005 | Every fifth first-clear reward granted once. Needs tests. |
| REW-005 | Next City action | P0 | IMPLEMENTED | NAV-001 | Guarded and returns to updated map without navigation lock. Needs device test. |
| REW-006 | 3D reward animation | P1 | PLANNED | MOT-008, AST-009 | Chest, stars, coins, XP, boosters animate coherently. |

# K. Economy, progress, and shop

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| ECON-001 | Coin wallet | P0 | IMPLEMENTED | ENG-008 | Cannot become negative; persisted. Needs transaction tests. |
| ECON-002 | Heart system and refill | P0 | IMPLEMENTED | ENG-008 | Maximum, spend, refill timer, and persistence exist. Needs lifecycle tests. |
| ECON-003 | XP and player level | P1 | IMPLEMENTED | ENG-008 | XP and level calculation exist. Needs animated presentation/tests. |
| ECON-004 | Booster inventory | P0 | IMPLEMENTED | ENG-008 | Hint, moves, shield persist and cannot become negative. Needs tests. |
| SHOP-001 | 3D shop screen | P1 | IMPLEMENTED | UI3D-002 | Hearts, boosters, themes shown with 3D-style components. Needs final asset/motion pass. |
| SHOP-002 | Safe purchase transaction | P0 | IMPLEMENTED | ECON-001 | Insufficient funds and duplicate actions handled. Needs atomicity tests. |
| SHOP-003 | Theme purchase and selection | P1 | IMPLEMENTED | SHOP-002 | Owned themes persist and selected theme applies. Needs full-screen consistency. |
| SHOP-004 | Purchase history/audit | P2 | PLANNED | SHOP-002 | Local transaction record supports debugging and reconciliation. |
| PROG-001 | Progress hub | P1 | IMPLEMENTED | ECON-003, WORLD-001 | Core statistics and progress screen exist. Needs 3D redesign. |
| PROG-002 | Achievement system | P2 | PLANNED | PROG-001 | Stable IDs, progress, one-time rewards, animated completion. |

# L. Retention and live content

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| RET-001 | Daily reward | P1 | IMPLEMENTED | ECON-001 | One claim per date, persisted. Needs calendar UI and tests. |
| RET-002 | Daily mission | P1 | IMPLEMENTED | PROG-001 | Wins/stars/coins progress and one-time claim. Needs final UI/tests. |
| RET-003 | Weekly missions | P2 | PLANNED | RET-002 | Reset-safe weekly goals and reward claim. |
| RET-004 | Login streak | P2 | PLANNED | RET-001 | Time-zone-safe streak rules and recovery. |
| RET-005 | Mystery chest | P2 | PLANNED | REW-006 | Transparent reward table, claim rules, animated reveal. |
| RET-006 | Event architecture | P3 | PLANNED | AST-002, RET-002 | Seasonal content can be configured without rewriting core gameplay. |

# M. Ads and monetization

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| ADS-001 | Non-blocking Mobile Ads startup | P0 | IMPLEMENTED | ENG-003 | Ad SDK failure/timeout never blocks game startup. Needs device verification. |
| ADS-002 | Debug test IDs and release configuration | P0 | PLANNED | ADS-001 | Test ads in debug; production IDs injected safely in release. |
| ADS-003 | Rewarded extra moves | P1 | PLANNED | ADS-002, REW-002 | Reward granted only after verified completion callback. |
| ADS-004 | Rewarded double reward | P2 | PLANNED | ADS-002, REW-001 | One-time doubling with transaction guard. |
| ADS-005 | Rewarded booster | P2 | PLANNED | ADS-002, ECON-004 | Inventory updated only after verified completion. |
| ADS-006 | Interstitial pacing | P2 | PLANNED | ADS-002 | Never during gameplay; frequency capped and configurable. |
| ADS-007 | Consent/privacy integration | P1 | PLANNED | ADS-002 | Consent flow and privacy hooks appropriate for release markets. |

# N. Audio and haptics

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| AV-001 | Audio service and preload policy | P1 | PLANNED | ENG-005 | Sounds are cached selectively and disposed safely. |
| AV-002 | Gameplay sound effects | P1 | PLANNED | AV-001, GAME-003 | Pickup, correct, wrong, combo, coin, star, win, loss. |
| AV-003 | World music system | P2 | PLANNED | AV-001, WORLD-001 | Per-world loops, crossfade, lifecycle handling. |
| AV-004 | Haptic feedback service | P1 | PLANNED | MOT-001 | Event-strength mapping and device-support fallback. |
| AV-005 | Sound/music/haptics settings | P1 | PLANNED | AV-001, AV-004 | Persisted toggles and immediate application. |
| AV-006 | Motion-audio-haptic synchronization | P1 | PLANNED | MOT-007, AV-002, AV-004 | Same event has one coordinated feedback profile. |

# O. Localization and accessibility

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| LOC-001 | English localization | P0 | IMPLEMENTED | ENG-001 | Core ARB/localization framework exists. Needs hard-coded text audit. |
| LOC-002 | Arabic localization and RTL | P0 | IMPLEMENTED | LOC-001 | Core language toggle and RTL exist. Needs complete translation audit. |
| LOC-003 | No hard-coded user-facing text | P1 | PLANNED | LOC-001 | All visible strings and accessibility labels localized. |
| LOC-004 | City/world name localization | P1 | PLANNED | WORLD-001, LOC-001 | All journey content translates consistently. |
| A11Y-001 | Semantic labels for 3D assets | P1 | PLANNED | AST-002 | All interactive/meaningful visual assets have localized semantics. |
| A11Y-002 | Large text and screen-reader validation | P1 | PLANNED | UI3D-006 | No overflow at supported scaling; core flow usable with screen reader. |
| A11Y-003 | Reduced motion | P1 | PLANNED | UI3D-007 | Setting affects all shared animation primitives. |

# P. Performance and reliability

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| PERF-001 | Frame performance budget | P0 | PLANNED | MOT-001, AST-004 | Core gameplay targets 60 FPS; documented fallback behavior. |
| PERF-002 | Memory and image budget | P0 | PLANNED | AST-004 | No unbounded cache; large assets decoded near display size. |
| PERF-003 | Pause off-screen animations | P1 | PLANNED | MOT-005 | TickerMode/lifecycle prevents hidden animation work. |
| PERF-004 | Startup time budget | P0 | IMPLEMENTED | ENG-003 | Main UI opens using defaults when optional services are slow. Needs profiling. |
| PERF-005 | Low-end device mode | P2 | PLANNED | UI3D-007 | Reduces particles, blur, shadows, and simultaneous animations. |
| REL-001 | ADB/device scripts remain dynamic | P0 | IN PROGRESS | ENG-002 | No hard-coded device or AVD name in any script. |
| REL-002 | Kotlin incremental-cache recovery | P0 | IMPLEMENTED | ENG-002 | Shared build repair performs cleanup/retry. Needs multi-machine verification. |

# Q. Tests and release

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| TEST-001 | Progress/economy unit tests | P0 | PLANNED | ENG-008 | Hearts, coins, boosters, milestones, worlds, and duplicate guards covered. |
| TEST-002 | Level generator and solvability tests | P0 | PLANNED | LEVEL-003 | Levels 1, 25, 26, 150 and all generated levels validate. |
| TEST-003 | Core screen widget tests | P1 | PLANNED | UI3D-006 | Home, map, briefing, game, result, shop at multiple sizes/languages. |
| TEST-004 | Navigation race regression tests | P0 | PLANNED | NAV-001 | Repeated Next/Retry/Start cannot duplicate routes/actions. |
| TEST-005 | Missing asset tests | P1 | PLANNED | AST-003 | Missing/corrupt asset fallback remains visible and functional. |
| TEST-006 | Golden visual tests | P2 | PLANNED | UI3D-004 | Critical screens captured for EN/AR and key dimensions. |
| REL-003 | Versioning and release notes | P1 | PLANNED | ENG-007 | Version/build updated consistently; release notes generated. |
| REL-004 | Android signing documentation | P0 | PLANNED | ENG-002 | Secure local/CI signing instructions without committed secrets. |
| REL-005 | Release APK | P0 | PLANNED | All P0 release blockers | Signed/unsigned as appropriate, installs and launches. |
| REL-006 | Release AAB | P0 | PLANNED | REL-004 | Bundle builds and passes release validation. |
| REL-007 | Play Store readiness | P1 | PLANNED | REL-006, ADS-007 | Listing assets, privacy, data safety, testing tracks documented. |

---

# Active work queue

Codex must keep this section concise and current.

## IN PROGRESS

- `ENG-002` Stable Android build toolchain.
- `REL-001` Dynamic ADB/device scripts.

## NEXT READY

1. `ENG-001` Complete baseline audit and documentation.
2. `MOT-001` Create motion tokens and reusable animation primitives.
3. `AST-001` Create 3D asset taxonomy and naming standard.
4. `TEST-001` Add progress/economy unit tests.

## BLOCKED

- None recorded.

## Recently verified

- None recorded yet. Existing implemented features require systematic verification against this catalog.
