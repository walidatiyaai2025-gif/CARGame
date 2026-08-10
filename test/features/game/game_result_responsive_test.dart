import 'dart:math';

import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/motion/game_action_feedback.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/game/game_screen.dart';
import 'package:cargo_sort_game/features/game/gameplay_result_debrief.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loss result stays reachable and blocks back on compact phone', (
    tester,
  ) async {
    await _pumpLossResult(
      tester,
      size: const Size(360, 640),
      locale: const Locale('en'),
    );

    final retry = find.bySemanticsLabel('Retry');
    expect(tester.takeException(), isNull);
    expect(retry, findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(retry, findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('loss result uses Arabic locale and RTL on a reference phone', (
    tester,
  ) async {
    await _pumpLossResult(
      tester,
      size: const Size(412, 915),
      locale: const Locale('ar'),
    );

    final retry = find.bySemanticsLabel('إعادة المحاولة');
    expect(tester.takeException(), isNull);
    expect(retry, findsOneWidget);
    expect(find.text('خيارات الاستمرار'), findsOneWidget);
    expect(find.byType(GameplayResultDebrief), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(GameplayResultDebrief))),
      TextDirection.rtl,
    );
  });

  testWidgets('loss result remains reachable on a tablet with large text', (
    tester,
  ) async {
    await _pumpLossResult(
      tester,
      size: const Size(1024, 1366),
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GameplayResultDebrief), findsOneWidget);
    expect(find.bySemanticsLabel('Retry'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

Future<void> _pumpLossResult(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = ProgressStore();
  await store.load();
  addTearDown(store.dispose);

  final first = productCatalog[0];
  final second = productCatalog[1];
  final level = LevelData(
    number: 1,
    world: 1,
    moves: 1,
    items: [first, second],
    difficulty: 1,
  );
  final shuffled = [...level.items]..shuffle(Random(level.number * 41));
  final selected = shuffled.first;
  final wrongWarehouse = selected.id == first.id ? second : first;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: GameScreen(
          level: level,
          store: store,
          adService: _NoopAdService(),
          hapticsEnabled: false,
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.byKey(ValueKey('cargo-${selected.id}-0')));
  await tester.pump();

  final warehouse = find.byKey(ValueKey('warehouse-${wrongWarehouse.id}'));
  final viewport = Offset.zero & size;
  final target = tester.getRect(warehouse).intersect(viewport);
  expect(target.isEmpty, isFalse);
  await tester.tapAt(target.center);

  await _pumpUntil(tester, find.byType(GameActionFeedback));
  await _pumpUntilAbsent(tester, find.byType(GameActionFeedback));
  await _pumpUntil(tester, find.byType(GameplayResultDebrief));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 50,
}) async {
  for (var attempt = 0; attempt < maxPumps; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  expect(finder, findsWidgets);
}

Future<void> _pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 50,
}) async {
  for (var attempt = 0; attempt < maxPumps; attempt++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(step);
  }
  expect(finder, findsNothing);
}

final class _NoopAdService extends AdService {
  @override
  void preload() {}

  @override
  void dispose() {}

  @override
  bool showRewarded({required void Function() onReward}) => false;
}
