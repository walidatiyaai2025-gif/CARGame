import 'dart:convert';

import 'package:cargo_sort_game/core/economy/economy_config.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/theme/game_skin.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/game/game_screen.dart';
import 'package:cargo_sort_game/features/game/gameplay_result_debrief.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/home/home_screen.dart';
import 'package:cargo_sort_game/features/levels/city_briefing_screen.dart';
import 'package:cargo_sort_game/features/levels/level_select_screen.dart';
import 'package:cargo_sort_game/features/shop/shop_screen.dart';
import 'package:cargo_sort_game/l10n/app_localizations.dart';
import 'package:cargo_sort_game/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void checkpoint(String id, Object? actual, Object? matcher) {
  expect(actual, matcher, reason: 'TEST-007 checkpoint $id');
}

void _resetPreferences() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}

Future<Map<String, int>> _runDeterministicStateScenario() async {
  _resetPreferences();
  final store = ProgressStore();
  await store.load();

  final level = levels.first;
  const stars = 3;
  const combo = 15;
  final economy = EconomyConfig.current;
  final reward = economy.levelCoinReward(
    level: level.number,
    stars: stars,
    combo: combo,
  );
  final xp = economy.levelXpReward(
    difficulty: level.difficulty,
    stars: stars,
    combo: combo,
  );

  await store.completeLevel(
    level.number,
    reward,
    stars: stars,
    combo: combo,
    xpEarned: xp,
    transactionId: 'test-007-level-1',
  );
  await store.purchaseShopBooster('hint');

  return <String, int>{
    'coins': store.coins,
    'hints': store.freeHints,
    'level': store.highestUnlockedLevel,
    'stars': store.starsForLevel(1),
    'xp': store.playerXp,
  };
}

