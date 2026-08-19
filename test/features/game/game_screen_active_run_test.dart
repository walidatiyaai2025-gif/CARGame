import 'dart:async';

import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/game/active_run_session.dart';
import 'package:cargo_sort_game/features/game/active_run_snapshot.dart';
import 'package:cargo_sort_game/features/game/active_run_store.dart';
import 'package:cargo_sort_game/features/game/game_screen.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('restore blocks play and rehydrates exact reward-neutral state', (
    tester,
  ) async {
    await _useGameplaySurface(tester);
    final level = _level();
    final store = ProgressStore();
    final ads = _FakeAdService();
    final persistence = _FakeActiveRunPersistence(
      restoreGate: Completer<void>(),
    );
    persistence.snapshot = ActiveRunSession(
      remaining: [level.items.last],
      remainingHouses: [level.houseForItemIndex(1)],
      movesRemaining: 2,
      combo: 1,
      bestCombo: 2,
      preparedHints: 1,
      shieldActive: true,
      madeWrongMove: true,
      rewardTransactionId: 'level-1-attempt-restored-test',
    ).toSnapshot(level);

    await tester.pumpWidget(
      MaterialApp(home: _game(level, store, ads, persistence)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('game-active-run-restoring')),
      findsOneWidget,
    );
    expect(persistence.saveCount, 0);

    persistence.releaseRestore();
    await _pumpUntilReady(tester);

    expect(
      find.byKey(const ValueKey('game-active-run-restoring')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-moves')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(store.wins, 0);
    expect(store.losses, 0);
    expect(store.hearts, ProgressStore.maxHearts);
    expect(ads.interstitialShows, 0);
    expect(ads.rewardedShows, 0);
    expect(persistence.saveCount, 0);
  });

  testWidgets(
    'post-mutation checkpoint survives simulated process recreation',
    (tester) async {
      await _useGameplaySurface(tester);
      final level = _level();
      final persistence = _FakeActiveRunPersistence();
      final firstStore = ProgressStore();

      await tester.pumpWidget(
        MaterialApp(
          home: _game(level, firstStore, _FakeAdService(), persistence),
        ),
      );
      await _pumpUntilReady(tester);
      expect(persistence.saveCount, 1);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('house-1-cargo-1-0')),
      );
      final warehouse = find.byKey(const ValueKey('warehouse-1'));
      final viewport = Offset.zero & tester.binding.renderViews.single.size;
      final target = tester.getRect(warehouse).intersect(viewport);
      expect(target.isEmpty, isFalse);
      await tester.tapAt(target.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pump(const Duration(milliseconds: 40));

      expect(persistence.saveCount, greaterThanOrEqualTo(2));
      expect(persistence.snapshot, isNotNull);
      expect(persistence.snapshot!.movesRemaining, 3);
      expect(persistence.snapshot!.remainingItemIds, hasLength(1));
      final restoredTransaction = persistence.snapshot!.rewardTransactionId;

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final secondStore = ProgressStore();
      final secondAds = _FakeAdService();
      await tester.pumpWidget(
        MaterialApp(home: _game(level, secondStore, secondAds, persistence)),
      );
      await _pumpUntilReady(tester);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('game-moves')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(persistence.snapshot!.rewardTransactionId, restoredTransaction);
      expect(secondStore.wins, 0);
      expect(secondStore.losses, 0);
      expect(secondStore.hearts, ProgressStore.maxHearts);
      expect(secondStore.freeHints, greaterThanOrEqualTo(0));
      expect(secondStore.extraMovesBoosters, greaterThanOrEqualTo(0));
      expect(secondStore.comboShields, greaterThanOrEqualTo(0));
      expect(secondAds.interstitialShows, 0);
      expect(secondAds.rewardedShows, 0);
    },
  );

  testWidgets('background lifecycle checkpoints the unfinished run', (
    tester,
  ) async {
    await _useGameplaySurface(tester);
    final level = _level();
    final persistence = _FakeActiveRunPersistence();

    await tester.pumpWidget(
      MaterialApp(
        home: _game(level, ProgressStore(), _FakeAdService(), persistence),
      ),
    );
    await _pumpUntilReady(tester);
    final initialSaves = persistence.saveCount;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 30));

    expect(persistence.saveCount, greaterThan(initialSaves));
    expect(persistence.snapshot, isNotNull);
    expect(persistence.snapshot!.movesRemaining, level.moves);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });

  testWidgets('explicit restart clears stale run before fresh checkpoint', (
    tester,
  ) async {
    await _useGameplaySurface(tester);
    final level = _level();
    final persistence = _FakeActiveRunPersistence();

    await tester.pumpWidget(
      MaterialApp(
        home: _game(level, ProgressStore(), _FakeAdService(), persistence),
      ),
    );
    await _pumpUntilReady(tester);
    final oldTransaction = persistence.snapshot!.rewardTransactionId;

    final restartTap = find.ancestor(
      of: find.byIcon(Icons.restart_alt_rounded),
      matching: find.byType(InkWell),
    );
    expect(restartTap, findsOneWidget);
    final restartInkWell = tester.widget<InkWell>(restartTap);
    expect(restartInkWell.onTap, isNotNull);
    restartInkWell.onTap!();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40));

    expect(persistence.clearCount, 1);
    expect(persistence.snapshot, isNotNull);
    expect(persistence.snapshot!.rewardTransactionId, isNot(oldTransaction));
    expect(persistence.snapshot!.movesRemaining, level.moves);
  });
}

LevelData _level() {
  final cargo = productCatalog.first;
  return LevelData(
    number: 1,
    world: 1,
    moves: 4,
    items: [cargo, cargo],
    difficulty: 1,
  );
}

GameScreen _game(
  LevelData level,
  ProgressStore store,
  _FakeAdService ads,
  _FakeActiveRunPersistence persistence,
) {
  return GameScreen(
    level: level,
    store: store,
    adService: ads,
    activeRunPersistence: persistence,
    hapticsEnabled: false,
    soundEnabled: false,
  );
}

Future<void> _useGameplaySurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpUntilReady(WidgetTester tester) async {
  for (var index = 0; index < 20; index++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (find
        .byKey(const ValueKey('game-active-run-restoring'))
        .evaluate()
        .isEmpty) {
      return;
    }
  }
  fail('GameScreen did not finish active-run restore in time.');
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

final class _FakeActiveRunPersistence implements ActiveRunPersistence {
  _FakeActiveRunPersistence({this.restoreGate});

  final Completer<void>? restoreGate;
  ActiveRunSnapshot? snapshot;
  int saveCount = 0;
  int clearCount = 0;

  void releaseRestore() {
    final gate = restoreGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<void> save(ActiveRunSnapshot value, LevelData level) async {
    saveCount++;
    snapshot = value;
  }

  @override
  Future<ActiveRunSnapshot?> restoreFor(LevelData level) async {
    final gate = restoreGate;
    if (gate != null) await gate.future;
    return snapshot;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    snapshot = null;
  }
}

final class _FakeAdService extends AdService {
  int interstitialShows = 0;
  int rewardedShows = 0;

  @override
  void preload() {}

  @override
  void showInterstitial() {
    interstitialShows++;
  }

  @override
  bool showRewarded({required void Function() onReward}) {
    rewardedShows++;
    return false;
  }

  @override
  void dispose() {}
}
