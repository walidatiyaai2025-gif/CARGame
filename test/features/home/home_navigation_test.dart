import 'package:cargo_sort_game/core/navigation/game_route_names.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/home/home_screen.dart';
import 'package:cargo_sort_game/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
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

      for (var attempt = 0; attempt < 10; attempt++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (observedNames.isNotEmpty && observedNames.last == expectedName) {
          break;
        }
      }

      expect(observedNames.last, expectedName);
      Navigator.of(tester.element(find.byType(HomeScreen))).pop();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await expectRoute(find.byType(GameButton), GameRouteNames.worldMap);
    await expectRoute(
      find.byIcon(Icons.storefront_rounded),
      GameRouteNames.shop,
    );
    await expectRoute(
      find.byIcon(Icons.insights_rounded),
      GameRouteNames.progress,
    );
    await expectRoute(find.byIcon(Icons.article_outlined), GameRouteNames.logs);

    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated Start action opens the journey route only once', (
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

    final startFinder = find.byType(GameButton);
    expect(startFinder, findsOneWidget);
    final startButton = tester.widget<GameButton>(startFinder);
    expect(startButton.onPressed, isNotNull);

    final firstAction = Future<void>.sync(() async {
      await startButton.onPressed!.call();
    });
    final secondAction = Future<void>.sync(() async {
      await startButton.onPressed!.call();
    });

    await tester.pump(const Duration(milliseconds: 50));
    expect(
      observedNames.where((name) => name == GameRouteNames.worldMap).length,
      1,
    );

    Navigator.of(tester.element(find.byType(HomeScreen))).pop();
    await tester.pump(const Duration(milliseconds: 400));
    await Future.wait([firstAction, secondAction]);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      observedNames.where((name) => name == GameRouteNames.worldMap).length,
      1,
    );
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
