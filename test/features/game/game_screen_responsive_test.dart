import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/game/game_screen.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _NoopAdService extends AdService {
  @override
  void preload() {}

  @override
  void showInterstitial() {}

  @override
  bool showRewarded({required void Function() onReward}) => false;
}

Future<ProgressStore> _store() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = ProgressStore();
  await store.load();
  return store;
}

Future<void> _pumpGame(
  WidgetTester tester, {
  required Size size,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final store = await _store();
  addTearDown(store.dispose);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          viewPadding: padding,
          textScaler: textScaler,
        ),
        child: GameScreen(
          level: levels.first,
          store: store,
          adService: _NoopAdService(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gameplay initial state is overflow-free on a narrow phone', (
    tester,
  ) async {
    await _pumpGame(tester, size: const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('gameplay survives large text on a tablet', (tester) async {
    await _pumpGame(
      tester,
      size: const Size(1024, 1366),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('gameplay derives RTL from the Arabic locale on a tall phone', (
    tester,
  ) async {
    await _pumpGame(
      tester,
      size: const Size(412, 915),
      locale: const Locale('ar'),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(GameScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('gameplay respects cutout safe areas without overflow', (
    tester,
  ) async {
    await _pumpGame(
      tester,
      size: const Size(412, 915),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
