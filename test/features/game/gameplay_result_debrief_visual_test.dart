import 'package:cargo_sort_game/core/theme/game_skin.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/game/gameplay_result_debrief.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('winning debrief exposes premium reward hierarchy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameplayResultDebrief(
            won: true,
            worldReward: false,
            isArabic: false,
            busy: false,
            cityName: 'Central Depot',
            worldName: 'Starter Depot',
            levelNumber: 1,
            stars: 3,
            reward: 120,
            xp: 45,
            bestCombo: 4,
            bonusCoins: 20,
            bonusXp: 10,
            skin: gameSkins.first,
            onPrimary: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MISSION DEBRIEF'), findsOneWidget);
    expect(find.text('ROUTE SECURED'), findsOneWidget);
    expect(find.text('REWARD MANIFEST'), findsOneWidget);
    expect(find.text('CARGO BAY'), findsNothing);
    expect(find.bySemanticsLabel('Next and back to map'), findsOneWidget);
    expect(find.byType(GameButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loss debrief preserves recovery controls on compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameplayResultDebrief(
            won: false,
            worldReward: false,
            isArabic: false,
            busy: false,
            cityName: 'Central Depot',
            worldName: 'Starter Depot',
            levelNumber: 1,
            stars: 0,
            reward: 0,
            xp: 0,
            bestCombo: 1,
            bonusCoins: 0,
            bonusXp: 0,
            skin: gameSkins.first,
            onWatchRewarded: () {},
            onPrimary: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MISSION INTERRUPTED'), findsOneWidget);
    expect(find.text('RECOVERY OPTIONS'), findsOneWidget);
    expect(find.bySemanticsLabel('Watch ad for five moves'), findsOneWidget);
    expect(find.bySemanticsLabel('Retry'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(GameButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
