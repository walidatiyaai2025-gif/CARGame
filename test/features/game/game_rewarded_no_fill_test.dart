import 'dart:math';

import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/motion/game_action_feedback.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/game/game_screen.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rewarded no-fill keeps the loss result and Retry available', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = ProgressStore();
    await store.load();
    addTearDown(store.dispose);

    final ads = _UnavailableRewardedAdService();
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
        home: GameScreen(
          level: level,
          store: store,
          adService: ads,
          hapticsEnabled: false,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(ValueKey('cargo-${selected.id}-0')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('warehouse-${wrongWarehouse.id}')));

    await _pumpUntil(tester, find.byType(GameActionFeedback));
    await _pumpUntilAbsent(tester, find.byType(GameActionFeedback));

    final watchAd = find.bySemanticsLabel('Watch ad for five moves');
    final retry = find.bySemanticsLabel('Retry');
    await _pumpUntil(tester, watchAd);
    expect(retry, findsOneWidget);

    await tester.scrollUntilVisible(
      watchAd,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(watchAd);
    await tester.pump();

    expect(ads.showRewardedCalls, 1);
    expect(watchAd, findsOneWidget);
    expect(retry, findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
  });
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

final class _UnavailableRewardedAdService extends AdService {
  int showRewardedCalls = 0;

  @override
  void preload() {}

  @override
  void dispose() {}

  @override
  bool showRewarded({required void Function() onReward}) {
    showRewardedCalls++;
    return false;
  }
}
