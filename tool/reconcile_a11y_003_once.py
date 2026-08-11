#!/usr/bin/env python3
from pathlib import Path

MERGE_SHA = '996bebf50e9f5b150e10a9f6455a27015a67355f'
PR_HEAD = '04abd449451e0fb44f5a95eca6f74af263a35665'
PR_RUN = '31472254901'
MAIN_RUN = '31473003490'
PR_ARTIFACT = '#9094044902 (80,659,591 bytes; sha256:bfa4d84edc21eaf6efdd376dcdc04b0101a5e21efc7de555dda18fae09709d3c)'
MAIN_ARTIFACT = '#9094321792 (80,659,593 bytes; sha256:ee95a99a8460d1824a28fb9512d12454d3e9f69648a9e0bd5506e34ccf2be98d)'

catalog_path = Path('docs/FEATURE_CATALOG.md')
catalog = catalog_path.read_text(encoding='utf-8')
old_row = '| A11Y-003 | Reduced motion | P1 | IN PROGRESS | UI3D-007 | Issue #208 / branch `agent/a11y-003-reduced-motion-enforcement` enforce typed motion intent, no-ticker reduced paths for shared primitives, deterministic nonessential cinematic skipping, repository-wide direct-motion audit, focused tests and permanent CI ownership. Final merge/build evidence pending. |'
new_row = f'| A11Y-003 | Reduced motion | P1 | IMPLEMENTED | UI3D-007 | Issue #208 / PR #209 complete the source-controlled reduced-motion accessibility contract: typed essential/nonessential/cinematic intent, no-ticker reduced paths, deterministic cinematic skipping, repository-wide direct-motion audit, EN/AR Settings explanation, focused tests and permanent CI ownership. Final PR head `{PR_HEAD}` passed Flutter CI #872 / run `{PR_RUN}` including full suite/coverage, Debug APK security and upload; artifact {PR_ARTIFACT}. PR #209 squash-merged as `{MERGE_SHA}` and exact-main Flutter CI #873 / run `{MAIN_RUN}` passed every gate with main artifact {MAIN_ARTIFACT}. Source-controlled acceptance is IMPLEMENTED; physical assistive-technology/device observation remains separate evidence and is not claimed. |'
if old_row not in catalog:
    raise SystemExit('A11Y-003 catalog row changed unexpectedly; refusing blind reconciliation')
catalog_path.write_text(catalog.replace(old_row, new_row, 1), encoding='utf-8')

status_path = Path('docs/STATUS.md')
status = status_path.read_text(encoding='utf-8')
replacements = {
    '| Primary feature | `A11Y-003` Reduced motion — IN PROGRESS on issue #208 / `agent/a11y-003-reduced-motion-enforcement`. |': '| Primary feature | None — `A11Y-003` source-controlled work is complete and reconciled as IMPLEMENTED; `AST-007` issue #210 is selected next but not started. |',
    '| Completed checkpoint | `UI3D-007` reduced motion and adaptive visual effects — IMPLEMENTED; issue #205 / PR #206 completed 100/100 source-controlled checkpoints, PR #206 merged as `a342b3befed9259326fa769735f327e6916d1a5a`, and exact-main Flutter CI #863 / run `31466188761` passed all 63 gates. |': f'| Completed checkpoint | `A11Y-003` reduced-motion accessibility — IMPLEMENTED; issue #208 / PR #209 completed 100/100 source-controlled checkpoints, PR #209 merged as `{MERGE_SHA}`, and exact-main Flutter CI #873 / run `{MAIN_RUN}` passed all gates. |',
    '| Status | UI3D-007 source-controlled acceptance is IMPLEMENTED: persistent Automatic/Reduced visual effects, app-wide accessibility/performance policy, shared effect budgets, EN/AR live Settings control, privacy inventory, 13/13 validator regressions, focused Flutter coverage, full suite/coverage, Debug APK build/security/upload, and exact-main verification are green. Physical-device visual/performance observation remains separate evidence and is not claimed. |': f'| Status | A11Y-003 source-controlled acceptance is IMPLEMENTED: shared motion intent classification, deterministic no-ticker reduced paths, cinematic skip semantics, direct-motion audit, EN/AR Settings copy, validator regressions, focused/full tests, coverage, Debug APK security/upload and exact-main verification are green. Main artifact {MAIN_ARTIFACT}. Physical assistive-technology/device observation is separate evidence and is not claimed. |',
    '| Previous checkpoint | `TEST-011` privacy, consent, and security verification — IMPLEMENTED with 100/100 repository checkpoints; external production UMP regulated-region/device evidence remains pending. |': '| Previous checkpoint | `UI3D-007` reduced motion and adaptive visual effects — IMPLEMENTED with 100/100 source-controlled checkpoints and exact-main verification. |',
    '| Next recommended feature | A11Y-003 is the active primary; no second source-controlled feature should start until merge/reconciliation completes. |': '| Next recommended feature | `AST-007` 100+ cargo visual variants — P1, dependency-ready via AST-002 and selected as issue #210 because it unblocks the P0 `GAME-012` production 3D board/products path while preserving stable gameplay IDs. |',
}
for old, new in replacements.items():
    if old not in status:
        raise SystemExit(f'STATUS line changed unexpectedly: {old}')
    status = status.replace(old, new, 1)

