import 'dart:convert';

import 'level_data.dart';

/// Versioned, reward-neutral checkpoint for an unfinished gameplay run.
///
/// This model deliberately contains only deterministic mission state. Durable
/// progression, rewards, hearts, ads, and store inventory remain owned by
/// ProgressStore and must never be replayed from this snapshot.
class ActiveRunSnapshot {
  const ActiveRunSnapshot({
    required this.version,
    required this.levelNumber,
    required this.levelCargoCount,
    required this.remainingItemIds,
    required this.remainingHouseIds,
    required this.movesRemaining,
    required this.combo,
    required this.bestCombo,
    required this.preparedHints,
    required this.shieldActive,
    required this.madeWrongMove,
    required this.rewardTransactionId,
  });

  static const int currentVersion = 1;

  final int version;
  final int levelNumber;
  final int levelCargoCount;
  final List<int> remainingItemIds;
  final List<int> remainingHouseIds;
  final int movesRemaining;
  final int combo;
  final int bestCombo;
  final int preparedHints;
  final bool shieldActive;
  final bool madeWrongMove;
  final String rewardTransactionId;

  bool get isTerminal => remainingItemIds.isEmpty || movesRemaining <= 0;

  Map<String, Object> toJson() => <String, Object>{
        'version': version,
        'levelNumber': levelNumber,
        'levelCargoCount': levelCargoCount,
        'remainingItemIds': remainingItemIds,
        'remainingHouseIds': remainingHouseIds,
        'movesRemaining': movesRemaining,
        'combo': combo,
        'bestCombo': bestCombo,
        'preparedHints': preparedHints,
        'shieldActive': shieldActive,
        'madeWrongMove': madeWrongMove,
        'rewardTransactionId': rewardTransactionId,
      };

  String encode() => jsonEncode(toJson());

  static ActiveRunSnapshot? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      int? readInt(String key) {
        final value = decoded[key];
        return value is int ? value : null;
      }

      bool? readBool(String key) {
        final value = decoded[key];
        return value is bool ? value : null;
      }

      List<int>? readIntList(String key) {
        final value = decoded[key];
        if (value is! List) return null;
        final result = <int>[];
        for (final element in value) {
          if (element is! int) return null;
          result.add(element);
        }
        return result;
      }

      final version = readInt('version');
      final levelNumber = readInt('levelNumber');
      final levelCargoCount = readInt('levelCargoCount');
      final remainingItemIds = readIntList('remainingItemIds');
      final remainingHouseIds = readIntList('remainingHouseIds');
      final movesRemaining = readInt('movesRemaining');
      final combo = readInt('combo');
      final bestCombo = readInt('bestCombo');
      final preparedHints = readInt('preparedHints');
      final shieldActive = readBool('shieldActive');
      final madeWrongMove = readBool('madeWrongMove');
      final rewardTransactionId = decoded['rewardTransactionId'];

      if (version == null ||
          levelNumber == null ||
          levelCargoCount == null ||
          remainingItemIds == null ||
          remainingHouseIds == null ||
          movesRemaining == null ||
          combo == null ||
          bestCombo == null ||
          preparedHints == null ||
          shieldActive == null ||
          madeWrongMove == null ||
          rewardTransactionId is! String) {
        return null;
      }

      return ActiveRunSnapshot(
        version: version,
        levelNumber: levelNumber,
        levelCargoCount: levelCargoCount,
        remainingItemIds: List<int>.unmodifiable(remainingItemIds),
        remainingHouseIds: List<int>.unmodifiable(remainingHouseIds),
        movesRemaining: movesRemaining,
        combo: combo,
        bestCombo: bestCombo,
        preparedHints: preparedHints,
        shieldActive: shieldActive,
        madeWrongMove: madeWrongMove,
        rewardTransactionId: rewardTransactionId,
      );
    } on FormatException {
      return null;
    }
  }

  /// Returns true only when this snapshot can safely resume [level].
  ///
  /// Validation fails closed for future schema versions, terminal runs,
  /// malformed counters, changed production level shape, unknown products,
  /// invalid houses, or impossible item/house list lengths.
  bool isCompatibleWith(LevelData level) {
    if (version != currentVersion ||
        levelNumber != level.number ||
        levelCargoCount != level.items.length ||
        rewardTransactionId.trim().isEmpty ||
        isTerminal ||
        movesRemaining < 0 ||
        combo < 0 ||
        bestCombo < combo ||
        preparedHints < 0 ||
        remainingItemIds.length != remainingHouseIds.length ||
        remainingItemIds.length > level.items.length) {
      return false;
    }

    final allowedItemCounts = <int, int>{};
    for (final item in level.items) {
      allowedItemCounts.update(item.id, (value) => value + 1,
          ifAbsent: () => 1);
    }

    final remainingCounts = <int, int>{};
    for (final itemId in remainingItemIds) {
      if (!allowedItemCounts.containsKey(itemId)) return false;
      remainingCounts.update(itemId, (value) => value + 1,
          ifAbsent: () => 1);
      if (remainingCounts[itemId]! > allowedItemCounts[itemId]!) return false;
    }

    for (final houseId in remainingHouseIds) {
      if (houseId < 1 || houseId > level.houseCount) return false;
    }

    return true;
  }
}
