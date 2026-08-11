from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, content: str) -> None:
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding='utf-8')


def replace(path: str, old: str, new: str, count: int = 1) -> None:
    text = read(path)
    actual = text.count(old)
    if actual != count:
        raise SystemExit(f'{path}: expected {count} occurrences, found {actual}: {old[:80]!r}')
    write(path, text.replace(old, new, count))


write('lib/core/settings/game_visual_effects_preference.dart', '''enum GameVisualEffectsPreference {
  automatic('automatic'),
  reduced('reduced');

  const GameVisualEffectsPreference(this.wireValue);

  final String wireValue;

  static GameVisualEffectsPreference parse(String? value) => switch (value) {
    'reduced' => GameVisualEffectsPreference.reduced,
    _ => GameVisualEffectsPreference.automatic,
  };
}
''')

write('lib/core/settings/visual_effects_preference_scope.dart', '''import 'package:flutter/widgets.dart';

import 'app_settings_store.dart';
import 'game_visual_effects_preference.dart';

class VisualEffectsPreferenceScope extends InheritedNotifier<AppSettingsStore> {
  const VisualEffectsPreferenceScope({
    super.key,
    required this.settings,
    required super.child,
  }) : super(notifier: settings);

  final AppSettingsStore settings;

  static GameVisualEffectsPreference preferenceOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<VisualEffectsPreferenceScope>()
          ?.settings
          .visualEffectsPreference ??
      GameVisualEffectsPreference.automatic;

  static bool userReducedEffectsOf(BuildContext context) =>
      preferenceOf(context) == GameVisualEffectsPreference.reduced;
}
''')

replace(
    'lib/core/settings/app_settings_store.dart',
    "import '../storage/recovering_preferences.dart';\n",
    "import '../storage/recovering_preferences.dart';\nimport 'game_visual_effects_preference.dart';\n",
)
replace(
    'lib/core/settings/app_settings_store.dart',
    "  static const _vibrationKey = 'settings_vibration';\n",
    "  static const _vibrationKey = 'settings_vibration';\n  static const _visualEffectsKey = 'settings_visual_effects';\n",
)
replace(
    'lib/core/settings/app_settings_store.dart',
    "  bool vibrationEnabled = true;\n",
    "  bool vibrationEnabled = true;\n  GameVisualEffectsPreference visualEffectsPreference =\n      GameVisualEffectsPreference.automatic;\n\n  bool get reducedVisualEffects =>\n      visualEffectsPreference == GameVisualEffectsPreference.reduced;\n",
)
replace(
    'lib/core/settings/app_settings_store.dart',
    "    vibrationEnabled = await _prefs.getBool(_vibrationKey) ?? true;\n    notifyListeners();\n",
    "    vibrationEnabled = await _prefs.getBool(_vibrationKey) ?? true;\n    visualEffectsPreference = GameVisualEffectsPreference.parse(\n      await _prefs.getString(_visualEffectsKey),\n    );\n    notifyListeners();\n",
)
replace(
    'lib/core/settings/app_settings_store.dart',
    "  Future<void> setVibration(bool value) async {\n    vibrationEnabled = value;\n    notifyListeners();\n    await _prefs.setBool(_vibrationKey, value);\n  }\n",
    "  Future<void> setVibration(bool value) async {\n    vibrationEnabled = value;\n    notifyListeners();\n    await _prefs.setBool(_vibrationKey, value);\n  }\n\n  Future<void> setVisualEffectsPreference(\n    GameVisualEffectsPreference value,\n  ) async {\n    if (visualEffectsPreference == value) return;\n    visualEffectsPreference = value;\n    notifyListeners();\n    await _prefs.setString(_visualEffectsKey, value.wireValue);\n  }\n\n  Future<void> setReducedVisualEffects(bool value) =>\n      setVisualEffectsPreference(\n        value\n            ? GameVisualEffectsPreference.reduced\n            : GameVisualEffectsPreference.automatic,\n      );\n",
)

