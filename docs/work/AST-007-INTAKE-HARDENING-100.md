# AST-007 Production Intake Hardening — 100 Checkpoints

Parent issue: #210
Branch: `agent/ast-007-intake-hardening-100`

## State

COMPLETE — H001-H100 source-controlled intake-hardening checkpoints are complete and exact-main verified. Parent AST-007 remains IN PROGRESS. Production truth remains 124 cargo descriptors, 0 approved provenance records, and 0 runtime cargo WebP binaries. No art, licensing, checksums, approvals, or device evidence is fabricated.

## A. Baseline and ownership
- [x] H001 Start from current main after PR #215/exact-main CI #902.
- [x] H002 Keep AST-007 as the single primary feature.
- [x] H003 Preserve all 18 gameplay archetype IDs.
- [x] H004 Preserve the deterministic 150-level gameplay catalog.
- [x] H005 Preserve reward/save/matching authority outside visual IDs.
- [x] H006 Preserve 124 cargo descriptor IDs and runtime paths.
- [x] H007 Preserve AST-011 fail-closed provenance admission.
- [x] H008 Preserve the 0-approved-provenance baseline honestly.
- [x] H009 Preserve the 0-runtime-cargo-WebP baseline honestly.
- [x] H010 Keep GAME-012 blocked until real assets are admitted.

## B. Intake summary model
- [x] H011 Add immutable intake summary value object.
- [x] H012 Report total descriptor count.
- [x] H013 Report admitted count.
- [x] H014 Report remaining count.
- [x] H015 Report missing-binary-only count.
- [x] H016 Report missing-provenance-only count.
- [x] H017 Report missing-both count.
- [x] H018 Preserve aggregate missing-binary count.
- [x] H019 Preserve aggregate missing-provenance count.
- [x] H020 Expose deterministic completion ratio/percent.

## C. Batch selection API
- [x] H021 Keep default batch size 12.
- [x] H022 Add non-negative deterministic offset support.
- [x] H023 Reject negative offsets.
- [x] H024 Keep invalid/non-positive limits rejected.
- [x] H025 Filter batches by intake state.
- [x] H026 Preserve partial-admission-first priority.
- [x] H027 Preserve stable asset-ID tie breaking.
- [x] H028 Return immutable batch lists.
- [x] H029 Add direct asset lookup by stable ID.
- [x] H030 Add state-specific item listing.

## D. Path and orphan integrity
- [x] H031 Normalize Windows path separators.
- [x] H032 Normalize redundant `./` prefixes.
- [x] H033 Normalize duplicate path separators.
- [x] H034 Deduplicate normalized runtime paths.
- [x] H035 Detect unreferenced cargo WebP runtime files.
- [x] H036 Keep unrelated non-cargo runtime files out of cargo orphan reports.
- [x] H037 Detect cargo provenance records orphaned from cargo descriptors.
- [x] H038 Keep unrelated category provenance out of cargo orphan reports.
- [x] H039 Include orphan counts in completion readiness.
- [x] H040 Keep descriptor/provenance alignment validation fail-fast.

## E. Deterministic reporting
- [x] H041 Add summary JSON serialization.
- [x] H042 Keep intake item JSON stable and explicit.
- [x] H043 Include state wire names in machine output.
- [x] H044 Include exact runtime path in machine output.
- [x] H045 Include profile and dimensions in machine output.
- [x] H046 Include orphan runtime paths in machine output.
- [x] H047 Include orphan provenance IDs in machine output.
- [x] H048 Include selected batch offset in machine output.
- [x] H049 Include selected state filter in machine output.
- [x] H050 Keep output ordering deterministic.

## F. CLI argument contract
- [x] H051 Preserve legacy `--json` support.
- [x] H052 Add `--format=human|json|csv`.
- [x] H053 Add `--offset=N`.
- [x] H054 Add `--state=<wire-name>`.
- [x] H055 Add `--summary-only`.
- [x] H056 Add `--strict` readiness mode.
- [x] H057 Add `--help` usage output.
- [x] H058 Reject unknown formats.
- [x] H059 Reject unknown state names.
- [x] H060 Reject unknown command-line options.

