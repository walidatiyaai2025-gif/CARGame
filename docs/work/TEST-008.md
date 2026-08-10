# TEST-008 — Coverage thresholds and flaky-test policy

- Issue: #190
- Branch: `agent/test-008-coverage-flaky-policy`
- State: IN PROGRESS
- Dependency: ENG-007 VERIFIED

## Objective

Make coverage and flaky-test handling explicit, versioned, and enforceable without weakening the existing critical-path, catalog, privacy, security, Analyze, full-test, or APK gates.

## Acceptance checklist

- [x] Add machine-readable coverage/flaky policy.
- [x] Add executable policy and LCOV validator.
- [x] Reject missing/empty/malformed coverage.
- [x] Enforce a non-zero repository line-coverage floor.
- [x] Record a higher coverage improvement target.
- [x] Keep deterministic tests at zero blanket retries.
- [x] Require owner, issue, reason, expiry, and bounded retry count for any quarantine.
- [x] Reject expired/duplicate/overlong/malformed quarantines.
- [x] Add focused validator regressions.
- [x] Document failure ownership and floor-ratcheting rules.
- [x] Wire policy validation into normal Flutter CI before package restore.
- [x] Generate LCOV from the full Flutter suite in CI.
- [x] Enforce the LCOV threshold after the full suite.
- [x] Preserve TEST-007 and TEST-010 blocking gates.
- [ ] Pass normal Flutter CI, Analyze, full tests, Debug APK, artifact security, and upload.
- [ ] Reconcile catalog/status and merge only with verified evidence.

## Initial policy

- Enforced line-coverage floor: 35%.
- Improvement target: 60%.
- Generated `lib/l10n/` output is excluded.
- Default retries: 0.
- Maximum temporary quarantine retry: 1.
- Maximum quarantine lifetime: 14 days.
- Active quarantines at implementation start: none.

## Local validator evidence

The focused Python suite contains 10 regressions covering valid policy, blanket retry rejection, invalid coverage floor, quarantine schema, expiry, maximum lifetime, LCOV parsing/exclusion, malformed LCOV, required preserved CI anchors, and below-floor failure. The same validator also accepts a synthetic LCOV report exactly at the 35% floor.

No production gameplay, economy, persistence, navigation, ads, privacy, signing, package, or asset behavior is intentionally changed by TEST-008.
