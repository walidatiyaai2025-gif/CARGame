import 'package:flutter/material.dart';

/// Disables descendant tickers whenever the app is not resumed, the subtree is
/// hidden by an ancestor [TickerMode], or the platform requests reduced motion.
class MotionLifecycleScope extends StatefulWidget {
  const MotionLifecycleScope({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<MotionLifecycleScope> createState() => _MotionLifecycleScopeState();
}

class _MotionLifecycleScopeState extends State<MotionLifecycleScope>
    with WidgetsBindingObserver {
  AppLifecycleState _lifecycleState =
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lifecycleState == state || !mounted) {
      return;
    }
    setState(() => _lifecycleState = state);
  }

  @override
  Widget build(BuildContext context) {
    final ancestorEnabled = TickerMode.of(context);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final active =
        widget.enabled &&
        ancestorEnabled &&
        !reducedMotion &&
        _lifecycleState == AppLifecycleState.resumed;

    return TickerMode(enabled: active, child: widget.child);
  }
}
