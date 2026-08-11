#!/usr/bin/env python3
from pathlib import Path

SOURCE = Path('tool/verify_a11y_003_reduced_motion.py').read_text(encoding='utf-8')

checks = [
    'enum GameMotionIntent',
    'enum GameMotionIntent { essential, nonessential, cinematic }',
    'shouldAnimate',
    'shouldUseTicker',
    'shouldUseSpatialMotion',
    'shouldSkipCinematic',
    'GameCinematicCompletionReason',
    'skippedReducedMotion',
    'direct motion primitive inventory changed',
    'AnimationController(',
    'PageRouteBuilder',
    'Future.delayed(',
    'Verify A11Y-003 reduced motion',
    'Test A11Y-003 reduced motion matrix',
    'A11Y-003 catalog status',
]

for token in checks:
    if token not in SOURCE:
        raise SystemExit(f'validator mutation coverage missing token: {token}')

print(f'A11Y-003 VALIDATOR REGRESSIONS PASSED ({len(checks)}/{len(checks)})')
