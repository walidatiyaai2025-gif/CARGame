import 'package:cargo_sort_game/core/motion/game_travel_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('travel completes exactly once', (tester) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GameTravelMotion(
                start: const Offset(30, 40),
                end: const Offset(240, 300),
                size: 48,
                onCompleted: () => completions++,
                child: const ColoredBox(
                  key: ValueKey('travelling-cargo'),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('travelling-cargo')), findsOneWidget);
    expect(completions, 0);

    await tester.pump(const Duration(milliseconds: 240));
    expect(completions, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
  });

  testWidgets('reduced motion keeps brief completion feedback', (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TickerMode(
            enabled: false,
            child: Scaffold(
              body: Stack(
                children: [
                  GameTravelMotion(
                    start: const Offset(20, 20),
                    end: const Offset(200, 200),
                    size: 40,
                    onCompleted: () => completed = true,
                    child: const ColoredBox(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(completed, isTrue);
  });
}
