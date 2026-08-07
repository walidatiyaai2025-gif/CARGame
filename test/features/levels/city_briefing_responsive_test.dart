import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_fit_view.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/levels/city_briefing_screen.dart';
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

Future<void> _pumpBriefing(
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
        child: CityBriefingScreen(
          level: levels.first,
          store: store,
          settings: settings,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('briefing stays bounded without scroll on a narrow phone', (
    tester,
  ) async {
    await _pumpBriefing(
      tester,
      size: const Size(360, 640),
      locale: const Locale('en'),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GameFitView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Choose Mission Loadout'), findsOneWidget);
  });

  testWidgets('briefing preserves Arabic RTL on a tall phone', (tester) async {
    await _pumpBriefing(
      tester,
      size: const Size(412, 915),
      locale: const Locale('ar'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('اختر تجهيزات المهمة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('اختر تجهيزات المهمة'))),
      TextDirection.rtl,
    );
  });

  testWidgets('briefing survives large text on a tablet', (tester) async {
    await _pumpBriefing(
      tester,
      size: const Size(1024, 1366),
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GameFitView), findsOneWidget);
    expect(find.text('Choose Mission Loadout'), findsOneWidget);
  });
}
