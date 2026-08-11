import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_motion.dart';

enum GameActionFeedbackKind { correct, wrong }

typedef GameActionFeedbackSoundHook =
    FutureOr<void> Function(GameActionFeedbackKind kind, int comboIntensity);

class GameActionFeedback extends StatefulWidget {
  const GameActionFeedback({
    super.key,
    required this.kind,
    required this.combo,
    required this.onCompleted,
    required this.semanticLabel,
    this.hapticsEnabled = true,
    this.onSound,
  });

  static const int maxComboIntensity = 8;

  final GameActionFeedbackKind kind;
  final int combo;
  final VoidCallback onCompleted;
  final String semanticLabel;
  final bool hapticsEnabled;
  final GameActionFeedbackSoundHook? onSound;

  static int comboIntensityFor(int combo) {
    if (combo <= 0) return 0;
    return combo >= maxComboIntensity ? maxComboIntensity : combo;
  }

  @override
  State<GameActionFeedback> createState() => _GameActionFeedbackState();
}

class _GameActionFeedbackState extends State<GameActionFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _reducedMotionTimer;
  bool _started = false;
  bool _completed = false;

  int get _cappedCombo => GameActionFeedback.comboIntensityFor(widget.combo);

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

    unawaited(_dispatchFeedback());

    final profile = GameMotion.of(context);
    if (profile.reducedMotion) {
      _controller.value = .5;
      _reducedMotionTimer = Timer(
        profile.duration(GameMotionDurations.standard),
        _finishOnce,
      );
      return;
    }

    _controller.duration = profile.duration(GameMotionDurations.reward);
    _controller.forward();
  }

  Future<void> _dispatchFeedback() async {
    final actions = <Future<void>>[];
    if (widget.hapticsEnabled) actions.add(_triggerHaptic());
    final sound = widget.onSound;
    if (sound != null) {
      actions.add(Future<void>.sync(() => sound(widget.kind, _cappedCombo)));
    }
    try {
      await Future.wait(actions);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'CARGame action feedback',
          context: ErrorDescription('while dispatching optional feedback'),
        ),
      );
    }
  }

  Future<void> _triggerHaptic() {
    if (widget.kind == GameActionFeedbackKind.wrong) {
      return HapticFeedback.heavyImpact();
    }
    if (_cappedCombo >= 5) {
      return HapticFeedback.mediumImpact();
    }
    return HapticFeedback.lightImpact();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finishOnce();
  }

  void _finishOnce() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  @override
  void dispose() {
    _reducedMotionTimer?.cancel();
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
    final sparkleCount = profile.particleCount(8);
    final shadowBlur = profile.shadow(28);
    final shadowSpread = profile.shadow(4);

    return Positioned.fill(
      child: IgnorePointer(
        child: Semantics(
          container: true,
          liveRegion: true,
          label: widget.semanticLabel,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                final entrance = profile
                    .curve(GameMotionCurves.emphasized)
                    .transform(math.min(1, value / .38));
                final fade = value < .72 ? 1.0 : 1 - ((value - .72) / .28);
                final recoil = correct
                    ? 0.0
                    : math.sin(value * math.pi * 7) *
                          (1 - value) *
                          profile.distance(16);
                final scale = profile.reducedMotion
                    ? 1.0
                    : .72 + entrance * (.28 + _cappedCombo * .012);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (correct && sparkleCount > 0)
                      for (var index = 0; index < sparkleCount; index++)
                        _Sparkle(
                          progress: value,
                          index: index,
                          total: sparkleCount,
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
                              boxShadow: shadowBlur <= 0
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: accent.withValues(
                                          alpha: .42 * profile.effectsScale,
                                        ),
                                        blurRadius: shadowBlur,
                                        spreadRadius: shadowSpread,
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
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.progress,
    required this.index,
    required this.total,
    required this.intensity,
    required this.color,
  });

  final double progress;
  final int index;
  final int total;
  final double intensity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final angle = index / total * math.pi * 2;
    final distance = Curves.easeOut.transform(progress) * 92 * intensity;
    final opacity = (1 - progress).clamp(0, 1).toDouble();
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