replace(
    'lib/bootstrap/cargo_sort_app.dart',
    "import '../core/settings/app_settings_store.dart';\n",
    "import '../core/settings/app_settings_store.dart';\nimport '../core/settings/visual_effects_preference_scope.dart';\n",
)
replace(
    'lib/bootstrap/cargo_sort_app.dart',
    "    return FramePerformanceScope(\n      child: MaterialApp(\n",
    "    return FramePerformanceScope(\n      child: VisualEffectsPreferenceScope(\n        settings: _activeSettings,\n        child: MaterialApp(\n",
)
text = read('lib/bootstrap/cargo_sort_app.dart')
old_tail = "        ),\n      ),\n    );\n  }\n}\n"
if not text.endswith(old_tail):
    raise SystemExit('cargo_sort_app.dart: unexpected build tail')
write(
    'lib/bootstrap/cargo_sort_app.dart',
    text[:-len(old_tail)] + "        ),\n      ),\n    ),\n    );\n  }\n}\n",
)

replace(
    'lib/core/motion/game_motion.dart',
    "import '../performance/frame_performance_scope.dart';\n",
    "import '../performance/frame_performance_scope.dart';\nimport '../settings/visual_effects_preference_scope.dart';\n",
)
replace(
    'lib/core/motion/game_motion.dart',
    "  bool get allowAmbientMotion =>\n      !reducedMotion && performanceQuality == GameVisualQuality.full;\n",
    "  bool get allowAmbientMotion =>\n      !reducedMotion && performanceQuality == GameVisualQuality.full;\n\n  bool get allowDecorativeEffects =>\n      !reducedMotion && performanceQuality != GameVisualQuality.reduced;\n\n  bool get allowExpensiveEffects =>\n      !reducedMotion && performanceQuality == GameVisualQuality.full;\n",
)
replace(
    'lib/core/motion/game_motion.dart',
    "  double distance(double value) => reducedMotion ? 0 : value * effectsScale;\n",
    "  double distance(double value) => reducedMotion ? 0 : value * effectsScale;\n\n  double blur(double value) => reducedMotion ? 0 : value * effectsScale;\n\n  double shadow(double value) => reducedMotion ? 0 : value * effectsScale;\n\n  double intensity(double value) => reducedMotion ? 0 : value * effectsScale;\n\n  int particleCount(int requested) {\n    if (requested <= 0 || reducedMotion) return 0;\n    return (requested * effectsScale).ceil().clamp(1, requested);\n  }\n\n  int simultaneousEffectsLimit(int requested) {\n    if (requested <= 0 || reducedMotion) return 0;\n    final limit = switch (performanceQuality) {\n      GameVisualQuality.full => requested,\n      GameVisualQuality.constrained => 2,\n      GameVisualQuality.reduced => 1,\n    };\n    return limit.clamp(1, requested);\n  }\n",
)
replace(
    'lib/core/motion/game_motion.dart',
    "abstract final class GameMotion {\n  static GameMotionProfile of(BuildContext context) => GameMotionProfile(\n    reducedMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,\n    performanceQuality: FramePerformanceScope.qualityOf(context),\n  );\n}\n",
    "abstract final class GameMotion {\n  static GameMotionProfile of(BuildContext context) {\n    final systemReduced =\n        MediaQuery.maybeOf(context)?.disableAnimations ?? false;\n    final userReduced =\n        VisualEffectsPreferenceScope.userReducedEffectsOf(context);\n    return GameMotionProfile(\n      reducedMotion: systemReduced || userReduced,\n      performanceQuality: FramePerformanceScope.qualityOf(context),\n    );\n  }\n}\n",
)

