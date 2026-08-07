import 'package:cargo_sort_game/core/theme/three_d_game_icon.dart';
import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:cargo_sort_game/core/widgets/game_resource_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders 3D icon, value, and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameResourcePanel(
            icon: ThreeDIconType.coin,
            value: '1250',
            label: 'Coins',
          ),
        ),
      ),
    );

    expect(find.byType(ThreeDGameIcon), findsOneWidget);
    expect(find.text('1250'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('interactive panel forwards a single tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameResourcePanel(
            icon: ThreeDIconType.star,
            value: '3',
            label: 'Stars',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GameResourcePanel));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('loading and error states replace resource content safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GameResourcePanel(
                icon: ThreeDIconType.heart,
                value: '5',
                label: 'Hearts',
                state: GamePanelState.loading,
              ),
              GameResourcePanel(
                icon: ThreeDIconType.coin,
                value: '0',
                label: 'Coins',
                state: GamePanelState.error,
                errorMessage: 'Wallet unavailable',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Wallet unavailable'), findsOneWidget);
    expect(find.text('Hearts'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
