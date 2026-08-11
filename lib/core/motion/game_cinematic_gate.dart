import 'package:flutter/material.dart';

import 'game_motion.dart';

enum GameCinematicCompletionReason { animated, skippedReducedMotion }

typedef GameCinematicBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      bool skipped,
    );

class GameCinematicGate extends StatefulWidget {
  const GameCinematicGate({
    super.key,
    required this.duration,
    required this.builder,
    required this.onCompleted,
    this.intent = GameMotionIntent.cinematic,
    this.curve = GameMotionCurves.enter,
    this.allowReducedTemporalFeedback = false,
  });

  final Duration duration;
  final GameCinematicBuilder builder;
  final ValueChanged<GameCinematicCompletionReason> onCompleted;
  final GameMotionIntent intent;
  final Curve curve;
  final bool allowReducedTemporalFeedback;

  @override
  State<GameCinematicGate> createState() => _GameCinematicGateState();
}

class _GameCinematicGateState extends State<GameCinematicGate>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _animation = const AlwaysStoppedAnimation<double>(1);
  bool _completionScheduled = false;
  bool _completed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_completed) return;

    final profile = GameMotion.of(context);
    final shouldUseTicker = profile.shouldUseTicker(
      widget.intent,
      allowReducedTemporalFeedback: widget.allowReducedTemporalFeedback,
    );

    if (!shouldUseTicker) {
      _controller?.dispose();
      _controller = null;
      _animation = const AlwaysStoppedAnimation<double>(1);
      _scheduleCompletion(GameCinematicCompletionReason.skippedReducedMotion);
      return;
    }

    if (_controller != null) return;
    final controller = AnimationController(
      vsync: this,
      duration: profile.durationFor(
        widget.intent,
        widget.duration,
        allowReducedTemporalFeedback: widget.allowReducedTemporalFeedback,
      ),
    );
    controller.addStatusListener(_handleStatus);
    _controller = controller;
    _animation = CurvedAnimation(
      parent: controller,
      curve: profile.curve(widget.curve),
    );
    controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _finishOnce(GameCinematicCompletionReason.animated);
    }
  }

  void _scheduleCompletion(GameCinematicCompletionReason reason) {
    if (_completionScheduled || _completed) return;
    _completionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completionScheduled = false;
      if (!mounted) return;
      _finishOnce(reason);
    });
  }

  void _finishOnce(GameCinematicCompletionReason reason) {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted(reason);
  }

  @override
  void dispose() {
    _controller
      ?..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skipped = _controller == null;
    return widget.builder(context, _animation, skipped);
  }
}
