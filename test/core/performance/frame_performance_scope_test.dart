import 'package:cargo_sort_game/core/motion/game_motion.dart';
import 'package:cargo_sort_game/core/performance/frame_performance_budget.dart';
import 'package:cargo_sort_game/core/performance/frame_performance_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scope propagates adaptive quality changes to shared motion', (
    tester,
  ) async {
    const policy = FramePerformancePolicy(
      windowSize: 5,
      minimumSamples: 5,
      evaluationStride: 5,
      degradeJankRatio: .2,
      degradeSevereRatio: .2,
    );
    final controller = FramePerformanceController(policy: policy);
    late GameMotionProfile profile;

    await tester.pumpWidget(
      FramePerformanceScope(
        controller: controller,
        observeScheduler: false,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              profile = GameMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(profile.performanceQuality, GameVisualQuality.full);
    expect(profile.allowAmbientMotion, isTrue);

    for (var index = 0; index < 5; index++) {
      controller.recordFrameDuration(const Duration(milliseconds: 40));
    }
    await tester.pump();

    expect(profile.performanceQuality, GameVisualQuality.constrained);
    expect(profile.allowAmbientMotion, isFalse);
    expect(profile.effectsScale, .65);
  });

  testWidgets('system reduced motion wins over adaptive quality', (
    tester,
  ) async {
    const policy = FramePerformancePolicy(
      windowSize: 5,
      minimumSamples: 5,
      evaluationStride: 5,
      degradeJankRatio: .2,
      degradeSevereRatio: .2,
    );
    final controller = FramePerformanceController(policy: policy);
    for (var index = 0; index < 5; index++) {
      controller.recordFrameDuration(const Duration(milliseconds: 40));
    }

    late GameMotionProfile profile;
    await tester.pumpWidget(
      FramePerformanceScope(
        controller: controller,
        observeScheduler: false,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                profile = GameMotion.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(profile.performanceQuality, GameVisualQuality.constrained);
    expect(profile.reducedMotion, isTrue);
    expect(profile.effectsScale, 0);
    expect(profile.distance(24), 0);
    expect(profile.scale(.8), 1);
    expect(profile.curve(Curves.elasticOut), Curves.linear);
    expect(
      profile.duration(GameMotionDurations.reward),
      const Duration(milliseconds: 100),
    );
  });

  testWidgets('shared motion defaults to full quality without a scope', (
    tester,
  ) async {
    late GameMotionProfile profile;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            profile = GameMotion.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(profile.performanceQuality, GameVisualQuality.full);
    expect(profile.allowAmbientMotion, isTrue);
  });
}
