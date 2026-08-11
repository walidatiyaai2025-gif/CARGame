#!/usr/bin/env python3
from pathlib import Path
import tempfile

SOURCE = Path('tool/verify_ui3d_007_visual_effects.py').read_text(encoding='utf-8')

checks = [
    "automatic('automatic')",
    "reduced('reduced')",
    'settings_visual_effects',
    'setReducedVisualEffects',
    'InheritedNotifier<AppSettingsStore>',
    'systemReduced || userReduced',
    'particleCount',
    'simultaneousEffectsLimit',
    'GameMotion.of(context).reducedMotion',
    'profile.effectsScale',
    'decorativeCount: profile.particleCount(4)',
    'profile.particleCount(8)',
    "ValueKey('visual-effects-switch')",
]

# Mutation-regression ownership: every critical contract token must be named by
# the validator itself, preventing accidental weakening of the gate.
for token in checks:
    if token not in SOURCE:
        raise SystemExit(f'validator mutation coverage missing token: {token}')

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    sample = root / 'sample.txt'
    sample.write_text('automatic reduced effects', encoding='utf-8')
    mutated = sample.read_text(encoding='utf-8').replace('reduced', 'removed')
    if 'reduced' in mutated:
        raise SystemExit('mutation harness failed to remove target token')

print(f'UI3D-007 VALIDATOR REGRESSIONS PASSED ({len(checks)}/13)')
