# CARGame Live Project Status

This document is the operational summary. Detailed feature tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically from that catalog.

## Current work

| Field | Value |
|---|---|
| Current phase | B/C — Shared 3D UI and motion |
| Active primary feature | `MOT-003` Universal Button Motion System |
| Status | IMPLEMENTED across major CTAs; CI and physical-device review pending |
| Catalog alignment | `MOT-003` tracks universal button adoption; resource interpolation is `MOT-011`. |
| Integrated flows | Settings, Home Start, Mission Start, result Next/Retry, rewarded continuation, heart/booster/theme purchases |
| Next checkpoint | Complete CI and physical Android motion review, then promote `MOT-003` to VERIFIED if acceptance remains satisfied. |

## GameButton implementation evidence — 2026-08-07

- One reusable `GameButton` component provides press depth, elastic spring release, desktop/web hover, ripple/highlight, disabled/loading states, optional haptics, a sound hook, keyboard/focus support, semantics, RTL/LTR inheritance, and responsive composition.
- Async callbacks are guarded so rapid repeated taps execute only once until completion.
- Settings Language, Privacy, and About actions use the shared component.
- Home Start and Mission Start use the shared component with loading and navigation guards.
- Result Next, Retry, and rewarded-continuation actions use the shared component.
- Heart, booster, and theme purchase/selection actions use the shared component.
- Five focused widget tests cover async tap deduplication, disabled state, loading state, RTL, and sound-hook ordering.
- The Home smoke test uses in-memory asynchronous preferences and bounded pumping so ambient looping motion does not stall tests.

## Changed areas

- `lib/core/widgets/game_button.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/features/home/home_screen.dart`
- `lib/features/levels/city_briefing_screen.dart`
- `lib/features/game/game_screen.dart`
- `lib/features/shop/shop_screen.dart`
- `test/core/widgets/game_button_test.dart`
- `test/widget_test.dart`
- `.github/workflows/flutter_ci.yml`
- `docs/FEATURE_CATALOG.md`
- `docs/STATUS.md`

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Static component and integration review | PASSED |
| 2026-08-07 | Focused GameButton tests | PASSED — 5/5 on previous CI checkpoint |
| 2026-08-07 | Optional-service tests | PASSED — 6/6 on previous CI checkpoint |
| 2026-08-07 | Full Flutter test suite | PASSED on previous CI checkpoint |
| 2026-08-07 | Final major-CTA formatting and whitespace validation | PASSED |
| 2026-08-07 | Final major-CTA Analyze, full tests, and Debug APK | IN PROGRESS in latest Flutter CI run |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables, phases A–S, supported statuses, and stable IDs preserved |

## Known limitations and next work

1. Promotion to VERIFIED requires the latest CI run to pass and a physical Android review of press motion, loading, RTL, and rapid-tap behavior.
2. The sound hook exists, but the audio service remains planned under Phase N.
3. Visual 3D assets are caller-provided; the generic button intentionally does not hard-code assets.

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run
```

Test Home Start, Mission Start, result Next/Retry, rewarded continuation, heart and booster purchases, theme selection, and Settings actions. Rapid repeated taps must execute only once.
