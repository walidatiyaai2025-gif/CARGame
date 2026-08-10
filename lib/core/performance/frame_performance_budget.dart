import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

enum GameVisualQuality { full, constrained, reduced }

@immutable
class FramePerformancePolicy {
  const FramePerformancePolicy({
    this.targetFps = 60,
    this.jankFrameBudget = const Duration(milliseconds: 24),
    this.severeFrameBudget = const Duration(milliseconds: 34),
    this.windowSize = 60,
    this.minimumSamples = 30,
    this.evaluationStride = 15,
    this.degradeJankRatio = 0.12,
    this.degradeSevereRatio = 0.04,
    this.recoverJankRatio = 0.03,
    this.healthyWindowsToRecover = 3,
  }) : assert(targetFps > 0),
       assert(windowSize > 0),
       assert(minimumSamples > 0),
       assert(minimumSamples <= windowSize),
       assert(evaluationStride > 0),
       assert(degradeJankRatio >= 0 && degradeJankRatio <= 1),
       assert(degradeSevereRatio >= 0 && degradeSevereRatio <= 1),
       assert(recoverJankRatio >= 0 && recoverJankRatio <= 1),
       assert(healthyWindowsToRecover > 0);

  static const FramePerformancePolicy mobile60Hz = FramePerformancePolicy();

  final int targetFps;
  final Duration jankFrameBudget;
  final Duration severeFrameBudget;
  final int windowSize;
  final int minimumSamples;
  final int evaluationStride;
  final double degradeJankRatio;
  final double degradeSevereRatio;
  final double recoverJankRatio;
  final int healthyWindowsToRecover;

  Duration get targetFrameBudget => Duration(
    microseconds: (Duration.microsecondsPerSecond / targetFps).round(),
  );
}

@immutable
class FramePerformanceSnapshot {
  const FramePerformanceSnapshot({
    required this.quality,
    required this.sampleCount,
    required this.totalFrames,
    required this.averageFrame,
    required this.worstFrame,
    required this.jankRatio,
    required this.severeJankRatio,
    required this.healthyWindows,
  });

  factory FramePerformanceSnapshot.initial() => const FramePerformanceSnapshot(
    quality: GameVisualQuality.full,
    sampleCount: 0,
    totalFrames: 0,
    averageFrame: Duration.zero,
    worstFrame: Duration.zero,
    jankRatio: 0,
    severeJankRatio: 0,
    healthyWindows: 0,
  );

  final GameVisualQuality quality;
  final int sampleCount;
  final int totalFrames;
  final Duration averageFrame;
  final Duration worstFrame;
  final double jankRatio;
  final double severeJankRatio;
  final int healthyWindows;
}

class FramePerformanceController extends ChangeNotifier {
  FramePerformanceController({this.policy = FramePerformancePolicy.mobile60Hz});

  final FramePerformancePolicy policy;
  final ListQueue<Duration> _samples = ListQueue<Duration>();

  GameVisualQuality _quality = GameVisualQuality.full;
  int _totalFrames = 0;
  int _framesSinceEvaluation = 0;
  int _healthyWindows = 0;

  GameVisualQuality get quality => _quality;

  int get sampleCount => _samples.length;

  int get totalFrames => _totalFrames;

  FramePerformanceSnapshot get snapshot {
    if (_samples.isEmpty) {
      return FramePerformanceSnapshot(
        quality: _quality,
        sampleCount: 0,
        totalFrames: _totalFrames,
        averageFrame: Duration.zero,
        worstFrame: Duration.zero,
        jankRatio: 0,
        severeJankRatio: 0,
        healthyWindows: _healthyWindows,
      );
    }

    var totalMicros = 0;
    var worstMicros = 0;
    var jank = 0;
    var severe = 0;
    for (final sample in _samples) {
      final micros = sample.inMicroseconds;
      totalMicros += micros;
      if (micros > worstMicros) worstMicros = micros;
      if (sample > policy.jankFrameBudget) jank++;
      if (sample > policy.severeFrameBudget) severe++;
    }

    return FramePerformanceSnapshot(
      quality: _quality,
      sampleCount: _samples.length,
      totalFrames: _totalFrames,
      averageFrame: Duration(
        microseconds: (totalMicros / _samples.length).round(),
      ),
      worstFrame: Duration(microseconds: worstMicros),
      jankRatio: jank / _samples.length,
      severeJankRatio: severe / _samples.length,
      healthyWindows: _healthyWindows,
    );
  }

  void recordFrameTiming(FrameTiming timing) {
    recordFrameDuration(timing.totalSpan);
  }

  void recordFrameDuration(Duration duration) {
    if (duration.isNegative) return;

    _totalFrames++;
    _framesSinceEvaluation++;
    _samples.addLast(duration);
    while (_samples.length > policy.windowSize) {
      _samples.removeFirst();
    }

    if (_samples.length < policy.minimumSamples ||
        _framesSinceEvaluation < policy.evaluationStride) {
      return;
    }

    _framesSinceEvaluation = 0;
    _evaluateWindow();
  }

  void clearHistory({bool restoreFullQuality = false}) {
    _samples.clear();
    _framesSinceEvaluation = 0;
    _healthyWindows = 0;
    if (restoreFullQuality && _quality != GameVisualQuality.full) {
      _quality = GameVisualQuality.full;
      notifyListeners();
    }
  }

  void _evaluateWindow() {
    final current = snapshot;
    final underPressure =
        current.jankRatio >= policy.degradeJankRatio ||
        current.severeJankRatio >= policy.degradeSevereRatio;
    final healthy =
        current.jankRatio <= policy.recoverJankRatio &&
        current.severeJankRatio == 0;

    if (underPressure) {
      _healthyWindows = 0;
      final next = switch (_quality) {
        GameVisualQuality.full => GameVisualQuality.constrained,
        GameVisualQuality.constrained => GameVisualQuality.reduced,
        GameVisualQuality.reduced => GameVisualQuality.reduced,
      };
      _setQuality(next);
      return;
    }

    if (!healthy || _quality == GameVisualQuality.full) {
      _healthyWindows = 0;
      return;
    }

    _healthyWindows++;
    if (_healthyWindows < policy.healthyWindowsToRecover) return;

    _healthyWindows = 0;
    final next = switch (_quality) {
      GameVisualQuality.reduced => GameVisualQuality.constrained,
      GameVisualQuality.constrained => GameVisualQuality.full,
      GameVisualQuality.full => GameVisualQuality.full,
    };
    _setQuality(next);
  }

  void _setQuality(GameVisualQuality next) {
    if (_quality == next) return;
    _quality = next;
    notifyListeners();
  }
}
