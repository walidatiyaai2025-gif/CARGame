# TEST-011 — Privacy consent and security verification

- Issue: #202
- Branch: `agent/test-011-privacy-security-verification`
- State: IN PROGRESS
- Dependencies: PRIV-001 VERIFIED, SEC-001 VERIFIED
- Verification ceiling: IMPLEMENTED until production UMP/privacy-message regulated-region/device evidence exists.

## Objective

Make every repository-owned privacy, consent, local-data, diagnostics, secret, dependency, network-policy, and packaged-artifact release assertion mechanically auditable without fabricating production Google UMP/device evidence.

## 100-checkpoint execution contract

### A. Baseline and workstream selection
- [ ] T001 Confirm PERF-002 final-head CI is green.
- [ ] T002 Confirm PERF-002 is merged to main.
- [ ] T003 Obtain a non-skipped full CI run against the merged PERF-002 runtime tree.
- [ ] T004 Reconcile PERF-002 honestly as IMPLEMENTED, not VERIFIED, without device RSS/GPU claims.
- [ ] T005 Confirm TEST-009 remains blocked on real PERF-001 device profiling.
- [ ] T006 Confirm PRIV-001 is VERIFIED.
- [ ] T007 Confirm SEC-001 is VERIFIED.
- [ ] T008 Confirm SEC-002 and PRIV-003 repository gates are already present.
- [ ] T009 Confirm no active TEST-011 implementation PR/branch exists.
- [ ] T010 Mark TEST-011 as the only primary source-controlled workstream before implementation edits.

### B. Consent and ad-request gating verification
- [ ] T011 Audit UMP consent-info refresh at launch.
- [ ] T012 Audit required-form presentation handling.
- [ ] T013 Audit `canRequestAds` as the ad eligibility authority.
- [ ] T014 Audit fail-closed behavior before consent eligibility.
- [ ] T015 Audit banner request gating.
- [ ] T016 Audit rewarded request gating.
- [ ] T017 Audit interstitial request gating.
- [ ] T018 Audit runtime consent revocation/disposal behavior.
- [ ] T019 Audit Settings privacy-options re-open path.
- [ ] T020 Verify offline/core play remains non-blocking when UMP fails or is unavailable.

### C. Privacy inventory and data-minimization verification
- [ ] T021 Re-run persisted-data inventory ownership checks.
- [ ] T022 Verify every SharedPreferences family remains inventoried.
- [ ] T023 Verify Google Mobile Ads remains the sole declared off-device processor.
- [ ] T024 Verify no first-party analytics emitter is enabled by default.
- [ ] T025 Verify analytics runtime privacy gate remains fail-closed.
- [ ] T026 Verify remote diagnostics remains disabled by default.
- [ ] T027 Verify crash/non-fatal reporting has no active remote emitter path.
- [ ] T028 Verify data-safety mapping matches current processor inventory.
- [ ] T029 Verify privacy disclosures retain local-only vs off-device distinctions.
- [ ] T030 Verify no source-controlled production identifiers/credentials are introduced.

### D. Local export and deletion verification
- [ ] T031 Audit schema-versioned local-data export.
- [ ] T032 Audit destructive-reset confirmation guard.
- [ ] T033 Audit concurrent-delete serialization.
- [ ] T034 Audit diagnostic-log clearing during deletion.
- [ ] T035 Audit ProgressStore rehydration after reset.
- [ ] T036 Audit AppSettingsStore rehydration after reset.
- [ ] T037 Audit stale-route removal after reset.
- [ ] T038 Verify unrelated runtime state is not silently reintroduced after deletion.
- [ ] T039 Verify Settings exposes the local privacy controls.
- [ ] T040 Add TEST-011 evidence linking export/deletion tests to the release matrix.

### E. Diagnostics, analytics, and redaction verification
- [ ] T041 Verify diagnostics logging respects its runtime enable gate.
- [ ] T042 Verify diagnostic payload size bounds remain enforced.
- [ ] T043 Verify secret redaction remains applied to diagnostics.
- [ ] T044 Verify path-sensitive diagnostic redaction remains applied.
- [ ] T045 Verify analytics properties remain allowlisted/schema-versioned.
- [ ] T046 Verify analytics cannot emit before runtime privacy permission.
- [ ] T047 Verify analytics cannot reuse UMP ad consent as first-party analytics consent.
- [ ] T048 Verify crash-reporting privacy contract remains isolated from ads consent.
- [ ] T049 Verify no new telemetry persistence/network path exists outside inventory.
- [ ] T050 Record machine-readable TEST-011 evidence for analytics/diagnostics gates.

