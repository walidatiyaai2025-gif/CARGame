import 'dart:convert';

import 'package:cargo_sort_game/features/game/active_run_snapshot.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ActiveRunSnapshot validSnapshot(LevelData level) {
    return ActiveRunSnapshot(
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
  }

  test('GAME-017 cargo progression contract remains intact', () {
    expect(levels, hasLength(150));
    expect(levels.first.items, hasLength(9));
    expect(levels.first.houseCount, 3);
    expect(LevelCargoProgression.cargoCountForLevel(1), 9);
    expect(LevelCargoProgression.cargoCountForLevel(11), 10);
    expect(LevelCargoProgression.cargoCountForLevel(21), 11);
    final firstCount = LevelCargoProgression.cargoCountForLevel(1);
    final finalCount = LevelCargoProgression.cargoCountForLevel(150);
    expect(finalCount, greaterThan(firstCount));
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
    final json = validSnapshot(level).toJson();
    json['version'] = ActiveRunSnapshot.currentVersion + 1;
    final decoded = ActiveRunSnapshot.tryDecode(jsonEncode(json));

    expect(decoded, isNotNull);
    expect(decoded!.isCompatibleWith(level), isFalse);
  });

  test('terminal snapshots never resume', () {
    final level = levels.first;
    final wonJson = validSnapshot(level).toJson();
    wonJson['remainingItemIds'] = <int>[];
    wonJson['remainingHouseIds'] = <int>[];
    final won = ActiveRunSnapshot.tryDecode(jsonEncode(wonJson));

    final lostJson = validSnapshot(level).toJson();
    lostJson['movesRemaining'] = 0;
    final lost = ActiveRunSnapshot.tryDecode(jsonEncode(lostJson));

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

    final unknownJson = snapshot.toJson();
    unknownJson['remainingItemIds'] = <int>[999];
    unknownJson['remainingHouseIds'] = <int>[1];
    final unknownCargo = ActiveRunSnapshot.tryDecode(jsonEncode(unknownJson));
    expect(unknownCargo!.isCompatibleWith(level), isFalse);

    final firstId = level.items.first.id;
    final available = level.items.where((item) => item.id == firstId).length;
    final overflowJson = snapshot.toJson();
    overflowJson['remainingItemIds'] = List<int>.filled(
      available + 1,
      firstId,
    );
    overflowJson['remainingHouseIds'] = List<int>.filled(available + 1, 1);
    final overflow = ActiveRunSnapshot.tryDecode(jsonEncode(overflowJson));
    expect(overflow!.isCompatibleWith(level), isFalse);

    final badHouseJson = snapshot.toJson();
    final houses = List<int>.from(snapshot.remainingHouseIds);
    houses[0] = level.houseCount + 1;
    badHouseJson['remainingHouseIds'] = houses;
    final badHouse = ActiveRunSnapshot.tryDecode(jsonEncode(badHouseJson));
    expect(badHouse!.isCompatibleWith(level), isFalse);
  });

  test('malformed JSON and wrong field types are rejected', () {
    expect(ActiveRunSnapshot.tryDecode('{broken'), isNull);
    final wrongTypes = jsonEncode(<String, Object>{'version': '1'});
    expect(ActiveRunSnapshot.tryDecode(wrongTypes), isNull);
  });
}
