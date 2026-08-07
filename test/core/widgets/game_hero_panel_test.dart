import 'package:cargo_sort_game/core/widgets/game_hero_panel.dart';
import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 360, child: child),
      ),
    ),
  );

  testWidgets('renders title, subtitle, progress and body', (tester) async {
    await tester.pumpWidget(
      host(
        const GameHeroPanel(
          title: 'Player Level',
          subtitle: 'Level 4',
          progress: .42,
          progressLabel: 'XP progress',
          body: Text('210/500 XP'),
        ),
      ),
    );

    expect(find.text('Player Level'), findsOneWidget);
    expect(find.text('Level 4'), findsOneWidget);
    expect(find.text('XP progress'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('210/500 XP'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('supports tap semantics', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        GameHeroPanel(
          title: 'Journey',
          semanticLabel: 'Open journey',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(GameHeroPanel));
    await tester.pump();
    expect(taps, 1);
    expect(find.bySemanticsLabel('Open journey'), findsOneWidget);
  });

  testWidgets('forwards loading and error states to GamePanel', (tester) async {
    await tester.pumpWidget(
      host(
        const GameHeroPanel(
          title: 'Loading hero',
          state: GamePanelState.loading,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Loading hero'), findsOneWidget);

    await tester.pumpWidget(
      host(
        const GameHeroPanel(
          title: 'Error hero',
          state: GamePanelState.error,
          errorMessage: 'Hero unavailable',
        ),
      ),
    );
    expect(find.text('Hero unavailable'), findsOneWidget);
  });
}
