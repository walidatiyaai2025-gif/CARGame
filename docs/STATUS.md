# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Completed checkpoint | `MOT-005` Ambient home/world motion |
| Status | IMPLEMENTED — Home and world-map integration complete; CI and physical-device review pending |
| Home implementation commit | `bfc16deb36bf3d675ca0c9f2b9df2b9713ebdd05` |
| World-map integration commit | `8b33f4491f0128adec6e806e6b3ff063982f550b` |
| Next recommended feature | `MOT-006` Product pickup, travel, placement, settle |

## MOT-005 implementation evidence — 2026-08-07

- Added a low-cost animated backdrop with gradient lighting, glow parallax, drifting clouds, and subtle depth.
- Home and World Map now reuse the same production painter and animation-controller implementation.
- World Map preserves all existing progress, locked/open/completed city states, stars, responsive grid behavior, navigation, and RTL/LTR behavior.
- Each visible route uses one ticker and one `RepaintBoundary`; no second painter implementation was introduced.
- Reduced Motion stops animation and renders a stable frame.
- Existing `MotionLifecycleScope` pauses animation while routes are hidden or the application is backgrounded.
- Added focused tests for Home rendering/disposal and World Map scrollable coexistence/reduced-motion disposal.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Flutter Analyze before world-map integration | PASSED — no issues found |
| 2026-08-07 | Home ambient focused tests | PASSED — 2/2 |
| 2026-08-07 | World-map focused tests | PENDING in Flutter CI |
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
flutter test test\features\home\home_ambient_background_test.dart
flutter test test\features\levels\world_map_ambient_background_test.dart
flutter test
flutter run
```
