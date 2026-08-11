import 'package:cargo_sort_game/core/motion/game_motion.dart';
import 'package:cargo_sort_game/core/performance/frame_performance_budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('full motion keeps all intents available', () {
    const profile = GameMotionProfile(reducedMotion: false);

    expect(profile.shouldAnimate(GameMotionIntent.essential), isTrue);
    expect(profile.shouldAnimate(GameMotionIntent.nonessential), isTrue);
    expect(profile.shouldAnimate(GameMotionIntent.cinematic), isTrue);
    expect(profile.shouldUseSpatialMotion(GameMotionIntent.essential), isTrue);
    expect(profile.shouldSkipCinematic(), isFalse);
  });

  test('effective reduced motion skips nonessential and cinematic motion', () {
    const profile = GameMotionProfile(reducedMotion: true);

    expect(profile.shouldAnimate(GameMotionIntent.nonessential), isFalse);
    expect(profile.shouldAnimate(GameMotionIntent.cinematic), isFalse);
    expect(profile.shouldUseTicker(GameMotionIntent.nonessential), isFalse);
    expect(profile.shouldUseSpatialMotion(GameMotionIntent.essential), isFalse);
    expect(profile.shouldSkipCinematic(), isTrue);
    expect(
      profile.durationFor(
        GameMotionIntent.cinematic,
        GameMotionDurations.reward,
      ),
      Duration.zero,
    );
  });

  test('essential temporal cue is bounded without spatial motion', () {
    const profile = GameMotionProfile(reducedMotion: true);

    expect(
      profile.shouldAnimate(
        GameMotionIntent.essential,
        allowReducedTemporalFeedback: true,
      ),
      isTrue,
    );
    expect(
      profile.durationFor(
        GameMotionIntent.essential,
        GameMotionDurations.standard,
        allowReducedTemporalFeedback: true,
      ),
      const Duration(milliseconds: 100),
    );
    expect(profile.distance(20), 0);
    expect(profile.scale(.9), 1);
    expect(profile.curve(Curves.elasticOut), Curves.linear);
  });

  test('performance pressure alone does not become accessibility skip', () {
    const constrained = GameMotionProfile(
      reducedMotion: false,
      performanceQuality: GameVisualQuality.constrained,
    );
    const reducedQuality = GameMotionProfile(
      reducedMotion: false,
      performanceQuality: GameVisualQuality.reduced,
    );

    expect(constrained.shouldSkipCinematic(), isFalse);
    expect(reducedQuality.shouldSkipCinematic(), isFalse);
    expect(constrained.shouldAnimate(GameMotionIntent.cinematic), isTrue);
    expect(reducedQuality.shouldAnimate(GameMotionIntent.cinematic), isTrue);
  });
}
