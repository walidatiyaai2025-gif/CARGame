#!/usr/bin/env python3
from pathlib import Path
import re

CATALOG = Path('docs/FEATURE_CATALOG.md')
STATUS = Path('docs/STATUS.md')
WORK = Path('docs/work/A11Y-003.md')

catalog = CATALOG.read_text(encoding='utf-8')
pattern = re.compile(
    r'^\| A11Y-003 \| Reduced motion \| P1 \| IN PROGRESS \| UI3D-007 \| .*? \|$',
    re.MULTILINE,
)
replacement = (
    '| A11Y-003 | Reduced motion | P1 | IMPLEMENTED | UI3D-007 | '
    'Issue #208 / PR #209 implement typed essential/nonessential/cinematic motion intent, '
    'no-ticker reduced paths for ambient/travel/action feedback, deterministic cinematic skipping, '
    'shared route/button enforcement, EN/AR Settings explanation, a checked-in 43-record direct-motion audit, '
    '16/16 validator ownership regressions, and permanent normal-CI gates. Final PR head '
    '`04abd449451e0fb44f5a95eca6f74af263a35665` passed Flutter CI #872 / run `31472254901` '
    'all 66 gates and artifact #9094044902 (80,659,591 bytes; SHA-256 '
    '`bfa4d84edc21eaf6efdd376dcdc04b0101a5e21efc7de555dda18fae09709d3c`). '
    'PR #209 merged as `996bebf50e9f5b150e10a9f6455a27015a67355f`; exact-main Flutter CI #873 / '
    'run `31473003490` passed all 66 gates and artifact #9094321792 (80,659,593 bytes; SHA-256 '
    '`ee95a99a8460d1824a28fb9512d12454d3e9f69648a9e0bd5506e34ccf2be98d`). '
    'Source-controlled acceptance is IMPLEMENTED; physical screen-reader/device observation is separate evidence. |'
)
catalog, count = pattern.subn(replacement, catalog, count=1)
if count != 1:
    raise SystemExit(f'A11Y-003 catalog reconciliation count={count}')
CATALOG.write_text(catalog, encoding='utf-8')

status = STATUS.read_text(encoding='utf-8')
fields = {
    'Primary feature': 'None — `A11Y-003` completed 100/100 source-controlled checkpoints as IMPLEMENTED; `A11Y-002` is selected next but not started.',
    'Completed checkpoint': '`A11Y-003` Reduced motion — IMPLEMENTED; issue #208 / PR #209 completed 100/100 source-controlled checkpoints, PR #209 merged as `996bebf50e9f5b150e10a9f6455a27015a67355f`, and exact-main Flutter CI #873 / run `31473003490` passed all 66 gates.',
    'Status': 'A11Y-003 source-controlled acceptance is IMPLEMENTED: typed motion intent, deterministic cinematic skip, no-ticker reduced paths, 43-record direct-motion audit, 16/16 validator regressions, focused motion/ambient regression coverage, full suite/coverage, Debug APK security/upload and exact-main verification are green. Physical screen-reader/device observation remains separate and is not claimed.',
    'Previous checkpoint': '`UI3D-007` reduced motion and adaptive visual effects — IMPLEMENTED with 100/100 source-controlled checkpoints and exact-main CI.',
    'Next recommended feature': '`A11Y-002` Large text and screen-reader validation — P1, dependency-ready through VERIFIED UI3D-006; selected next but not started.',
}
for field, value in fields.items():
    pattern = re.compile(rf'^\| {re.escape(field)} \| .* \|$', re.MULTILINE)
    status, count = pattern.subn(f'| {field} | {value} |', status, count=1)
    if count != 1:
        raise SystemExit(f'STATUS field reconciliation failed: {field} count={count}')

