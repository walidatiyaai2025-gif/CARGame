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
  late final AnimationController _controller;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final profile = GameMotion.of(context);
    if (profile.reducedMotion) {
      _completed = true;
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCompleted();
      });
      return;
    }
    _controller.duration = profile.duration(GameMotionDurations.standard);
    _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _completed) return;
    _completed = true;
    widget.onCompleted();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = GameMotion.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
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
                .transform(_controller.value);
            final point = profile.reducedMotion
                ? widget.end
                : _quadraticPoint(progress);
            final scale = profile.reducedMotion
                ? 1.0
                : _pickupAndSettleScale(progress);

            return Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: point - Offset(widget.size / 2, widget.size / 2),
                child: Opacity(
                  opacity: profile.reducedMotion ? progress : 1,
                  child: Transform.scale(scale: scale, child: child),
                ),
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
