# CARGame Repository Baseline

## Audit identity

| Field | Baseline |
|---|---|
| Captured | 2026-08-07 |
| Source revision | `b5952de97f1fc0512c1e2577d26fe0e8966756c5` |
| Scope | Tracked source, platform configuration, tooling, assets, persistence, tests, and delivery risks |
| Catalog feature | `ENG-001` |

This is an evidence snapshot, not a replacement for `docs/FEATURE_CATALOG.md`. The
catalog remains the only source for status and progress. The Developer Portal reads
the machine-readable inventory from `docs/dashboard/baseline.json` separately.

## Repository inventory

| Area | Evidence | Baseline |
|---|---|---|
| Repository | `git ls-files` | 111 tracked files after this checkpoint |
| Flutter source | `lib/**/*.dart` | 30 files |
| Flutter tests | `test/**/*.dart` | 11 files |
| Tooling | Root `*.ps1` and `*.bat` | 21 PowerShell and 13 batch files |
| Localization | `lib/l10n/*.arb` | English and Arabic ARB files; generated Dart output is tracked |
| Binary assets | `pubspec.yaml`, `git ls-files assets` | No declared asset bundles and no tracked asset files |
| Dashboard | `docs/dashboard/index.html` | Catalog-derived progress plus non-progress baseline inventory |
| Platform hosts | tracked Android/iOS paths | Partial hosts; generated wrapper/project files are not tracked |

## Architecture baseline

The composition root is `lib/main.dart`. It creates one `ProgressStore`, one
`AppSettingsStore`, and one `OptionalServiceCoordinator`, then passes the stores
through widget constructors. This is explicit dependency injection without a service
locator or hidden mutable application state. Startup treats logger, orientation,
settings, local progress, and ads as bounded or optional work so the offline game can
open with safe defaults.

The current module boundaries are:

- `lib/core`: ads, logging/error boundary, motion/lifecycle primitives, optional
  service coordination, settings/storage, theme, and shared widgets.
- `lib/features`: game, home, levels, progress, settings, and shop presentation plus
  game-local models/content.
- `lib/l10n`: ARB inputs and generated localization output.
- `test/core` and `test/features`: 11 focused unit/widget test files.

The architecture is feature-first at the presentation layer but not yet cleanly
layered. Domain rules and persistence mutations live inside `ProgressStore`, concrete
`SharedPreferencesAsync` instances are constructed by stores, and `GameScreen` may
construct `AdService`. Repository interfaces, application use cases, and explicit
service ports do not yet exist. `ENG-005` owns that separation; this audit does not
redesign working modules.

## Toolchain and baseline commands

The canonical automated environment is Flutter 3.44.8 on stable with Dart
`>=3.10.0 <4.0.0`, JDK 17, Android minSdk 23, AGP 8.11.1, and Kotlin 2.3.20.
`pubspec.lock` is tracked. README and CI now name the same Flutter baseline.

Run the non-destructive code gate from the repository root:

```powershell
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug --no-pub
```

Run the Windows toolchain self-test before device work:

```powershell
powershell -ExecutionPolicy Bypass -File .\TEST_BUILD_TOOLCHAIN.ps1
powershell -ExecutionPolicy Bypass -File .\TEST_BUILD_TOOLCHAIN.ps1 -EnvironmentCheck
```

Use `BUILD_COMMON.ps1` as the shared JDK/SDK/build implementation and
`COLD_BOOT_AND_RUN.ps1` for dynamic device discovery. `BUILD_RELEASE.ps1` and
`BUILD_RELEASE_V2.ps1` are build entry points. `OPEN_DEVELOPMENT_DASHBOARD.ps1`
serves the portal over localhost. `SYNC_AND_BUILD.ps1` intentionally performs
`git reset --hard` and `git clean -xfd`; it is a recovery workflow and must never be
used with uncommitted work.

The repository currently carries several older `*_V2` and batch wrappers around
overlapping flows. `ENG-011` owns consolidation and clean-machine documentation;
`ENG-002` owns final Windows/device verification.

## Dependency and asset baseline

