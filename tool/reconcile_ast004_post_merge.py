#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

CATALOG = Path('docs/FEATURE_CATALOG.md')
STATUS = Path('docs/STATUS.md')
WORK = Path('docs/work/AST-004.md')

MERGE_SHA = '22239a6cdd7af3770a03a4b9a86e8d32d078a01b'
PR_HEAD = '61c5741ba8340e0baafb2d2cea9989137b25a279'
PR_RUN = '31408977215'
MAIN_RUN = '31409971405'
PR_ARTIFACT_SHA = '0e6da3e6d75212817f22c91592009e97532d838f4f395a4f4f1c9f488a59f5bb'
MAIN_ARTIFACT_SHA = 'b7150ca0969b0f32e3741ca4a47e9c51e7c8d6ce02880af9d47b5f1cfbfec562'


def replace_regex(text: str, pattern: str, replacement: str, label: str, flags: int = 0) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    return updated


def reconcile_catalog() -> None:
    text = CATALOG.read_text(encoding='utf-8')
    row = (
        '| AST-004 | Precache and memory policy | P1 | VERIFIED | AST-002 | '
        'Issue #192 / PR #193 harden the bounded asset cache with shared same-ID in-flight operations, '
        'global/per-ID invalidation so clear/forget cannot be undone by late completion, bounded LRU/failure state, '
        'explicit near-future retry policy, immutable observability counters, safe eviction failures, and machine ownership '
        'gates that reject raw production `precacheImage` bypasses. Final PR head `61c5741ba8340e0baafb2d2cea9989137b25a279` '
        'passed Flutter CI #839 / run `31408977215`: AST-004 focused tests 14/14, validator regressions 6/6, full 320-test '
        'Flutter suite, 88.34% authored-source coverage, Debug APK and artifact security/upload; artifact #9071093253 is '
        '80,633,602 bytes with SHA-256 `0e6da3e6d75212817f22c91592009e97532d838f4f395a4f4f1c9f488a59f5bb`. '
        'PR #193 squash-merged as `22239a6cdd7af3770a03a4b9a86e8d32d078a01b`; exact-main Flutter CI #840 / run '
        '`31409971405` repeated 320 tests, 88.34% coverage, Debug APK, artifact security and upload. Main artifact #9071436511 '
        'is 80,633,603 bytes with SHA-256 `b7150ca0969b0f32e3741ca4a47e9c51e7c8d6ce02880af9d47b5f1cfbfec562`. '
        'Asset admission remains 9 descriptors / 0 provenance / 0 runtime WebP, so fallback-safe runtime behavior is unchanged. |'
    )
    text = replace_regex(text, r'^\| AST-004 \|.*$', row, 'AST-004 catalog row', re.MULTILINE)

    text = replace_regex(
        text,
        r'(## IN PROGRESS\n\n).*?(?=\n## NEXT READY)',
        r'\1- None. `AST-004` is VERIFIED after its 100/100 checkpoint sprint and exact-main CI #840; start exactly one next primary workstream only after the recorded dependency-ready selection.\n',
        'active work queue',
        re.DOTALL,
    )
    text = replace_regex(
        text,
        r'(## NEXT READY\n\n).*?(?=\n## BLOCKED)',
        r'\1- `PERF-001` Frame performance budget — P0 and dependency-ready now that MOT-001 is IMPLEMENTED and AST-004 is VERIFIED. It is the selected next primary workstream and must be marked IN PROGRESS only when implementation begins; completing it unlocks TEST-009 device/API compatibility work.\n',
        'next-ready queue',
        re.DOTALL,
    )
    text = replace_regex(
        text,
        r'^- `TEST-009`.*$',
        '- `TEST-009` remains dependency-blocked until selected next workstream `PERF-001` is VERIFIED; the device/API compatibility matrix should follow the performance-budget checkpoint.',
        'TEST-009 blocker',
        re.MULTILINE,
    )

    recent_header = '## Recently verified\n\n'
    if recent_header not in text:
        raise SystemExit('Recently verified section missing')
    recent_line = (
        '- `AST-004` Precache and memory policy — issue #192 / PR #193 complete the 100-checkpoint cache hardening sprint. '
        'Final PR head `61c5741ba8340e0baafb2d2cea9989137b25a279` passed Flutter CI #839 / run `31408977215` '
        'with 14/14 focused cache tests, 6/6 validator regressions, 320 Flutter tests, 88.34% authored-source coverage, '
        'Debug APK, artifact security and upload; artifact #9071093253 is 80,633,602 bytes with SHA-256 '
        '`0e6da3e6d75212817f22c91592009e97532d838f4f395a4f4f1c9f488a59f5bb`. PR #193 squash-merged as '
        '`22239a6cdd7af3770a03a4b9a86e8d32d078a01b`; exact-main Flutter CI #840 / run `31409971405` repeated all '
        'gates and uploaded artifact #9071436511 (80,633,603 bytes; SHA-256 '
        '`b7150ca0969b0f32e3741ca4a47e9c51e7c8d6ce02880af9d47b5f1cfbfec562`).\n'
    )
    if recent_line not in text:
        text = text.replace(recent_header, recent_header + recent_line, 1)
    CATALOG.write_text(text, encoding='utf-8')


