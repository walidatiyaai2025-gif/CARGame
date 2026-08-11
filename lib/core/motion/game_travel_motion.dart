import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_motion.dart';

/// Moves a visual from a known source to a destination while keeping input and
/// domain-state ownership with the caller.
class GameTravelMotion extends StatefulWidget {
  const GameTravelMotion({
    super.key,
    required this.start,
    required this.end,
    required this.size,
    required this.child,
    required this.onCompleted,
  });

  final Offset start;
  final Offset end;
  final double size;
  final Widget child;
  final VoidCallback onCompleted;

  @override
  State<GameTravelMotion> createState() => _GameTravelMotionState();
}

class _GameTravelMotionState extends State<GameTravelMotion>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _completionScheduled = false;
  bool _completed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_completed) return;

    final profile = GameMotion.of(context);
    const intent = GameMotionIntent.essential;
    final shouldTravel =
        profile.shouldUseTicker(intent) &&
        profile.shouldUseSpatialMotion(intent);

    if (!shouldTravel) {
      _disposeController();
      _scheduleCompletion();
      return;
    }

    if (_controller != null) return;
    final controller = AnimationController(
      vsync: this,
      duration: profile.durationFor(intent, GameMotionDurations.standard),
    )..addStatusListener(_handleStatus);
    _controller = controller;
    controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finishOnce();
  }

  void _scheduleCompletion() {
    if (_completionScheduled || _completed) return;
    _completionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completionScheduled = false;
      if (mounted) _finishOnce();
    });
  }

  void _finishOnce() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  void _disposeController() {
    final controller = _controller;
    if (controller == null) return;
    controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = GameMotion.of(context);
    final controller = _controller;
    final animation = controller ?? const AlwaysStoppedAnimation<double>(1);
    final reduced = controller == null;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: SizedBox.square(
                dimension: widget.size,
                child: widget.child,
              ),
            ),
          ),
          builder: (context, child) {
            final progress = profile
                .curve(GameMotionCurves.enter)
                .transform(animation.value);
            final point = reduced ? widget.end : _quadraticPoint(progress);
            final scale = reduced ? 1.0 : _pickupAndSettleScale(progress);

            return Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: point - Offset(widget.size / 2, widget.size / 2),
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
        ),
      ),
    );
  }

  Offset _quadraticPoint(double progress) {
    final midpoint = Offset.lerp(widget.start, widget.end, .5)!;
    final distance = (widget.end - widget.start).distance;
    final control = midpoint.translate(0, -math.min(72.0, distance * .2));
    final inverse = 1 - progress;
    return widget.start * (inverse * inverse) +
        control * (2 * inverse * progress) +
        widget.end * (progress * progress);
  }

  double _pickupAndSettleScale(double progress) {
    if (progress < .2) {
      return 1 + math.sin(progress / .2 * math.pi) * .06;
    }
    if (progress > .72) {
      return 1 + math.sin((progress - .72) / .28 * math.pi) * .11;
    }
    return 1;
  }
}