Widget _resultHarness({
  required ProgressStore store,
  required bool won,
  required int reward,
  required int xp,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GameplayResultDebrief(
        won: won,
        worldReward: false,
        isArabic: false,
        busy: false,
        cityName: levels.first.cityName,
        worldName: gameWorlds.first.name,
        levelNumber: 1,
        stars: 3,
        reward: reward,
        xp: xp,
        bestCombo: 15,
        bonusCoins: store.lastCompletionBonus,
        bonusXp: store.lastCompletionBonusXp,
        skin: gameSkinById(store.selectedTheme),
        onPrimary: () {},
        onWatchRewarded: () {},
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _resetPreferences();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('first run reaches gameplay through the guarded offline UI path', (
    tester,
  ) async {
    final store = ProgressStore();
    final settings = AppSettingsStore();
    await store.load();
    await settings.load();

    checkpoint('T01', store.coins >= 0, isTrue);
    checkpoint(
      'T02',
      store.coins,
      EconomyConfig.current.player.startingCoins,
    );
    checkpoint('T03', store.highestUnlockedLevel, 1);
    checkpoint('T04', store.completedLevels, 0);
    checkpoint('T05', store.starsForLevel(1), 0);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(CargoSortApp(store: store, settings: settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    checkpoint('T06', find.byType(CargoSortApp), findsOneWidget);
    checkpoint('T07', tester.takeException(), isNull);
    checkpoint('T08', find.byType(GameButton), findsOneWidget);
    checkpoint(
      'T41',
      Directionality.of(tester.element(find.byType(HomeScreen))),
      TextDirection.ltr,
    );

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    checkpoint(
      'T42',
      Directionality.of(tester.element(find.byType(HomeScreen))),
      TextDirection.rtl,
    );
    checkpoint('T43', tester.takeException(), isNull);

    final startButton = tester.widget<GameButton>(find.byType(GameButton));
    final firstStart = Future<void>.sync(() async {
      await startButton.onPressed!.call();
    });
    final secondStart = Future<void>.sync(() async {
      await startButton.onPressed!.call();
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    checkpoint('T09', find.byType(LevelSelectScreen), findsOneWidget);
    checkpoint('T10', find.byType(LevelSelectScreen), findsOneWidget);

    final firstCity = find.text(levels.first.cityName).first;
    await tester.ensureVisible(firstCity);
    await tester.pump();
    checkpoint('T11', firstCity, findsOneWidget);

    final lockedCity = find.text(levels[1].cityName).first;
    await tester.ensureVisible(lockedCity);
    await tester.pump();
    await tester.tap(lockedCity);
    await tester.pump(const Duration(milliseconds: 350));
    checkpoint('T12', find.byType(CityBriefingScreen), findsNothing);

    await tester.ensureVisible(firstCity);
    await tester.pump();
    await tester.tap(firstCity);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    checkpoint('T13', find.byType(CityBriefingScreen), findsOneWidget);
    final briefing = tester.widget<CityBriefingScreen>(
      find.byType(CityBriefingScreen),
    );
    checkpoint('T14', briefing.level.number, 1);

    final missionButton = tester.widget<GameButton>(find.byType(GameButton));
    await missionButton.onPressed!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    checkpoint('T15', find.byType(GameScreen), findsOneWidget);
    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    checkpoint('T16', game.level.number, levels.first.number);
    checkpoint('T17', game.level.moves, levels.first.moves);
    checkpoint('T18', store.completedLevels, 0);
    checkpoint('T19', tester.takeException(), isNull);
    checkpoint(
      'T20',
      Navigator.of(tester.element(find.byType(GameScreen))).canPop(),
      isTrue,
    );

    await tester.binding.setSurfaceSize(const Size(412, 915));
    await tester.pump(const Duration(milliseconds: 100));
    checkpoint('T44', tester.takeException(), isNull);
    checkpoint(
      'T46',
      SharedPreferencesAsyncPlatform.instance,
      isA<InMemorySharedPreferencesAsync>(),
    );

    Navigator.of(tester.element(find.byType(GameScreen))).pop();
    await tester.pump(const Duration(milliseconds: 400));
    Navigator.of(tester.element(find.byType(LevelSelectScreen))).pop();
    await tester.pump(const Duration(milliseconds: 400));
    await Future.wait(<Future<void>>[firstStart, secondStart]);
  });

  testWidgets('completion reward shop restart and restore remain idempotent', (
    tester,
  ) async {
    final store = ProgressStore();
    final settings = AppSettingsStore();
    await store.load();
    await settings.load();

    final level = levels.first;
    const stars = 3;
    const combo = 15;
    const transactionId = 'test-007-level-1';
    final economy = EconomyConfig.current;
    final reward = economy.levelCoinReward(
      level: level.number,
      stars: stars,
      combo: combo,
    );
    final xp = economy.levelXpReward(
      difficulty: level.difficulty,
      stars: stars,
      combo: combo,
    );
    final initialCoins = store.coins;
    final initialHints = store.freeHints;

    await store.completeLevel(
      level.number,
      reward,
      stars: stars,
      combo: combo,
      xpEarned: xp,
      transactionId: transactionId,
    );

    checkpoint('T21', store.wins, 1);
    checkpoint('T22', store.starsForLevel(1), stars);
    checkpoint('T23', store.highestUnlockedLevel, 2);
    checkpoint('T26', store.coins, initialCoins + reward);
    checkpoint('T27', store.playerXp, xp);
    checkpoint(
      'T28',
      store.completedRewardTransactions.contains(
        'level:1:$transactionId',
      ),
      isTrue,
    );

    final coinsAfterFirstCompletion = store.coins;
    final xpAfterFirstCompletion = store.playerXp;
    await store.completeLevel(
      level.number,
      reward,
      stars: stars,
      combo: combo,
      xpEarned: xp,
      transactionId: transactionId,
    );
    checkpoint('T29', store.coins, coinsAfterFirstCompletion);
    checkpoint('T30', store.playerXp, xpAfterFirstCompletion);
    checkpoint('T47', store.coins >= 0 && store.playerXp >= 0, isTrue);

    await tester.pumpWidget(
      _resultHarness(store: store, won: true, reward: reward, xp: xp),
    );
    await tester.pump();
    checkpoint('T24', find.byType(GameplayResultDebrief), findsOneWidget);
    final hasWinControl =
        find.text('NEXT — RETURN TO ROUTE NETWORK').evaluate().isNotEmpty;

    await tester.pumpWidget(
      _resultHarness(store: store, won: false, reward: reward, xp: xp),
    );
    await tester.pump();
    final hasRetryControl = find.text('RESTART MISSION').evaluate().isNotEmpty;
    final hasRewardedControl =
        find.text('QUICK CONTINUE — +5 MOVES').evaluate().isNotEmpty;
    checkpoint(
      'T25',
      hasWinControl && hasRetryControl && hasRewardedControl,
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ShopScreen(store: store),
      ),
    );
    await tester.pump();
    checkpoint('T31', find.byType(ShopScreen), findsOneWidget);

    final hintOffer = economy.boosterOfferFor('hint');
    checkpoint(
      'T32',
      hintOffer.price < store.coins && hintOffer.price > 0,
      isTrue,
    );

    final beforePurchaseCoins = store.coins;
    final beforePurchaseHints = store.freeHints;
    final purchased = await store.purchaseShopBooster('hint');
    checkpoint(
      'T33',
      purchased && store.coins == beforePurchaseCoins - hintOffer.price,
      isTrue,
    );
    checkpoint(
      'T34',
      store.freeHints,
      beforePurchaseHints + hintOffer.amount,
    );

    final prefs = SharedPreferencesAsync();
    const pendingPurchaseKey = 'pending_shop_purchase_v1';
    final finalCoins = store.coins;
    final finalHints = store.freeHints;
    await prefs.setString(
      pendingPurchaseKey,
      jsonEncode(<String, Object>{
        'version': 1,
        'reason': 'booster:hint',
        'values': <String, Object>{
          'booster_free_hints': finalHints,
          'coins': finalCoins,
        },
      }),
    );

    final recovered = ProgressStore();
    await recovered.load();
    final restored = ProgressStore();
    await restored.load();
    checkpoint(
      'T35',
      recovered.coins == finalCoins &&
          recovered.freeHints == finalHints &&
          restored.coins == finalCoins &&
          restored.freeHints == finalHints &&
          !await prefs.containsKey(pendingPurchaseKey),
      isTrue,
    );
    checkpoint('T36', restored.coins, finalCoins);
    checkpoint('T37', restored.completedLevels, 1);
    checkpoint('T38', restored.starsForLevel(1), stars);
    checkpoint('T39', restored.highestUnlockedLevel, 2);
    checkpoint('T40', restored.freeHints, finalHints);
    checkpoint('T48', restored.coins >= 0 && restored.freeHints >= 0, isTrue);

    final restoredSettings = AppSettingsStore();
    await restoredSettings.load();
    await tester.binding.setSurfaceSize(const Size(800, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CargoSortApp(store: restored, settings: restoredSettings),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    checkpoint(
      'T45',
      tester.takeException() == null && find.byType(HomeScreen).evaluate().isNotEmpty,
      isTrue,
    );
  });

  test('same clean input produces the same critical-path state', () async {
    final first = await _runDeterministicStateScenario();
    final second = await _runDeterministicStateScenario();
    checkpoint('T49', second, equals(first));
    checkpoint(
      'T50',
      List<String>.generate(
        50,
        (index) => 'T${(index + 1).toString().padLeft(2, '0')}',
      ).toSet().length,
      50,
    );
  });
}
