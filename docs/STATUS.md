# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | B — Shared 3D design system |
| Completed checkpoint | `UI3D-004` Reusable 3D card and panel system |
| Status | IMPLEMENTED — shared panel primitives are adopted in Home, Shop, and Progress Hub; Flutter CI/device verification pending |
| Previous checkpoint | `AST-001` Asset folder taxonomy and naming standard |
| Next recommended feature | `MOT-004` Unified screen transitions after CI confirms the UI3D checkpoint |
| Known blocker | No production verification claim until format/analyze/widget tests/debug APK run against the latest shared-panel commits. |

## UI3D-004 implementation evidence — 2026-08-07

- Added reusable `GamePanel` with unified depth, highlight, border, clipping,
  press/hover interaction, loading skeleton, error state, semantics, and reduced-motion handling.
- Added `GameResourcePanel`, `GameActionPanel`, `GameStatPanel`, and `GameHeroPanel`
  so resource cards, actions, metrics, and hero summaries share one visual contract.
- Home resource cards now use `GameResourcePanel`; Daily Reward, Daily Mission, and
  Cargo Shop entries use `GameActionPanel`; Win Streak uses `GamePanel` while the
  existing `GameFitView` no-scroll composition is preserved.
- Shop booster cards now use `GamePanel` without changing prices, inventory, or purchase logic.
- Progress Hub was refactored onto `GameHeroPanel`, `GameStatPanel`, `GamePanel`, and
  `GameButton` while preserving its intentionally scrollable long-form layout,
  mission claim behavior, achievements, hearts, XP, streaks, and statistics.
- Progress Hero and Performance Summary no longer own duplicate gradient/shadow card
  implementations; shared panel primitives own the depth and interaction contract.
- Added focused widget/regression tests for panel ready/loading/error states,
  interactions, Home no-scroll adoption, Shop booster adoption, Progress long-form
  scrolling, shared hero/stat adoption, and dynamic 3D asset fallbacks.
- Latest implementation commits include `1faea8a1f1388fc8b2a6a2fdfb1d8915227f7cda`
  and `87923cddd7cb609c41d1bc22bb00baada9469a3d`; GitHub combined status has not yet
  exposed checks for the latest commit, so this checkpoint is not marked VERIFIED.

## AST-001 verification evidence — 2026-08-07

- Added the production `assets/3d` taxonomy separating runtime, provenance, and
  reproducible source responsibilities.
- Defined stable lowercase filename grammar and registry-ID derivation that exclude
  locale, screen, dimensions, author, and revision from identity.
- Locked `pui`, `pcargo`, `pcity`, and `phero` camera/framing profiles with zero roll,
  reproducible pivots, safety padding, and consistent perceived scale.
- Standardized upper-left key lighting, fill/rim behavior, contact shadows,
  materials, alpha edges, and rules against baked text/interface effects.
- Established initial sRGB WebP canvas and encoded-size budgets for UI, boosters,
  cargo, cities, heroes, environments, and effects.
- Added accessibility, localization, animation-state, commercial provenance, and
  batch-review handoff requirements linked to their owning catalog gates.
- Created the guarded `assets/3d` policy root without declaring or adding binary
  runtime art before registry/fallback/provenance controls exist.
- Updated the repository baseline and Dashboard JSON to 116 tracked files, one asset
  policy file, and zero tracked binary assets; added a direct Dashboard catalog link.

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
| 2026-08-07 | Full Flutter test suite | PASSED — 32/32 in Flutter CI run 74 |
| 2026-08-07 | Debug APK build | PASSED — `app-debug.apk` built and artifact uploaded in Flutter CI run 74 |
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
| 2026-08-07 | AST-001 asset standard contract | PASSED — required taxonomy/render/export/provenance sections, four camera profiles, and six filename examples validated |
| 2026-08-07 | Asset admission gate | PASSED — `assets/3d` contains policy only and zero binary runtime assets before dependent controls |
| 2026-08-07 | AST-001 dashboard baseline JSON | PASSED — JSON parses and matches 116 tracked files, zero binary assets, and checkpoint identity |
| 2026-08-07 | AST-001 catalog/dashboard integrity | PASSED — 19 phases, 191 unique features, valid status/dependencies, zero active tasks, and inline Dashboard JavaScript syntax valid |
| 2026-08-07 | Flutter format/analyze/tests/debug APK | NOT APPLICABLE — documentation and asset-governance files only; no Dart, platform, dependency, or binary asset changes |
| 2026-08-07 | UI3D-004 latest combined GitHub status | PENDING — no check statuses exposed yet for `87923cddd7cb609c41d1bc22bb00baada9469a3d` |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
dart format lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test test\core\widgets\game_panel_test.dart
flutter test test\core\widgets\game_resource_panel_test.dart
flutter test test\core\widgets\game_action_panel_test.dart
flutter test test\core\widgets\game_stat_panel_test.dart
flutter test test\core\widgets\game_hero_panel_test.dart
flutter test test\features\home\home_shared_panels_test.dart
flutter test test\features\shop\shop_game_panel_test.dart
flutter test test\features\progress\progress_hub_game_panel_test.dart
flutter test
flutter build apk --debug
flutter run
```

## Fullscreen home + banner checkpoint — 2026-08-07

- Android/iOS app shell requests immersive-sticky fullscreen at startup while retaining portrait orientation policy.
- Home no longer uses a ListView/scroll container; content scales down as one bounded composition and compact resource/hero cards reclaim vertical space.
- Google Mobile Ads banner footer is isolated from offline core play, uses official debug test IDs, and occupies no footer space until an ad actually loads.
- Full checkpoint verification passed in GitHub Actions: Dart format, Flutter Analyze with no issues, full Flutter tests, and Debug APK build.
- Added regression coverage for 360x640 and 412x915 home layouts with no ListView/SingleChildScrollView and no captured Flutter layout exception.
- Release ad unit injection/consent remain separate ADS-002/ADS-007 work and are not claimed complete.

## UI3D-006 fit shell checkpoint — 2026-08-07

- Added reusable `GameFitView` for bounded game screens that must remain fully visible without a scroll container.
- Home now uses the shared fit primitive instead of a screen-local FittedBox implementation.
- Mission Briefing replaces its ListView with the shared fit primitive and tighter vertical rhythm while preserving boosters, wallet, RTL/LTR, SafeArea, and guarded mission launch.
- UI3D-006 remains IN PROGRESS until remaining short screens and large-text/tablet/cutout cases are migrated and verified.