## G. CLI output/handoff behavior
- [x] H061 Human output shows progress and remaining count.
- [x] H062 Human output shows orphan warnings.
- [x] H063 Human output shows selected offset/filter.
- [x] H064 JSON output includes summary object.
- [x] H065 JSON output includes selected batch array.
- [x] H066 JSON output includes orphan arrays.
- [x] H067 CSV output uses stable columns.
- [x] H068 CSV output escapes commas/quotes/newlines safely.
- [x] H069 Summary-only mode omits batch rows.
- [x] H070 Strict mode exits non-zero while intake is incomplete.

## H. Focused regression coverage
- [x] H071 Test partial-admission priority.
- [x] H072 Test path normalization.
- [x] H073 Test invalid batch limit.
- [x] H074 Test invalid negative offset.
- [x] H075 Test deterministic offset slicing.
- [x] H076 Test state filtering.
- [x] H077 Test summary counts.
- [x] H078 Test completion ratio.
- [x] H079 Test orphan runtime detection.
- [x] H080 Test orphan provenance detection.

## I. Machine ownership and CI
- [x] H081 Extend AST-007 machine validator for summary API.
- [x] H082 Extend validator for offset/filter API.
- [x] H083 Extend validator for orphan detection.
- [x] H084 Extend validator for CLI format contract.
- [x] H085 Extend validator for strict mode.
- [x] H086 Add validator mutation for summary drift.
- [x] H087 Add validator mutation for CLI-format drift.
- [x] H088 Add validator mutation for orphan-contract drift.
- [x] H089 Add normal-CI CLI JSON/CSV smoke checks.
- [x] H090 Keep all existing security/privacy/PERF/A11Y gates intact.

## J. Documentation, verification, and handoff
- [x] H091 Add production-art intake runbook.
- [x] H092 Document exact first-batch handoff flow.
- [x] H093 Document provenance fields as mandatory, never synthesized.
- [x] H094 Document orphan cleanup/repair flow.
- [x] H095 Document strict readiness usage.
- [x] H096 Pass Dart formatting and whitespace validation.
- [x] H097 Pass Analyze and focused AST-007 tests.
- [x] H098 Pass full Flutter suite, coverage, Debug APK and artifact security/upload.
- [x] H099 Merge only from a green final head and verify exact-main CI.
- [x] H100 Reconcile evidence while keeping AST-007 IN PROGRESS until real provenance-backed WebP admission occurs.

## Acceptance boundary

This 100-checkpoint sprint improves the source-controlled intake pipeline and handoff quality. It does **not** complete the production art pack by itself. AST-007 remains IN PROGRESS until real cargo WebP files and valid commercial-use provenance are supplied, validated, admitted, and then visually/profile tested.

## Verification evidence

- Final PR #218 head `dd4347299f21eb22a5803a59ec43112243f19ee8` passed Flutter CI #913 / run `31493446170` all 70 gates, including the composed AST-007 machine contract, 17 intake-hardening mutations + 7 Batch-01 mutations, JSON/CSV/strict CLI smoke, canonical formatting, Analyze, focused matrices, full Flutter suite, coverage, Debug APK, artifact security and upload.
- PR Debug artifact #9102251590 (80,673,118 bytes; SHA-256 `7f8d9e327875246f3641d6ce7bdc418e9c3d40f3b808dbb5d5f5f7c1c776637c`).
- PR #218 squash-merged as `6546cd978cba2c7c6cd560879df54a57f70e873c`.
- Exact-main Flutter CI #915 / run `31494288422` repeated all 70 gates successfully on `6546cd978cba2c7c6cd560879df54a57f70e873c`.
- Exact-main Debug artifact #9102597251 (80,673,118 bytes; SHA-256 `13bbc58b07c3e772ed57b45b30c30943e155af83fa3312228370697610ca5917`).
- The 18 gameplay archetype IDs, deterministic 150-level gameplay truth, 124 cargo descriptor IDs and AST-011 fail-closed provenance boundary remain unchanged.
- This closes the H001-H100 hardening sprint only. Parent issue #210 / AST-007 remains IN PROGRESS until real commercial-use provenance-backed cargo WebP assets are admitted and exercised through the required visual/profile/device checks.
