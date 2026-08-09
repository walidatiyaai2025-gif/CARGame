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
| ENG-009 | Environment and build configuration | P0 | VERIFIED | ENG-002 | PR #95 externalized Android release AdMob/signing inputs, forbids Google test application IDs and debug-signing fallback in release, and fails early on incomplete release configuration. PR #99 then exercised the guarded release APK/AAB packaging path successfully while Flutter CI #539 remained green. Real production credentials remain external by design. |
| ENG-010 | Secret and credential handling | P0 | VERIFIED | ENG-009 | Issue #113 / PR #114 align tracked-secret scanning with local ignore policy, add focused scanner regression coverage, redact standalone high-confidence GitHub/AWS/Google/Slack credentials in diagnostics, and document local/CI injection plus rotation/recovery rules. Flutter CI #588 passed secret hygiene, policy regression, formatting, Analyze, full Flutter tests, Debug APK build, and artifact upload. Debug artifact #9031846609 is 80,518,478 bytes with SHA-256 `913d9a9ae3107cde00ced9e6e7197098f5f15e640de59ae3e474715661cf33df`. |
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
| UI3D-004 | Reusable 3D card and panel system | P1 | IMPLEMENTED | UI3D-001 | `GamePanel`, `GameResourcePanel`, `GameActionPanel`, `GameStatPanel`, and `GameHeroPanel` provide shared depth, highlights, border, clipping, loading/error states, semantics and interaction; adopted in Home, Shop, and Progress Hub with regression tests; latest Flutter CI/device verification pending. |
| UI3D-005 | Resource chips | P1 | IMPLEMENTED | UI3D-002 | Heart, coin, star, XP, and booster chips use shared rules; full-screen adoption remains. |
| UI3D-006 | Responsive screen shell and safe areas | P0 | VERIFIED | UI3D-001 | Shared `GameFitView` keeps bounded screens visible without unnecessary scroll; automated coverage spans compact/reference/tablet viewports, large text, keyboard/view insets, safe-area cutouts and RTL. Gameplay/result, Shop, Progress Hub and Settings checkpoints through PRs #86–#92 passed formatting, Analyze, full Flutter tests, Debug APK build and artifact upload. Physical-device visual review remains under the broader RC/device verification work, not this feature. |
| UI3D-007 | Reduced motion and low-performance visual mode | P1 | PLANNED | MOT-001 | User setting and automatic graceful degradation affect all shared visual effects. |
| UI3D-008 | Remove production emoji and primary flat icons | P1 | PLANNED | AST-001 | Primary game visuals use approved 3D assets/components with accessible fallbacks. |
| UI3D-009 | Loading, empty, error, and retry visual states | P1 | PLANNED | UI3D-004 | Shared states are consistent, localized, responsive, and do not block offline core play. |

# C. Motion and living interface

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| MOT-001 | Motion tokens and reusable animation primitives | P0 | IMPLEMENTED | UI3D-001 | Central duration budgets, curves, spring descriptions, distance/scale amplitude, and MediaQuery-driven reduced-motion profile exist and are integrated into GameButton with focused tests. |
| MOT-002 | Button press and release feedback primitive | P0 | IMPLEMENTED | UI3D-003 | `GameButton` responds within 100 ms, springs on release, and guards delayed or duplicate async taps; wider screen adoption remains under MOT-003. |
| MOT-003 | Universal Button Motion System | P0 | IMPLEMENTED | UI3D-003, MOT-002 | Major Start, mission launch, Next, Retry, rewarded continuation, heart/booster/theme purchase, and settings actions use shared `GameButton`; focused tests and CI verification exist, while physical-device motion review remains. |
| MOT-004 | Screen transitions | P1 | IMPLEMENTED | MOT-001 | `GameRoute` supplies shared fade/shared-axis motion with RTL-aware direction and Reduced Motion fallback; `GameNavigator` centralizes route naming, replacement and duplicate-push guards; World Map to briefing uses named guarded transitions and focused navigation tests exist. Full main-route adoption remains tracked by NAV-002; latest CI/device verification pending. |
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
| AST-002 | Asset manifest and typed registry | P0 | IMPLEMENTED | AST-001 | `GameAsset`, `game_asset_manifest.dart`, and `GameAssetRegistry` provide typed stable IDs, runtime path, category, semantics, fallback, dimensions, rarity, world, and render profile metadata; focused manifest/registry tests are present. |
| AST-003 | Missing-asset fallback | P0 | IMPLEMENTED | AST-002 | `GameAssetView` and `GameManifestAssetView` provide visible runtime fallbacks for missing/corrupt assets, with focused widget tests covering the fallback path. Full release/device validation remains before VERIFIED. |
| AST-004 | Precache and memory policy | P1 | PLANNED | AST-002 | Only near-future assets are precached and caches are bounded/observable. |
| AST-005 | 3D UI resource asset pack | P1 | PLANNED | AST-001 | Production heart, coin, star, XP, chest, gift, lock, and badge assets meet style/size rules. |
| AST-006 | 3D booster asset pack | P1 | PLANNED | AST-001 | Hint, moves, shield, and future boosters use one visual direction. |
| AST-007 | 100+ 3D cargo product pack | P1 | PLANNED | AST-002 | At least 100 distinct products across documented categories are used in real levels. |
| AST-008 | World and city asset pack | P1 | PLANNED | AST-002, WORLD-001 | Six world heroes and 150 city representations/reusable kits are available. |
| AST-009 | Boss and reward asset pack | P2 | PLANNED | AST-002 | Boss gate/chest/trophy and milestone/world reward assets exist. |
| AST-010 | Asset performance validation | P1 | PLANNED | AST-004 | Compression, dimensions, memory, decode, and load-time budgets pass. |
| AST-011 | Asset licensing and provenance | P0 | PLANNED | AST-001 | Every external/generated asset has source, license, authoring prompt/file, and commercial-use record. |
| AST-012 | Asset build validation | P1 | PLANNED | AST-002, AST-011 | CI detects missing manifest entries, duplicate IDs, oversized files, and unsupported formats. |

