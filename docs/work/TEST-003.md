# TEST-003 — Core screen widget tests

## Goal

Establish an explicit, deterministic widget-test release contract for Home, World Map, Mission Briefing, Gameplay, Result, and Shop across representative viewport classes and English/Arabic behavior.

## Issue

- GitHub Issue #179
- Branch: `agent/test-003-core-screen-widget-matrix`

## Current checkpoint

`IN PROGRESS` — preserve existing responsive tests, close real locale/RTL and viewport gaps, and add a machine coverage guard without introducing golden snapshots or full E2E behavior owned by later testing tasks.

## Baseline audit

- Home has tablet/large-text, cutout, and keyboard-inset coverage but no Arabic locale case.
- World Map already covers compact English, Arabic RTL on a tall phone, and large-text tablet behavior.
- Mission Briefing already covers compact English, Arabic RTL, large-text tablet behavior, and the stable gameplay route transition.
- Gameplay covers compact/tablet/cutout behavior and manual RTL, but does not prove a real Arabic locale-driven app surface.
- Result coverage exercises the compact loss state/navigation guard only; reference/tablet and Arabic locale coverage are missing.
- Shop covers compact/tablet/cutout and manual RTL, but does not prove a real Arabic locale-driven app surface.

## Acceptance

- Existing screen-specific tests remain the source of behavioral detail; TEST-003 adds only missing matrix coverage.
- The six required screens are covered at compact/reference/tablet viewport classes across the suite.
- English and Arabic/RTL are exercised across the critical screen set using real locale-driven configuration where supported.
- Covered states render without overflow or uncaught widget exceptions.
- Tests remain offline and deterministic with no live ad/network dependency.
- A machine TEST-003 matrix guard prevents accidental deletion of required screen/size/locale coverage.
- Formatting, Analyze, focused TEST-003 tests, full Flutter suite, Debug APK, existing privacy/security/dependency/catalog gates, and artifact security pass before VERIFIED.

## Dependency impact

When VERIFIED, TEST-003 satisfies the final catalog dependency for P0 TEST-007 Integration and end-to-end critical path.

## Verification

Pending implementation and GitHub Actions verification.
