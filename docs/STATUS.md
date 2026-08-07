# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Completed checkpoint | `MOT-010` Animation lifecycle and interruption safety |
| Status | IMPLEMENTED — CI and physical-device lifecycle review pending |
| Previous checkpoint | `MOT-001` shared motion tokens; Analyze and full tests passed before MOT-010 |
| Next recommended feature | `MOT-006` Product pickup, travel, placement, settle |

## MOT-010 implementation evidence — 2026-08-07

- Added `MotionLifecycleScope` as a reusable ticker lifecycle boundary.
- Descendant tickers stop when the app is paused/inactive, an ancestor disables tickers, or reduced motion is requested.
- Tickers resume once when the application returns to the resumed state.
- The observer is registered and removed with widget lifecycle, preventing retained observers.
- Integrated the boundary around the premium splash and the full authenticated game route tree.
- Added focused widget tests for resumed, paused/resumed, reduced-motion, and ancestor ticker behavior.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Pre-checkpoint Flutter Analyze | PASSED |
| 2026-08-07 | Pre-checkpoint full Flutter tests | PASSED |
| 2026-08-07 | MOT-010 format and static integration | PASSED in implementation workflow |
| 2026-08-07 | MOT-010 focused lifecycle tests | PENDING in Flutter CI |
| 2026-08-07 | Full test suite and Debug APK | PENDING in Flutter CI |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables and phases A–S preserved |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter test test\core\motion\motion_lifecycle_scope_test.dart
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run
```
