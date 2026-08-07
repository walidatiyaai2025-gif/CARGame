import 'package:flutter/material.dart';

import '../../core/motion/game_motion.dart';

class CargoMotionTile extends StatelessWidget {
  const CargoMotionTile({
    super.key,
    required this.selected,
    required this.busy,
    required this.child,
  });

  final bool selected;
  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = GameMotion.of(context);
    final active = selected && !busy;

    return AnimatedSlide(
      offset: Offset(0, motion.distance(active ? -0.08 : 0)),
      duration: motion.duration(GameMotionDurations.fast),
      curve: motion.curve(GameMotionCurves.enter),
      child: AnimatedScale(
        scale: motion.scale(
          active
              ? 1.07
              : busy
              ? 0.96
              : 1,
        ),
        duration: motion.duration(GameMotionDurations.fast),
        curve: motion.curve(GameMotionCurves.springRelease),
        child: AnimatedOpacity(
          opacity: busy ? 0.72 : 1,
          duration: motion.duration(GameMotionDurations.tap),
          child: child,
        ),
      ),
    );
  }
}

class WarehouseMotionTarget extends StatelessWidget {
  const WarehouseMotionTarget({
    super.key,
    required this.active,
    required this.correct,
    required this.child,
  });

  final bool active;
  final bool correct;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = GameMotion.of(context);
    final scale = active ? (correct ? 1.08 : 0.94) : 1.0;

    return AnimatedScale(
      scale: motion.scale(scale),
      duration: motion.duration(GameMotionDurations.standard),
      curve: motion.curve(
        correct ? GameMotionCurves.springRelease : GameMotionCurves.exit,
      ),
      child: AnimatedRotation(
        turns: motion.distance(active && !correct ? -0.015 : 0),
        duration: motion.duration(GameMotionDurations.fast),
        child: child,
      ),
    );
  }
}
