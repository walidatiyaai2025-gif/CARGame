# CARGame Live Project Status

This document is the operational summary. Detailed feature tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically from that catalog.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Completed checkpoint | `MOT-001` Motion tokens and reusable animation primitives |
| Status | IMPLEMENTED — CI verification started; physical-device motion review remains |
| Implementation commit | `33416064a1c1b24844ab784c4f9aa0524f658e8a` |
| Next recommended feature | `MOT-010` Animation lifecycle and interruption safety |
| Build foundation | `ENG-002` moved to IMPLEMENTED; Windows device verification remains |

## MOT-001 implementation evidence — 2026-08-07

- Added `lib/core/motion/game_motion.dart` as the single motion-token source.
- Centralized tap, fast, standard, modal, reward, and idle duration budgets.
- Centralized enter, exit, emphasized, and spring-release curves.
- Added reusable button and placement spring descriptions.
- Added `GameMotionProfile` for duration, distance, scale, and curve adaptation.
- Reduced motion follows `MediaQuery.disableAnimations`, removes travel/scale, and keeps brief functional feedback.
- `GameButton` now consumes motion tokens instead of local duration/curve/amplitude literals.
- Added focused tests for documented motion budgets, reduced-motion behavior, and MediaQuery integration.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Motion-token static integration review | PASSED |
| 2026-08-07 | Patch application, Dart format, and whitespace validation | PASSED |
| 2026-08-07 | Motion budget and reduced-motion tests | RUNNING in Flutter CI |
| 2026-08-07 | Existing GameButton tests | RUNNING in Flutter CI |
| 2026-08-07 | Full Flutter test suite | RUNNING in Flutter CI |
| 2026-08-07 | Debug APK build | RUNNING in Flutter CI |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables and phases A–S preserved |

## Known limitations and next work

1. Physical-device review is still required to confirm press response and reduced-motion behavior.
2. Existing screens outside `GameButton` still need migration to the shared motion tokens.
3. `MOT-010` should add lifecycle-safe reusable controllers and off-screen pause behavior.

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter test test\core\motion\game_motion_test.dart
flutter test test\core\widgets\game_button_test.dart
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run
```