section = '''## A11Y-003 reduced motion accessibility enforcement — 2026-08-11

- Issue #208 / PR #209 complete the 100-checkpoint source-controlled sprint. Repository status is IMPLEMENTED.
- `GameMotionIntent` classifies essential, nonessential and cinematic motion while keeping PERF-001 performance pressure separate from accessibility intent.
- `GameCinematicGate` skips nonessential cinematic motion under effective reduced motion without allocating a ticker and reports an explicit exact-once completion reason.
- Shared ambient, cargo-travel and action-feedback reduced paths no longer allocate AnimationControllers; GameButton and route motion consume intent-aware shared policy while preserving semantics, taps, navigation completion and the established reduced route timing contract.
- The checked-in direct-motion audit owns 43 current `lib/` primitive records and normal CI rejects unreviewed AnimationController/Animated*/Hero/PageRouteBuilder/transition/timer/delay drift.
- A11Y-003 machine validation passes with 16/16 validator ownership regressions. The focused matrix includes the ambient no-ticker regression that was promoted after the first full-suite discovery.
- Final PR head `04abd449451e0fb44f5a95eca6f74af263a35665` passed Flutter CI #872 / run `31472254901` all 66 gates. Debug artifact #9094044902 is 80,659,591 bytes with SHA-256 `bfa4d84edc21eaf6efdd376dcdc04b0101a5e21efc7de555dda18fae09709d3c`.
- PR #209 merged as `996bebf50e9f5b150e10a9f6455a27015a67355f`. Exact-main Flutter CI #873 / run `31473003490` passed all 66 gates. Main debug artifact #9094321792 is 80,659,593 bytes with SHA-256 `ee95a99a8460d1824a28fb9512d12454d3e9f69648a9e0bd5506e34ccf2be98d`.
- No physical screen-reader, assistive-technology or device observation is invented. Those remain separate verification evidence.
- Fresh dependency-ready scan selects exactly one next source-controlled workstream: `A11Y-002` Large text and screen-reader validation (P1), now dependency-ready through VERIFIED UI3D-006. It is selected but not started.

'''
anchor = '## UI3D-007 reduced motion and adaptive visual effects — 2026-08-11\n'
if '## A11Y-003 reduced motion accessibility enforcement — 2026-08-11' not in status:
    if anchor not in status:
        raise SystemExit('STATUS section insertion anchor missing')
    status = status.replace(anchor, section + anchor, 1)
STATUS.write_text(status, encoding='utf-8')

WORK.write_text('''# A11Y-003 Reduced Motion Accessibility Enforcement

Issue: #208
Implementation PR: #209
Implementation merge: `996bebf50e9f5b150e10a9f6455a27015a67355f`

## State

IMPLEMENTED — T001-T100 source-controlled checkpoints complete.

## Runtime contract

- System Reduce Motion and the persistent user Reduced effects choice both feed `GameMotion.of(context)`.
- Performance quality remains a separate graceful-degradation signal and never impersonates an accessibility preference.
- Shared motion is classified as essential, nonessential or cinematic so reduced behavior is explicit.
- Spatial/decorative/cinematic animation is removed under effective reduced motion while state, semantics, navigation and rewards remain deterministic.
- Ambient, cargo-travel and action-feedback reduced paths do not allocate AnimationControllers/tickers.
- `GameCinematicGate` completes skipped nonessential cinematics exactly once with `skippedReducedMotion`.
- Existing sound/haptic settings, gameplay, economy, navigation identity, privacy, ads and persistence ownership remain unchanged.

## Machine ownership

- Direct-motion audit: 43 current primitive records across `lib/`, excluding generated localization.
- A11Y-003 validator ownership regressions: 16/16.
- Permanent normal CI gates: validator, mutation regressions, focused runtime/ambient matrix.
- Ambient reduced-mode regression explicitly proves no AnimationController is allocated.

## 100-checkpoint completion evidence

- T001-T097: implementation, audit, focused tests, machine ownership and normal-CI integration complete.
- T098: Flutter CI #872 / run `31472254901` passed all 66 gates on final PR head `04abd449451e0fb44f5a95eca6f74af263a35665`; artifact #9094044902 is 80,659,591 bytes with SHA-256 `bfa4d84edc21eaf6efdd376dcdc04b0101a5e21efc7de555dda18fae09709d3c`.
- T099: PR #209 merged as `996bebf50e9f5b150e10a9f6455a27015a67355f`; exact-main Flutter CI #873 / run `31473003490` passed all 66 gates; artifact #9094321792 is 80,659,593 bytes with SHA-256 `ee95a99a8460d1824a28fb9512d12454d3e9f69648a9e0bd5506e34ccf2be98d`.
- T100: catalog/status/work reconciliation records IMPLEMENTED 100/100 and selects `A11Y-002` next without starting it.

## Verification boundary

Repository evidence proves source-controlled accessibility behavior and build safety. No physical screen-reader, assistive-technology or device observation is claimed by this sprint.
''', encoding='utf-8')

print('A11Y-003 reconciliation applied: IMPLEMENTED 100/100; A11Y-002 selected next')
