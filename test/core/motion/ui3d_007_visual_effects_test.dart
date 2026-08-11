import 'package:cargo_sort_game/core/motion/game_motion.dart';
import 'package:cargo_sort_game/core/performance/frame_performance_budget.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/settings/game_visual_effects_preference.dart';
import 'package:cargo_sort_game/core/settings/visual_effects_preference_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

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
    expect(constrained.shadow(12), closeTo(7.8, 1e-9));
    expect(reduced.shadow(12), closeTo(4.2, 1e-9));
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
