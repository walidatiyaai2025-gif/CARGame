# CARGame Live Project Status

This document is the operational summary. Detailed feature tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically from that catalog.

## Current work

| Field | Value |
|---|---|
| Current phase | B/C — Shared 3D UI and motion |
| Active primary feature | `MOT-003` Universal Button Motion System |
| Status | IN PROGRESS — shared component and Settings adoption implemented; major CTA adoption remains |
| Catalog alignment | Explicitly reconciled: `MOT-003` now tracks universal button adoption; resource interpolation moved to `MOT-011`. |
| Integrated screen | Settings: Language, Privacy, and About actions |
| Next checkpoint | Adopt `GameButton` in Home Start, mission launch, result Next/Retry, and shop purchase flows without duplicating motion logic. |

## GameButton implementation evidence — 2026-08-07

- Added one reusable `GameButton` component under `lib/core/widgets`.
- Press depth responds immediately and releases using an elastic spring curve.
- Desktop/web hover raises and highlights the button without affecting mobile behavior.
- Disabled and externally controlled loading states are supported.
- Async callbacks are guarded so rapid repeated taps execute only once until completion.
- Haptic feedback is optional and respects the persisted vibration setting where integrated.
- A sound hook is provided without hard-coding an audio package or asset.
- Ink ripple/highlight, semantic button state, keyboard activation, focus behavior, and mouse cursors are included.
- Directionality is inherited, preserving RTL/LTR child layout and responsive composition.
- Settings language, privacy, and about actions use the shared component.
- Five focused widget tests cover async tap deduplication, disabled state, loading state, RTL, and sound-hook ordering.
- The Home smoke test uses an in-memory asynchronous preferences platform and bounded pumping, so ambient looping motion no longer causes `pumpAndSettle` timeouts.

## Changed areas

- `lib/core/widgets/game_button.dart`
- `lib/features/settings/settings_screen.dart`
- `test/core/widgets/game_button_test.dart`
- `test/widget_test.dart`
- `pubspec.yaml`
- `.github/workflows/flutter_ci.yml`
- `docs/FEATURE_CATALOG.md`
- `docs/STATUS.md`

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Static component and Settings integration review | PASSED |
| 2026-08-07 | Flutter Analyze in GitHub Actions | PASSED; one pre-existing non-fatal style info remains in `progress_store.dart` |
| 2026-08-07 | Focused GameButton tests | PASSED — 5/5 |
| 2026-08-07 | Optional-service tests | PASSED — 6/6 |
| 2026-08-07 | Full Flutter test suite | PASSED after replacing unbounded `pumpAndSettle` with bounded startup pumping |
| 2026-08-07 | Debug APK build | IN PROGRESS in Flutter CI run 12 |
| 2026-08-07 | Catalog migration | PASSED — `MOT-003` reconciled and `MOT-011` created for resource interpolation |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables, phases A–S, supported statuses, and unique stable IDs preserved |

## Known limitations and next work

1. `MOT-003` remains IN PROGRESS because Start, mission launch, Next, Retry, and purchase CTAs still contain legacy button implementations.
2. The sound hook exists, but the audio service remains planned under Phase N.
3. Visual 3D assets are caller-provided; the generic component intentionally does not hard-code assets.
4. Promotion to VERIFIED requires complete major-CTA adoption, regression coverage, and a successful applicable Android build.

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter test test\core\widgets\game_button_test.dart
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter run
```

Open Settings and test Language, Privacy, and About. Each action should depress, spring back, reject rapid duplicate activation, and honor the vibration toggle.
