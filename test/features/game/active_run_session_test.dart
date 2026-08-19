import 'package:cargo_sort_game/features/game/active_run_session.dart';
import 'package:cargo_sort_game/features/game/active_run_snapshot.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ActiveRunSnapshot snapshotFor(LevelData level) {
    final remaining = level.items.take(level.items.length - 1).toList();
    final houses = <int>[
      for (var index = 0; index < remaining.length; index++)
        level.houseForItemIndex(index),
    ];
    return ActiveRunSnapshot(
      version: ActiveRunSnapshot.currentVersion,
      levelNumber: level.number,
      levelCargoCount: level.items.length,
      remainingItemIds: remaining.map((item) => item.id).toList(),
      remainingHouseIds: houses,
      movesRemaining: level.moves - 1,
      combo: 2,
      bestCombo: 3,
      preparedHints: 1,
      shieldActive: true,
      madeWrongMove: true,
      rewardTransactionId: 'level-${level.number}-attempt-recovery-test',
    );
  }

  test('maps a compatible checkpoint into reward-neutral runtime state', () {
    final level = levels.first;
    final snapshot = snapshotFor(level);

    final session = ActiveRunSession.fromSnapshot(snapshot, level);

    expect(session, isNotNull);
    expect(session!.remaining.map((item) => item.id), snapshot.remainingItemIds);
    expect(session.remainingHouses, snapshot.remainingHouseIds);
    expect(session.movesRemaining, snapshot.movesRemaining);
    expect(session.combo, snapshot.combo);
    expect(session.bestCombo, snapshot.bestCombo);
    expect(session.preparedHints, snapshot.preparedHints);
    expect(session.shieldActive, snapshot.shieldActive);
    expect(session.madeWrongMove, snapshot.madeWrongMove);
    expect(session.rewardTransactionId, snapshot.rewardTransactionId);
  });

  test('round trips runtime state without changing transaction identity', () {
    final level = levels[20];
    final original = snapshotFor(level);
    final session = ActiveRunSession.fromSnapshot(original, level)!;

    final roundTripped = session.toSnapshot(level);

    expect(roundTripped.isCompatibleWith(level), isTrue);
    expect(roundTripped.toJson(), original.toJson());
  });

  test('rejects a snapshot for a different production level', () {
    final snapshot = snapshotFor(levels.first);
    expect(ActiveRunSession.fromSnapshot(snapshot, levels[1]), isNull);
  });

  test('preserves GAME-017 progressive cargo contract', () {
    expect(levels.first.items, hasLength(9));
    expect(levels.first.houseCount, 3);
    expect(LevelCargoProgression.cargoCountForLevel(1), 9);
    expect(LevelCargoProgression.cargoCountForLevel(11), 10);
    expect(LevelCargoProgression.cargoCountForLevel(21), 11);
    expect(
      LevelCargoProgression.cargoCountForLevel(150),
      greaterThan(LevelCargoProgression.cargoCountForLevel(1)),
    );
  });
}
