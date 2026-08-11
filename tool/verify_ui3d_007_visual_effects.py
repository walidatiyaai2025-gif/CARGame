#!/usr/bin/env python3
from pathlib import Path
import sys


def require(path: str, *needles: str) -> None:
    text = Path(path).read_text(encoding='utf-8')
    missing = [needle for needle in needles if needle not in text]
    if missing:
        raise SystemExit(f'{path}: missing required UI3D-007 contract: {missing}')


require(
    'lib/core/settings/game_visual_effects_preference.dart',
    "automatic('automatic')",
    "reduced('reduced')",
    'static GameVisualEffectsPreference parse',
)
require(
    'lib/core/settings/app_settings_store.dart',
    "settings_visual_effects",
    'visualEffectsPreference',
    'setReducedVisualEffects',
)
require(
    'lib/core/settings/visual_effects_preference_scope.dart',
    'InheritedNotifier<AppSettingsStore>',
    'userReducedEffectsOf',
)
require(
    'lib/bootstrap/cargo_sort_app.dart',
    'VisualEffectsPreferenceScope(',
    'settings: _activeSettings',
)
require(
    'lib/core/motion/game_motion.dart',
    'systemReduced || userReduced',
    'particleCount',
    'simultaneousEffectsLimit',
    'allowExpensiveEffects',
)
require(
    'lib/core/motion/motion_lifecycle_scope.dart',
    'GameMotion.of(context).reducedMotion',
)
require(
    'lib/core/motion/game_route.dart',
    'final profile = GameMotion.of(context);',
    'profile.effectsScale',
)
require(
    'lib/core/motion/ambient_motion_background.dart',
    'effectsScale: profile.effectsScale',
    'decorativeCount: profile.particleCount(4)',
)
require(
    'lib/core/motion/game_action_feedback.dart',
    'profile.particleCount(8)',
    'profile.shadow(28)',
    'profile.distance(16)',
)
require(
    'lib/features/settings/settings_screen.dart',
    "ValueKey('visual-effects-switch')",
    'Visual effects: Automatic',
    'Visual effects: Reduced',
    'المؤثرات المرئية: تلقائية',
    'المؤثرات المرئية: مخفضة',
)
for path in [
    'test/core/settings/game_visual_effects_preference_test.dart',
    'test/core/settings/visual_effects_preference_scope_test.dart',
    'test/core/motion/ui3d_007_visual_effects_test.dart',
    'test/features/settings/visual_effects_settings_test.dart',
]:
    if not Path(path).is_file():
        raise SystemExit(f'missing focused UI3D-007 test: {path}')

catalog = Path('docs/FEATURE_CATALOG.md').read_text(encoding='utf-8')
if '| UI3D-007 | Reduced motion and low-performance visual mode | P1 | IN PROGRESS |' not in catalog and '| UI3D-007 | Reduced motion and low-performance visual mode | P1 | IMPLEMENTED |' not in catalog:
    raise SystemExit('UI3D-007 catalog status is not owned by the current sprint')

print('UI3D-007 VISUAL EFFECTS CONTRACT PASSED')
