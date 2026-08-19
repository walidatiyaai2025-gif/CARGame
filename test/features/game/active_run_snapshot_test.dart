import 'dart:convert';

import 'package:cargo_sort_game/features/game/active_run_snapshot.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ActiveRunSnapshot validSnapshot(LevelData level) => ActiveRunSnapshot(
        version: ActiveRunSnapshot.currentVersion,
        levelNumber: level.number,
        levelCargoCount: level.items.length,
        remainingItemIds: level.items.map((item) => item.id).toList(),
        remainingHouseIds: List<int>.generate(
          level.items.length,
          level.houseForItemIndex,
        ),
        movesRemaining: level.moves,
        combo: 0,
        bestCombo: 0,
        preparedHints: 0,
        shieldActive: false,
        madeWrongMove: false,
        rewardTransactionId: 'level-${level.number}-attempt-test',
      );

  test('GAME-017 cargo progression contract remains intact', () {
    expect(levels, hasLength(150));
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

  test('round trips a compatible unfinished run', () {
    final level = levels.first;
    final snapshot = validSnapshot(level);

    final decoded = ActiveRunSnapshot.tryDecode(snapshot.encode());

    expect(decoded, isNotNull);
    expect(decoded!.isCompatibleWith(level), isTrue);
    expect(decoded.rewardTransactionId, snapshot.rewardTransactionId);
    expect(decoded.remainingItemIds, snapshot.remainingItemIds);
    expect(decoded.remainingHouseIds, snapshot.remainingHouseIds);
  });

  test('future schema fails closed', () {
    final level = levels.first;
    final json = validSnapshot(level).toJson()
      ..['version'] = ActiveRunSnapshot.currentVersion + 1;

    final decoded = ActiveRunSnapshot.tryDecode(jsonEncode(json));

    expect(decoded, isNotNull);
    expect(decoded!.isCompatibleWith(level), isFalse);
  });

  test('terminal snapshots never resume', () {
    final level = levels.first;
    final base = validSnapshot(level).toJson();

    final won = ActiveRunSnapshot.tryDecode(
      jsonEncode(<String, Object>{
        ...base,
        'remainingItemIds': <int>[],
        'remainingHouseIds': <int>[],
      }),
    );
    final lost = ActiveRunSnapshot.tryDecode(
      jsonEncode(<String, Object>{...base, 'movesRemaining': 0}),
    );

    expect(won, isNotNull);
    expect(won!.isCompatibleWith(level), isFalse);
    expect(lost, isNotNull);
    expect(lost!.isCompatibleWith(level), isFalse);
  });

  test('changed level identity or production shape fails closed', () {
    final level = levels.first;
    final snapshot = validSnapshot(level);

    expect(snapshot.isCompatibleWith(levels[1]), isFalse);

    final changedShape = ActiveRunSnapshot(
      version: snapshot.version,
      levelNumber: snapshot.levelNumber,
      levelCargoCount: snapshot.levelCargoCount + 1,
      remainingItemIds: snapshot.remainingItemIds,
      remainingHouseIds: snapshot.remainingHouseIds,
      movesRemaining: snapshot.movesRemaining,
      combo: snapshot.combo,
      bestCombo: snapshot.bestCombo,
      preparedHints: snapshot.preparedHints,
      shieldActive: snapshot.shieldActive,
      madeWrongMove: snapshot.madeWrongMove,
      rewardTransactionId: snapshot.rewardTransactionId,
    );
    expect(changedShape.isCompatibleWith(level), isFalse);
  });

  test('unknown cargo, duplicate overflow, and invalid houses fail closed', () {
    final level = levels.first;
    final snapshot = validSnapshot(level);
    final base = snapshot.toJson();

    final unknownCargo = ActiveRunSnapshot.tryDecode(
      jsonEncode(<String, Object>{
        ...base,
        'remainingItemIds': <int>[999],
        'remainingHouseIds': <int>[1],
      }),
    );
    expect(unknownCargo!.isCompatibleWith(level), isFalse);

    final firstId = level.items.first.id;
    final available = level.items.where((item) => item.id == firstId).length;
    final overflow = ActiveRunSnapshot.tryDecode(
      jsonEncode(<String, Object>{
        ...base,
        'remainingItemIds': List<int>.filled(available + 1, firstId),
        'remainingHouseIds': List<int>.filled(available + 1, 1),
      }),
    );
    expect(overflow!.isCompatibleWith(level), isFalse);

    final badHouse = ActiveRunSnapshot.tryDecode(
      jsonEncode(<String, Object>{
        ...base,
        'remainingHouseIds': <int>[
          level.houseCount + 1,
          ...snapshot.remainingHouseIds.skip(1),
        ],
      }),
    );
    expect(badHouse!.isCompatibleWith(level), isFalse);
  });

  test('malformed JSON and wrong field types are rejected', () {
    expect(ActiveRunSnapshot.tryDecode('{broken'), isNull);
    expect(
      ActiveRunSnapshot.tryDecode(
        jsonEncode(<String, Object>{'version': '1'}),
      ),
      isNull,
    );
  });
}
