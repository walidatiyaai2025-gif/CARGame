import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_motion.dart';

enum GameActionFeedbackKind { correct, wrong }

class GameActionFeedback extends StatefulWidget {
  const GameActionFeedback({
    super.key,
    required this.kind,
    required this.combo,
    required this.onCompleted,
    this.onSound,
  });

  final GameActionFeedbackKind kind;
  final int combo;
  final VoidCallback onCompleted;
  final VoidCallback? onSound;

  @override
  State<GameActionFeedback> createState() => _GameActionFeedbackState();
}

class _GameActionFeedbackState extends State<GameActionFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _completed = false;

  int get _cappedCombo => widget.combo.clamp(0, 8);

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

    widget.onSound?.call();
    _triggerHaptic();

    final profile = GameMotion.of(context);
    if (profile.reducedMotion) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishOnce());
      return;
    }

    _controller.duration = profile.duration(GameMotionDurations.reward);
    _controller.forward();
  }

  void _triggerHaptic() {
    if (widget.kind == GameActionFeedbackKind.wrong) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (_cappedCombo >= 5) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finishOnce();
  }

  void _finishOnce() {
    if (_completed) return;
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
    final correct = widget.kind == GameActionFeedbackKind.correct;
    final accent = correct ? const Color(0xFF2FD17B) : const Color(0xFFFF5364);

    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final value = _controller.value;
              final entrance = Curves.easeOutBack.transform(
                math.min(1, value / .38),
              );
              final fade = value < .72 ? 1.0 : 1 - ((value - .72) / .28);
              final recoil = correct
                  ? 0.0
                  : math.sin(value * math.pi * 7) * (1 - value) * 16;
              final scale = profile.reducedMotion
                  ? 1.0
                  : .72 + entrance * (.28 + _cappedCombo * .012);

              return Stack(
                alignment: Alignment.center,
                children: [
                  if (correct && !profile.reducedMotion)
                    for (var index = 0; index < 8; index++)
                      _Sparkle(
                        progress: value,
                        index: index,
                        intensity: 1 + _cappedCombo * .08,
                        color: accent,
                      ),
                  Transform.translate(
                    offset: Offset(recoil, 0),
                    child: Opacity(
                      opacity: fade.clamp(0, 1),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 118,
                            minHeight: 92,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: .42),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                correct
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                              if (correct && widget.combo >= 2)
                                Text(
                                  'COMBO x${widget.combo}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.progress,
    required this.index,
    required this.intensity,
    required this.color,
  });

  final double progress;
  final int index;
  final double intensity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final angle = index / 8 * math.pi * 2;
    final distance = Curves.easeOut.transform(progress) * 92 * intensity;
    final opacity = (1 - progress).clamp(0, 1);
    return Transform.translate(
      offset: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
      child: Opacity(
        opacity: opacity,
        child: Icon(
          index.isEven ? Icons.star_rounded : Icons.circle,
          color: index.isEven ? Colors.white : color,
          size: index.isEven ? 18 : 10,
        ),
      ),
    );
  }
}
