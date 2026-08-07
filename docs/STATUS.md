# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | A — Engineering foundation |
| Completed checkpoint | `ENG-001` Repository audit and baseline |
| Status | VERIFIED — documentation and machine-readable inventory checks passed |
| Previous checkpoint | `MOT-007` Correct/wrong/combo feedback |
| Next recommended feature | `AST-001` 3D asset taxonomy and naming standard |
| Known blocker | Local environment has no Flutter/Dart SDK; physical Android review and Windows toolchain verification require configured devices |

## ENG-001 verification evidence — 2026-08-07

- Added `docs/BASELINE_AUDIT.md` as the canonical human-readable snapshot for
  architecture, module boundaries, baseline commands, tooling, dependencies, assets,
  persistence keys, debt, and delivery risk.
- Added `docs/dashboard/baseline.json` with a schema-versioned inventory that is
  deliberately separate from catalog-derived progress.
- Measured 111 tracked files, 30 production Dart files, 11 Dart test files, 21
  PowerShell scripts, 13 batch files, zero tracked binary assets, and 28 persistence
  key families.
- Reconciled the documented developer baseline with CI at Flutter 3.44.8, Dart
  3.10+, JDK 17, Android minSdk 23, AGP 8.11.1, and Kotlin 2.3.20.
- Recorded ten prioritized risks with existing catalog owners, including incomplete
  tracked platform wrappers, debug release signing, rewarded-ad fallback grants,
  migration/atomicity gaps, architecture boundaries, and asset-pipeline absence.
- Updated the Developer Portal to render baseline inventory and risk counts without
  hard-coding or altering project progress percentages.
- Updated the roadmap checkpoint, README baseline link, feature evidence, active
  queue, and this operational status.

## MOT-007 implementation evidence — 2026-08-07

- Added reusable `GameActionFeedback` for correct and wrong sorting outcomes.
- Correct placement produces a bounce, glow, radial sparkle burst, and capped combo-size escalation.
- Wrong placement produces a red recoil/shake response with a distinct heavy haptic profile.
- Correct haptics escalate from light to medium at higher combos while visual escalation is capped at intensity eight without truncating the real combo value.
- A typed one-shot sound hook is exposed without hard-coding audio assets or creating a competing audio service.
- Sound and vibration settings are injected through Home, World Map, briefing, and gameplay; disabled feedback is respected without hidden globals.
- Correct/wrong feedback announces a localized live-region label and retains check/close cues so the result is not communicated by color alone.
- Gameplay resolution waits for feedback completion before win/loss result presentation, preventing overlapping result sheets and duplicate state mutation.
- Feedback completion uses a guarded `Completer`, is disposed safely, and remains single-fire during Reduced Motion or route disposal.
- Reduced Motion renders stable feedback for a bounded interval and completes without an active ticker; disposal cancels pending completion.
- Added focused widget tests for correct/combo feedback, wrong feedback, capped intensity, typed one-shot sound hook, localized semantics, one-time completion, Reduced Motion, disposal, and repeated input through the full gameplay flow.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Dart format | PASSED |
| 2026-08-07 | Flutter Analyze | PASSED — no issues found |
| 2026-08-07 | Action feedback focused tests | PASSED — 3/3 |
| 2026-08-07 | Travel-motion regression tests | PASSED |
| 2026-08-07 | Dashboard/catalog schema | PASSED — phases A–S and six-column task rows preserved |
| 2026-08-07 | Full Flutter test suite | PASSED — 32/32 in Flutter CI run 73 |
| 2026-08-07 | Debug APK build | PASSED — `app-debug.apk` built and artifact uploaded in Flutter CI run 73 |
| 2026-08-07 | Physical Android motion/audio review | PENDING |
| 2026-08-07 | Post-hardening Dart syntax/formatting | PASSED — 41 `lib`/`test` files parsed with zero formatting drift |
| 2026-08-07 | Post-hardening Flutter Analyze, focused/full tests, and debug APK | PASSED — GitHub Actions job `92756421170` |
| 2026-08-07 | Dashboard/catalog integrity | PASSED — phases A–S, priorities, statuses, unique IDs, dependencies, and active-task rule validated |
| 2026-08-07 | ENG-001 repository inventory | PASSED — dashboard JSON matches 111 tracked files and measured source/test/tooling/asset counts |
| 2026-08-07 | Dashboard JSON and inline JavaScript syntax | PASSED — JSON parsed and dashboard script compiled |
| 2026-08-07 | ENG-001 catalog/dashboard integrity | PASSED — 19 phases, 191 features, valid IDs/statuses/priorities/dependencies, zero active tasks |
| 2026-08-07 | Dart parse/format regression | PASSED — all 41 tracked Dart files parsed with zero formatter drift using the local WASM formatter |
| 2026-08-07 | Flutter analyze, tests, and debug APK | NOT APPLICABLE to documentation-only behavior; regression execution remains BLOCKED locally because Flutter/Dart SDK is unavailable |
| 2026-08-07 | Windows PowerShell toolchain self-test | BLOCKED locally — `pwsh` and Android workstation dependencies are unavailable |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test test\core\motion\game_action_feedback_test.dart
flutter test test\core\motion\game_travel_motion_test.dart
flutter test test\features\game\game_screen_motion_test.dart
flutter test
flutter build apk --debug
flutter run
```
