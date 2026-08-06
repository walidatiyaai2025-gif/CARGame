# CARGame Live Project Status

This document is the short operational dashboard. Detailed tracking lives in `docs/FEATURE_CATALOG.md`; counts and percentages are calculated dynamically by the Developer Portal.

## Project objective

Build a production-quality Flutter cargo sorting game with 150 levels, 6 worlds, unified premium 3D visuals, responsive living motion, offline-first progress, Arabic/English support, measurable quality, privacy/security/legal readiness, and Android store release operations.

## Current work

| Field | Value |
|---|---|
| Current phase | A — Engineering foundation |
| Active primary feature | `ENG-014` Offline-first service isolation |
| Status | IMPLEMENTED checkpoint; Flutter/device verification pending |
| Branch | main |
| Blocker | The GitHub execution environment cannot run Flutter, Android SDK, an emulator, or an offline/online device transition test. |
| Completed checkpoint | Optional services are isolated behind timeout, deduplication, bounded retry, observable state, and lifecycle-safe retry; Mobile Ads starts after offline core UI. |
| Next checkpoint | Run focused Flutter tests, analyze, debug build, and airplane-mode/device verification on Windows/Android. |

## ENG-014 implementation evidence — 2026-08-07

- Added `OptionalServiceCoordinator` as a reusable boundary for network-backed and optional platform services.
- Each service has independent `idle`, `running`, `ready`, and `unavailable` states.
- Initialization failures and timeouts return `false` instead of throwing into the core gameplay/bootstrap flow.
- Concurrent initialization of the same service is deduplicated to one Future and one side effect.
- Retry attempts are bounded by a configurable maximum and cannot loop indefinitely on lifecycle resume.
- Mobile Ads initialization now starts only after the local player profile/settings bootstrap and the offline application shell are available.
- Ad timeout/failure is logged as optional-service unavailability and does not block levels, progress, economy, home navigation, RTL/LTR, or responsive UI.
- A failed Ads initialization retries safely when the application resumes, while the coordinator prevents duplicate parallel attempts.
- Coordinator resources and lifecycle observers are disposed.
- Focused tests cover success, failure containment, timeout isolation, concurrent deduplication, successful retry, and maximum-attempt enforcement.

## Reproducible verification commands

```powershell
cd "D:\Apps\CARGame"

dart format lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test test\core\services\optional_service_coordinator_test.dart
flutter test
flutter build apk --debug
```

Device/offline verification:

1. Launch the application with network disabled.
2. Confirm Home, level map, mission briefing, gameplay, local rewards, and progress open normally.
3. Re-enable network and resume the application.
4. Confirm optional Ads retry occurs without duplicate startup, navigation interruption, or progress mutation.
5. Disable network again and confirm repeated lifecycle resumes stop retrying after the configured attempt limit.

## Phase overview

| Phase | Current evidence state |
|---|---|
| A Engineering foundation | ENG-014 implementation checkpoint completed; external Flutter/device verification remains. ENG-002/REL-001 verification is still open. |
| M Ads and monetization | ADS-001 now uses the shared optional-service isolation boundary; device verification remains. |
| B–L, N–S | No unrelated functional or status promotion performed by this checkpoint. |

## Verification ledger

| Date | Scope | Verification | Result | Commit |
|---|---|---|---|---|
| 2026-08-07 | ENG-014 static implementation review | Confirmed offline UI is made ready before Mobile Ads starts; optional service exceptions/timeouts are contained; retry is deduplicated and bounded. | PASSED — static review | Current checkpoint |
| 2026-08-07 | ENG-014 focused test design | Added six deterministic tests for success, failure, timeout, concurrency, retry, and attempt limit. | IMPLEMENTED; execution pending | Current checkpoint |
| 2026-08-07 | Flutter analyze/test/debug build | Requires Flutter and Android environment. | BLOCKED by execution environment | - |
| 2026-08-07 | Offline/online Android device test | Requires supported Android device/emulator and network state control. | BLOCKED by execution environment | - |
| 2026-08-07 | Dashboard compatibility | Catalog retains phases A–S, the existing six-column table schema, a unique ENG-014 ID, and supported `IMPLEMENTED` status. | PASSED — static compatibility | Current checkpoint |

## Known high-priority risks

1. `ENG-014` must not be promoted to `VERIFIED` until focused tests, full tests, analyze, debug build, and a real offline/online device flow pass.
2. Local storage startup still uses safe defaults after timeout; persistence/migration tests under ENG-008 remain necessary.
3. Only Mobile Ads currently uses the new optional-service boundary; future analytics, crash reporting, remote configuration, social, and cloud services must use the same isolation pattern.
4. ENG-005 architecture boundaries remain planned, so later service adoption should consolidate interfaces rather than creating feature-specific retry implementations.
5. ENG-002 and REL-001 still need Windows/toolchain verification.

## Next ready work

1. Execute the ENG-014 verification commands and offline device matrix; promote to VERIFIED only with evidence.
2. Apply the coordinator boundary to future analytics, crash reporting, remote configuration, and cloud/social integrations as those tasks begin.
3. Complete ENG-005 architecture boundaries so optional service interfaces and ownership are formally documented.
4. Finish ENG-002 and REL-001 Windows verification.
5. Complete ENG-001 baseline audit.

## Last update

- Isolated Mobile Ads from the offline-first core application flow.
- Added bounded, deduplicated, timeout-safe optional-service initialization and lifecycle retry.
- Added focused regression tests without changing gameplay visuals, motion, localization, responsive layouts, or saved progress schemas.
- Kept ENG-014 at IMPLEMENTED because executable Flutter and device evidence is unavailable in this environment.
