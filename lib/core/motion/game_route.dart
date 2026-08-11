import 'package:flutter/material.dart';

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
    const intent = GameMotionIntent.essential;
    final horizontalOffset =
        (direction == TextDirection.rtl ? -0.065 : 0.065) *
        profile.effectsScale;

    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: profile.reducedMotion
          ? const Duration(milliseconds: 120)
          : profile.durationFor(intent, forwardDuration),
      reverseTransitionDuration: profile.reducedMotion
          ? const Duration(milliseconds: 100)
          : profile.durationFor(intent, reverseDuration),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: profile.curve(Curves.easeOutCubic),
          reverseCurve: profile.curve(Curves.easeInCubic),
        );

        if (!profile.shouldUseSpatialMotion(intent)) {
          return FadeTransition(opacity: fade, child: child);
        }

        final slide =
            Tween<Offset>(
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
