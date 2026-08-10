# TEST-003 — Core screen widget tests

## Goal

Establish an explicit, deterministic widget-test release contract for Home, World Map, Mission Briefing, Gameplay, Result, and Shop across representative viewport classes and English/Arabic behavior.

## Issue

- GitHub Issue #179
- Branch: `agent/test-003-core-screen-widget-matrix`

## Current checkpoint

`VERIFIED` — Issue #179 / PR #180 completed the explicit compact/reference/tablet plus EN/AR matrix and blocking CI guard without production UI redesign, golden snapshots, or live network dependency.

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

Flutter CI #803 / run `31344139284` passed the matrix validator, formatting, Analyze, focused TEST-003 suite, full Flutter suite, Debug APK build, privacy/security/dependency/catalog gates, artifact security, and upload on head `8d7c48fbde9dceffeb9fb6edb87a02bd941643ab`. Debug artifact #9046841743 is 80,633,606 bytes with SHA-256 `f4f2b86d7dae9c44ecaf66042a91321a121356f8bd36f355dc38cf227e69e94f`. PR #180 squash-merged to `main` as `4ca093a843ab685dfeef8df2c86e3950a13f482f`; TEST-003 is VERIFIED and TEST-007 is dependency-ready.
