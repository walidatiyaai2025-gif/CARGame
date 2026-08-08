# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | Android RC hardening — issue #79 |
| Completed checkpoint | `UI3D-006` responsive screen shell and safe-area automated matrix |
| Status | VERIFIED — UI3D-006 acceptance is complete. PRs #86–#92 cover shared fit behavior, gameplay/result reachability, compact/reference/tablet sizes, large text, safe-area cutouts, keyboard/view insets, RTL, and intentionally scrollable Shop/Progress cases. Applicable checkpoints passed formatting, Analyze, full Flutter tests, Debug APK build, and artifact upload before merge. |
| Previous checkpoint | PR #92 Settings RTL validation merged as `88c17828afa4fd7de52cfe29550a107cb34d1ee3` after Flutter CI #522 passed the complete gate set |
| Next recommended feature | RC-001: audit remaining P0/P1 runtime blockers under #79, select the highest-priority unblocked catalog item, then execute full Android RC release verification/artifacts |
| Known blocker | No known Android development blocker. Physical-device and signed-release validation remain part of the broader RC/release gates, not UI3D-006. Visual Studio C++ components remain optional for Windows desktop only. |

## RC / UI3D reconciliation — 2026-08-09

- RC tracking remains under issue #79. UI3D-006 automated responsive acceptance is complete; execution now advances to the remaining P0/P1 runtime-blocker audit, followed by full Android RC release verification and artifacts.
- `docs/work/UI3D-006.md` already records the feature as VERIFIED; `docs/FEATURE_CATALOG.md` is reconciled to the same state in the UI3D-006 closeout change.
- PR #85 completed Mission Briefing -> Gameplay adoption through `GameNavigator` and closed the known NAV-002 mission-flow gap.
- PR #86 merged as `9d04dc9848706a46043d0fd9e6a4ef13eeeea6bf`; Flutter CI #503 passed formatting, Analyze, optional-service isolation, GameButton tests, the full Flutter test suite, Debug APK build, and debug APK artifact upload.
- PR #87 merged as `323f7fe0fb4bf55b5c0206059f8d04e6eb6a235b`; Flutter CI #505 passed the same full gate set while adding gameplay RTL and cutout coverage.
- PR #88 merged as `0dfcfd7c46d5ba80b0aee9648fcdf5973091b634`; Flutter CI #507 passed the same full gate set while validating the compact loss-result sheet, reachable Retry action, and guarded system-back behavior.
- PR #90 merged as `ffc437dc486cf560383e27e38c15b3db676516ce`; Flutter CI #511 passed the full gate set while validating Shop RTL and cutout layouts.
- PR #91 merged as `7eb16d6cf747d9db23fa15703386cfbbf67d9da8`; Flutter CI #516 passed the full gate set while validating Progress Hub cutout/safe-area behavior and scroll reachability.
- PR #92 merged as `88c17828afa4fd7de52cfe29550a107cb34d1ee3`; Flutter CI #522 passed formatting, whitespace, Analyze, focused tests, full Flutter tests, Debug APK build, and artifact upload while validating Settings RTL layout.
- CI #522 artifact `cargame-debug-apk`: artifact id `9029071810`, 80,509,116 bytes, SHA-256 `c70c51470539b1de3a8594023a6bf149c17958b64826618dc9dbcb45231d1792`.
- Physical-device visual review remains part of RC/device verification and does not reopen the automated UI3D-006 feature acceptance.

## Tracking reconciliation — 2026-08-07

- Repository evidence shows the typed asset model, manifest, registry, runtime asset views, and focused tests already exist under `lib/core/assets` and `test/core/assets`.
- `AST-002` and `AST-003` therefore require catalog promotion to `IMPLEMENTED`; they must not be marked `VERIFIED` until the catalog/dashboard integrity and applicable CI evidence are complete.
- UI3D-006 was the sole active feature during the responsive workstream; it is now VERIFIED by the 2026-08-09 reconciliation above.
- PR #62 merged the first NAV-002 Home/app-shell checkpoint; later NAV-002 mission-flow adoption is recorded in the 2026-08-09 reconciliation above.
- Issue #54 tracks the remaining historical catalog reconciliation so status and feature catalog stay consistent with repository evidence.

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
- Historical note: Flutter previously reported Gradle 8.13.0 as nearing end of support. Current repository validation no longer treats that warning as an active Android blocker.

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
| 2026-08-07 | Setup Tool Git ownership recovery | IMPLEMENTED — v2.6.1 adds project-scoped `safe.directory` repair and one retry for dubious ownership |
| 2026-08-07 | MOT-004 shared route primitive and World Map adoption | IMPLEMENTED — CI/device-wide route adoption remains under NAV-002 |
| 2026-08-07 | NAV-002 Home/app-shell checkpoint | PASSED — PR #62 merged after Flutter CI run #433 completed successfully with Debug APK artifact uploaded |
| 2026-08-09 | UI3D-006 GameFitView hardening | PASSED — PR #86 / CI #503, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Gameplay RTL/cutout validation | PASSED — PR #87 / CI #505, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Compact result/back-guard validation | PASSED — PR #88 / CI #507, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Shop RTL/cutout validation | PASSED — PR #90 / CI #511, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Progress Hub cutout validation | PASSED — PR #91 / CI #516, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Settings RTL validation | PASSED — PR #92 / CI #522, full tests + Debug APK + artifact `9029071810` / SHA-256 `c70c51470539b1de3a8594023a6bf149c17958b64826618dc9dbcb45231d1792` |

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
- Home uses the shared fit primitive instead of a screen-local FittedBox implementation.
- Mission Briefing uses the shared fit primitive with tighter vertical rhythm while preserving boosters, wallet, RTL/LTR, SafeArea, and guarded mission launch.
- The automated responsive matrix is now VERIFIED; physical-device visual review is carried by the broader RC/device validation gates.