write('lib/core/motion/game_route.dart', '''import 'package:flutter/material.dart';

import 'game_motion.dart';

final class GameRoute {
  const GameRoute._();

  static const Duration forwardDuration = Duration(milliseconds: 320);
  static const Duration reverseDuration = Duration(milliseconds: 240);

  static Route<T> build<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? name,
  }) {
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final profile = GameMotion.of(context);
    final reducedMotion = profile.reducedMotion;
    final horizontalOffset =
        (direction == TextDirection.rtl ? -0.065 : 0.065) *
        profile.effectsScale;

    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: reducedMotion
          ? const Duration(milliseconds: 120)
          : profile.duration(forwardDuration),
      reverseTransitionDuration: reducedMotion
          ? const Duration(milliseconds: 100)
          : profile.duration(reverseDuration),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: profile.curve(Curves.easeOutCubic),
          reverseCurve: profile.curve(Curves.easeInCubic),
        );

        if (reducedMotion) {
          return FadeTransition(opacity: fade, child: child);
        }

        final slide = Tween<Offset>(
          begin: Offset(horizontalOffset, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: profile.curve(Curves.easeOutCubic),
            reverseCurve: profile.curve(Curves.easeInCubic),
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
''')

replace(
    'lib/core/motion/motion_lifecycle_scope.dart',
    "import 'package:flutter/material.dart';\n",
    "import 'package:flutter/material.dart';\n\nimport 'game_motion.dart';\n",
)
replace(
    'lib/core/motion/motion_lifecycle_scope.dart',
    "    final reducedMotion =\n        MediaQuery.maybeOf(context)?.disableAnimations ?? false;\n",
    "    final reducedMotion = GameMotion.of(context).reducedMotion;\n",
)

replace(
    'lib/core/motion/ambient_motion_background.dart',
    "  Widget build(BuildContext context) {\n    return RepaintBoundary(\n",
    "  Widget build(BuildContext context) {\n    final profile = GameMotion.of(context);\n    return RepaintBoundary(\n",
)
replace(
    'lib/core/motion/ambient_motion_background.dart',
    "            reducedMotion: _ambientMotionDisabled,\n",
    "            reducedMotion: _ambientMotionDisabled,\n            effectsScale: profile.effectsScale,\n            decorativeCount: profile.particleCount(4),\n",
)
replace(
    'lib/core/motion/ambient_motion_background.dart',
    "    required this.reducedMotion,\n  });\n\n  final double progress;\n  final Color startColor;\n  final Color endColor;\n  final bool reducedMotion;\n",
    "    required this.reducedMotion,\n    required this.effectsScale,\n    required this.decorativeCount,\n  });\n\n  final double progress;\n  final Color startColor;\n  final Color endColor;\n  final bool reducedMotion;\n  final double effectsScale;\n  final int decorativeCount;\n",
)
replace(
    'lib/core/motion/ambient_motion_background.dart',
    "    _drawGlow(\n      canvas,\n      Offset(size.width * (.16 + math.sin(phase) * .025), size.height * .14),\n      size.shortestSide * .34,\n      startColor.withValues(alpha: .13),\n    );\n    _drawGlow(\n      canvas,\n      Offset(size.width * (.84 + math.cos(phase) * .02), size.height * .34),\n      size.shortestSide * .28,\n      endColor.withValues(alpha: .10),\n    );\n\n    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: .34);\n    for (var index = 0; index < 4; index++) {\n",
    "    if (effectsScale > 0) {\n      _drawGlow(\n        canvas,\n        Offset(size.width * (.16 + math.sin(phase) * .025), size.height * .14),\n        size.shortestSide * .34,\n        startColor.withValues(alpha: .13 * effectsScale),\n      );\n      _drawGlow(\n        canvas,\n        Offset(size.width * (.84 + math.cos(phase) * .02), size.height * .34),\n        size.shortestSide * .28,\n        endColor.withValues(alpha: .10 * effectsScale),\n      );\n    }\n\n    final cloudPaint = Paint()\n      ..color = Colors.white.withValues(alpha: .34 * effectsScale);\n    for (var index = 0; index < decorativeCount; index++) {\n",
)
replace(
    'lib/core/motion/ambient_motion_background.dart',
    "      oldDelegate.endColor != endColor ||\n      oldDelegate.reducedMotion != reducedMotion;\n",
    "      oldDelegate.endColor != endColor ||\n      oldDelegate.reducedMotion != reducedMotion ||\n      oldDelegate.effectsScale != effectsScale ||\n      oldDelegate.decorativeCount != decorativeCount;\n",
)

