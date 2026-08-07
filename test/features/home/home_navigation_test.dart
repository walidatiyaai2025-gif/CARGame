import 'package:cargo_sort_game/core/navigation/game_route_names.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
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

  testWidgets('Home uses stable shared route names for main destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final observedNames = <String?>[];
    final store = ProgressStore();
    final settings = AppSettingsStore();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [_RouteObserver(observedNames.add)],
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

    Future<void> expectRoute(Finder trigger, String expectedName) async {
      await tester.tap(trigger);
      await tester.pump();
      expect(observedNames.last, expectedName);
      Navigator.of(tester.element(find.byType(HomeScreen))).pop();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await expectRoute(find.byIcon(Icons.storefront_rounded), GameRouteNames.shop);
    await expectRoute(find.byIcon(Icons.insights_rounded), GameRouteNames.progress);
    await expectRoute(find.byIcon(Icons.article_outlined), GameRouteNames.logs);
    await expectRoute(find.byIcon(Icons.play_arrow_rounded), GameRouteNames.worldMap);

    expect(tester.takeException(), isNull);
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
