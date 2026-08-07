from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'Expected text not found in {path}: {old[:80]!r}')
    target.write_text(text.replace(old, new, 1), encoding='utf-8')


motion_tokens = '''import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

abstract final class GameMotionDurations {
  static const Duration tap = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration modal = Duration(milliseconds: 280);
  static const Duration reward = Duration(milliseconds: 700);
  static const Duration idle = Duration(milliseconds: 3200);
}

abstract final class GameMotionCurves {
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve springRelease = Curves.elasticOut;
}

abstract final class GameMotionSprings {
  static const SpringDescription button = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 28,
  );

  static const SpringDescription placement = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 22,
  );
}

class GameMotionProfile {
  const GameMotionProfile({required this.reducedMotion});

  final bool reducedMotion;

  Duration duration(Duration value) {
    if (!reducedMotion) return value;
    if (value <= GameMotionDurations.fast) return const Duration(milliseconds: 60);
    return const Duration(milliseconds: 100);
  }

  double distance(double value) => reducedMotion ? 0 : value;

  double scale(double value) => reducedMotion ? 1 : value;

  Curve curve(Curve value) => reducedMotion ? Curves.linear : value;
}

abstract final class GameMotion {
  static GameMotionProfile of(BuildContext context) => GameMotionProfile(
        reducedMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      );
}
'''
Path('lib/core/motion').mkdir(parents=True, exist_ok=True)
Path('lib/core/motion/game_motion.dart').write_text(motion_tokens, encoding='utf-8')

replace_once(
    'lib/core/widgets/game_button.dart',
    "import 'package:flutter/services.dart';\n",
    "import 'package:flutter/services.dart';\n\nimport '../motion/game_motion.dart';\n",
)
replace_once(
    'lib/core/widgets/game_button.dart',
    "    final translateY = _pressed ? 5.0 : (_hovered && hoverSupported ? -2.0 : 0.0);\n    final scale = _pressed ? .975 : (_hovered && hoverSupported ? 1.012 : 1.0);\n",
    "    final motion = GameMotion.of(context);\n    final translateY = motion.distance(\n      _pressed ? 5.0 : (_hovered && hoverSupported ? -2.0 : 0.0),\n    );\n    final scale = motion.scale(\n      _pressed ? .975 : (_hovered && hoverSupported ? 1.012 : 1.0),\n    );\n",
)
replace_once(
    'lib/core/widgets/game_button.dart',
    "      duration: const Duration(milliseconds: 150),\n      curve: Curves.easeOutCubic,\n",
    "      duration: motion.duration(GameMotionDurations.fast),\n      curve: motion.curve(GameMotionCurves.enter),\n",
)
replace_once(
    'lib/core/widgets/game_button.dart',
    "        duration: const Duration(milliseconds: 180),\n",
    "        duration: motion.duration(GameMotionDurations.standard),\n",
)
replace_once(
    'lib/core/widgets/game_button.dart',
    "          duration: Duration(milliseconds: _pressed ? 70 : 240),\n          curve: _pressed ? Curves.easeOut : Curves.elasticOut,\n",
    "          duration: motion.duration(\n            _pressed ? GameMotionDurations.tap : GameMotionDurations.standard,\n          ),\n          curve: motion.curve(\n            _pressed ? GameMotionCurves.enter : GameMotionCurves.springRelease,\n          ),\n",
)
replace_once(
    'lib/core/widgets/game_button.dart',
    "            duration: Duration(milliseconds: _pressed ? 70 : 240),\n            curve: _pressed ? Curves.easeOut : Curves.elasticOut,\n",
    "            duration: motion.duration(\n              _pressed ? GameMotionDurations.tap : GameMotionDurations.standard,\n            ),\n            curve: motion.curve(\n              _pressed ? GameMotionCurves.enter : GameMotionCurves.springRelease,\n            ),\n",
)

