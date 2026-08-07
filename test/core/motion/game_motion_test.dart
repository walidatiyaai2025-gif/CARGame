import 'package:cargo_sort_game/core/motion/game_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion budgets stay inside documented ranges', () {
    expect(GameMotionDurations.tap.inMilliseconds, inInclusiveRange(80, 140));
    expect(
      GameMotionDurations.standard.inMilliseconds,
      inInclusiveRange(180, 280),
    );
    expect(
      GameMotionDurations.modal.inMilliseconds,
      inInclusiveRange(220, 320),
    );
    expect(
      GameMotionDurations.reward.inMilliseconds,
      inInclusiveRange(500, 900),
    );
    expect(
      GameMotionDurations.idle.inMilliseconds,
      inInclusiveRange(2500, 6000),
    );
  });

  test(
    'reduced motion removes travel and scale while keeping brief feedback',
    () {
      const profile = GameMotionProfile(reducedMotion: true);

      expect(profile.distance(12), 0);
      expect(profile.scale(.9), 1);
      expect(
        profile.duration(GameMotionDurations.reward),
        const Duration(milliseconds: 100),
      );
      expect(profile.curve(Curves.elasticOut), Curves.linear);
    },
  );

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
