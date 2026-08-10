# Test quality, coverage, and flaky-test policy

TEST-008 defines the repository-owned quality contract for automated Flutter tests. The machine-readable source is `tool/test_quality_policy.json`; `tool/verify_test_quality.py` is the enforcing validator.

## Coverage contract

- Normal Flutter CI generates `coverage/lcov.info` from the full suite with `flutter test --coverage`.
- The enforced repository line-coverage floor is **35%**. CI fails when measured authored `lib/` line coverage falls below that floor.
- The improvement target is **60%**. The target is aspirational until the hard floor is ratcheted upward using reproducible verified-main evidence.
- Only authored production sources under `lib/` are counted. Generated localization output under `lib/l10n/` is excluded.
- LCOV source paths are normalized before include/exclude matching, so GitHub Actions absolute paths and local relative paths produce the same metric.
- Coverage is calculated from `DA` executable-line records and cross-checked against each record's `LF`/`LH` summaries.
- Missing, empty, malformed, duplicate-source, inconsistent, or zero-measurable-line LCOV reports are hard failures.
- Coverage never replaces behavior-focused tests: TEST-007 remains the critical-path contract and TEST-010 remains the catalog/dashboard integrity contract.

## Flaky-test policy

Deterministic unit, widget, and integration tests have zero blanket retries. A failure is treated as a failure until its root cause is understood.

A temporary quarantine is permitted only when all of the following are recorded in `tool/test_quality_policy.json`:

- exact existing repository `test/*_test.dart` path;
- GitHub owner in `@handle` form;
- local tracking issue such as `#190`;
- specific reason describing the observed nondeterminism;
- ISO expiry date;
- retry count no greater than the machine-enforced maximum.

Quarantines are bounded to 14 days and at most one retry. Expired, duplicate, malformed, unknown-field, overlong, or orphaned test-path quarantine records fail the validator. The default retry count must remain zero, and normal Flutter CI rejects any `--retry` flag.

## Ownership and failure handling

The issue linked by a quarantine is the failure owner and must contain reproduction evidence and the removal plan. Quarantine is a containment mechanism, not a completion state. Deleting or renaming a quarantined test without updating the policy creates an orphan record and fails CI. A feature cannot be marked VERIFIED based only on a quarantined path if that path is part of its acceptance criteria.

## Ratcheting the floor

Raise `coverage.minimum_line_percent` only from a clean, reproducible CI baseline and keep it below or equal to `coverage.target_line_percent`. Coverage changes must not be achieved by excluding authored production code or deleting tests. Any new include/exclude boundary requires an explicit rationale in this document and focused policy regression coverage.
