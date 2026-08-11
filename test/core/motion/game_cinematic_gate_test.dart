import 'package:cargo_sort_game/core/motion/game_cinematic_gate.dart';
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

  testWidgets('normal cinematic animates and completes exactly once', (
    tester,
  ) async {
    final reasons = <GameCinematicCompletionReason>[];

    await tester.pumpWidget(
      MaterialApp(
        home: GameCinematicGate(
          duration: const Duration(milliseconds: 200),
          onCompleted: reasons.add,
          builder: (context, animation, skipped) => Text(
            skipped
                ? 'skipped'
                : 'animated-${animation.value.toStringAsFixed(1)}',
          ),
        ),
      ),
    );

    expect(reasons, isEmpty);
    await tester.pump(const Duration(milliseconds: 220));
    expect(reasons, [GameCinematicCompletionReason.animated]);
    await tester.pump(const Duration(seconds: 1));
    expect(reasons, hasLength(1));
  });

  testWidgets('system reduced motion skips cinematic without animation wait', (
    tester,
  ) async {
    final reasons = <GameCinematicCompletionReason>[];

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: GameCinematicGate(
            duration: const Duration(seconds: 2),
            onCompleted: reasons.add,
            builder: (context, animation, skipped) =>
                Text(skipped ? 'skipped' : 'animated'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('skipped'), findsOneWidget);
    expect(reasons, [GameCinematicCompletionReason.skippedReducedMotion]);
  });

  testWidgets('user reduced effects also skips cinematic live policy', (
    tester,
  ) async {
    final settings = AppSettingsStore();
    await settings.setVisualEffectsPreference(
      GameVisualEffectsPreference.reduced,
    );
    final reasons = <GameCinematicCompletionReason>[];

    await tester.pumpWidget(
      VisualEffectsPreferenceScope(
        settings: settings,
        child: MaterialApp(
          home: GameCinematicGate(
            duration: const Duration(seconds: 2),
            onCompleted: reasons.add,
            builder: (context, animation, skipped) =>
                Text(skipped ? 'user-skipped' : 'animated'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('user-skipped'), findsOneWidget);
    expect(reasons, [GameCinematicCompletionReason.skippedReducedMotion]);
  });

  testWidgets('dispose before completion prevents late callback', (
    tester,
  ) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: GameCinematicGate(
          duration: const Duration(seconds: 1),
          onCompleted: (_) => completions++,
          builder: (context, animation, skipped) => const SizedBox(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));

    expect(completions, 0);
  });
}