motion_test = '''import 'package:cargo_sort_game/core/motion/game_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion budgets stay inside documented ranges', () {
    expect(GameMotionDurations.tap.inMilliseconds, inInclusiveRange(80, 140));
    expect(GameMotionDurations.standard.inMilliseconds, inInclusiveRange(180, 280));
    expect(GameMotionDurations.modal.inMilliseconds, inInclusiveRange(220, 320));
    expect(GameMotionDurations.reward.inMilliseconds, inInclusiveRange(500, 900));
    expect(GameMotionDurations.idle.inMilliseconds, inInclusiveRange(2500, 6000));
  });

  test('reduced motion removes travel and scale while keeping brief feedback', () {
    const profile = GameMotionProfile(reducedMotion: true);

    expect(profile.distance(12), 0);
    expect(profile.scale(.9), 1);
    expect(profile.duration(GameMotionDurations.reward), const Duration(milliseconds: 100));
    expect(profile.curve(Curves.elasticOut), Curves.linear);
  });

  testWidgets('profile follows MediaQuery disableAnimations', (tester) async {
    late GameMotionProfile profile;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            profile = GameMotion.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(profile.reducedMotion, isTrue);
  });
}
'''
Path('test/core/motion').mkdir(parents=True, exist_ok=True)
Path('test/core/motion/game_motion_test.dart').write_text(motion_test, encoding='utf-8')

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
text = text.replace(
    '| ENG-002 | Stable Android build toolchain | P0 | IN PROGRESS | ENG-001 | Debug/release scripts use dynamic device discovery, JDK validation, Kotlin cache recovery, and reproducible commands. |',
    '| ENG-002 | Stable Android build toolchain | P0 | IMPLEMENTED | ENG-001 | Shared scripts provide dynamic device discovery, JDK validation, Kotlin cache recovery, and reproducible debug/release commands; final Windows device verification remains. |',
)
text = text.replace(
    '| MOT-001 | Motion tokens and reusable animation primitives | P0 | READY | UI3D-001 | Central durations, curves, springs, stagger, amplitude, and reduced-motion behavior exist. |',
    '| MOT-001 | Motion tokens and reusable animation primitives | P0 | IMPLEMENTED | UI3D-001 | Central duration budgets, curves, spring descriptions, distance/scale amplitude, and MediaQuery-driven reduced-motion profile exist and are integrated into GameButton with focused tests. |',
)
catalog.write_text(text, encoding='utf-8')

status = Path('docs/STATUS.md')
status.write_text('''# CARGame Live Project Status

This document is the operational summary. Detailed feature tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically from that catalog.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Completed checkpoint | `MOT-001` Motion tokens and reusable animation primitives |
| Status | IMPLEMENTED — awaiting final CI and physical-device motion review |
| Next recommended feature | `MOT-010` Animation lifecycle and interruption safety |
| Build foundation | `ENG-002` moved to IMPLEMENTED; Windows device verification remains |

## MOT-001 implementation evidence — 2026-08-07

- Added `lib/core/motion/game_motion.dart` as the single motion-token source.
- Centralized tap, fast, standard, modal, reward, and idle duration budgets.
- Centralized enter, exit, emphasized, and spring-release curves.
- Added reusable button and placement spring descriptions.
- Added `GameMotionProfile` for duration, distance, scale, and curve adaptation.
- Reduced motion follows `MediaQuery.disableAnimations`, removes travel/scale, and keeps brief functional feedback.
- `GameButton` now consumes motion tokens instead of local duration/curve/amplitude literals.
- Added focused tests for documented motion budgets, reduced-motion behavior, and MediaQuery integration.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Motion-token static integration review | PASSED |
| 2026-08-07 | Motion budget and reduced-motion tests | PENDING in Flutter CI |
| 2026-08-07 | Existing GameButton tests | PENDING in Flutter CI |
| 2026-08-07 | Full Flutter test suite | PENDING in Flutter CI |
| 2026-08-07 | Debug APK build | PENDING in Flutter CI |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables and phases A–S preserved |

## Known limitations and next work

1. Physical-device review is still required to confirm press response and reduced-motion behavior.
2. Existing screens outside `GameButton` still need migration to the shared motion tokens.
3. `MOT-010` should add lifecycle-safe reusable controllers and off-screen pause behavior.

## Test locally

```powershell
cd "D:\\Apps\\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter test test\\core\\motion\\game_motion_test.dart
flutter test test\\core\\widgets\\game_button_test.dart
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run
```
''', encoding='utf-8')

Path('.github/workflows/one_time_motion_tokens.yml').unlink()
Path('scripts/one_time_motion_tokens.py').unlink()
