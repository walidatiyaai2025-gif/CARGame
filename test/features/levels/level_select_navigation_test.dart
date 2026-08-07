import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/game/city_catalog.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/levels/city_briefing_screen.dart';
import 'package:cargo_sort_game/features/levels/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unlocked city opens briefing through named shared game route', (
    tester,
  ) async {
    String? pushedRouteName;
    final store = ProgressStore();
    final settings = AppSettingsStore();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [
          _RouteObserver((name) => pushedRouteName = name),
        ],
        home: LevelSelectScreen(store: store, settings: settings),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final firstCity = levels.first.cityName;
    expect(find.text(firstCity), findsOneWidget);

    await tester.tap(find.text(firstCity));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(pushedRouteName, '/briefing/level/1');
    expect(find.byType(CityBriefingScreen), findsOneWidget);
  });
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
