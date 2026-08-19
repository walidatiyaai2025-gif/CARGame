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

  Map<String, Object> toJson() {
    return <String, Object>{
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
  }

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

      if (version == null) return null;
      if (levelNumber == null) return null;
      if (levelCargoCount == null) return null;
      if (remainingItemIds == null) return null;
      if (remainingHouseIds == null) return null;
      if (movesRemaining == null) return null;
      if (combo == null) return null;
      if (bestCombo == null) return null;
      if (preparedHints == null) return null;
      if (shieldActive == null) return null;
      if (madeWrongMove == null) return null;
      if (rewardTransactionId is! String) return null;

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
    if (version != currentVersion) return false;
    if (levelNumber != level.number) return false;
    if (levelCargoCount != level.items.length) return false;
    if (rewardTransactionId.trim().isEmpty) return false;
    if (isTerminal) return false;
    if (movesRemaining < 0) return false;
    if (combo < 0) return false;
    if (bestCombo < combo) return false;
    if (preparedHints < 0) return false;
    if (remainingItemIds.length != remainingHouseIds.length) return false;
    if (remainingItemIds.length > level.items.length) return false;

    final allowedItemCounts = <int, int>{};
    for (final item in level.items) {
      final currentCount = allowedItemCounts[item.id] ?? 0;
      allowedItemCounts[item.id] = currentCount + 1;
    }

    final remainingCounts = <int, int>{};
    for (final itemId in remainingItemIds) {
      final allowedCount = allowedItemCounts[itemId];
      if (allowedCount == null) return false;
      final currentCount = remainingCounts[itemId] ?? 0;
      final nextCount = currentCount + 1;
      if (nextCount > allowedCount) return false;
      remainingCounts[itemId] = nextCount;
    }

    for (final houseId in remainingHouseIds) {
      if (houseId < 1) return false;
      if (houseId > level.houseCount) return false;
    }

    return true;
  }
}