# E. Home and navigation

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| HOME-001 | Premium 3D home screen | P1 | IMPLEMENTED | UI3D-002 | Hero, resources, cards, and start CTA exist; a lifecycle-safe living backdrop with parallax glow and drifting cloud layers is integrated. Final authored assets and device polish remain. |
| HOME-002 | Responsive Start button | P0 | IMPLEMENTED | HOME-001 | Home is fit-to-screen without a scroll container on 360x640 and 412x915 regression sizes; compact resources/hero preserve the guarded Start action; physical-device matrix remains. |
| HOME-003 | Current world and next-city hero | P1 | IMPLEMENTED | WORLD-001 | Current journey/next target are shown; production city assets remain. |
| HOME-004 | Daily reward entry | P1 | IMPLEMENTED | RET-001 | Entry reflects availability; animated claim flow remains. |
| HOME-005 | Daily mission entry | P1 | IMPLEMENTED | RET-002 | Progress and claim state are visible; final UI/tests remain. |
| HOME-006 | Shop and progress navigation | P1 | IMPLEMENTED | SHOP-001, PROG-001 | Navigation exists and must adopt shared transitions. |
| NAV-001 | Navigation guard framework | P0 | IMPLEMENTED | ENG-003 | Double push/pop and result action races are prevented; regression tests remain. |
| NAV-002 | Unified animated route transitions | P1 | IMPLEMENTED | MOT-004 | Home/app-shell Journey, Shop, Progress, Logs, Settings, and runtime Log Viewer now use `GameNavigator` with stable names and duplicate-push guards; Mission Briefing→Gameplay also uses the shared named route. Result/back-guard regression coverage is present; broader device validation remains in RC-001. |
| NAV-003 | Deep-link and notification route safety | P2 | PLANNED | NAV-001, RET-008 | External entry opens only allowed destinations and never duplicates navigation. |
| HOME-007 | First-run onboarding and returning-player resume | P1 | PLANNED | GAME-013, ENG-008 | New players receive concise onboarding; returning players resume the correct journey safely. |

# F. Worlds, cities, and level map

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| WORLD-001 | Six-world data model | P0 | IMPLEMENTED | ENG-008 | Six worlds and 25 cities per world are represented. |
| WORLD-002 | Responsive world/city map | P0 | IMPLEMENTED | WORLD-001 | Dynamic columns/extents prevent overflows; device verification remains. |
| WORLD-003 | Locked/open/completed city states | P1 | IMPLEMENTED | WORLD-001 | States and star progress are visible. |
| WORLD-004 | 3D city nodes | P1 | IMPLEMENTED | UI3D-002 | Procedural 3D-style nodes exist; production asset integration remains. |
| WORLD-005 | Boss city presentation | P1 | IMPLEMENTED | WORLD-001 | Every 25th level has boss visual treatment. |
| WORLD-006 | World unlock and completion flow | P1 | PLANNED | REW-003, MOT-009 | New world opens once with persistent state and animated reveal. |
| WORLD-007 | Preserve map scroll position | P2 | PLANNED | WORLD-002 | Returning from gameplay restores the relevant world/city position. |
| WORLD-008 | World content versioning and migration | P1 | PLANNED | WORLD-001, ENG-008 | Updates can add/rebalance content without invalidating unlocked progress or rewards. |

