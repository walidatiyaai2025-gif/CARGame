from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old = '| ENG-007 | CI verification workflow | P1 | PLANNED | ENG-002 | CI runs format, analyze, tests, dashboard parser validation, debug build, and protected release checks. |'
new = '| ENG-007 | CI verification workflow | P1 | IN PROGRESS | ENG-002 | Issue #160 is closing the remaining CI acceptance gaps: executable dashboard/catalog parser integrity plus protected release-workflow contract checks while preserving the existing format/analyze/test/debug-build and path-triggered release smoke gates. |'
if old not in text:
    raise SystemExit('ENG-007 catalog row did not match expected PLANNED state')
catalog.write_text(text.replace(old, new, 1), encoding='utf-8')

status = Path('docs/STATUS.md')
text = status.read_text(encoding='utf-8')
replacements = {
    '| Primary feature | None — `ENG-006` dependency/package governance is verified; `ENG-007` CI verification workflow is the next dependency-ready engineering item. |': '| Primary feature | `ENG-007` CI verification workflow — Issue #160 / branch `agent/eng-007-ci-verification`. |',
    '| Completed checkpoint | `ENG-006` dependency and package governance — PR #158 merged as `e8e474e54ada81b5936bd5adf0d9aa9e31ff117e` after green Flutter CI #730. |': '| Completed checkpoint | `ENG-006` dependency and package governance — PRs #158/#159, latest reconciliation `8caabd9629b46714041d4fdcb8aabca1690f1135`. |',
    '| Status | ENG-006 is VERIFIED: normal Flutter CI now enforces approved dependency sources, direct manifest/lock alignment, reviewed direct-package licenses and policy regressions while reporting upstream version drift without auto-upgrading. |': '| Status | ENG-007 is IN PROGRESS: dashboard/catalog parser integrity and protected release-workflow contracts are being made executable in normal Flutter CI without changing runtime behavior. |',
    '| Previous checkpoint | `ENG-005` enforceable clean-architecture boundary checkpoint — PRs #155/#156. |': '| Previous checkpoint | `ENG-006` dependency/package governance — VERIFIED after PRs #158/#159. |',
    '| Next recommended feature | `ENG-007` CI verification workflow — close the remaining CI acceptance gaps around dashboard/parser validation and protected release checks while preserving the existing green Flutter pipeline. |': '| Next recommended feature | Complete `ENG-007` focused CI-contract validation, full Flutter CI, Debug APK artifact, and current-main reconciliation before selecting the next catalog item. |',
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f'STATUS line did not match expected text: {old}')
    text = text.replace(old, new, 1)
status.write_text(text, encoding='utf-8')
