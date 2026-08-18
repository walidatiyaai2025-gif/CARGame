import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/levels/city_briefing_screen.dart';
import 'package:cargo_sort_game/features/levels/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'unlocked capital opens briefing through named shared game route',
    (tester) async {
      final pushedRouteNames = <String?>[];
      final store = ProgressStore();
      final settings = AppSettingsStore();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [_RouteObserver(pushedRouteNames.add)],
          home: LevelSelectScreen(store: store, settings: settings),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lisbon'), findsWidgets);
      expect(find.text('Portugal'), findsWidgets);

      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pump(const Duration(milliseconds: 300));

      final startMissionFinder = find.byType(GameButton);
      expect(startMissionFinder, findsOneWidget);
      expect(find.text('START MISSION'), findsOneWidget);

      final startMission = tester.widget<GameButton>(startMissionFinder);
      expect(startMission.onPressed, isNotNull);
      startMission.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(pushedRouteNames, contains('/briefing/level/1'));
      expect(find.byType(CityBriefingScreen), findsOneWidget);
    },
  );
}

final class _RouteObserver extends NavigatorObserver {
  _RouteObserver(this.onPush);

  final ValueChanged<String?> onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPush(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