Direct runtime packages are Flame 1.38.0, Google Mobile Ads 9.0.0,
Shared Preferences 2.5.5, Path Provider 2.1.6, and Cupertino Icons 1.0.9 as resolved
in `pubspec.lock`. Flame is declared but the current game flow uses Flutter widgets.
Dependency review, license inventory, update policy, and removal of unused packages
remain under `ENG-006` and `LEGAL-004`.

There is no `assets/` tree and no `flutter.assets` declaration. Current premium
visuals are code-rendered widgets and custom painters. Phase D must establish the
asset taxonomy, typed registry, fallbacks, provenance, memory budgets, and production
packs before binary art is introduced.

## Persistence inventory

Both stores use `SharedPreferencesAsync`. There are 28 stable key families: 24 scalar
or list families plus the dynamic `level_stars_<1..150>` family in `ProgressStore`,
and three boolean settings keys in `AppSettingsStore`.

| Domain | Keys / families | Defaults and validation |
|---|---|---|
| Progress | `highest_unlocked_level`, `level_stars_<n>` | Level 1; levels clamp 1–150 and stars clamp 0–3 |
| Wallet/energy | `coins`, `hearts`, `heart_refill_timestamp` | 100 coins; 5 hearts; parse-safe ISO timestamp |
| Daily systems | `daily_reward_date`, `mission_date`, `mission_wins`, `mission_stars`, `mission_coins`, `mission_claimed` | Date mismatch resets mission counters |
| Statistics/XP | `stats_games`, `stats_wins`, `stats_losses`, `stats_coins_earned`, `stats_perfect_wins`, `stats_best_combo`, `stats_win_streak`, `stats_best_win_streak`, `player_xp` | Numeric zero |
| Shop/boosters | `selected_shop_theme`, `unlocked_shop_themes`, `booster_free_hints`, `booster_extra_moves`, `booster_combo_shields` | Classic theme; 2/1/1 boosters |
| Settings | `settings_sound`, `settings_music`, `settings_vibration` | All enabled |

No schema-version key, transaction journal, corruption quarantine, or migration runner
exists. Writes spanning multiple keys are not atomic. These gaps remain acceptance
work for `ENG-008`, `ECON-009`, `PERF-016`, and `TEST-004`; existing keys must remain
readable while those features are implemented.

## Debt and risk register

| Severity | Finding | Evidence | Owning feature |
|---|---|---|---|
| P0 | Android Gradle wrapper and full iOS host project are not tracked; clean checkout build reproducibility depends on regeneration. | `git ls-files android ios` | `ENG-002`, `ENG-011` |
| P0 | Android release currently uses the debug signing configuration. | `android/app/build.gradle.kts` | `REL-002`, `REL-003` |
| P0 | Rewarded flow grants the reward when inventory is absent or presentation fails, allowing an economy bypass. | `lib/core/ads/ad_service.dart` | `ADS-002`, `ECON-004` |
| P0 | Persistence has no schema version or atomic multi-key transaction boundary. | `ProgressStore`, `AppSettingsStore` | `ENG-008`, `ECON-009` |
| P1 | Domain, application, repository, and platform boundaries are incomplete. | Stores and `GameScreen` construct concrete dependencies | `ENG-005` |
| P1 | No binary asset registry, fallbacks, provenance records, or tracked production assets exist. | `pubspec.yaml`, tracked files | Phase D |
| P1 | Root tooling has 34 PowerShell/batch entry files with overlapping legacy/V2 behavior. | Root script inventory | `ENG-011` |
| P1 | Full build/test evidence depends on CI because this audit environment has no Flutter/Dart SDK. | command discovery | `ENG-002`, `ENG-007` |
| P2 | Runtime app version constants can drift from `pubspec.yaml`. | `lib/main.dart`, `pubspec.yaml` | `REL-001` |
| P2 | Logger bounds in-memory entries but not the on-disk append-only file. | `lib/core/logging/app_logger.dart` | `PERF-012`, `OBS-003` |

## Baseline conclusion

The repository has a playable offline-first Flutter core, explicit store injection,
localized presentation, reusable motion, focused tests, and a CI definition. It is
not yet a reproducible release repository or a clean-architecture production system.
The catalog already contains owners for every material gap found here, so no new
feature IDs are required. Future checkpoints must update this snapshot and
`docs/dashboard/baseline.json` when these measured facts change.