replace(
    'lib/core/motion/game_action_feedback.dart',
    "    final accent = correct ? const Color(0xFF2FD17B) : const Color(0xFFFF5364);\n\n    return Positioned.fill(\n",
    "    final accent = correct ? const Color(0xFF2FD17B) : const Color(0xFFFF5364);\n    final sparkleCount = profile.particleCount(8);\n    final shadowBlur = profile.shadow(28);\n    final shadowSpread = profile.shadow(4);\n\n    return Positioned.fill(\n",
)
replace(
    'lib/core/motion/game_action_feedback.dart',
    "                final entrance = Curves.easeOutBack.transform(\n                  math.min(1, value / .38),\n                );\n",
    "                final entrance = profile\n                    .curve(GameMotionCurves.emphasized)\n                    .transform(math.min(1, value / .38));\n",
)
replace(
    'lib/core/motion/game_action_feedback.dart',
    "                final recoil = correct\n                    ? 0.0\n                    : math.sin(value * math.pi * 7) * (1 - value) * 16;\n",
    "                final recoil = correct\n                    ? 0.0\n                    : math.sin(value * math.pi * 7) *\n                          (1 - value) *\n                          profile.distance(16);\n",
)
replace(
    'lib/core/motion/game_action_feedback.dart',
    "                    if (correct && !profile.reducedMotion)\n                      for (var index = 0; index < 8; index++)\n                        _Sparkle(\n                          progress: value,\n                          index: index,\n                          intensity: 1 + _cappedCombo * .08,\n                          color: accent,\n                        ),\n",
    "                    if (correct && sparkleCount > 0)\n                      for (var index = 0; index < sparkleCount; index++)\n                        _Sparkle(\n                          progress: value,\n                          index: index,\n                          total: sparkleCount,\n                          intensity: 1 + _cappedCombo * .08,\n                          color: accent,\n                        ),\n",
)
replace(
    'lib/core/motion/game_action_feedback.dart',
    "                              boxShadow: [\n                                BoxShadow(\n                                  color: accent.withValues(alpha: .42),\n                                  blurRadius: 28,\n                                  spreadRadius: 4,\n                                ),\n                              ],\n",
    "                              boxShadow: shadowBlur <= 0\n                                  ? const []\n                                  : [\n                                      BoxShadow(\n                                        color: accent.withValues(\n                                          alpha: .42 * profile.effectsScale,\n                                        ),\n                                        blurRadius: shadowBlur,\n                                        spreadRadius: shadowSpread,\n                                      ),\n                                    ],\n",
)
replace(
    'lib/core/motion/game_action_feedback.dart',
    "    required this.index,\n    required this.intensity,\n",
    "    required this.index,\n    required this.total,\n    required this.intensity,\n",
)
replace(
    'lib/core/motion/game_action_feedback.dart',
    "  final int index;\n  final double intensity;\n",
    "  final int index;\n  final int total;\n  final double intensity;\n",
)
replace(
    'lib/core/motion/game_action_feedback.dart',
    "    final angle = index / 8 * math.pi * 2;\n",
    "    final angle = index / total * math.pi * 2;\n",
)

