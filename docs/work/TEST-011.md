# TEST-011 — Privacy consent and security verification

- Issue: #202
- Branch: `agent/test-011-privacy-security-verification`
- State: IMPLEMENTED
- Dependencies: PRIV-001 VERIFIED, SEC-001 VERIFIED
- Verification ceiling: IMPLEMENTED until production UMP/privacy-message regulated-region/device evidence exists.

## Objective

Make every repository-owned privacy, consent, local-data, diagnostics, secret, dependency, network-policy, and packaged-artifact release assertion mechanically auditable without fabricating production Google UMP/device evidence.

## 100-checkpoint execution contract

### A. Baseline and workstream selection
- [x] T001 Confirm PERF-002 final-head CI is green.
- [x] T002 Confirm PERF-002 is merged to main.
- [x] T003 Obtain a non-skipped full CI run against the merged PERF-002 runtime tree.
- [x] T004 Reconcile PERF-002 honestly as IMPLEMENTED, not VERIFIED, without device RSS/GPU claims.
- [x] T005 Confirm TEST-009 remains blocked on real PERF-001 device profiling.
- [x] T006 Confirm PRIV-001 is VERIFIED.
- [x] T007 Confirm SEC-001 is VERIFIED.
- [x] T008 Confirm SEC-002 and PRIV-003 repository gates are already present.
- [x] T009 Confirm no active TEST-011 implementation PR/branch exists.
- [x] T010 Mark TEST-011 as the only primary source-controlled workstream before implementation edits.

### B. Consent and ad-request gating verification
- [x] T011 Audit UMP consent-info refresh at launch.
- [x] T012 Audit required-form presentation handling.
- [x] T013 Audit `canRequestAds` as the ad eligibility authority.
- [x] T014 Audit fail-closed behavior before consent eligibility.
- [x] T015 Audit banner request gating.
- [x] T016 Audit rewarded request gating.
- [x] T017 Audit interstitial request gating.
- [x] T018 Audit runtime consent revocation/disposal behavior.
- [x] T019 Audit Settings privacy-options re-open path.
- [x] T020 Verify offline/core play remains non-blocking when UMP fails or is unavailable.

### C. Privacy inventory and data-minimization verification
- [x] T021 Re-run persisted-data inventory ownership checks.
- [x] T022 Verify every SharedPreferences family remains inventoried.
- [x] T023 Verify Google Mobile Ads remains the sole declared off-device processor.
- [x] T024 Verify no first-party analytics emitter is enabled by default.
- [x] T025 Verify analytics runtime privacy gate remains fail-closed.
- [x] T026 Verify remote diagnostics remains disabled by default.
- [x] T027 Verify crash/non-fatal reporting has no active remote emitter path.
- [x] T028 Verify data-safety mapping matches current processor inventory.
- [x] T029 Verify privacy disclosures retain local-only vs off-device distinctions.
- [x] T030 Verify no source-controlled production identifiers/credentials are introduced.

### D. Local export and deletion verification
- [x] T031 Audit schema-versioned local-data export.
- [x] T032 Audit destructive-reset confirmation guard.
- [x] T033 Audit concurrent-delete serialization.
- [x] T034 Audit diagnostic-log clearing during deletion.
- [x] T035 Audit ProgressStore rehydration after reset.
- [x] T036 Audit AppSettingsStore rehydration after reset.
- [x] T037 Audit stale-route removal after reset.
- [x] T038 Verify unrelated runtime state is not silently reintroduced after deletion.
- [x] T039 Verify Settings exposes the local privacy controls.
- [x] T040 Add TEST-011 evidence linking export/deletion tests to the release matrix.

### E. Diagnostics, analytics, and redaction verification
- [x] T041 Verify diagnostics logging respects its runtime enable gate.
- [x] T042 Verify diagnostic payload size bounds remain enforced.
- [x] T043 Verify secret redaction remains applied to diagnostics.
- [x] T044 Verify path-sensitive diagnostic redaction remains applied.
- [x] T045 Verify analytics properties remain allowlisted/schema-versioned.
- [x] T046 Verify analytics cannot emit before runtime privacy permission.
- [x] T047 Verify analytics cannot reuse UMP ad consent as first-party analytics consent.
- [x] T048 Verify crash-reporting privacy contract remains isolated from ads consent.
- [x] T049 Verify no new telemetry persistence/network path exists outside inventory.
- [x] T050 Record machine-readable TEST-011 evidence for analytics/diagnostics gates.

### F. Secret, dependency, artifact, and network security verification
- [x] T051 Re-run tracked-secret policy contract.
- [x] T052 Re-run secret-scanner regression suite.
- [x] T053 Re-run dependency advisory enforcement.
- [x] T054 Re-run dependency-security regression suite.
- [x] T055 Verify lockfile enforcement remains blocking.
- [x] T056 Verify security advisory exceptions are explicit and bounded.
- [x] T057 Verify packaged APK secret/artifact scan remains mandatory.
- [x] T058 Verify security baseline trust-boundary/network-processor parity.
- [x] T059 Verify no undeclared network processor is present in repository-owned disclosures.
- [x] T060 Record the network-policy and artifact-security requirements in TEST-011 evidence.

