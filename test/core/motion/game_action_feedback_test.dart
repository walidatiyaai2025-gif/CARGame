import 'package:cargo_sort_game/core/motion/game_action_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('correct feedback completes once and exposes combo text', (
    tester,
  ) async {
    var completions = 0;
    var sounds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            GameActionFeedback(
              kind: GameActionFeedbackKind.correct,
              combo: 4,
              onSound: () => sounds++,
              onCompleted: () => completions++,
            ),
          ],
        ),
      ),
    );

    expect(find.text('COMBO x4'), findsOneWidget);
    expect(sounds, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(completions, 1);
  });

  testWidgets('wrong feedback renders without combo text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            GameActionFeedback(
              kind: GameActionFeedbackKind.wrong,
              combo: 0,
              onCompleted: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.textContaining('COMBO'), findsNothing);
  });

  testWidgets('reduced motion completes after one frame without ticker leak', (
    tester,
  ) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Stack(
            children: [
              GameActionFeedback(
                kind: GameActionFeedbackKind.correct,
                combo: 8,
                onCompleted: () => completions++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(completions, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