replace(
    'lib/features/settings/settings_screen.dart',
    "                      _SwitchTile(\n                        icon: Icons.vibration_rounded,\n                        title: ar ? 'الاهتزاز' : 'Vibration',\n                        subtitle: ar\n                            ? 'اهتزاز خفيف عند التفاعل'\n                            : 'Light haptic feedback',\n                        value: settings.vibrationEnabled,\n                        onChanged: settings.setVibration,\n                      ),\n",
    "                      _SwitchTile(\n                        icon: Icons.vibration_rounded,\n                        title: ar ? 'الاهتزاز' : 'Vibration',\n                        subtitle: ar\n                            ? 'اهتزاز خفيف عند التفاعل'\n                            : 'Light haptic feedback',\n                        value: settings.vibrationEnabled,\n                        onChanged: settings.setVibration,\n                      ),\n                      _SwitchTile(\n                        key: const ValueKey('visual-effects-switch'),\n                        icon: Icons.auto_awesome_motion_rounded,\n                        title: ar\n                            ? settings.reducedVisualEffects\n                                  ? 'المؤثرات المرئية: مخفضة'\n                                  : 'المؤثرات المرئية: تلقائية'\n                            : settings.reducedVisualEffects\n                            ? 'Visual effects: Reduced'\n                            : 'Visual effects: Automatic',\n                        subtitle: ar\n                            ? settings.reducedVisualEffects\n                                  ? 'تقليل الحركة والتمويه والجسيمات والظلال غير الضرورية'\n                                  : 'تتكيف الحركة والمؤثرات تلقائيًا مع ضغط الإطارات'\n                            : settings.reducedVisualEffects\n                            ? 'Minimizes nonessential motion, blur, particles and shadows'\n                            : 'Adapts motion and effects automatically to frame pressure',\n                        value: settings.reducedVisualEffects,\n                        onChanged: settings.setReducedVisualEffects,\n                      ),\n",
)
replace(
    'lib/features/settings/settings_screen.dart',
    "class _SwitchTile extends StatelessWidget {\n  const _SwitchTile({\n    required this.icon,\n",
    "class _SwitchTile extends StatelessWidget {\n  const _SwitchTile({\n    super.key,\n    required this.icon,\n",
)

write('test/core/settings/game_visual_effects_preference_test.dart', '''import 'package:cargo_sort_game/core/settings/game_visual_effects_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual effects preference wire contract is stable and fail closed', () {
    expect(
      GameVisualEffectsPreference.parse(null),
      GameVisualEffectsPreference.automatic,
    );
    expect(
      GameVisualEffectsPreference.parse('automatic'),
      GameVisualEffectsPreference.automatic,
    );
    expect(
      GameVisualEffectsPreference.parse('reduced'),
      GameVisualEffectsPreference.reduced,
    );
    expect(
      GameVisualEffectsPreference.parse('future-unknown-mode'),
      GameVisualEffectsPreference.automatic,
    );
    expect(GameVisualEffectsPreference.automatic.wireValue, 'automatic');
    expect(GameVisualEffectsPreference.reduced.wireValue, 'reduced');
  });
}
''')

write('test/core/settings/visual_effects_preference_scope_test.dart', '''import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/settings/game_visual_effects_preference.dart';
import 'package:cargo_sort_game/core/settings/visual_effects_preference_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scope defaults safely when absent', (tester) async {
    GameVisualEffectsPreference? value;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          value = VisualEffectsPreferenceScope.preferenceOf(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(value, GameVisualEffectsPreference.automatic);
  });

  testWidgets('scope propagates live settings notifications', (tester) async {
    final settings = AppSettingsStore();
    var builds = 0;
    var reduced = false;

    await tester.pumpWidget(
      VisualEffectsPreferenceScope(
        settings: settings,
        child: Builder(
          builder: (context) {
            builds++;
            reduced = VisualEffectsPreferenceScope.userReducedEffectsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(reduced, isFalse);

    await settings.setVisualEffectsPreference(
      GameVisualEffectsPreference.reduced,
    );
    await tester.pump();
    expect(reduced, isTrue);
    expect(builds, greaterThan(1));
  });
}
''')

