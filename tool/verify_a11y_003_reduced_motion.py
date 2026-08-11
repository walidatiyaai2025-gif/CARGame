#!/usr/bin/env python3
from pathlib import Path
import json

PRIMITIVES = [
    'AnimationController(',
    'AnimatedBuilder(',
    'TweenAnimationBuilder',
    'AnimatedContainer(',
    'AnimatedOpacity(',
    'AnimatedScale(',
    'AnimatedSlide(',
    'AnimatedSwitcher(',
    'Hero(',
    'PageRouteBuilder',
    'FadeTransition(',
    'SlideTransition(',
    'ScaleTransition(',
    'RotationTransition(',
    'Timer(',
    'Future.delayed(',
]


def require(path: str, *needles: str) -> None:
    text = Path(path).read_text(encoding='utf-8')
    missing = [needle for needle in needles if needle not in text]
    if missing:
        raise SystemExit(f'{path}: missing required A11Y-003 contract: {missing}')


def classification(path: str, primitive: str) -> str:
    if path.startswith('lib/core/motion/') or path == 'lib/core/widgets/game_button.dart':
        return 'shared-policy-consumer'
    if primitive == 'AnimatedBuilder(' and path == 'lib/features/settings/settings_screen.dart':
        return 'state-listener-not-motion'
    return 'audited-local-motion'


def scan_motion() -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    for path in sorted(Path('lib').rglob('*.dart')):
        path_text = path.as_posix()
        if path_text.startswith('lib/l10n/'):
            continue
        text = path.read_text(encoding='utf-8')
        for primitive in PRIMITIVES:
            count = text.count(primitive)
            if count:
                entries.append({
                    'path': path_text,
                    'primitive': primitive,
                    'count': count,
                    'classification': classification(path_text, primitive),
                })
    return entries


require(
    'lib/core/motion/game_motion.dart',
    'enum GameMotionIntent',
    'enum GameMotionIntent { essential, nonessential, cinematic }',
    'shouldAnimate',
    'shouldUseTicker',
    'shouldUseSpatialMotion',
    'shouldSkipCinematic',
    'durationFor',
)
require(
    'lib/core/motion/game_cinematic_gate.dart',
    'GameCinematicCompletionReason',
    'skippedReducedMotion',
    'AnimationController?',
    'shouldUseTicker',
    'addPostFrameCallback',
    '_finishOnce',
)
require(
    'lib/core/motion/game_travel_motion.dart',
    'AnimationController?',
    'shouldUseSpatialMotion',
    '_scheduleCompletion',
)
require(
    'lib/core/motion/ambient_motion_background.dart',
    'AnimationController?',
    'GameMotionIntent.nonessential',
    'profile.shouldUseTicker(intent)',
)
require(
    'lib/core/motion/game_action_feedback.dart',
    'AnimationController?',
    'GameMotionIntent.nonessential',
    'profile.shouldUseTicker(intent)',
)
require(
    'lib/core/motion/game_route.dart',
    'GameMotionIntent.essential',
    'profile.durationFor',
    'profile.shouldUseSpatialMotion(intent)',
)
require(
    'lib/core/widgets/game_button.dart',
    'GameMotionIntent.essential',
    'motion.shouldUseSpatialMotion(motionIntent)',
    'motion.durationFor',
)
require(
    'lib/features/settings/settings_screen.dart',
    'skips decorative cinematic effects',
    'وتخطي المؤثرات السينمائية الزخرفية',
)
require(
    'test/features/home/home_ambient_background_test.dart',
    'reduced motion uses a static animation without a ticker',
    'isNot(isA<AnimationController>())',
)

baseline_path = Path('docs/accessibility/a11y_003_motion_audit.json')
if not baseline_path.is_file():
    raise SystemExit('missing A11Y-003 direct-motion audit baseline')
baseline = json.loads(baseline_path.read_text(encoding='utf-8'))
if baseline.get('schema') != 1:
    raise SystemExit('unsupported A11Y-003 audit schema')
expected = baseline.get('entries')
actual = scan_motion()
if actual != expected:
    raise SystemExit(
        'direct motion primitive inventory changed; update A11Y-003 audit intentionally\n'
        f'expected={expected}\nactual={actual}'
    )

for path in [
    'test/core/motion/a11y_003_motion_policy_test.dart',
    'test/core/motion/game_cinematic_gate_test.dart',
    'test/features/home/home_ambient_background_test.dart',
    'docs/A11Y_REDUCED_MOTION_AUDIT.md',
]:
    if not Path(path).is_file():
        raise SystemExit(f'missing A11Y-003 evidence: {path}')

ci = Path('.github/workflows/flutter_ci.yml').read_text(encoding='utf-8')
for token in [
    'Verify A11Y-003 reduced motion',
    'Test A11Y-003 reduced-motion validator',
    'Test A11Y-003 reduced motion matrix',
    'test/features/home/home_ambient_background_test.dart',
]:
    if token not in ci:
        raise SystemExit(f'normal Flutter CI is missing A11Y-003 gate: {token}')

catalog = Path('docs/FEATURE_CATALOG.md').read_text(encoding='utf-8')
if '| A11Y-003 | Reduced motion | P1 | IN PROGRESS |' not in catalog and '| A11Y-003 | Reduced motion | P1 | IMPLEMENTED |' not in catalog:
    raise SystemExit('A11Y-003 catalog status is not owned by the current sprint')

print(f'A11Y-003 REDUCED MOTION CONTRACT PASSED ({len(actual)} audited primitive records)')
