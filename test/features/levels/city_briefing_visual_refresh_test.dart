import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/core/widgets/game_fit_view.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/levels/city_briefing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('briefing exposes the premium mission-control hierarchy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = ProgressStore();
    final settings = AppSettingsStore();
    addTearDown(store.dispose);
    addTearDown(settings.dispose);
    await store.load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: CityBriefingScreen(
          level: levels.first,
          store: store,
          settings: settings,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MISSION CONTROL'), findsOneWidget);
    expect(find.text('DEPLOYMENT BRIEF'), findsOneWidget);
    expect(find.text('Mission Brief'), findsOneWidget);
    expect(find.text('Choose Mission Loadout'), findsOneWidget);
    expect(find.text('START MISSION'), findsOneWidget);
    expect(find.byType(GameFitView), findsOneWidget);
    expect(find.byType(GameButton), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