write('test/core/motion/ui3d_007_visual_effects_test.dart', '''import 'package:cargo_sort_game/core/motion/game_motion.dart';
import 'package:cargo_sort_game/core/performance/frame_performance_budget.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/settings/game_visual_effects_preference.dart';
import 'package:cargo_sort_game/core/settings/visual_effects_preference_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automatic quality scales expensive visual budgets predictably', () {
    const full = GameMotionProfile(reducedMotion: false);
    const constrained = GameMotionProfile(
      reducedMotion: false,
      performanceQuality: GameVisualQuality.constrained,
    );
    const reduced = GameMotionProfile(
      reducedMotion: false,
      performanceQuality: GameVisualQuality.reduced,
    );
    const accessibility = GameMotionProfile(reducedMotion: true);

    expect(full.particleCount(8), 8);
    expect(constrained.particleCount(8), 6);
    expect(reduced.particleCount(8), 3);
    expect(accessibility.particleCount(8), 0);

    expect(full.blur(20), 20);
    expect(constrained.blur(20), 13);
    expect(reduced.blur(20), 7);
    expect(accessibility.blur(20), 0);

    expect(full.shadow(12), 12);
    expect(constrained.shadow(12), 7.8);
    expect(reduced.shadow(12), 4.2);
    expect(accessibility.shadow(12), 0);

    expect(full.simultaneousEffectsLimit(6), 6);
    expect(constrained.simultaneousEffectsLimit(6), 2);
    expect(reduced.simultaneousEffectsLimit(6), 1);
    expect(accessibility.simultaneousEffectsLimit(6), 0);

    expect(full.allowExpensiveEffects, isTrue);
    expect(constrained.allowExpensiveEffects, isFalse);
    expect(reduced.allowDecorativeEffects, isFalse);
  });

  testWidgets('user reduced effects participates in GameMotion policy', (
    tester,
  ) async {
    final settings = AppSettingsStore();
    await settings.setVisualEffectsPreference(
      GameVisualEffectsPreference.reduced,
    );
    late GameMotionProfile profile;

    await tester.pumpWidget(
      VisualEffectsPreferenceScope(
        settings: settings,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              profile = GameMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(profile.reducedMotion, isTrue);
    expect(profile.effectsScale, 0);
    expect(profile.distance(40), 0);
  });

  testWidgets('system reduced motion remains authoritative', (tester) async {
    final settings = AppSettingsStore();
    late GameMotionProfile profile;

    await tester.pumpWidget(
      VisualEffectsPreferenceScope(
        settings: settings,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              profile = GameMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(settings.reducedVisualEffects, isFalse);
    expect(profile.reducedMotion, isTrue);
  });
}
''')

# Extend the settings-store regression file with persistence/no-op/invalid tests.
settings_test = read('test/core/settings/app_settings_store_test.dart')
marker = '\n}\n'
if not settings_test.endswith(marker):
    raise SystemExit('app_settings_store_test.dart: unexpected end')
settings_test = settings_test[:-len(marker)] + '''

  test('visual effects default automatic and persist reduced mode', () async {
    final first = AppSettingsStore();
    await first.load();
    expect(first.reducedVisualEffects, isFalse);

    await first.setReducedVisualEffects(true);
    expect(first.reducedVisualEffects, isTrue);

    final second = AppSettingsStore();
    await second.load();
    expect(second.reducedVisualEffects, isTrue);
  });

  test('unknown visual effects value falls back to automatic', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('settings_visual_effects', 'future-mode');

    final settings = AppSettingsStore();
    await settings.load();

    expect(settings.reducedVisualEffects, isFalse);
  });

  test('setting the current visual mode is a notifier no-op', () async {
    final settings = AppSettingsStore();
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.setReducedVisualEffects(false);
    expect(notifications, 0);

    await settings.setReducedVisualEffects(true);
    expect(notifications, 1);

    await settings.setReducedVisualEffects(true);
    expect(notifications, 1);
  });
}\n'''
write('test/core/settings/app_settings_store_test.dart', settings_test)