# G. Mission briefing and loadout

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| BRIEF-001 | Mission briefing screen | P0 | IMPLEMENTED | WORLD-002 | City, objective, moves, difficulty, previous stars, and wallet are visible. |
| BRIEF-002 | Responsive 3D booster selection | P0 | IMPLEMENTED | UI3D-002 | Hint, extra moves, and shield selection work on narrow screens. |
| BRIEF-003 | Atomic booster consumption | P0 | IMPLEMENTED | ENG-008 | Boosters are consumed only after mission launch succeeds; transaction tests remain. |
| BRIEF-004 | No-hearts handling | P0 | IMPLEMENTED | ECON-002 | Start is disabled and state is clear; recovery/offer flow remains. |
| BRIEF-005 | Animated briefing-to-game transition | P1 | PLANNED | MOT-004 | Selected city/loadout visually carries into gameplay without duplicate launch. |
| BRIEF-006 | Mission preview and accessibility summary | P2 | PLANNED | BRIEF-001, A11Y-001 | Objectives, hazards, boosters, and rewards are understandable without color or animation alone. |

# H. Core gameplay

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| GAME-001 | Deterministic level model | P0 | IMPLEMENTED | WORLD-001 | Same level number produces stable valid content; design audit remains. |
| GAME-002 | Cargo product domain model | P0 | IMPLEMENTED | GAME-001 | Stable product IDs and categories are supported; 100-asset integration remains. |
| GAME-003 | Core sorting interaction | P0 | IMPLEMENTED | GAME-001 | Player can sort cargo and win/lose; production interaction polish remains. |
| GAME-004 | Moves and objective tracking | P0 | IMPLEMENTED | GAME-003 | HUD and end conditions operate; tests remain. |
| GAME-005 | Combo system | P1 | IMPLEMENTED | GAME-003 | Combo count/best combo work; visual/audio escalation remains. |
| GAME-006 | Smart Hint | P1 | IMPLEMENTED | GAME-003 | Free/loadout hints work without invalid consumption; tests remain. |
| GAME-007 | Extra Moves | P1 | IMPLEMENTED | GAME-004 | Starts with +5 moves only when selected and consumed. |
| GAME-008 | Combo Shield | P1 | IMPLEMENTED | GAME-005 | Protects first mistake and cannot be re-granted on restart. |
| GAME-009 | Pause and resume | P1 | PLANNED | GAME-003 | Timers, animation, audio, and app lifecycle pause/resume consistently. |
| GAME-010 | Restart safety | P0 | IMPLEMENTED | GAME-003 | No duplicate booster grant or completion; regression test remains. |
| GAME-011 | Action and result guards | P0 | IMPLEMENTED | NAV-001 | No input after result and result cannot execute/open twice; tests remain. |
| GAME-012 | 3D board, crates, shelves, products | P0 | PLANNED | AST-007, UI3D-004 | Primary gameplay contains no production emoji/flat placeholders. |
| GAME-013 | Gameplay tutorial | P1 | PLANNED | GAME-003 | Interactive first-level tutorial and contextual onboarding are skippable/replayable. |
| GAME-014 | Accessibility feedback | P2 | PLANNED | GAME-003, A11Y-001 | Semantics, non-color cues, scalable text, and reduced motion cover the core loop. |
| GAME-015 | App interruption and recovery | P0 | PLANNED | GAME-009, ENG-008 | Backgrounding, phone interruptions, process restart, and route loss cannot corrupt/duplicate a run. |
| GAME-016 | Input determinism and anti-spam state machine | P0 | VERIFIED | GAME-003, GAME-011 | Issue #110 / PR #111 verify deterministic input locking across cargo travel and placement feedback: repeated warehouse taps and cargo reselection attempts cannot consume a second move, replace selection, or emit duplicate feedback; gameplay boosters, restart, and back are disabled while resolving, and TEST-004 verifies result-boundary action races. Flutter CI #580 passed formatting, Analyze, all 215 Flutter tests, Debug APK build, and artifact upload. Debug artifact #9031438726 is 80,515,901 bytes with SHA-256 `afa0597b32a4d08f5fdaf76f109c92821eb84f3ad6b4e0a388b9b29d7fee1ae6`. |

# I. Level design and content

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| LEVEL-001 | 150 playable levels | P0 | IMPLEMENTED | GAME-001 | 150 generated level entries exist; validation and balancing remain. |
| LEVEL-002 | Difficulty curve | P0 | PLANNED | LEVEL-001 | Tutorial/easy/medium/hard/expert bands meet documented quantitative targets. |
| LEVEL-003 | Level solvability validator | P0 | PLANNED | LEVEL-001 | Automated checks reject impossible, invalid, or degenerate configurations. |
| LEVEL-004 | Boss mechanics | P1 | PLANNED | LEVEL-002 | Each world boss has a distinct mechanic, tutorial cue, and validated difficulty. |
| LEVEL-005 | Milestone levels | P1 | IMPLEMENTED | LEVEL-001 | Every fifth city grants a one-time milestone reward; tests remain. |
| LEVEL-006 | Content balancing telemetry model | P2 | PLANNED | LEVEL-002, ENG-012 | Completion, fail reason, moves left, duration, and booster use can be measured safely. |
| LEVEL-007 | Level content schema and authoring validation | P1 | PLANNED | LEVEL-001 | Versioned schema, authoring rules, validation errors, and deterministic export are documented. |
| LEVEL-008 | Content regression and compatibility policy | P1 | PLANNED | LEVEL-007, WORLD-008 | Updating levels preserves completed progress/rewards and records intentional balance changes. |

