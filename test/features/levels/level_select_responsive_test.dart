import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/levels/capital_world_map.dart';
import 'package:cargo_sort_game/features/levels/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<ProgressStore> _store() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = ProgressStore();
  await store.load();
  return store;
}

Future<void> _pumpMap(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final store = await _store();
  final settings = AppSettingsStore();
  addTearDown(store.dispose);
  addTearDown(settings.dispose);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: LevelSelectScreen(store: store, settings: settings),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('world map is overflow-free on a narrow phone', (tester) async {
    await _pumpMap(
      tester,
      size: const Size(360, 640),
      locale: const Locale('en'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('World Map'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(CapitalWorldMap), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('world map mirrors safely for Arabic RTL', (tester) async {
    await _pumpMap(
      tester,
      size: const Size(412, 915),
      locale: const Locale('ar'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('خريطة العالم'), findsOneWidget);
    expect(find.text('تحدي عواصم العالم'), findsOneWidget);
    expect(find.text('لشبونة'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('خريطة العالم'))),
      TextDirection.rtl,
    );
  });

  testWidgets('world map survives large text on a tablet', (tester) async {
    await _pumpMap(
      tester,
      size: const Size(1024, 1366),
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('World Capitals Challenge'), findsOneWidget);
    expect(find.byType(CapitalWorldMap), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
