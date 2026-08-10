# TEST-008 — Coverage thresholds and flaky-test policy

- Issue: #190
- Branch: `agent/test-008-coverage-flaky-policy`
- State: IN PROGRESS
- Dependency: ENG-007 VERIFIED

## Objective

Make coverage and flaky-test handling explicit, versioned, and enforceable without weakening the existing critical-path, catalog, privacy, security, Analyze, full-test, or APK gates.

## 50-task execution sprint

- [x] T01 Audit current `main` after TEST-010 reconciliation.
- [x] T02 Confirm branch is current with `main` and avoid duplicate team work.
- [x] T03 Confirm issue #190 is the selected dependency-ready workstream.
- [x] T04 Confirm ENG-007 dependency is VERIFIED.
- [x] T05 Record TEST-008 as the single IN PROGRESS primary feature.
- [x] T06 Add the machine-readable test-quality policy.
- [x] T07 Version the policy schema as v1.
- [x] T08 Scope measured coverage to authored `lib/` sources.
- [x] T09 Exclude generated `lib/l10n/` output.
- [x] T10 Set an enforced non-zero line-coverage floor at 35%.
- [x] T11 Record a 60% improvement target above the hard floor.
- [x] T12 Set deterministic-test default retries to zero.
- [x] T13 Bound temporary quarantine retries to at most one.
- [x] T14 Bound quarantine lifetime to 14 days.
- [x] T15 Keep the active quarantine list explicit and currently empty.
- [x] T16 Add deterministic JSON policy loading and error reporting.
- [x] T17 Reject unsupported policy schema versions.
- [x] T18 Reject invalid coverage floors.
- [x] T19 Reject targets below the enforced floor.
- [x] T20 Validate coverage include prefixes.
- [x] T21 Validate coverage exclusion prefixes.
- [x] T22 Reject non-zero blanket/default retries.
- [x] T23 Require all quarantine ownership and tracking fields.
- [x] T24 Reject unknown quarantine fields.
- [x] T25 Require exact `test/*_test.dart` quarantine paths.
- [x] T26 Reject orphan quarantine paths whose test file no longer exists.
- [x] T27 Require a valid GitHub `@owner` handle.
- [x] T28 Require a local `#issue` reference.
- [x] T29 Require a specific quarantine reason.
- [x] T30 Parse and validate ISO quarantine expiry dates.
- [x] T31 Reject expired quarantines.
- [x] T32 Reject quarantines beyond the maximum lifetime.
- [x] T33 Reject duplicate quarantined test paths.
- [x] T34 Normalize absolute and relative LCOV source paths identically.
- [x] T35 Parse executable `DA` line records strictly.
- [x] T36 Cross-check `DA` results against `LF`/`LH` summaries.
- [x] T37 Reject duplicate LCOV source records.
- [x] T38 Reject empty or zero-authored-line coverage reports.
- [x] T39 Run policy validation before package restore in normal CI.
- [x] T40 Generate LCOV from the full Flutter suite with `flutter test --coverage`.
- [x] T41 Enforce coverage after tests and before Debug APK packaging.
- [x] T42 Preserve the blocking TEST-007 critical-path contract.
- [x] T43 Preserve the blocking TEST-010 dashboard/catalog contract.
- [x] T44 Reject any normal-CI `--retry` flag.
- [x] T45 Document coverage, quarantine ownership, and floor-ratcheting rules.
- [x] T46 Expand focused policy/LCOV/workflow regressions to 30 tests.
- [x] T47 Run the focused TEST-008 suite locally: 30/30 PASS.
- [ ] T48 Open the TEST-008 pull request against `main`.
- [ ] T49 Pass normal Flutter CI including Analyze, full tests, Debug APK, artifact security, and upload.
- [ ] T50 Reconcile catalog/status with exact CI evidence, merge, and close issue #190.

## Policy summary

- Enforced line-coverage floor: 35%.
- Improvement target: 60%.
- Counted scope: authored `lib/` source lines.
- Generated `lib/l10n/` output: excluded after canonical path normalization.
- Default retries: 0.
- Maximum temporary quarantine retry: 1.
- Maximum quarantine lifetime: 14 days.
- Active quarantines at implementation start: none.

## Focused verification evidence

`python3 tool/test_test_quality.py` passes 30/30 focused regressions covering policy schema/floors/targets, include/exclude boundaries, blanket retry rejection, quarantine schema/ownership/issue/expiry/orphan/duplicate rules, strict LCOV parsing and summary consistency, absolute GitHub Actions path normalization, non-`lib/` exclusion, preserved CI gates/order, and below-floor enforcement.

A synthetic 34% authored-line report is rejected below the 35% floor. Absolute GitHub Actions paths under `.../lib/l10n/` are correctly excluded after normalization.

No production gameplay, economy, persistence, navigation, ads, privacy, signing, package, or asset behavior is intentionally changed by TEST-008.
