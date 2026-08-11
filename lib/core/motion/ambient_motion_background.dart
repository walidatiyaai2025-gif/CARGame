import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_motion.dart';

/// Low-cost ambient scene shared by the home and world-map surfaces.
class AmbientMotionBackground extends StatefulWidget {
  const AmbientMotionBackground({
    super.key,
    required this.startColor,
    required this.endColor,
  });

  final Color startColor;
  final Color endColor;

  @override
  State<AmbientMotionBackground> createState() =>
      _AmbientMotionBackgroundState();
}

class _AmbientMotionBackgroundState extends State<AmbientMotionBackground>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  bool _ambientMotionDisabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = GameMotion.of(context);
    const intent = GameMotionIntent.nonessential;
    final ambientMotionDisabled = !GameMotion.of(context).allowAmbientMotion;
    final shouldAnimate =
        !ambientMotionDisabled && profile.shouldUseTicker(intent);
    _ambientMotionDisabled = !shouldAnimate;

    if (!shouldAnimate) {
      _controller?.dispose();
      _controller = null;
      return;
    }

    if (_controller != null) return;
    _controller = AnimationController(
      vsync: this,
      duration: GameMotionDurations.idle,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = GameMotion.of(context);
    final animation = _controller ?? const AlwaysStoppedAnimation<double>(0);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          painter: _AmbientMotionPainter(
            progress: animation.value,
            startColor: widget.startColor,
            endColor: widget.endColor,
            reducedMotion: _ambientMotionDisabled,
            effectsScale: profile.effectsScale,
            decorativeCount: profile.particleCount(4),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AmbientMotionPainter extends CustomPainter {
  const _AmbientMotionPainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    required this.reducedMotion,
    required this.effectsScale,
    required this.decorativeCount,
  });

  final double progress;
  final Color startColor;
  final Color endColor;
  final bool reducedMotion;
  final double effectsScale;
  final int decorativeCount;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          startColor.withValues(alpha: .24),
          const Color(0xFFF6FAFF),
          const Color(0xFFFFF8E7),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final phase = reducedMotion ? 0.0 : progress * math.pi * 2;
    if (effectsScale > 0) {
      _drawGlow(
        canvas,
        Offset(size.width * (.16 + math.sin(phase) * .025), size.height * .14),
        size.shortestSide * .34,
        startColor.withValues(alpha: .13 * effectsScale),
      );
      _drawGlow(
        canvas,
        Offset(size.width * (.84 + math.cos(phase) * .02), size.height * .34),
        size.shortestSide * .28,
        endColor.withValues(alpha: .10 * effectsScale),
      );
    }

    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: .34 * effectsScale);
    for (var index = 0; index < decorativeCount; index++) {
      final base = (index * .29 + progress * .08) % 1.25 - .12;
      final x = size.width * base;
      final y = size.height * (.08 + index * .075);
      _drawCloud(canvas, Offset(x, y), 18 + index * 3, cloudPaint);
    }

    final roadPaint = Paint()
      ..color = startColor.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final road = Path()
      ..moveTo(-20, size.height * .82)
      ..cubicTo(
        size.width * .25,
        size.height * .70,
        size.width * .65,
        size.height * .95,
        size.width + 30,
        size.height * .76,
      );
    canvas.drawPath(road, roadPaint);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCloud(Canvas canvas, Offset origin, double radius, Paint paint) {
    canvas.drawCircle(origin, radius, paint);
    canvas.drawCircle(origin + Offset(radius * .9, 3), radius * .72, paint);
    canvas.drawCircle(origin - Offset(radius * .8, -5), radius * .58, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientMotionPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.startColor != startColor ||
      oldDelegate.endColor != endColor ||
      oldDelegate.reducedMotion != reducedMotion ||
      oldDelegate.effectsScale != effectsScale ||
      oldDelegate.decorativeCount != decorativeCount;
}