# J. Results and rewards

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| REW-001 | Victory result flow | P0 | IMPLEMENTED | GAME-011 | Stars, coins, XP, replay/map actions exist; final 3D animation remains. |
| REW-002 | Failure result flow | P0 | IMPLEMENTED | GAME-011 | Retry/return flow exists and heart loss cannot duplicate; final design remains. |
| REW-003 | One-time world reward | P0 | IMPLEMENTED | WORLD-005 | Boss/world reward is granted once and persisted; regression tests remain. |
| REW-004 | Milestone reward | P1 | IMPLEMENTED | LEVEL-005 | Every fifth first-clear reward is granted once; tests remain. |
| REW-005 | Next City action | P0 | IMPLEMENTED | NAV-001 | Guarded action returns to updated map without navigation lock; device test remains. |
| REW-006 | 3D reward animation | P1 | PLANNED | MOT-008, AST-009 | Chest, stars, coins, XP, and boosters animate coherently. |
| REW-007 | Reward transaction ledger and reconciliation | P0 | PLANNED | ENG-008, REW-001 | Every grant has stable reason/idempotency key and can be audited/reconciled after interruption. |
| REW-008 | Reward table configuration and probability disclosure | P1 | PLANNED | REW-007, RET-005 | Reward tables are versioned, testable, and odds are disclosed where legally/product required. |

# K. Economy, progress, and shop

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| ECON-001 | Coin wallet | P0 | IMPLEMENTED | ENG-008 | Cannot become negative and persists; transaction tests remain. |
| ECON-002 | Heart system and refill | P0 | IMPLEMENTED | ENG-008 | Maximum, spend, refill timer, and persistence exist; lifecycle tests remain. |
| ECON-003 | XP and player level | P1 | IMPLEMENTED | ENG-008 | XP/level calculation exists; animated presentation/tests remain. |
| ECON-004 | Booster inventory | P0 | IMPLEMENTED | ENG-008 | Hint, moves, and shield persist and cannot become negative; tests remain. |
| ECON-005 | Versioned economy configuration and balance rules | P0 | PLANNED | ECON-001, REW-007 | Prices, rewards, sinks, sources, caps, and migrations are versioned and validated. |
| SHOP-001 | 3D shop screen | P1 | IMPLEMENTED | UI3D-002 | Hearts, boosters, and themes use 3D-style components; final asset/motion pass remains. |
| SHOP-002 | Safe purchase transaction | P0 | VERIFIED | ECON-001 | PR #97 adds an idempotent persisted shop-purchase journal using absolute final wallet/entitlement values, validates allowed keys/non-negative values, serializes overlapping purchases, recovers interrupted theme/booster writes without double debit/grant, and discards malformed journals safely. Flutter CI #536 passed the full test suite, Analyze, Debug APK build, and artifact upload before merge. |
| SHOP-003 | Theme purchase and selection | P1 | IMPLEMENTED | SHOP-002 | Owned themes persist and selected theme applies; consistency pass remains. |
| SHOP-004 | Purchase history/audit | P2 | PLANNED | SHOP-002 | Local transaction records support debugging and reconciliation. |
| SHOP-005 | Optional in-app purchase abstraction | P3 | PLANNED | ENG-009, PRIV-001 | Store billing can be added without coupling core economy; restore/verification/error states are specified. |
| PROG-001 | Progress hub | P1 | IMPLEMENTED | ECON-003, WORLD-001 | Core statistics/progress screen exists; 3D redesign remains. |
| PROG-002 | Achievement system | P2 | PLANNED | PROG-001 | Stable IDs, progress, one-time rewards, and animated completion exist. |
| PROG-003 | Cloud-save-ready synchronization boundary | P3 | PLANNED | ENG-005, ENG-008, PRIV-001 | Local data remains authoritative offline; future sync supports conflict/version policy without embedded credentials. |

