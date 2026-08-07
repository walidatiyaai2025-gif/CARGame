# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Active checkpoint | `MOT-006` Product pickup, travel, placement, settle |
| Status | IN PROGRESS — pickup and placement feedback implemented; full travel path and physical-device review remain |
| Implementation commit | `03c741a8627e6c48feeb8bf28624c1c86e079a56` |
| Previous checkpoint | `MOT-005` lifecycle-safe Home and World Map ambient motion |
| Next checkpoint | Animate cargo between measured source and warehouse coordinates without changing deterministic state timing |

## MOT-006 implementation evidence — 2026-08-07

- Added reusable `CargoMotionTile` and `WarehouseMotionTarget` primitives based on shared motion tokens.
- Selected cargo lifts, scales, and receives clear pickup feedback.
- Cargo and warehouse input are locked while a placement action resolves, preventing repeated taps and duplicate move consumption.
- The selected warehouse gives correct spring-settle or wrong recoil feedback before board state changes.
- Moves, combo, remaining cargo, win/loss checks, rewards, and persistence still mutate exactly once after the motion delay.
- Reduced Motion shortens durations and removes unnecessary movement.
- Added focused widget tests for pickup, correct placement settle, disposal safety, and reduced motion.
- Fixed the invalid const wrapper in the World Map motion test so the project-wide analyzer gate can proceed.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Dart format | PASSED |
| 2026-08-07 | Flutter Analyze | PASSED — no issues found |
| 2026-08-07 | Cargo motion focused tests | PASSED — 3/3 |
| 2026-08-07 | Deterministic input guard review | PASSED |
| 2026-08-07 | Full Flutter test suite | PENDING in Flutter CI |
| 2026-08-07 | Debug APK build | PENDING in Flutter CI |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables and phases A–S preserved |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter analyze
flutter test test\features\game\cargo_motion_tile_test.dart
flutter test
flutter run
```