def reconcile_status() -> None:
    text = STATUS.read_text(encoding='utf-8')
    rows = {
        'Primary feature': 'None — `AST-004` Precache and memory policy is VERIFIED after 100/100 checkpoints; `PERF-001` is selected next but not started.',
        'Completed checkpoint': '`AST-004` bounded asset precache and memory policy — VERIFIED; issue #192 / PR #193 completed 100/100 checkpoints, PR #193 squash-merged as `22239a6cdd7af3770a03a4b9a86e8d32d078a01b`, and exact-main Flutter CI #840 / run `31409971405` passed all gates with 320 tests and 88.34% authored-source coverage.',
        'Status': 'AST-004 is VERIFIED: same-ID precache work is shared, clear/forget invalidation is race-safe, LRU/failure state is bounded, observability is immutable, raw precache bypasses are CI-blocked, and descriptor-only fallback behavior remains intact. Exact-main artifact #9071436511 is 80,633,603 bytes with SHA-256 `b7150ca0969b0f32e3741ca4a47e9c51e7c8d6ce02880af9d47b5f1cfbfec562`.',
        'Previous checkpoint': '`TEST-008` coverage thresholds and flaky-test policy — VERIFIED and merged; exact-main Flutter CI #836 passed 310 tests and 88.01% authored-source coverage before AST-004.',
        'Next recommended feature': '`PERF-001` Frame performance budget — P0, now dependency-ready via MOT-001 + AST-004. Establish measurable frame targets and graceful fallback before TEST-009 device/API matrix work.',
    }
    for field, value in rows.items():
        text = replace_regex(
            text,
            rf'^\| {re.escape(field)} \|.*$',
            f'| {field} | {value} |',
            f'STATUS {field}',
            re.MULTILINE,
        )

    text = re.sub(
        r'`TEST-009`[^.\n]*PERF-001[^.\n]*\.',
        '`TEST-009` remains dependency-blocked until selected next workstream `PERF-001` is VERIFIED.',
        text,
        count=1,
    )

    section = '''## AST-004 bounded asset precache and memory policy — 2026-08-10

- Issue #192 / PR #193 complete the 100-checkpoint AST-004 sprint; issue #192 is closed completed.
- `GameAssetCachePolicy` shares concurrent same-ID load operations, permits independent different-ID loads, and uses global/per-ID generations so `clear()` or `forget(id)` cannot be reversed by stale async completion.
- Completed cache state and failure history remain bounded; cache hits update LRU priority without reload; near-future work is sequential/deduplicated/budget-clamped and skips known failures unless retry is explicit.
- Immutable snapshots expose hit/miss, joined request, successful load, load failure, eviction, stale completion, and eviction-failure counters; reset affects statistics only.
- `tool/verify_asset_cache_policy.py` mechanically blocks raw production `precacheImage` bypasses and required CI/test drift; its regression suite passes 6/6. Focused cache widget coverage passes 14/14.
- Final clean PR head `61c5741ba8340e0baafb2d2cea9989137b25a279` passed Flutter CI #839 / run `31408977215`: 320 Flutter tests, 88.34% authored-source coverage, Debug APK, artifact security and upload. Artifact #9071093253 is 80,633,602 bytes with SHA-256 `0e6da3e6d75212817f22c91592009e97532d838f4f395a4f4f1c9f488a59f5bb`.
- PR #193 squash-merged as `22239a6cdd7af3770a03a4b9a86e8d32d078a01b`. Exact-main Flutter CI #840 / run `31409971405` passed all 51 gates, the full 320-test suite, 88.34% coverage, Debug APK, artifact security and upload; main artifact #9071436511 is 80,633,603 bytes with SHA-256 `b7150ca0969b0f32e3741ca4a47e9c51e7c8d6ce02880af9d47b5f1cfbfec562`.
- Asset admission remains deliberately unchanged at 9 descriptors / 0 provenance records / 0 runtime WebP files; missing art remains fallback-safe. No gameplay, economy, persistence, ads, privacy runtime, production identifiers, signing, packages, or binary art changed.
- Fresh dependency scan selects `PERF-001` as the next P0 workstream; AST-004 verification also satisfies the asset-cache dependency for PERF-002/AST-010.
'''
    text = replace_regex(
        text,
        r'## AST-004 bounded asset precache and memory policy — 2026-08-10\n.*?(?=\n## TEST-008 coverage thresholds and flaky-test policy — 2026-08-10\n)',
        section.rstrip(),
        'AST-004 STATUS section',
        re.DOTALL,
    )
    STATUS.write_text(text, encoding='utf-8')


