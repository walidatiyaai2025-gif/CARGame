# AST-007 Production Intake Hardening — 100 Checkpoints

Parent issue: #210
Branch: `agent/ast-007-intake-hardening-100`

## State

IN PROGRESS — source-controlled hardening only. Production truth remains 124 cargo descriptors, 0 approved provenance records, and 0 runtime cargo WebP binaries. This sprint must not fabricate art, licensing, checksums, approvals, or device evidence.

## A. Baseline and ownership
- [ ] H001 Start from current main after PR #215/exact-main CI #902.
- [ ] H002 Keep AST-007 as the single primary feature.
- [ ] H003 Preserve all 18 gameplay archetype IDs.
- [ ] H004 Preserve the deterministic 150-level gameplay catalog.
- [ ] H005 Preserve reward/save/matching authority outside visual IDs.
- [ ] H006 Preserve 124 cargo descriptor IDs and runtime paths.
- [ ] H007 Preserve AST-011 fail-closed provenance admission.
- [ ] H008 Preserve the 0-approved-provenance baseline honestly.
- [ ] H009 Preserve the 0-runtime-cargo-WebP baseline honestly.
- [ ] H010 Keep GAME-012 blocked until real assets are admitted.

## B. Intake summary model
- [ ] H011 Add immutable intake summary value object.
- [ ] H012 Report total descriptor count.
- [ ] H013 Report admitted count.
- [ ] H014 Report remaining count.
- [ ] H015 Report missing-binary-only count.
- [ ] H016 Report missing-provenance-only count.
- [ ] H017 Report missing-both count.
- [ ] H018 Preserve aggregate missing-binary count.
- [ ] H019 Preserve aggregate missing-provenance count.
- [ ] H020 Expose deterministic completion ratio/percent.

## C. Batch selection API
- [ ] H021 Keep default batch size 12.
- [ ] H022 Add non-negative deterministic offset support.
- [ ] H023 Reject negative offsets.
- [ ] H024 Keep invalid/non-positive limits rejected.
- [ ] H025 Filter batches by intake state.
- [ ] H026 Preserve partial-admission-first priority.
- [ ] H027 Preserve stable asset-ID tie breaking.
- [ ] H028 Return immutable batch lists.
- [ ] H029 Add direct asset lookup by stable ID.
- [ ] H030 Add state-specific item listing.

## D. Path and orphan integrity
- [ ] H031 Normalize Windows path separators.
- [ ] H032 Normalize redundant `./` prefixes.
- [ ] H033 Normalize duplicate path separators.
- [ ] H034 Deduplicate normalized runtime paths.
- [ ] H035 Detect unreferenced cargo WebP runtime files.
- [ ] H036 Keep unrelated non-cargo runtime files out of cargo orphan reports.
- [ ] H037 Detect cargo provenance records orphaned from cargo descriptors.
- [ ] H038 Keep unrelated category provenance out of cargo orphan reports.
- [ ] H039 Include orphan counts in completion readiness.
- [ ] H040 Keep descriptor/provenance alignment validation fail-fast.

## E. Deterministic reporting
- [ ] H041 Add summary JSON serialization.
- [ ] H042 Keep intake item JSON stable and explicit.
- [ ] H043 Include state wire names in machine output.
- [ ] H044 Include exact runtime path in machine output.
- [ ] H045 Include profile and dimensions in machine output.
- [ ] H046 Include orphan runtime paths in machine output.
- [ ] H047 Include orphan provenance IDs in machine output.
- [ ] H048 Include selected batch offset in machine output.
- [ ] H049 Include selected state filter in machine output.
- [ ] H050 Keep output ordering deterministic.

## F. CLI argument contract
- [ ] H051 Preserve legacy `--json` support.
- [ ] H052 Add `--format=human|json|csv`.
- [ ] H053 Add `--offset=N`.
- [ ] H054 Add `--state=<wire-name>`.
- [ ] H055 Add `--summary-only`.
- [ ] H056 Add `--strict` readiness mode.
- [ ] H057 Add `--help` usage output.
- [ ] H058 Reject unknown formats.
- [ ] H059 Reject unknown state names.
- [ ] H060 Reject unknown command-line options.

## G. CLI output/handoff behavior
- [ ] H061 Human output shows progress and remaining count.
- [ ] H062 Human output shows orphan warnings.
- [ ] H063 Human output shows selected offset/filter.
- [ ] H064 JSON output includes summary object.
- [ ] H065 JSON output includes selected batch array.
- [ ] H066 JSON output includes orphan arrays.
- [ ] H067 CSV output uses stable columns.
- [ ] H068 CSV output escapes commas/quotes/newlines safely.
- [ ] H069 Summary-only mode omits batch rows.
- [ ] H070 Strict mode exits non-zero while intake is incomplete.

## H. Focused regression coverage
- [ ] H071 Test partial-admission priority.
- [ ] H072 Test path normalization.
- [ ] H073 Test invalid batch limit.
- [ ] H074 Test invalid negative offset.
- [ ] H075 Test deterministic offset slicing.
- [ ] H076 Test state filtering.
- [ ] H077 Test summary counts.
- [ ] H078 Test completion ratio.
- [ ] H079 Test orphan runtime detection.
- [ ] H080 Test orphan provenance detection.

## I. Machine ownership and CI
- [ ] H081 Extend AST-007 machine validator for summary API.
- [ ] H082 Extend validator for offset/filter API.
- [ ] H083 Extend validator for orphan detection.
- [ ] H084 Extend validator for CLI format contract.
- [ ] H085 Extend validator for strict mode.
- [ ] H086 Add validator mutation for summary drift.
- [ ] H087 Add validator mutation for CLI-format drift.
- [ ] H088 Add validator mutation for orphan-contract drift.
- [ ] H089 Add normal-CI CLI JSON/CSV smoke checks.
- [ ] H090 Keep all existing security/privacy/PERF/A11Y gates intact.

## J. Documentation, verification, and handoff
- [ ] H091 Add production-art intake runbook.
- [ ] H092 Document exact first-batch handoff flow.
- [ ] H093 Document provenance fields as mandatory, never synthesized.
- [ ] H094 Document orphan cleanup/repair flow.
- [ ] H095 Document strict readiness usage.
- [ ] H096 Pass Dart formatting and whitespace validation.
- [ ] H097 Pass Analyze and focused AST-007 tests.
- [ ] H098 Pass full Flutter suite, coverage, Debug APK and artifact security/upload.
- [ ] H099 Merge only from a green final head and verify exact-main CI.
- [ ] H100 Reconcile evidence while keeping AST-007 IN PROGRESS until real provenance-backed WebP admission occurs.

## Acceptance boundary

This 100-checkpoint sprint improves the source-controlled intake pipeline and handoff quality. It does **not** complete the production art pack by itself. AST-007 remains IN PROGRESS until real cargo WebP files and valid commercial-use provenance are supplied, validated, admitted, and then visually/profile tested.