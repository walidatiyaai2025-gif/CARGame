#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

PR_HEAD = 'dd4347299f21eb22a5803a59ec43112243f19ee8'
PR_RUN = '31493446170'
PR_ARTIFACT = '#9102251590 (80,673,118 bytes; SHA-256 `7f8d9e327875246f3641d6ce7bdc418e9c3d40f3b808dbb5d5f5f7c1c776637c`)'
MERGE_SHA = '6546cd978cba2c7c6cd560879df54a57f70e873c'
MAIN_RUN = '31494288422'
MAIN_ARTIFACT = '#9102597251 (80,673,118 bytes; SHA-256 `13bbc58b07c3e772ed57b45b30c30943e155af83fa3312228370697610ca5917`)'


def update_hardening() -> None:
    path = Path('docs/work/AST-007-INTAKE-HARDENING-100.md')
    text = path.read_text(encoding='utf-8')
    old_state = (
        'IN PROGRESS — source-controlled hardening only. Production truth remains '
        '124 cargo descriptors, 0 approved provenance records, and 0 runtime cargo '
        'WebP binaries. This sprint must not fabricate art, licensing, checksums, '
        'approvals, or device evidence.'
    )
    new_state = (
        'COMPLETE — H001-H100 source-controlled intake-hardening checkpoints are '
        'complete and exact-main verified. Parent AST-007 remains IN PROGRESS. '
        'Production truth remains 124 cargo descriptors, 0 approved provenance records, '
        'and 0 runtime cargo WebP binaries. No art, licensing, checksums, approvals, '
        'or device evidence is fabricated.'
    )
    if old_state not in text:
        raise SystemExit('hardening state anchor missing')
    text = text.replace(old_state, new_state, 1)
    text = re.sub(r'^- \[ \] (H\d{3}\b)', r'- [x] \1', text, flags=re.M)
    if text.count('- [x] H') != 100:
        raise SystemExit(f'expected 100 checked H checkpoints, found {text.count("- [x] H")}')
    evidence = f'''\n\n## Verification evidence\n\n- Final PR #218 head `{PR_HEAD}` passed Flutter CI #913 / run `{PR_RUN}` all 70 gates, including the composed AST-007 machine contract, 17 intake-hardening mutations + 7 Batch-01 mutations, JSON/CSV/strict CLI smoke, canonical formatting, Analyze, focused matrices, full Flutter suite, coverage, Debug APK, artifact security and upload.\n- PR Debug artifact {PR_ARTIFACT}.\n- PR #218 squash-merged as `{MERGE_SHA}`.\n- Exact-main Flutter CI #915 / run `{MAIN_RUN}` repeated all 70 gates successfully on `{MERGE_SHA}`.\n- Exact-main Debug artifact {MAIN_ARTIFACT}.\n- The 18 gameplay archetype IDs, deterministic 150-level gameplay truth, 124 cargo descriptor IDs and AST-011 fail-closed provenance boundary remain unchanged.\n- This closes the H001-H100 hardening sprint only. Parent issue #210 / AST-007 remains IN PROGRESS until real commercial-use provenance-backed cargo WebP assets are admitted and exercised through the required visual/profile/device checks.\n'''
    if '## Verification evidence' not in text:
        text += evidence
    path.write_text(text, encoding='utf-8')


def update_parent_work() -> None:
    path = Path('docs/work/AST-007.md')
    text = path.read_text(encoding='utf-8')
    anchor = '\n## Remaining AST-007 acceptance\n'
    if anchor not in text:
        raise SystemExit('AST-007 remaining-acceptance anchor missing')
    section = f'''\n## Production intake hardening — 100/100 source-controlled checkpoint\n\n- PR #218 adds immutable intake summary/readiness metrics, deterministic offset/state-filtered batching, path normalization, cargo runtime/provenance orphan detection, direct stable-ID lookup, human/JSON/CSV handoff, strict readiness mode, and a production-art intake runbook without changing gameplay identity.\n- AST-007 machine ownership now composes 17 intake-hardening mutation regressions with the 7 Batch-01 regressions (24 protections total); normal CI also executes JSON/CSV/strict planner smoke checks.\n- Final PR head `{PR_HEAD}` passed Flutter CI #913 / run `{PR_RUN}` all 70 gates; PR artifact {PR_ARTIFACT}.\n- PR #218 squash-merged as `{MERGE_SHA}`. Exact-main Flutter CI #915 / run `{MAIN_RUN}` then passed all 70 gates; main artifact {MAIN_ARTIFACT}.\n- H001-H100 are complete for this source-controlled hardening sprint. This is not production-art completion: approved provenance remains 0 and runtime cargo WebP remains 0, so AST-007 stays IN PROGRESS and GAME-012 stays blocked.\n'''
    if '## Production intake hardening — 100/100 source-controlled checkpoint' not in text:
        text = text.replace(anchor, section + anchor, 1)
    path.write_text(text, encoding='utf-8')


