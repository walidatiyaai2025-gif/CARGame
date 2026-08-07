# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | B — Shared 3D design system |
| Completed checkpoint | `NAV-002` Home/app-shell route adoption checkpoint |
| Status | IMPLEMENTED — PR #62 merged at `f953607f1cc182c86d9ec02cb189cea5168c7402`; Flutter CI run #433 passed formatting, Analyze, focused/full tests, Debug APK build, and artifact upload. Broader NAV-002 briefing/game/result adoption and complete RTL/back-stack validation remain open. |
| Previous checkpoint | `MOT-004` Screen transitions |
| Next recommended feature | `UI3D-006` Continue responsive shell migration and large-text/tablet/cutout validation |
| Known blocker | No Android development blocker. Gradle 8.13.0 still emits a future-support warning and should be made reproducibly >=8.14.0. Visual Studio C++ components are missing only for optional Windows desktop builds. |

## Tracking reconciliation — 2026-08-07

- Repository evidence shows the typed asset model, manifest, registry, runtime asset views, and focused tests already exist under `lib/core/assets` and `test/core/assets`.
- `AST-002` and `AST-003` therefore require catalog promotion to `IMPLEMENTED`; they must not be marked `VERIFIED` until the catalog/dashboard integrity and applicable CI evidence are complete.
- `UI3D-006` remains the sole `IN PROGRESS` feature and must not be overwritten by this docs-only reconciliation.
- PR #62 merged the first NAV-002 Home/app-shell checkpoint; the broader NAV-002 feature remains open for briefing/game/result route adoption and complete RTL/back-stack validation.
- Issue #54 tracks the remaining catalog reconciliation so status and feature catalog stay consistent with repository evidence.

## Workstation Android toolchain evidence — 2026-08-07

- Flutter stable 3.44.8 and Dart 3.12.2 are available from `C:\flutter`.
- Android SDK 37.0.0, platform android-37.1, build-tools 37.0.0, and Emulator 37.1.11 are installed.
- Flutter is explicitly configured to use Temurin JDK 17.0.20+8.
- All Android SDK licenses are accepted and network resources are available.
- `flutter doctor` reports the Android toolchain healthy.
- No Android hardware/emulator was online during this diagnostic snapshot; Windows, Chrome, and Edge were the three detected targets.
- Visual Studio Enterprise 2022 is installed but lacks the Desktop development with C++ workload/components. This is optional for the Android-first product and does not block APK/AAB development.

## Setup Tool safe-directory repair — 2026-08-07

- `SETUP_TOOL.ps1` upgraded to v2.6.1 after Option 14 failed on a Windows repository whose owner SID differed from the current user SID.
- Git operations now call a centralized `Ensure-GitSafeDirectory` preflight before `git -C <project>` commands.
- The tool adds only the current project path to global `safe.directory`; it does not use wildcard trust.
- If Git still returns `dubious ownership`/`safe.directory`, the command is repaired and retried once.
- Startup diagnostics now reports the Git safe-directory state and attempts automatic repair before reading remotes/branch data.
- First clone also registers the newly cloned project path as safe before normal repository operations.
- Fix commit: `1b56d3ba13ab4e413f7562bd01c77becbecd7df9`.

## Workstation release-build evidence — 2026-08-07

- User workstation completed the full Flutter test suite successfully: 159 tests passed.
- User workstation completed `flutter build apk --release --no-pub` successfully.
- Latest release artifact reported at `build/app/outputs/flutter-apk/app-release.apk` with size 53.4 MB.
- Material icon tree shaking reduced the font asset by 99.2% during release build.
- Flutter Analyze previously completed with only two informational unnecessary-import findings; both redundant imports were removed in follow-up commits.
- Flutter reported Gradle 8.13.0 as nearing end of support and recommends >=8.14.0. The wrapper used on the workstation is not currently tracked in the repository, so the toolchain fix must be reproducible rather than machine-local only.

## MOT-004 implementation evidence — 2026-08-07

