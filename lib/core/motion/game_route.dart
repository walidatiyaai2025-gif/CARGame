import 'package:flutter/material.dart';

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
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final horizontalOffset = direction == TextDirection.rtl ? -0.065 : 0.065;

    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: reducedMotion
          ? const Duration(milliseconds: 120)
          : forwardDuration,
      reverseTransitionDuration: reducedMotion
          ? const Duration(milliseconds: 100)
          : reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
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
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
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
