import 'package:cargo_sort_game/core/theme/three_d_game_icon.dart';
import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:cargo_sort_game/core/widgets/game_stat_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders value label and optional 3D icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameStatPanel(
            value: '42',
            label: 'Stars',
            icon: ThreeDIconType.star,
          ),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Stars'), findsOneWidget);
    expect(find.byType(ThreeDGameIcon), findsOneWidget);
  });

  testWidgets('supports loading and error states through GamePanel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GameStatPanel(
                value: '0',
                label: 'Loading stat',
                state: GamePanelState.loading,
              ),
              GameStatPanel(
                value: '0',
                label: 'Failed stat',
                state: GamePanelState.error,
                errorMessage: 'Unable to load stat',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Unable to load stat'), findsOneWidget);
    expect(find.byType(GamePanel), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