- Added `GameRoute` as the single shared route-motion primitive with fade plus shared-axis slide.
- Route direction automatically mirrors for Arabic RTL versus English LTR.
- Reduced Motion removes the lateral slide and uses a bounded fade transition.
- Added `GameNavigator` to centralize route names, replacement, and duplicate-push guards.
- Guard keys are released in `finally`, so returning from a route cannot leave navigation permanently locked.
- Added focused tests for route names/results, replacement, RTL/LTR motion, Reduced Motion, and concurrent duplicate-push rejection.
- World Map city navigation now opens `CityBriefingScreen` through `GameNavigator` using `/briefing/level/<number>` route names and per-level guard keys.
- Added a World Map regression test that verifies the first unlocked city opens through the named shared route without relying on `pumpAndSettle` while ambient motion is active.
- Implementation commits include `c7244ac4b0934c6415d38b2638d4a9646e2cfa31`, `c209b3433b1750e11727b26f6f01254315cfefd9`, `aee4063b78f63064c1f2dba101db277134b6b9c4`, `c279f2648d39e406a11ce2dc1d767adea4152988`, and `94b7ecab2c76616a547699e19fbf13abb11420db`.
- `MOT-004` is IMPLEMENTED rather than VERIFIED because full-route adoption is intentionally tracked separately by `NAV-002`.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Flutter doctor — Android toolchain | PASSED — Flutter 3.44.8, Dart 3.12.2, Android SDK 37.0.0, JDK 17.0.20, all licenses accepted |
| 2026-08-07 | Flutter doctor — Windows desktop | OPTIONAL INCOMPLETE — Visual Studio lacks C++ workload/components; does not block Android release work |
| 2026-08-07 | Full Flutter test suite on workstation | PASSED — 159 tests |
| 2026-08-07 | Workstation Release APK | PASSED — `app-release.apk` built successfully, 53.4 MB |
| 2026-08-07 | Material icon tree shaking | PASSED — 99.2% reduction reported in release build |
| 2026-08-07 | Gradle support policy | WARNING — local wrapper is 8.13.0; Flutter recommends >=8.14.0 |
| 2026-08-07 | Setup Tool Git ownership recovery | IMPLEMENTED — v2.6.1 adds project-scoped `safe.directory` repair and one retry for dubious ownership |
| 2026-08-07 | MOT-004 shared route primitive and World Map adoption | IMPLEMENTED — CI/device-wide route adoption remains under NAV-002 |
| 2026-08-07 | NAV-002 Home/app-shell checkpoint | PASSED — PR #62 merged after Flutter CI run #433 completed successfully with Debug APK artifact uploaded |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
dart format lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release --no-pub
flutter run
```

## Fullscreen home + banner checkpoint — 2026-08-07

- Android/iOS app shell requests immersive-sticky fullscreen at startup while retaining portrait orientation policy.
- Home no longer uses a ListView/scroll container; content scales down as one bounded composition and compact resource/hero cards reclaim vertical space.
- Google Mobile Ads banner footer is isolated from offline core play, uses official debug test IDs, and occupies no footer space until an ad actually loads.
- Full checkpoint verification passed in GitHub Actions: Dart format, Flutter Analyze with no issues, full Flutter tests, and Debug APK build.
- Added regression coverage for 360x640 and 412x915 home layouts with no ListView/SingleChildScrollView and no captured Flutter layout exception.
- Release ad unit injection/consent remain separate ADS-002/ADS-007 work and are not claimed complete.

## UI3D-006 fit shell checkpoint — 2026-08-07

- Added reusable `GameFitView` for bounded game screens that must remain fully visible without a scroll container.
- Home now uses the shared fit primitive instead of a screen-local FittedBox implementation.
- Mission Briefing replaces its ListView with the shared fit primitive and tighter vertical rhythm while preserving boosters, wallet, RTL/LTR, SafeArea, and guarded mission launch.
- UI3D-006 remains IN PROGRESS until remaining short screens and large-text/tablet/cutout cases are migrated and verified.
