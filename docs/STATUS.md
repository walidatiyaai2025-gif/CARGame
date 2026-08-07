# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Completed checkpoint | `MOT-006` Product pickup, travel, placement, settle |
| Status | IMPLEMENTED — Flutter CI and physical-device motion review pending |
| Previous checkpoint | `MOT-005` lifecycle-safe Home and World Map ambient motion |
| Next recommended feature | `MOT-007` Correct/wrong/combo feedback |
| Known blocker | Local environment has no Flutter/Dart SDK; required commands are delegated to repository CI |

## MOT-006 implementation evidence — 2026-08-07

- Reused the shared `CargoMotionTile` and `WarehouseMotionTarget` primitives for source lift/busy state and target settle.
- Added reusable `GameTravelMotion` with measured source-to-target curved travel, pickup lift, arrival settle, repaint isolation, lifecycle-safe disposal, and excluded duplicate semantics.
- Cargo and warehouse tap coordinates are captured from the live board; duplicate cargo instances resolve by stable selected index.
- Gameplay, boosters, restart, and back navigation remain locked until resolution completes; moves, combo, remaining cargo, win/loss, rewards, and persistence mutate exactly once.
- Reduced Motion renders destination feedback and completes after the frame without relying on a disabled ticker.
- Added focused widget tests for one-time travel completion, ticker-disabled Reduced Motion, and repeated warehouse input during resolution.
- Preserved the existing World Map analyzer cleanup and all MOT-005 work from the concurrent mainline updates.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Pre-travel Flutter Analyze | PASSED — no issues found at the pickup/placement checkpoint |
| 2026-08-07 | Cargo motion primitive tests | PASSED — 3/3 before coordinate travel integration |
| 2026-08-07 | Dart syntax and formatting for all `lib`/`test` sources | PASSED — 39 files parsed by `dart_style` WASM with zero formatting drift |
| 2026-08-07 | Git whitespace validation | PASSED — `git diff --check` |
| 2026-08-07 | Flutter Analyze after coordinate travel | BLOCKED locally — Flutter SDK unavailable; CI pending |
| 2026-08-07 | Focused and full Flutter tests after coordinate travel | BLOCKED locally — Flutter SDK unavailable; CI pending |
| 2026-08-07 | Debug APK | BLOCKED locally — Flutter SDK unavailable; CI pending |
| 2026-08-07 | Dashboard/catalog integrity | PASSED — phases A–S, six-column task rows, unique IDs, dependencies, statuses, and single-active-task rule validated |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test test\features\game\cargo_motion_tile_test.dart
flutter test test\core\motion\game_travel_motion_test.dart
flutter test test\features\game\game_screen_motion_test.dart
flutter test
flutter build apk --debug
flutter run
```
