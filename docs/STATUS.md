# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Active checkpoint | `MOT-005` Ambient home/world motion |
| Status | IN PROGRESS — Home implementation complete; full CI, world-map adoption, and device review remain |
| Implementation commit | `bfc16deb36bf3d675ca0c9f2b9df2b9713ebdd05` |
| Previous checkpoint | `MOT-010` lifecycle-safe ticker boundaries |
| Next checkpoint | Apply the shared ambient-motion layer to the world/city map |

## MOT-005 home implementation evidence — 2026-08-07

- Added `HomeAmbientBackground` with a low-cost custom painter and one shared ticker.
- Added animated gradient lighting, two parallax glow fields, drifting cloud layers, and subtle road depth.
- Wrapped painting in `RepaintBoundary` to isolate repaints from the Home content tree.
- Reduced motion stops the ticker and renders a stable frame.
- Existing `MotionLifecycleScope` pauses the ticker automatically when the app is backgrounded or hidden.
- Integrated the backdrop behind the existing responsive, RTL/LTR-safe Home content without changing gameplay or persistence.
- Added widget tests for rendering, reduced motion, disposal, and ticker-leak safety.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Patch anchors and Dart format | PASSED |
| 2026-08-07 | Flutter Analyze | PASSED — no issues found |
| 2026-08-07 | Home ambient focused tests | PASSED — 2/2 |
| 2026-08-07 | Full Flutter test suite | RUNNING in Flutter CI |
| 2026-08-07 | Debug APK build | RUNNING in Flutter CI |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables and phases A–S preserved |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter test test\features\home\home_ambient_background_test.dart
flutter analyze
flutter test
flutter run
```
