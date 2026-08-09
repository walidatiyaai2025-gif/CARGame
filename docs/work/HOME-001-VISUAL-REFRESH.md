# HOME-001 Visual Refresh

Issue: #138
Branch: `agent/home-001-visual-refresh`
Primary feature: `HOME-001`

## State

IN PROGRESS until Flutter CI proves formatting, Analyze, Home regressions, full tests, and Debug APK build.

## Scope

Refresh the production Home screen so the new visual direction is immediately visible from `main` after merge, without changing persistence, economy, rewards, navigation identity, ad placement, or game balance.

## Acceptance

- Premium command-center hierarchy replaces the previous generic dashboard treatment.
- Current world, current city, next level, global completion, hearts, coins, stars, daily reward, mission, shop, streak/combo, and Start remain backed by existing `ProgressStore` truth.
- Existing named routes and double-push guard behavior are preserved.
- Exactly three shared `GameResourcePanel` and three shared `GameActionPanel` widgets remain on Home.
- Home remains bounded without a scroll container and continues to use `GameFitView`/`SafeArea`.
- Arabic/English text paths remain present.
- Banner ad footer remains persistent.
- Merge to `main` only after green Flutter CI.

## Implementation checkpoint

Commit `e845f4e1fe28d22f00231dac55e2fa4130e873fb` replaces the Home presentation layer while preserving the existing feature/service boundaries.

## Verification

Pending GitHub Actions on the pull request.
