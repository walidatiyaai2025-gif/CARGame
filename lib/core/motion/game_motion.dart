import 'package:flutter/animation.dart';
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
    if (value <= GameMotionDurations.fast)
      return const Duration(milliseconds: 60);
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
