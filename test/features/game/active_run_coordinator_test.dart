import 'dart:async';

import 'package:cargo_sort_game/features/game/active_run_coordinator.dart';
import 'package:cargo_sort_game/features/game/active_run_session.dart';
import 'package:cargo_sort_game/features/game/active_run_snapshot.dart';
import 'package:cargo_sort_game/features/game/active_run_store.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ActiveRunSession sessionFor(LevelData level, {int removed = 1}) {
    final remaining = level.items.take(level.items.length - removed).toList();
    return ActiveRunSession(
      remaining: remaining,
      remainingHouses: [
        for (var index = 0; index < remaining.length; index++)
          level.houseForItemIndex(index),
      ],
      movesRemaining: level.moves - removed,
      combo: removed,
      bestCombo: removed,
      preparedHints: 0,
      shieldActive: false,
      madeWrongMove: false,
      rewardTransactionId: 'level-${level.number}-attempt-coordinator-test',
    );
  }

  test('restores a valid reward-neutral unfinished session', () async {
    final level = levels.first;
    final fake = _FakeActiveRunPersistence();
    final session = sessionFor(level);
    fake.snapshot = session.toSnapshot(level);
    final coordinator = ActiveRunCoordinator(level: level, store: fake);

    final restored = await coordinator.restore();

    expect(restored, isNotNull);
    expect(
      restored!.remaining.map((item) => item.id),
      session.remaining.map((item) => item.id),
    );
    expect(restored.rewardTransactionId, session.rewardTransactionId);
    expect(fake.clearCount, 0);
  });

  test('serializes checkpoints so newest mutation wins', () async {
    final level = levels[20];
    final fake = _FakeActiveRunPersistence(blockFirstSave: true);
    final coordinator = ActiveRunCoordinator(level: level, store: fake);
    final first = sessionFor(level, removed: 1);
    final second = sessionFor(level, removed: 2);

    final firstWrite = coordinator.checkpoint(first);
    final secondWrite = coordinator.checkpoint(second);
    await Future<void>.delayed(Duration.zero);
    expect(fake.saveCount, 1);

    fake.releaseFirstSave();
    await Future.wait([firstWrite, secondWrite]);

    expect(fake.saveCount, 2);
    expect(
      fake.snapshot!.remainingItemIds,
      second.remaining.map((item) => item.id).toList(),
    );
  });

  test('terminal clear prevents later checkpoints from resurrecting run', () async {
    final level = levels[40];
    final fake = _FakeActiveRunPersistence();
    final coordinator = ActiveRunCoordinator(level: level, store: fake);

    await coordinator.checkpoint(sessionFor(level));
    await coordinator.clearTerminal();
    await coordinator.checkpoint(sessionFor(level, removed: 2));
    await coordinator.flush();

    expect(fake.snapshot, isNull);
    expect(fake.clearCount, 1);
    expect(fake.saveCount, 1);
  });

  test('restart or abandon clears but still permits a fresh checkpoint', () async {
    final level = levels[60];
    final fake = _FakeActiveRunPersistence();
    final coordinator = ActiveRunCoordinator(level: level, store: fake);

    await coordinator.checkpoint(sessionFor(level));
    await coordinator.clearForRestartOrAbandon();
    expect(fake.snapshot, isNull);

    final fresh = sessionFor(level, removed: 2);
    await coordinator.checkpoint(fresh);
    expect(
      fake.snapshot!.remainingItemIds,
      fresh.remaining.map((item) => item.id).toList(),
    );
  });

  test('preserves GAME-017 cargo progression contract', () {
    expect(levels.first.items, hasLength(9));
    expect(levels.first.houseCount, 3);
    expect(LevelCargoProgression.cargoCountForLevel(1), 9);
    expect(LevelCargoProgression.cargoCountForLevel(11), 10);
    expect(LevelCargoProgression.cargoCountForLevel(21), 11);
    expect(LevelCargoProgression.cargoCountForLevel(150), greaterThan(9));
  });
}

final class _FakeActiveRunPersistence implements ActiveRunPersistence {
  _FakeActiveRunPersistence({this.blockFirstSave = false});

  final bool blockFirstSave;
  final Completer<void> _firstSaveGate = Completer<void>();
  ActiveRunSnapshot? snapshot;
  int saveCount = 0;
  int clearCount = 0;

  void releaseFirstSave() {
    if (!_firstSaveGate.isCompleted) _firstSaveGate.complete();
  }

  @override
  Future<void> save(ActiveRunSnapshot value, LevelData level) async {
    saveCount++;
    if (blockFirstSave && saveCount == 1) await _firstSaveGate.future;
    snapshot = value;
  }

  @override
  Future<ActiveRunSnapshot?> restoreFor(LevelData level) async => snapshot;

  @override
  Future<void> clear() async {
    clearCount++;
    snapshot = null;
  }
}