### F. Secret, dependency, artifact, and network security verification
- [ ] T051 Re-run tracked-secret policy contract.
- [ ] T052 Re-run secret-scanner regression suite.
- [ ] T053 Re-run dependency advisory enforcement.
- [ ] T054 Re-run dependency-security regression suite.
- [ ] T055 Verify lockfile enforcement remains blocking.
- [ ] T056 Verify security advisory exceptions are explicit and bounded.
- [ ] T057 Verify packaged APK secret/artifact scan remains mandatory.
- [ ] T058 Verify security baseline trust-boundary/network-processor parity.
- [ ] T059 Verify no undeclared network processor is present in repository-owned disclosures.
- [ ] T060 Record the network-policy and artifact-security requirements in TEST-011 evidence.

### G. Dedicated TEST-011 release evidence contract
- [ ] T061 Add `docs/TEST_011_PRIVACY_SECURITY.md`.
- [ ] T062 Separate repository-verifiable evidence from external/device evidence.
- [ ] T063 Add repository status for consent integration.
- [ ] T064 Add repository status for local export/deletion.
- [ ] T065 Add repository status for redaction and diagnostics privacy.
- [ ] T066 Add repository status for secret/dependency scanning.
- [ ] T067 Add repository status for APK artifact security.
- [ ] T068 Add repository status for processor/network-policy parity.
- [ ] T069 Explicitly mark production UMP/privacy-message configuration as external pending evidence.
- [ ] T070 Explicitly prohibit marking TEST-011 VERIFIED from CI-only evidence.

### H. Machine validator and regressions
- [ ] T071 Add `tool/verify_test_011_privacy_security.py`.
- [ ] T072 Require the TEST-011 evidence document.
- [ ] T073 Require existing privacy inventory/disclosure gates.
- [ ] T074 Require analytics/crash privacy gates.
- [ ] T075 Require secret and dependency-security gates.
- [ ] T076 Require packaged artifact-security gate.
- [ ] T077 Require local data controller/Settings privacy focused tests.
- [ ] T078 Require consent/ad request focused tests.
- [ ] T079 Reject any TEST-011 VERIFIED claim while external evidence is pending.
- [ ] T080 Add `tool/test_test_011_privacy_security.py` with mutation-based regressions.

### I. CI integration and quality gates
- [ ] T081 Add TEST-011 machine validator to normal Flutter CI.
- [ ] T082 Add TEST-011 validator regressions to normal Flutter CI.
- [ ] T083 Preserve TEST-007 critical-path gates.
- [ ] T084 Preserve TEST-008 coverage/flaky policy gates.
- [ ] T085 Preserve TEST-010 dashboard/catalog parity gates.
- [ ] T086 Preserve AST-004/PERF-001/PERF-002 gates.
- [ ] T087 Run formatting and whitespace validation.
- [ ] T088 Run Flutter Analyze.
- [ ] T089 Run focused privacy/consent/security/local-data tests.
- [ ] T090 Run the complete Flutter test suite and coverage threshold.

### J. Build, merge, and honest release-state reconciliation
- [ ] T091 Build the Debug APK in normal CI.
- [ ] T092 Pass packaged APK artifact-security scanning.
- [ ] T093 Upload the CI Debug APK artifact.
- [ ] T094 Record final-head CI run/test/coverage/artifact evidence.
- [ ] T095 Keep TEST-011 IMPLEMENTED rather than VERIFIED while real UMP regulated-device evidence is absent.
- [ ] T096 Merge only with a green final PR head and no unresolved source-controlled blocker.
- [ ] T097 Run/review exact-main CI after merge.
- [ ] T098 Reconcile FEATURE_CATALOG/STATUS/work evidence on main.
- [ ] T099 Record the precise external steps still required for TEST-011 VERIFIED status.
- [ ] T100 Run a fresh dependency-ready scan and select exactly one next source-controlled workstream.

## Safety boundary

No production UMP/privacy-message configuration, production AdMob IDs, credentials, production signing evidence, regulated-region observations, or physical-device claims may be invented. Repository CI may complete source-owned acceptance and move TEST-011 to IMPLEMENTED, but VERIFIED requires the external/device evidence in `docs/TEST_011_PRIVACY_SECURITY.md`.
