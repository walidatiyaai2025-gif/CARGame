# TEST-010 Dashboard/catalog parser validation

Issue: #187
Branch: `agent/test-010-dashboard-catalog-parity`

## State

VERIFIED

## Goal

Turn the existing ENG-007 dashboard/catalog integrity baseline into a dedicated release-quality TEST-010 parity contract without creating a second maintained feature catalog.

## Scope

- Keep `docs/FEATURE_CATALOG.md` as the single source of truth.
- Validate exact A-S phases, the six-column schema, feature IDs, priorities, statuses, dependencies, and one-active-feature policy.
- Reject missing/self/cyclic dependencies deterministically.
- Parse catalog rows through an independent dashboard-equivalent model and require parity with the authoritative catalog parser.
- Require the dashboard to support the complete status vocabulary and retain runtime catalog fetch, parser, audit, and render contracts.
- Reject hard-coded aggregate feature totals/completion percentages in dashboard source.
- Add focused TEST-010 regressions and a blocking normal-CI gate.
- Preserve all TEST-007 and latest-verified-APK gates.

## Non-goals

- No gameplay, economy, persistence, navigation, ads, privacy, asset, or release-signing behavior changes.
- No production identifiers, credentials, packages, or generated binaries.
- No second source of truth for feature status.

## Acceptance

- [x] Actual catalog parses and dashboard-equivalent parsing matches phase/feature identity.
- [x] Full dashboard status vocabulary matches catalog status vocabulary.
- [x] Missing, self, and cyclic dependencies fail.
- [x] Malformed/duplicate catalog rows fail.
- [x] Hard-coded dashboard aggregate totals/percentages fail.
- [x] Focused TEST-010 regression suite passes.
- [x] Normal Flutter CI runs TEST-010 before package restore.
- [x] Formatting, Analyze, full Flutter tests, Debug APK, artifact scan, and upload pass.
- [x] Catalog and STATUS are reconciled to final evidence before merge.

## Verification evidence

- PR: #188; Issue #187 closed completed after squash merge.
- Catalog integrity: 19 phases / 192 features; dashboard-equivalent identity matches the authoritative parser; seven dashboard statuses match the catalog vocabulary; dependency graph is acyclic.
- Focused regressions: existing CI integrity 15/15 PASS; TEST-010 parity regressions 9/9 PASS.
- Implementation checkpoint: Flutter CI #822 / run `31384332431` passed all 45 steps.
- Final clean-head checkpoint: `a7fd43118ec42852984aaf3f2b4f723534fad6b5` passed Flutter CI #827 / run `31385221550` 45/45; debug artifact #9061656030 is 80,633,607 bytes, SHA-256 `04a7620731d146aac4aec44f305d895fd21454472e2126cab46e365ea3a4d0e3`.
- Merge: PR #188 squash-merged as `d148ac820ee7dcfbacd0f88304a9cf168bc66b41`. Exact-merge main Flutter CI #828 / run `31385904664` passed 45/45; debug artifact #9061890276 is 80,633,607 bytes, SHA-256 `a2684e4697cf2e153ee75f471cc1bfeaaf0feb15638e43a788984c2bc585b173`.
- Latest verified APK promotion: run `31386487136` passed release build/security/promotion and committed `743356b2a8e66b699feadb09e1c9f5fa60b858a7`. `Last verified APK/CARGame-latest-verified.apk` is 55,878,023 bytes with SHA-256 `7b24570855c3e3f48007f53eac9770cde3a6a9fe0de519abff35fcb36925383f`; ephemeral CI signing, ads disabled, QA/installable evidence only, not production/Play Store signed.
- TEST-010 is fully VERIFIED, merged, and reconciled. The next workstream must be selected by a fresh dependency-ready scan.