marker = '## UI3D-007 reduced motion and adaptive visual effects — 2026-08-11\n'
section = f'''## A11Y-003 reduced-motion accessibility — 2026-08-11\n\n- Issue #208 / PR #209 complete the 100-checkpoint source-controlled accessibility sprint; repository status is IMPLEMENTED.\n- Shared motion is explicitly classified as essential, nonessential or cinematic. Effective reduced motion removes spatial/decorative motion while preserving semantic, gameplay, reward, callback and navigation completion.\n- `GameCinematicGate`, cargo travel, ambient motion and action feedback have deterministic no-ticker reduced paths. GameButton and route motion consume the intent-aware shared policy.\n- The checked-in direct-motion audit covers the current primitive inventory and the machine validator blocks unclassified source drift.\n- Final PR head `{PR_HEAD}` passed Flutter CI #872 / run `{PR_RUN}` through full tests/coverage, Debug APK, artifact security and upload; PR artifact {PR_ARTIFACT}.\n- PR #209 squash-merged as `{MERGE_SHA}`. Exact-main Flutter CI #873 / run `{MAIN_RUN}` then passed all gates; main Debug artifact {MAIN_ARTIFACT}.\n- No physical assistive-technology/device observation is invented; that broader evidence remains separate.\n- Fresh dependency-ready/product-risk scan selects `AST-007` issue #210 next: introduce 100+ stable cargo visual variants without changing the 18 gameplay archetype IDs or existing 150-level gameplay truth.\n\n'''
if '## A11Y-003 reduced-motion accessibility — 2026-08-11' not in status:
    if marker not in status:
        raise SystemExit('STATUS insertion marker missing')
    status = status.replace(marker, section + marker, 1)
status_path.write_text(status, encoding='utf-8')

work_path = Path('docs/work/A11Y-003.md')
work_path.write_text(f'''# A11Y-003 Reduced Motion Accessibility Enforcement\n\nIssue: #208\nImplementation PR: #209\nImplementation branch: `agent/a11y-003-reduced-motion-enforcement`\nMerge SHA: `{MERGE_SHA}`\n\n## State\n\nIMPLEMENTED — 100/100 source-controlled checkpoints complete. Physical assistive-technology/device observation is separate evidence and is not claimed by this workstream.\n\n## Runtime contract\n\n- System Reduce Motion and the persistent user Reduced effects choice both feed the effective shared motion profile.\n- Performance quality remains a separate graceful-degradation signal and never impersonates accessibility intent.\n- Motion is classified as essential, nonessential or cinematic so reduced behavior is explicit.\n- Nonessential/cinematic spatial animation is skipped under effective reduced motion while state, semantics, navigation, rewards and callbacks remain deterministic.\n- Shared primitives avoid tickers when their reduced path does not animate.\n- Existing sound/haptics, gameplay, economy, privacy, ads and persistence ownership remain unchanged.\n\n## Verification evidence\n\n- Final PR head: `{PR_HEAD}`.\n- Flutter CI #872 / run `{PR_RUN}`: PASSED all gates, including A11Y-003 validator/regressions, Analyze, focused matrix, full suite, coverage, Debug APK, artifact security and upload.\n- PR Debug artifact: {PR_ARTIFACT}.\n- PR #209 squash merge: `{MERGE_SHA}`.\n- Exact-main Flutter CI #873 / run `{MAIN_RUN}`: PASSED every gate.\n- Exact-main Debug artifact: {MAIN_ARTIFACT}.\n\n## 100-checkpoint result\n\nT001-T100 are complete for the source-controlled acceptance boundary. Issue closure/reconciliation is supported by final-head and exact-main evidence.\n\n## Handoff\n\n`AST-007` issue #210 is selected next but is not started in this reconciliation. Its design preserves the existing 18 gameplay archetype IDs and adds a separate 100+ deterministic visual-variant layer so production art work cannot silently change gameplay/save identity.\n''', encoding='utf-8')

print('A11Y-003 reconciliation patch applied')