# L. Retention and live content

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| RET-001 | Daily reward | P1 | IMPLEMENTED | ECON-001 | One claim per date persists; calendar UI/tests remain. |
| RET-002 | Daily mission | P1 | IMPLEMENTED | PROG-001 | Wins/stars/coins progress and one-time claim work; final UI/tests remain. |
| RET-003 | Weekly missions | P2 | PLANNED | RET-002 | Reset-safe weekly goals and claims are time-zone tested. |
| RET-004 | Login streak | P2 | PLANNED | RET-001 | Time-zone-safe streak rules, grace/recovery, and clock changes are tested. |
| RET-005 | Mystery chest | P2 | PLANNED | REW-006, REW-008 | Transparent reward table, one-time claim rules, and animated reveal exist. |
| RET-006 | Event architecture | P3 | PLANNED | AST-002, RET-002 | Seasonal content can be configured/versioned without rewriting core gameplay. |
| RET-007 | Remote/live configuration boundary | P2 | PLANNED | ENG-014, ENG-009 | Cached signed/versioned configuration fails closed and never blocks offline play. |
| RET-008 | Local notification and deep-link readiness | P2 | PLANNED | NAV-003, PRIV-001 | Opt-in reminders use localized schedules, permission states, and safe routes. |
| RET-009 | Leaderboard/social readiness | P3 | PLANNED | ENG-012, PRIV-001 | Optional identity/social layer has privacy, moderation, offline, and failure boundaries documented. |
| RET-010 | Device-clock and claim abuse safeguards | P1 | PLANNED | RET-001, RET-003 | Backward/forward clock changes cannot duplicate claims or corrupt streaks. |

# M. Ads and monetization

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| ADS-001 | Non-blocking Mobile Ads startup | P0 | IMPLEMENTED | ENG-003 | SDK failure/timeout never blocks startup; device verification remains. |
| ADS-002 | Debug test IDs and release configuration | P0 | PLANNED | ADS-001, ENG-009 | Test ads run in debug and production IDs are injected safely in release. |
| ADS-003 | Rewarded extra moves | P1 | PLANNED | ADS-002, REW-002 | Reward grants only once after verified completion callback. |
| ADS-004 | Rewarded double reward | P2 | PLANNED | ADS-002, REW-001 | One-time doubling uses an idempotency key and survives interruption. |
| ADS-005 | Rewarded booster | P2 | PLANNED | ADS-002, ECON-004 | Inventory updates only after verified completion. |
| ADS-006 | Interstitial pacing | P2 | PLANNED | ADS-002 | Never appears during gameplay; frequency/session caps are configurable/tested. |
| ADS-007 | Consent/privacy integration | P1 | PLANNED | ADS-002, PRIV-001 | Consent state controls personalized ads/analytics and is re-openable. |
| ADS-008 | Ad placement analytics and quality safeguards | P2 | PLANNED | ADS-006, ENG-012 | Impression, completion, failure, churn signals are measured without sensitive data. |
| ADS-009 | Ad-free failure and fallback UX | P1 | PLANNED | ADS-001 | Unavailable/no-fill/network errors return immediately to a valid non-blocking UI state. |
| ADS-010 | Home banner ad footer | P1 | IMPLEMENTED | ADS-001, ENG-014 | Home uses a Google banner footer with official debug test ID; it reserves no space until loaded and no-fill/offline leaves core play usable. Production ID injection remains governed by ADS-002. |

# N. Audio and haptics

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| AV-001 | Audio service and preload policy | P1 | PLANNED | ENG-005 | Sounds are cached selectively, lifecycle-aware, and disposed safely. |
| AV-002 | Gameplay sound effects | P1 | PLANNED | AV-001, GAME-003 | Pickup, correct, wrong, combo, coin, star, win, and loss profiles exist. |
| AV-003 | World music system | P2 | PLANNED | AV-001, WORLD-001 | Per-world loops, crossfade, focus loss, background, and resume are handled. |
| AV-004 | Haptic feedback service | P1 | PLANNED | MOT-001 | Event-strength mapping and unsupported-device fallback exist. |
| AV-005 | Sound/music/haptics settings | P1 | PLANNED | AV-001, AV-004 | Persisted toggles and immediate application work. |
| AV-006 | Motion-audio-haptic synchronization | P1 | PLANNED | MOT-007, AV-002, AV-004 | Same event has one coordinated feedback profile. |
| AV-007 | Audio licensing, loudness, and accessibility validation | P1 | PLANNED | AV-001 | Commercial rights, loudness targets, captions/non-audio cues, and headphone safety are documented. |

# O. Localization

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| LOC-001 | English localization | P0 | IMPLEMENTED | ENG-001 | Core ARB/localization framework exists; hard-coded text audit remains. |
| LOC-002 | Arabic localization and RTL | P0 | IMPLEMENTED | LOC-001 | Core language toggle/RTL exist; complete translation audit remains. |
| LOC-003 | No hard-coded user-facing text | P1 | PLANNED | LOC-001 | All visible strings, errors, notifications, and semantics are localized. |
| LOC-004 | City/world name localization | P1 | PLANNED | WORLD-001, LOC-001 | All journey content translates consistently. |
| LOC-005 | Locale-aware numbers, dates, plurals, and fonts | P1 | PLANNED | LOC-001 | Numbers, timers, dates, plural rules, font fallback, and bidi text pass EN/AR tests. |
| LOC-006 | Translation QA and fallback policy | P1 | PLANNED | LOC-003 | Missing keys fail visibly in test, fall back safely in release, and glossary/terminology are documented. |

