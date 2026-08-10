import 'package:flutter/material.dart';

import '../performance/frame_performance_budget.dart';
import '../performance/frame_performance_scope.dart';

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
  const GameMotionProfile({
    required this.reducedMotion,
    this.performanceQuality = GameVisualQuality.full,
  });

  final bool reducedMotion;
  final GameVisualQuality performanceQuality;

  bool get allowAmbientMotion =>
      !reducedMotion && performanceQuality == GameVisualQuality.full;

  double get effectsScale {
    if (reducedMotion) return 0;
    return switch (performanceQuality) {
      GameVisualQuality.full => 1,
      GameVisualQuality.constrained => .65,
      GameVisualQuality.reduced => .35,
    };
  }

  Duration duration(Duration value) {
    if (reducedMotion) {
      if (value <= GameMotionDurations.fast) {
        return const Duration(milliseconds: 60);
      }
      return const Duration(milliseconds: 100);
    }

    final factor = switch (performanceQuality) {
      GameVisualQuality.full => 1.0,
      GameVisualQuality.constrained => .8,
      GameVisualQuality.reduced => .55,
    };
    final micros = (value.inMicroseconds * factor).round();
    return Duration(microseconds: micros.clamp(60000, value.inMicroseconds));
  }

  double distance(double value) => reducedMotion ? 0 : value * effectsScale;

  double scale(double value) {
    if (reducedMotion) return 1;
    final delta = value - 1;
    return 1 + delta * effectsScale;
  }

  Curve curve(Curve value) {
    if (reducedMotion) return Curves.linear;
    if (performanceQuality == GameVisualQuality.reduced) {
      return Curves.easeOut;
    }
    return value;
  }
}

abstract final class GameMotion {
  static GameMotionProfile of(BuildContext context) => GameMotionProfile(
    reducedMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
    performanceQuality: FramePerformanceScope.qualityOf(context),
  );
}
