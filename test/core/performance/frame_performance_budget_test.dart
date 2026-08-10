import 'package:cargo_sort_game/core/performance/frame_performance_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FramePerformancePolicy', () {
    test('defines an explicit 60 Hz target budget', () {
      const policy = FramePerformancePolicy.mobile60Hz;

      expect(policy.targetFps, 60);
      expect(policy.targetFrameBudget.inMicroseconds, inInclusiveRange(16666, 16667));
      expect(policy.jankFrameBudget, const Duration(milliseconds: 24));
      expect(policy.severeFrameBudget, const Duration(milliseconds: 34));
    });
  });

  group('FramePerformanceController', () {
    test('keeps rolling history strictly bounded', () {
      const policy = FramePerformancePolicy(
        windowSize: 5,
        minimumSamples: 5,
        evaluationStride: 5,
      );
      final controller = FramePerformanceController(policy: policy);

      for (var index = 0; index < 20; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 16));
      }

      expect(controller.sampleCount, 5);
      expect(controller.totalFrames, 20);
      expect(controller.snapshot.sampleCount, 5);
    });

    test('one isolated bad frame does not degrade visual quality', () {
      final controller = FramePerformanceController();

      for (var index = 0; index < 29; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 16));
      }
      controller.recordFrameDuration(const Duration(milliseconds: 40));

      expect(controller.quality, GameVisualQuality.full);
      expect(controller.snapshot.jankRatio, closeTo(1 / 30, 0.001));
    });

    test('sustained pressure degrades one level per evaluation window', () {
      const policy = FramePerformancePolicy(
        windowSize: 10,
        minimumSamples: 5,
        evaluationStride: 5,
        degradeJankRatio: .2,
        degradeSevereRatio: .2,
      );
      final controller = FramePerformanceController(policy: policy);

      for (var index = 0; index < 5; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 40));
      }
      expect(controller.quality, GameVisualQuality.constrained);

      for (var index = 0; index < 5; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 40));
      }
      expect(controller.quality, GameVisualQuality.reduced);
    });

    test('recovery is conservative and occurs one level at a time', () {
      const policy = FramePerformancePolicy(
        windowSize: 5,
        minimumSamples: 5,
        evaluationStride: 5,
        degradeJankRatio: .2,
        degradeSevereRatio: .2,
        recoverJankRatio: 0,
        healthyWindowsToRecover: 2,
      );
      final controller = FramePerformanceController(policy: policy);

      for (var index = 0; index < 10; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 40));
      }
      expect(controller.quality, GameVisualQuality.reduced);

      for (var index = 0; index < 5; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 16));
      }
      expect(controller.quality, GameVisualQuality.reduced);
      expect(controller.snapshot.healthyWindows, 1);

      for (var index = 0; index < 5; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 16));
      }
      expect(controller.quality, GameVisualQuality.constrained);

      for (var index = 0; index < 10; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 16));
      }
      expect(controller.quality, GameVisualQuality.full);
    });

    test('neutral windows reset recovery hysteresis', () {
      const policy = FramePerformancePolicy(
        windowSize: 5,
        minimumSamples: 5,
        evaluationStride: 5,
        degradeJankRatio: .4,
        degradeSevereRatio: .4,
        recoverJankRatio: 0,
        healthyWindowsToRecover: 2,
      );
      final controller = FramePerformanceController(policy: policy);

      for (var index = 0; index < 5; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 40));
      }
      expect(controller.quality, GameVisualQuality.constrained);

      for (var index = 0; index < 5; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 16));
      }
      expect(controller.snapshot.healthyWindows, 1);

      controller.recordFrameDuration(const Duration(milliseconds: 25));
      for (var index = 0; index < 4; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 16));
      }
      expect(controller.snapshot.healthyWindows, 0);
      expect(controller.quality, GameVisualQuality.constrained);
    });

    test('snapshot exposes deterministic bounded diagnostics', () {
      const policy = FramePerformancePolicy(
        windowSize: 4,
        minimumSamples: 4,
        evaluationStride: 4,
        degradeJankRatio: 1,
        degradeSevereRatio: 1,
      );
      final controller = FramePerformanceController(policy: policy);

      for (final duration in <Duration>[
        const Duration(milliseconds: 10),
        const Duration(milliseconds: 20),
        const Duration(milliseconds: 30),
        const Duration(milliseconds: 40),
      ]) {
        controller.recordFrameDuration(duration);
      }

      final snapshot = controller.snapshot;
      expect(snapshot.averageFrame, const Duration(milliseconds: 25));
      expect(snapshot.worstFrame, const Duration(milliseconds: 40));
      expect(snapshot.jankRatio, .5);
      expect(snapshot.severeJankRatio, .25);
      expect(snapshot.totalFrames, 4);
    });

    test('negative durations are ignored', () {
      final controller = FramePerformanceController();

      controller.recordFrameDuration(const Duration(microseconds: -1));

      expect(controller.totalFrames, 0);
      expect(controller.sampleCount, 0);
    });

    test('clearing history does not silently reset quality by default', () {
      const policy = FramePerformancePolicy(
        windowSize: 5,
        minimumSamples: 5,
        evaluationStride: 5,
        degradeJankRatio: .2,
        degradeSevereRatio: .2,
      );
      final controller = FramePerformanceController(policy: policy);
      for (var index = 0; index < 5; index++) {
        controller.recordFrameDuration(const Duration(milliseconds: 40));
      }

      controller.clearHistory();

      expect(controller.sampleCount, 0);
      expect(controller.quality, GameVisualQuality.constrained);
    });
  });
}
