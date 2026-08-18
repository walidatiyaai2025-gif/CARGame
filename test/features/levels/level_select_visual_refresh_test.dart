import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/levels/capital_world_map.dart';
import 'package:cargo_sort_game/features/levels/level_select_screen.dart';
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

  testWidgets('world map exposes the real capital campaign hierarchy', (
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
        home: LevelSelectScreen(store: store, settings: settings),
      ),
    );
    await tester.pump();

    expect(find.text('World Map'), findsOneWidget);
    expect(find.text('150 COUNTRIES & CAPITALS'), findsOneWidget);
    expect(find.text('World Capitals Challenge'), findsOneWidget);
    expect(find.text('Western Europe'), findsWidgets);
    expect(find.text('Lisbon'), findsWidgets);
    expect(find.text('Portugal'), findsWidgets);
    expect(find.text('START MISSION'), findsOneWidget);
    expect(find.byType(CapitalWorldMap), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
