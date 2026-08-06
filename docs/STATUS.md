# CARGame Live Project Status

This document is the operational summary. Detailed feature tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically from that catalog.

## Current work

| Field | Value |
|---|---|
| Current phase | B/C — Shared 3D UI and motion |
| Requested feature | `MOT-003` Universal Button Motion System |
| Catalog alignment | The existing catalog currently defines `MOT-003` as resource interpolation; this checkpoint functionally maps to `MOT-002` and `UI3D-003`. Stable IDs were not silently renamed. |
| Status | IMPLEMENTED checkpoint; CI verification running |
| Integrated screen | Settings |
| Next checkpoint | Adopt `GameButton` in Home Start, mission launch, result Next/Retry, and shop purchase flows after CI passes. |

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
- Settings language, privacy, and about actions now use the shared component.
- Five widget tests cover async tap deduplication, disabled state, loading state, RTL, and sound-hook ordering.

## Changed areas

- `lib/core/widgets/game_button.dart`
- `lib/features/settings/settings_screen.dart`
- `test/core/widgets/game_button_test.dart`
- `.github/workflows/flutter_ci.yml`

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Static component and integration review | PASSED |
| 2026-08-07 | First CI run | Reached formatter; exposed pre-existing repository-wide formatting debt before Analyze |
| 2026-08-07 | CI quality-gate correction | CI now runs formatter, whitespace validation, Analyze, focused GameButton tests, full tests, and Debug APK build |
| 2026-08-07 | Latest CI run | IN PROGRESS |
| 2026-08-07 | Dashboard schema | No catalog table/phase schema change; parser compatibility preserved |

## Known limitations and next work

1. The requested `MOT-003` label conflicts with the current catalog definition. The catalog must be reconciled explicitly rather than silently repurposing a stable ID.
2. This checkpoint replaces three safe settings actions; remaining major CTAs still use legacy implementations.
3. The sound hook exists, but the audio service is still planned under Phase N.
4. Visual 3D assets are not embedded in the generic component; callers provide their own child composition.
5. Final status must remain below VERIFIED until GitHub Actions passes Analyze, focused/full tests, and Debug APK build.

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter test test\core\widgets\game_button_test.dart
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter run
```

Open Settings and test Language, Privacy, and About. Each action should depress, spring back, reject rapid duplicate activation, and honor the vibration toggle.
