import 'package:cargo_sort_game/core/motion/motion_lifecycle_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('enables tickers while app is resumed', (tester) async {
    late bool enabled;
    await tester.pumpWidget(
      MaterialApp(
        home: MotionLifecycleScope(
          child: Builder(
            builder: (context) {
              enabled = TickerMode.valuesOf(context).enabled;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(enabled, isTrue);
  });

  testWidgets('disables tickers when app is paused and resumes safely', (
    tester,
  ) async {
    bool? enabled;
    await tester.pumpWidget(
      MaterialApp(
        home: MotionLifecycleScope(
          child: Builder(
            builder: (context) {
              enabled = TickerMode.valuesOf(context).enabled;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(enabled, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(enabled, isTrue);
  });

  testWidgets('respects reduced motion and ancestor ticker mode', (
    tester,
  ) async {
    late bool enabled;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TickerMode(
            enabled: true,
            child: MotionLifecycleScope(
              child: Builder(
                builder: (context) {
                  enabled = TickerMode.valuesOf(context).enabled;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(enabled, isFalse);
  });
}
