import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_action_panel.dart';
import 'package:cargo_sort_game/core/widgets/game_resource_panel.dart';
import 'package:cargo_sort_game/features/home/home_screen.dart';
import 'package:cargo_sort_game/l10n/app_localizations.dart';
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

  testWidgets('home uses shared resource/action panels without adding scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = ProgressStore();
    final settings = AppSettingsStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(
          store: store,
          settings: settings,
          onToggleLanguage: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GameResourcePanel), findsNWidgets(3));
    expect(find.byType(GameActionPanel), findsNWidgets(3));
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
