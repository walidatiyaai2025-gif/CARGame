import 'package:cargo_sort_game/core/motion/game_action_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combo intensity is capped without truncating game combo state', () {
    expect(GameActionFeedback.comboIntensityFor(4), 4);
    expect(
      GameActionFeedback.comboIntensityFor(99),
      GameActionFeedback.maxComboIntensity,
    );
  });

  testWidgets('correct feedback completes once and exposes combo text', (
    tester,
  ) async {
    var completions = 0;
    final sounds = <(GameActionFeedbackKind, int)>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            GameActionFeedback(
              kind: GameActionFeedbackKind.correct,
              combo: 4,
              semanticLabel: 'Correct placement, combo 4',
              hapticsEnabled: false,
              onSound: (kind, intensity) => sounds.add((kind, intensity)),
              onCompleted: () => completions++,
            ),
          ],
        ),
      ),
    );

    expect(find.text('COMBO x4'), findsOneWidget);
    expect(find.bySemanticsLabel('Correct placement, combo 4'), findsOneWidget);
    expect(sounds, [(GameActionFeedbackKind.correct, 4)]);

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
              semanticLabel: 'Wrong placement',
              hapticsEnabled: false,
              onCompleted: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.textContaining('COMBO'), findsNothing);
  });

  testWidgets('reduced motion stays visible and completes without a ticker', (
    tester,
  ) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TickerMode(
            enabled: false,
            child: Stack(
              children: [
                GameActionFeedback(
                  kind: GameActionFeedbackKind.correct,
                  combo: 8,
                  semanticLabel: 'Correct placement, combo 8',
                  hapticsEnabled: false,
                  onCompleted: () => completions++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('COMBO x8'), findsOneWidget);
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 110));
    expect(completions, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposal cancels reduced-motion completion', (tester) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Stack(
            children: [
              GameActionFeedback(
                kind: GameActionFeedbackKind.correct,
                combo: 2,
                semanticLabel: 'Correct placement, combo 2',
                hapticsEnabled: false,
                onCompleted: () => completions++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 150));
    expect(completions, 0);
    expect(tester.takeException(), isNull);
  });
}