# P. Accessibility

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| A11Y-001 | Semantic labels for 3D assets | P1 | PLANNED | AST-002, LOC-003 | Interactive/meaningful assets have localized semantics and decorative assets are excluded. |
| A11Y-002 | Large text and screen-reader validation | P1 | PLANNED | UI3D-006 | Core flow has no overflow at supported scaling and is operable with screen reader. |
| A11Y-003 | Reduced motion | P1 | PLANNED | UI3D-007 | Setting affects all shared animation primitives and skips nonessential cinematics. |
| A11Y-004 | Contrast, touch targets, focus, and non-color cues | P1 | PLANNED | UI3D-001 | Text/controls meet target contrast, touch targets, focus order, and state is never color-only. |
| A11Y-005 | Accessibility test matrix and statement | P2 | PLANNED | A11Y-001, A11Y-004 | Manual/automated matrix and known limitations are documented for release. |

# Q. Performance and reliability

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| PERF-001 | Frame performance budget | P0 | PLANNED | MOT-001, AST-004 | Core gameplay meets documented frame targets with graceful fallback. |
| PERF-002 | Memory and image budget | P0 | PLANNED | AST-004 | No unbounded cache and large assets decode near display size. |
| PERF-003 | Pause off-screen animations | P1 | PLANNED | MOT-005 | TickerMode/lifecycle prevents hidden animation work. |
| PERF-004 | Startup time budget | P0 | IMPLEMENTED | ENG-003 | Main UI opens with defaults when optional services are slow; profiling remains. |
| PERF-005 | Low-end device mode | P2 | PLANNED | UI3D-007 | Particles, blur, shadows, and simultaneous animations reduce predictably. |
| PERF-006 | Network and battery efficiency | P1 | PLANNED | ENG-014, RET-007 | Background work, retries, telemetry, ads, and downloads use bounded policies. |
| PERF-007 | App size and asset delivery budget | P1 | PLANNED | AST-010, REL-008 | APK/AAB size, native libs, fonts, and assets meet documented thresholds. |
| REL-001 | ADB/device scripts remain dynamic | P0 | VERIFIED | ENG-002 | `tool/verify_dynamic_android_targets.dart` rejects fixed emulator serials, literal AVD arguments/defaults, and fixed `adb -s` targets; Flutter CI #546 passed the dynamic-target gate across 38 scripts on the merged TEST-001 checkpoint. |
| REL-002 | Kotlin incremental-cache recovery | P0 | IMPLEMENTED | ENG-002 | Shared build repair performs cleanup/retry; multi-machine verification remains. |
| REL-003 | Runtime resilience and watchdog policy | P1 | PLANNED | ENG-004, ENG-014 | Recoverable failures surface actionable UI/logs without restart loops or data loss. |
| REL-004 | Storage corruption backup/recovery | P0 | VERIFIED | ENG-008 | PR #107 verifies versioned pre-repair snapshots, single-backup preservation across multiple repairs, safe normalization/removal, diagnostics, unrelated-state preservation, and continued recovery when snapshot creation fails. Flutter CI #551 passed formatting, Analyze, the full Flutter suite, Debug APK build, and artifact upload before merge. |