def reconcile_work() -> None:
    text = WORK.read_text(encoding='utf-8')
    text = replace_regex(text, r'^- State: .*$', '- State: VERIFIED', 'AST work state', re.MULTILINE)
    for number in range(97, 101):
        text = replace_regex(
            text,
            rf'^- \[[ x]\] T{number:03d} ',
            f'- [x] T{number:03d} ',
            f'T{number:03d}',
            re.MULTILINE,
        )
    final = '''
## Final verification and merge evidence

- Final PR head `61c5741ba8340e0baafb2d2cea9989137b25a279` passed Flutter CI #839 / run `31408977215`: AST-004 widget suite 14/14, machine validator regressions 6/6, full Flutter suite 320/320, authored-source coverage 5,650 / 6,396 = 88.34%, Debug APK build, artifact security and upload. Artifact #9071093253 is 80,633,602 bytes with SHA-256 `0e6da3e6d75212817f22c91592009e97532d838f4f395a4f4f1c9f488a59f5bb`.
- PR #193 squash-merged to `main` as `22239a6cdd7af3770a03a4b9a86e8d32d078a01b`; issue #192 closed completed.
- Exact-main Flutter CI #840 / run `31409971405` passed every gate on the merge SHA, including AST-004 policy/tests, TEST-007/008/010, privacy/security/dependency contracts, Analyze, 320 Flutter tests, 88.34% coverage, Debug APK, artifact security and upload.
- Exact-main artifact #9071436511 is 80,633,603 bytes with SHA-256 `b7150ca0969b0f32e3741ca4a47e9c51e7c8d6ce02880af9d47b5f1cfbfec562`.
- AST-004 is VERIFIED at 100/100 checkpoints. Fresh dependency scan selects P0 `PERF-001` Frame performance budget as the next primary workstream; it is selected but not yet started.
'''
    if '## Final verification and merge evidence' not in text:
        text = text.rstrip() + '\n' + final
    WORK.write_text(text, encoding='utf-8')


if __name__ == '__main__':
    reconcile_catalog()
    reconcile_status()
    reconcile_work()
    print('AST-004 post-merge reconciliation applied')
