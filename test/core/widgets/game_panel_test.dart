import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ready interactive panel exposes button semantics and taps once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GamePanel(
            semanticLabel: 'Open reward',
            onTap: () => taps++,
            child: const Text('Reward'),
          ),
        ),
      ),
    );

    expect(find.text('Reward'), findsOneWidget);
    expect(find.bySemanticsLabel('Open reward'), findsOneWidget);

    await tester.tap(find.text('Reward'));
    await tester.pump(const Duration(milliseconds: 180));

    expect(taps, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('loading panel replaces content with bounded skeleton', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: GamePanel(
              state: GamePanelState.loading,
              minHeight: 90,
              child: Text('Hidden while loading'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Hidden while loading'), findsNothing);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error panel is visible, bounded, and cannot trigger tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: GamePanel(
              state: GamePanelState.error,
              errorMessage: 'Cargo data unavailable',
              onTap: () => taps++,
              child: const Text('Hidden'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cargo data unavailable'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);

    await tester.tap(find.text('Cargo data unavailable'));
    await tester.pump();

    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });
}