# R. Testing and quality gates

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| TEST-001 | Progress/economy unit tests | P0 | VERIFIED | ENG-008 | `progress_store_test.dart` covers wallet bounds, hearts, boosters, best-star persistence, milestone/world first-clear rewards, final-level bounds, duplicate daily-mission claims, corrupt-value backup/repair, and legacy-save compatibility with safe defaults for newer fields. PR #97 adds interruption-safe shop purchase/recovery coverage; PR #104 added explicit legacy-save migration compatibility. Flutter CI #546 passed Analyze, the full Flutter suite, Debug APK build, and artifact upload. |
| TEST-002 | Level generator and solvability tests | P0 | PLANNED | LEVEL-003 | Levels 1, 25, 26, 150 and every generated configuration validate. |
| TEST-003 | Core screen widget tests | P1 | PLANNED | UI3D-006 | Home, map, briefing, game, result, and shop pass key sizes/languages. |
| TEST-004 | Navigation race regression tests | P0 | VERIFIED | NAV-001 | PR #109 hardens result-route dismissal against repeated actions and adds deterministic integration coverage for repeated Next, Retry, and Home Start actions; existing `GameNavigator` tests cover concurrent/named duplicate-push guards. Flutter CI #571 passed formatting, Analyze, the full 214-test Flutter suite, Debug APK build, and artifact upload. Debug artifact #9031075109 is 80,515,902 bytes with SHA-256 `299e710a467672c57c91fd956669d67506cf5534b8741499066032ff9e60b539`. |
| TEST-005 | Missing asset tests | P1 | PLANNED | AST-003 | Missing/corrupt asset fallback remains visible and functional. |
| TEST-006 | Golden visual tests | P2 | PLANNED | UI3D-004 | Critical screens have stable EN/AR snapshots at representative sizes. |
| TEST-007 | Integration and end-to-end critical path | P0 | PLANNED | TEST-001, TEST-003 | First run through level completion, reward, shop, restart, and restore passes. |
| TEST-008 | Coverage thresholds and flaky-test policy | P1 | PLANNED | ENG-007 | Coverage targets, retries, quarantine rules, and failure ownership are enforced. |
| TEST-009 | Device/API compatibility matrix | P0 | PLANNED | ENG-002, PERF-001 | Supported Android API/ABI, phone/tablet, low/mid/high tiers, and physical-device smoke tests are recorded. |
| TEST-010 | Dashboard/catalog parser validation | P1 | PLANNED | ENG-007 | CI confirms phases A–S, table schema, unique IDs, valid statuses/dependencies, and dashboard rendering. |
| TEST-011 | Privacy, consent, and security verification | P0 | PLANNED | PRIV-001, SEC-001 | Consent, data deletion, redaction, secret scan, dependency scan, and network policy pass. |
| TEST-012 | Release candidate smoke and soak tests | P0 | PLANNED | REL-008, TEST-007 | Signed candidate installs/updates, survives repeated sessions, offline/online changes, and backgrounding. |

# S. Release, privacy, security, and store readiness

| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |
|---|---|---:|---|---|---|
| PRIV-001 | Privacy inventory, consent, and data minimization | P0 | PLANNED | ENG-001 | Every collected datum, purpose, retention, consent, processor, and deletion path is documented. |
| PRIV-002 | Privacy policy and Play Data safety mapping | P0 | PLANNED | PRIV-001, ADS-007 | Published policy and store disclosures match actual SDK/data behavior. |
| PRIV-003 | User data export/deletion readiness | P1 | PLANNED | PRIV-001, ENG-008 | Local/remote data handling includes deletion/reset/export procedures where applicable. |
| SEC-001 | Mobile security baseline and threat model | P0 | PLANNED | ENG-010 | Threats, trust boundaries, secure storage, network rules, tamper risks, and mitigations are documented. |
| SEC-002 | Dependency, secret, and artifact security scans | P0 | PLANNED | ENG-006, ENG-010, ENG-007 | CI blocks committed secrets, critical vulnerable dependencies, and sensitive build artifacts. |
| SEC-003 | App integrity, obfuscation, and release hardening | P1 | PLANNED | SEC-001, REL-008 | R8/obfuscation/integrity choices are tested without breaking ads, logging, or stack traces. |
| LEGAL-001 | Open-source notices and content rights | P0 | PLANNED | ENG-006, AST-011, AV-007 | Third-party licenses, asset/audio rights, notices, trademarks, and age-rating inputs are complete. |
| REL-005 | Versioning and release notes | P1 | PLANNED | ENG-007 | Version/build are updated consistently and release notes/changelog are generated. |
| REL-006 | Android signing and key-management procedure | P0 | VERIFIED | ENG-002, ENG-010 | PR #102 added `VERIFY_RELEASE_INPUTS.ps1`, redacted signing/AdMob preflight, PowerShell contract coverage, `docs/ANDROID_SIGNING.md`, backup/recovery/rotation guidance, and production handoff rules. Flutter CI #544 and Android Release Packaging Smoke #4 both passed; release-smoke evidence artifact #9030181913 has SHA-256 `6b27c786fe315739f27825e39514971a1f05f182bb34cdb36ac77cc0a625589f`. |
| REL-007 | Release APK | P0 | PLANNED | TEST-012, REL-006 | PR #99 proves release-mode APK packaging with ephemeral CI signing (55.8 MB; SHA-256 `2f6b2b5d3eb7de9a9029b0f51ae2e8a7e69a3c3278feb230abb116e4b56778dd`), but this smoke binary is non-distributable. VERIFIED still requires the real production-signed candidate to install, launch, upgrade, and pass device smoke checks. |
| REL-008 | Release AAB | P0 | PLANNED | REL-006, PERF-007 | PR #99 proves release-mode AAB packaging with ephemeral CI signing (57.0 MB; SHA-256 `957c1d4b696ee2547e97faa796544b3ab514fa2660681d4f01876af83a48c548`), but this smoke bundle is non-distributable. VERIFIED still requires real production signing plus bundle/ABI/API/store validation. |
| REL-009 | Play Store listing and asset readiness | P1 | PLANNED | REL-008, PRIV-002, LEGAL-001 | Listing copy, screenshots, feature graphic, icon, localization, category, rating, and contact are complete. |
| REL-010 | Internal/closed/open testing tracks | P1 | PLANNED | REL-008 | Tester groups, staged rollout, feedback, crash/ANR review, and promotion criteria are documented. |
| REL-011 | Production monitoring and rollback | P0 | PLANNED | ENG-013, REL-010 | Crash/ANR/ratings/ads/retention monitoring, rollback/stop rules, and hotfix ownership are documented. |
| REL-012 | Backup, disaster recovery, and release archive | P1 | PLANNED | REL-006, REL-011 | Signing keys, source tag, mapping files, symbols, artifacts, notices, and release evidence are archived securely. |
| REL-013 | Final go/no-go checklist | P0 | PLANNED | All P0 release blockers | All P0 tasks are VERIFIED, known risks accepted, and release owner signs the checklist. |

