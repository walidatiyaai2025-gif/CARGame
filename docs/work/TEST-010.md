# TEST-010 Dashboard/catalog parser validation

Issue: #187
Branch: `agent/test-010-dashboard-catalog-parity`

## State

IN PROGRESS

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

- [ ] Actual catalog parses and dashboard-equivalent parsing matches phase/feature identity.
- [ ] Full dashboard status vocabulary matches catalog status vocabulary.
- [ ] Missing, self, and cyclic dependencies fail.
- [ ] Malformed/duplicate catalog rows fail.
- [ ] Hard-coded dashboard aggregate totals/percentages fail.
- [ ] Focused TEST-010 regression suite passes.
- [ ] Normal Flutter CI runs TEST-010 before package restore.
- [ ] Formatting, Analyze, full Flutter tests, Debug APK, artifact scan, and upload pass.
- [ ] Catalog and STATUS are reconciled to final evidence before merge.