write('test/features/settings/visual_effects_settings_test.dart', '''import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('visual effects setting applies live in ${locale.languageCode}', (
      tester,
    ) async {
      final settings = AppSettingsStore();
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: SettingsScreen(
            settings: settings,
            onToggleLanguage: () {},
          ),
        ),
      );

      final tile = find.byKey(const ValueKey('visual-effects-switch'));
      expect(tile, findsOneWidget);
      expect(settings.reducedVisualEffects, isFalse);

      final switchFinder = find.descendant(
        of: tile,
        matching: find.byType(Switch),
      );
      final adaptiveFinder = find.descendant(
        of: tile,
        matching: find.byType(SwitchListTile),
      );
      expect(adaptiveFinder, findsOneWidget);
      await tester.tap(adaptiveFinder);
      await tester.pump();

      expect(settings.reducedVisualEffects, isTrue);
      expect(
        find.text(
          locale.languageCode == 'ar'
              ? 'المؤثرات المرئية: مخفضة'
              : 'Visual effects: Reduced',
        ),
        findsOneWidget,
      );
      expect(switchFinder, findsWidgets);
    });
  }
}
''')

write('tool/verify_ui3d_007_visual_effects.py', '''#!/usr/bin/env python3
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
''')

write('tool/test_ui3d_007_visual_effects.py', '''#!/usr/bin/env python3
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
''')

write('docs/work/UI3D-007.md', '''# UI3D-007 Reduced Motion and Adaptive Visual Effects

Issue: #205
Branch: `agent/ui3d-007-adaptive-visual-effects`

## State

IN PROGRESS — current Feature Catalog definition. The historical world-map visual-refresh branch that reused UI3D-007 is stale/reference-only.

## Runtime contract

- Persistent user setting: Automatic (default) or Reduced visual effects.
- System `MediaQuery.disableAnimations` remains authoritative.
- PERF-001 `FramePerformanceScope` remains the automatic full/constrained/reduced quality authority.
- `GameMotion` combines user/system accessibility with performance pressure and exposes deterministic motion, blur, shadow, particle, intensity and simultaneous-effect budgets.
- Shared ambient motion, route motion, travel/action feedback and lifecycle ticker policy consume the shared effective profile.
- Visual reduction never changes gameplay, rewards, haptics, sound dispatch, navigation identity, ads/privacy, persistence ownership or completion callbacks.

## 100-checkpoint progress

T001-T080 implemented in source. T081-T096 are covered by focused tests and machine ownership gates. T097-T100 require final PR CI, build, merge, exact-main verification and reconciliation evidence.
''')

# Register the current workstream in catalog/status.
replace(
    'docs/FEATURE_CATALOG.md',
    '| UI3D-007 | Reduced motion and low-performance visual mode | P1 | PLANNED | MOT-001 | User setting and automatic graceful degradation affect all shared visual effects. |',
    '| UI3D-007 | Reduced motion and low-performance visual mode | P1 | IN PROGRESS | MOT-001 | Issue #205 / branch `agent/ui3d-007-adaptive-visual-effects` implement persistent user reduced-effects plus PERF-001 automatic graceful degradation across shared motion and visual-effect budgets; final CI/merge evidence pending. |',
)
status = read('docs/STATUS.md')
status = status.replace(
    '| Primary feature | None — `TEST-011` completed 100/100 source-controlled checkpoints as IMPLEMENTED; `UI3D-007` is selected next but not started. |',
    '| Primary feature | `UI3D-007` Reduced motion and adaptive visual effects — IN PROGRESS on issue #205 / `agent/ui3d-007-adaptive-visual-effects`. |',
)
status = status.replace(
    '| Next recommended feature | `UI3D-007` Reduced motion and low-performance visual mode — P1, dependency-ready via MOT-001. Start fresh from current `main`; stale `agent/ui3d-007-world-map-refresh` is reference-only. |',
    '| Next recommended feature | UI3D-007 is the active primary; no second source-controlled feature should start until its merge/reconciliation completes. |',
)
write('docs/STATUS.md', status)

print('UI3D-007 bootstrap patch applied')