### G. Dedicated TEST-011 release evidence contract
- [x] T061 Add `docs/TEST_011_PRIVACY_SECURITY.md`.
- [x] T062 Separate repository-verifiable evidence from external/device evidence.
- [x] T063 Add repository status for consent integration.
- [x] T064 Add repository status for local export/deletion.
- [x] T065 Add repository status for redaction and diagnostics privacy.
- [x] T066 Add repository status for secret/dependency scanning.
- [x] T067 Add repository status for APK artifact security.
- [x] T068 Add repository status for processor/network-policy parity.
- [x] T069 Explicitly mark production UMP/privacy-message configuration as external pending evidence.
- [x] T070 Explicitly prohibit marking TEST-011 VERIFIED from CI-only evidence.

### H. Machine validator and regressions
- [x] T071 Add `tool/verify_test_011_privacy_security.py`.
- [x] T072 Require the TEST-011 evidence document.
- [x] T073 Require existing privacy inventory/disclosure gates.
- [x] T074 Require analytics/crash privacy gates.
- [x] T075 Require secret and dependency-security gates.
- [x] T076 Require packaged artifact-security gate.
- [x] T077 Require local data controller/Settings privacy focused tests.
- [x] T078 Require consent/ad request focused tests.
- [x] T079 Reject any TEST-011 VERIFIED claim while external evidence is pending.
- [x] T080 Add `tool/test_test_011_privacy_security.py` with mutation-based regressions.

### I. CI integration and quality gates
- [x] T081 Add TEST-011 machine validator to normal Flutter CI.
- [x] T082 Add TEST-011 validator regressions to normal Flutter CI.
- [x] T083 Preserve TEST-007 critical-path gates.
- [x] T084 Preserve TEST-008 coverage/flaky policy gates.
- [x] T085 Preserve TEST-010 dashboard/catalog parity gates.
- [x] T086 Preserve AST-004/PERF-001/PERF-002 gates.
- [x] T087 Run formatting and whitespace validation.
- [x] T088 Run Flutter Analyze.
- [x] T089 Run focused privacy/consent/security/local-data tests.
- [x] T090 Run the complete Flutter test suite and coverage threshold.

### J. Build, merge, and honest release-state reconciliation
- [x] T091 Build the Debug APK in normal CI.
- [x] T092 Pass packaged APK artifact-security scanning.
- [x] T093 Upload the CI Debug APK artifact.
- [x] T094 Record final-head CI run/test/coverage/artifact evidence.
- [x] T095 Keep TEST-011 IMPLEMENTED rather than VERIFIED while real UMP regulated-device evidence is absent.
- [x] T096 Merge only with a green final PR head and no unresolved source-controlled blocker.
- [x] T097 Run/review exact-main CI after merge.
- [x] T098 Reconcile FEATURE_CATALOG/STATUS/work evidence on main.
- [x] T099 Record the precise external steps still required for TEST-011 VERIFIED status.
- [x] T100 Run a fresh dependency-ready scan and select exactly one next source-controlled workstream.

## Safety boundary

No production UMP/privacy-message configuration, production AdMob IDs, credentials, production signing evidence, regulated-region observations, or physical-device claims may be invented. Repository CI may complete source-owned acceptance and move TEST-011 to IMPLEMENTED, but VERIFIED requires the external/device evidence in `docs/TEST_011_PRIVACY_SECURITY.md`.


## Final source-controlled completion evidence

- Final PR head `d07dc2a1b84f5f949cf1cf5925b8348c581cb27b` passed Flutter CI #856 / run `31440184413`: formatting/whitespace, Analyze, TEST-011 validator, 17/17 mutation regressions, focused TEST-011 matrix 38/38, full Flutter suite 345/345, authored-source coverage 5,840 / 6,620 = 88.22%, Debug APK build, packaged-artifact security and upload.
- PR artifact #9082737774 is 80,650,503 bytes with artifact ZIP SHA-256 `f2e73219019f78fa16f67f56a0cd551ab822f2d2cad52b301b6eddc834800cb7`.
- PR #203 squash-merged to `main` as `eb3f4df464173dab6729bfb6ed4ccf7289747057`.
- Exact-main Flutter CI #857 / run `31440863970` passed every one of the 60 workflow gates, including TEST-011 validator/mutations/focused matrix, full suite, coverage, Debug APK, artifact security and upload. Main artifact #9082985280 is 80,650,506 bytes with artifact ZIP SHA-256 `30024ca046038fb7c9ed3b1425d72366830750389bb011a65b4a3b86648ad3ca`.
- T001-T100 are complete for the repository-owned sprint. TEST-011 remains IMPLEMENTED because production AdMob Privacy & messaging/UMP regulated-region/device verification is an explicit external evidence boundary and remains PENDING.
- T100 fresh dependency scan selects P1 `UI3D-007` Reduced motion and low-performance visual mode as the next source-controlled workstream. It must start from current `main`; stale `agent/ui3d-007-world-map-refresh` is 45 commits behind and reference-only.
