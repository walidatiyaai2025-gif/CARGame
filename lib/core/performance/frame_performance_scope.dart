import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'frame_performance_budget.dart';

class FramePerformanceScope extends StatefulWidget {
  const FramePerformanceScope({
    super.key,
    required this.child,
    this.controller,
    this.observeScheduler = true,
  });

  final Widget child;
  final FramePerformanceController? controller;
  final bool observeScheduler;

  static FramePerformanceController? maybeControllerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_FramePerformanceInherited>()
          ?.controller;

  static GameVisualQuality qualityOf(BuildContext context) =>
      maybeControllerOf(context)?.quality ?? GameVisualQuality.full;

  @override
  State<FramePerformanceScope> createState() => _FramePerformanceScopeState();
}

class _FramePerformanceScopeState extends State<FramePerformanceScope> {
  late FramePerformanceController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
    if (widget.observeScheduler) {
      SchedulerBinding.instance.addTimingsCallback(_handleFrameTimings);
    }
  }

  @override
  void didUpdateWidget(covariant FramePerformanceScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observeScheduler != widget.observeScheduler) {
      if (oldWidget.observeScheduler) {
        SchedulerBinding.instance.removeTimingsCallback(_handleFrameTimings);
      }
      if (widget.observeScheduler) {
        SchedulerBinding.instance.addTimingsCallback(_handleFrameTimings);
      }
    }

    if (!identical(oldWidget.controller, widget.controller)) {
      final previous = _controller;
      final disposePrevious = _ownsController;
      _bindController(widget.controller);
      if (disposePrevious) previous.dispose();
    }
  }

  @override
  void dispose() {
    if (widget.observeScheduler) {
      SchedulerBinding.instance.removeTimingsCallback(_handleFrameTimings);
    }
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _bindController(FramePerformanceController? controller) {
    _controller = controller ?? FramePerformanceController();
    _ownsController = controller == null;
  }

  void _handleFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _controller.recordFrameTiming(timing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FramePerformanceInherited(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _FramePerformanceInherited extends InheritedNotifier<FramePerformanceController> {
  const _FramePerformanceInherited({
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final FramePerformanceController controller;
}
