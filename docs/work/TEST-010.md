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

- PR: #188; implementation head: `fc560c2668fcf6eef8aded139e13b1aa329a467d`.
- Catalog integrity: 19 phases / 192 features; dashboard-equivalent identity matches the authoritative parser; seven dashboard statuses match the catalog vocabulary; dependency graph is acyclic.
- Focused regressions: existing CI integrity 15/15 PASS; TEST-010 parity regressions 9/9 PASS.
- Flutter CI #822 / run `31384332431`: all 45 workflow steps PASS, including TEST-007, TEST-010, formatting, Analyze, full Flutter tests, Debug APK build, artifact security and upload.
- Debug artifact #9061312211: 80,633,603 bytes; SHA-256 `d5d370e02469ba47db3f773e1de88e97293f394df5d904f5f881cf450275028a`.
- Final merge remains gated on a normal Flutter CI run of the reconciled tracking head.
