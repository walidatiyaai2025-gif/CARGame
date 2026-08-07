import 'package:cargo_sort_game/core/theme/three_d_game_icon.dart';
import 'package:cargo_sort_game/core/widgets/game_action_panel.dart';
import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title, subtitle, and 3D icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameActionPanel(
            icon: ThreeDIconType.gift,
            title: 'Daily reward',
            subtitle: '+50',
          ),
        ),
      ),
    );

    expect(find.text('Daily reward'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    expect(find.byType(ThreeDGameIcon), findsOneWidget);
  });

  testWidgets('forwards one tap to the guarded panel interaction', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameActionPanel(
            icon: ThreeDIconType.chest,
            title: 'Mission',
            subtitle: '2/3',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GameActionPanel));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('loading and error states replace action content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GameActionPanel(
                icon: ThreeDIconType.coin,
                title: 'Shop',
                subtitle: 'Upgrade',
                state: GamePanelState.loading,
              ),
              GameActionPanel(
                icon: ThreeDIconType.coin,
                title: 'Shop error',
                subtitle: 'Upgrade',
                state: GamePanelState.error,
                errorMessage: 'Shop unavailable',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Shop'), findsNothing);
    expect(find.text('Shop unavailable'), findsOneWidget);
  });
}