def update_status() -> None:
    path = Path('docs/STATUS.md')
    text = path.read_text(encoding='utf-8')
    completed_pattern = re.compile(r'^\| Completed checkpoint \| .*? \|$', re.M)
    status_pattern = re.compile(r'^\| Status \| .*? \|$', re.M)
    completed = (
        '| Completed checkpoint | `AST-007` production intake hardening — 100/100 '
        'source-controlled checkpoints complete via PR #218; squash merge '
        f'`{MERGE_SHA}` and exact-main Flutter CI #915 / run `{MAIN_RUN}` passed all '
        '70 gates. |'
    )
    status = (
        '| Status | AST-007 intake is now mechanically production-ready for handoff: '
        'immutable readiness metrics, orphan detection, deterministic offset/state '
        'paging, human/JSON/CSV output, strict completion mode, Batch-01 integration, '
        '24 composed mutation protections and normal-CI smoke are green. Exact-main '
        f'artifact {MAIN_ARTIFACT}. Production truth remains 133 descriptors / 0 '
        'approved provenance / 0 runtime WebP, so parent AST-007 remains IN PROGRESS '
        'and GAME-012 remains blocked. |'
    )
    text, count1 = completed_pattern.subn(completed, text, count=1)
    text, count2 = status_pattern.subn(status, text, count=1)
    if count1 != 1 or count2 != 1:
        raise SystemExit('STATUS current-work anchors missing')
    bullet_anchor = (
        '- AST-007 remains IN PROGRESS. The next checkpoint is admission of real '
        'commercial-use cargo WebP assets with complete AST-011 provenance; no second '
        'primary feature should start and GAME-012 remains blocked until that evidence exists.'
    )
    bullet = (
        f'- Intake-hardening PR #218 merged as `{MERGE_SHA}` after Flutter CI #913 / '
        f'run `{PR_RUN}` passed all 70 gates; exact-main CI #915 / run `{MAIN_RUN}` '
        f'also passed all 70 gates. The source-controlled H001-H100 sprint is complete, '
        'including readiness metrics, orphan detection, filtered paging, JSON/CSV/strict '
        'handoff, the intake runbook, and 24 composed mutation protections. Production '
        'binary/provenance counts remain 0/0.'
    )
    if bullet not in text:
        if bullet_anchor not in text:
            raise SystemExit('STATUS AST-007 final bullet anchor missing')
        text = text.replace(bullet_anchor, bullet + '\n' + bullet_anchor, 1)
    path.write_text(text, encoding='utf-8')


def update_catalog() -> None:
    path = Path('docs/FEATURE_CATALOG.md')
    text = path.read_text(encoding='utf-8')
    pattern = re.compile(r'^\| AST-007 \| 100\+ 3D cargo product pack \| P1 \| IN PROGRESS \| AST-002 \|.*$', re.M)
    row = (
        '| AST-007 | 100+ 3D cargo product pack | P1 | IN PROGRESS | AST-002 | '
        'Issue #210 remains the single active product-art workstream. The 124-identity '
        'source/runtime-fallback layer, deterministic intake planner and Batch-01 handoff '
        'are merged. Intake-hardening PR #218 adds readiness metrics, path/orphan integrity, '
        'offset/state-filtered batching, human/JSON/CSV/strict handoff, a production-art '
        'runbook, 17 hardening mutation regressions composed with 7 Batch-01 regressions, '
        f'and normal-CI smoke; it squash-merged as `{MERGE_SHA}` after CI #913 / run '
        f'`{PR_RUN}` passed all 70 gates, and exact-main CI #915 / run `{MAIN_RUN}` '
        f'passed all 70 gates with artifact {MAIN_ARTIFACT}. Gameplay truth remains 18 '
        'stable archetype IDs across the deterministic 150-level catalog. Production art '
        'is deliberately not claimed complete: main still has 133 manifest descriptors, '
        '0 approved provenance records and 0 runtime cargo WebP binaries. AST-007 therefore '
        'remains IN PROGRESS and GAME-012 remains blocked until real commercial-use '
        'WebP/provenance and device/profile evidence exist. |'
    )
    text, count = pattern.subn(row, text, count=1)
    if count != 1:
        raise SystemExit('AST-007 catalog row anchor missing')
    path.write_text(text, encoding='utf-8')


def main() -> None:
    update_hardening()
    update_parent_work()
    update_status()
    update_catalog()
    print('AST-007 intake-hardening reconciliation applied: H001-H100 complete; parent remains IN PROGRESS.')


if __name__ == '__main__':
    main()
