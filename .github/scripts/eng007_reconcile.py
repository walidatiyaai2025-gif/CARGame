from pathlib import Path

MERGE_SHA = '1e1ffd1c36f1338dc36820a3f38e78ae4bbcb47a'
ARTIFACT_SHA = '35e6836f0b85a890bb8a159f0f71657ac3b4be1af8abdda1581fd3ae77822cf4'

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old = '| ENG-007 | CI verification workflow | P1 | IN PROGRESS | ENG-002 | Issue #160 is closing the remaining CI acceptance gaps: executable dashboard/catalog parser integrity plus protected release-workflow contract checks while preserving the existing format/analyze/test/debug-build and path-triggered release smoke gates. |'
new = f'| ENG-007 | CI verification workflow | P1 | VERIFIED | ENG-002 | Issue #160 / PR #161 add executable dashboard/catalog parser integrity and protected release-workflow contracts to normal Flutter CI, with 12 focused regressions while preserving existing security/privacy/dependency/assets/format/analyze/full-test/debug-APK gates and the path-triggered release APK+AAB smoke. Flutter CI #734 passed all gates and uploaded Debug APK artifact #9041540363; PR #161 squash-merged as `{MERGE_SHA}`. |'
if old not in text:
    raise SystemExit('ENG-007 catalog row did not match expected IN PROGRESS state')
catalog.write_text(text.replace(old, new, 1), encoding='utf-8')

status = Path('docs/STATUS.md')
text = status.read_text(encoding='utf-8')
replacements = {
    '| Primary feature | `ENG-007` CI verification workflow — Issue #160 / branch `agent/eng-007-ci-verification`. |': '| Primary feature | None — `ENG-007` CI verification workflow is VERIFIED; `TEST-011` is the highest-priority dependency-ready catalog item. |',
    '| Completed checkpoint | `ENG-006` dependency and package governance — PRs #158/#159, latest reconciliation `8caabd9629b46714041d4fdcb8aabca1690f1135`. |': f'| Completed checkpoint | `ENG-007` CI verification and dashboard integrity — PR #161 merged as `{MERGE_SHA}` after green Flutter CI #734. |',
    '| Status | ENG-007 is IN PROGRESS: dashboard/catalog parser integrity and protected release-workflow contracts are being made executable in normal Flutter CI without changing runtime behavior. |': '| Status | ENG-007 is VERIFIED: normal Flutter CI now blocks dashboard/catalog parser drift and protected release-smoke contract regressions, backed by 12 focused tests, while preserving the full existing verification pipeline. |',
    '| Previous checkpoint | `ENG-006` dependency/package governance — VERIFIED after PRs #158/#159. |': '| Previous checkpoint | `ENG-006` dependency/package governance — VERIFIED after PRs #158/#159. |',
    '| Next recommended feature | Complete `ENG-007` focused CI-contract validation, full Flutter CI, Debug APK artifact, and current-main reconciliation before selecting the next catalog item. |': '| Next recommended feature | `TEST-011` Privacy, consent, and security verification — P0; dependencies `PRIV-001` and `SEC-001` are satisfied. `REL-013` is not considered ready while its human-readable dependency “All P0 release blockers” remains unresolved. |',
}
for old_line, new_line in replacements.items():
    if old_line not in text:
        raise SystemExit(f'STATUS line did not match expected text: {old_line}')
    text = text.replace(old_line, new_line, 1)

section = f'''## ENG-007 CI verification workflow — 2026-08-09

- Issue #160 / PR #161 close the remaining CI acceptance gaps without changing runtime behavior.
- `tool/verify_ci_integrity.py` validates all 19 catalog phases and 192 current feature rows, exact six-column Markdown structure, stable/unique feature IDs, status/priority vocabulary, dependency references, and the single-primary-work invariant.
- The same verifier protects the Developer Portal runtime parser contract so `docs/dashboard/index.html` continues to load and audit `docs/FEATURE_CATALOG.md` instead of maintaining a second status copy.
- The protected release-smoke contract requires release-input preflight, ephemeral CI signing, synthetic compile-only AdMob input, ads-disabled release APK+AAB builds, output/checksum evidence, and artifact upload while rejecting production repository-secret dependencies.
- Twelve focused regressions cover catalog, dashboard, and release-workflow failure modes. Focused probe run `31325591817` passed the real 19-phase / 192-feature catalog, all 12 tests, Analyze, and whitespace validation.
- Flutter CI #734 / run `31325664494` passed the new ENG-007 gates plus dynamic Android, secret/privacy/security/dependency/assets, formatting, whitespace, Analyze, optional-service/GameButton coverage, full Flutter suite, Debug APK build, and artifact upload on head `644a7635bc5f1f3289c05cd3d88bcf9510fee157`.
- Debug artifact #9041540363 is 80,594,411 bytes with SHA-256 `{ARTIFACT_SHA}`.
- PR #161 squash-merged to main as `{MERGE_SHA}`; Issue #160 closed Completed. ENG-007 has no remaining acceptance blocker and is VERIFIED.
- A dependency-ready queue audit selects `TEST-011` (P0, dependencies `PRIV-001` and `SEC-001`) as the next valid feature. `REL-013` is intentionally excluded until its human-readable “All P0 release blockers” condition is truly satisfied.

'''
marker = '## ENG-006 dependency governance verification — 2026-08-09\n'
if marker not in text:
    raise SystemExit('STATUS insertion marker not found')
text = text.replace(marker, section + marker, 1)
status.write_text(text, encoding='utf-8')

work = Path('docs/work/ENG-007.md')
text = work.read_text(encoding='utf-8')
if 'IN PROGRESS.' not in text:
    raise SystemExit('ENG-007 work state not IN PROGRESS')
text = text.replace('IN PROGRESS.', 'VERIFIED.', 1).rstrip() + f'''\n\n## Verification evidence\n\n- Focused ENG-007 probe run `31325591817`: real catalog 19/19 phases and 192 features parsed; dashboard runtime parser contract passed; protected release workflow contract passed; Flutter CI gate-order contract passed; 12/12 focused regressions passed; Analyze and `git diff --check` passed.\n- Flutter CI #734 / run `31325664494`: all existing and new gates passed, including full Flutter suite, Debug APK build, and artifact upload.\n- Debug artifact #9041540363: 80,594,411 bytes; SHA-256 `{ARTIFACT_SHA}`.\n- PR #161 squash-merged as `{MERGE_SHA}`; Issue #160 closed Completed.\n- No runtime, package-version, persistence, gameplay, ads, navigation, localization, or release-packaging behavior changed.\n- Next dependency-ready work: `TEST-011` Privacy, consent, and security verification (P0; `PRIV-001`, `SEC-001`).\n'''
work.write_text(text, encoding='utf-8')