---

# Active work queue

## IN PROGRESS

- None after `GAME-016` verification.

## NEXT READY

1. `ENG-010` Secret and credential handling — `ENG-009` is VERIFIED; audit injection, redaction, rotation, and CI protection gaps.
2. `PRIV-001` Privacy inventory, consent, and data minimization — `ENG-001` is VERIFIED and the current privacy inventory gate provides a baseline for reconciliation.
3. `ADS-002` Debug test IDs and release configuration — `ADS-001` and `ENG-009` are implemented/verified; reconcile remaining release-ad configuration evidence.

## BLOCKED

- `REL-007`/`REL-008` distribution-ready artifact verification requires the actual production AdMob application configuration and real release signing material, both intentionally external to source control.
- `TEST-009` is not yet ready because its declared `PERF-001` dependency remains PLANNED; physical-device/API matrix work should follow performance-budget definition.
- Final `TEST-012` install/update/soak evidence also requires an Android device or testing track with the production-signed candidate.

## Recently verified

- `GAME-016` Input determinism and anti-spam state machine — PR #111 merged after Flutter CI #580 passed all 215 tests plus Debug APK build/upload; cargo/warehouse spam, selection locking, resolution input disablement, and result-boundary guards are deterministic.
- `REL-006` Android signing and key-management procedure — PR #102 merged as `8f2e4ddb69d339938ba05911fb297960859e1a77`; Flutter CI #544 and Release Packaging Smoke #4 passed the redacted preflight, contract, APK/AAB packaging and evidence gates.
- `TEST-001` Progress/economy unit tests — PR #104 merged as `2ab3578ecc214f995f194eff95f1a27b7cc3f442`; Flutter CI #546 passed full tests and Debug APK after adding explicit legacy-save/default migration coverage.
- `REL-001` ADB/device scripts remain dynamic — current CI validates all discovered PowerShell/batch scripts against fixed emulator/AVD/adb-target patterns; CI #546 passed 38 scripts.
- `ENG-009` Environment and build configuration — PR #95 hardened Android release inputs and PR #99 proved guarded release APK/AAB packaging while current Flutter CI stayed green.
- `SHOP-002` Safe purchase transaction — PR #97 adds interruption-safe absolute-state journaling and idempotent recovery; Flutter CI #536 passed full tests and Debug APK artifact generation.
- `UI3D-006` Responsive screen shell and safe areas — shared fit-shell acceptance plus compact/reference/tablet, large-text, cutout/view-inset, RTL, gameplay/result and scrollable-screen regressions passed through PRs #86–#92; CI #522 built and uploaded the Debug APK successfully.
- `AST-001` Asset folder taxonomy and naming standard — production paths, stable names/IDs, render profiles, lighting, export budgets, accessibility, and provenance handoff are documented and mechanically validated.
- `ENG-001` Repository audit and baseline — architecture, commands, tooling, assets, persistence keys, debt, and risks are recorded in human- and machine-readable evidence.

## Recently implemented

- `NAV-002` Shared route adoption — Home/app-shell and Mission Briefing→Gameplay use the guarded navigator with stable route names; result/back-guard regression coverage is present, while device-wide RC validation remains under #79.
- `AST-002` Asset manifest and typed registry — typed asset metadata, manifest, and registry implementation plus focused tests are present; release/device verification remains before VERIFIED.
- `AST-003` Missing-asset fallback — runtime asset views provide visible fallback behavior with focused widget coverage; release/device verification remains before VERIFIED.
- `MOT-004` Screen transitions — shared RTL-aware route motion, Reduced Motion fallback, central navigator façade, duplicate-push guards, named World Map→Briefing integration, and focused navigation tests added; latest Flutter CI/device verification pending.
- `UI3D-004` Reusable 3D card and panel system — shared panels adopted in Home, Shop, and Progress Hub with focused regression tests; latest Flutter CI/device verification pending.