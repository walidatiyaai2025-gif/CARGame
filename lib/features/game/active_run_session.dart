import 'active_run_snapshot.dart';
import 'level_data.dart';

/// Immutable runtime projection of a validated unfinished mission snapshot.
///
/// This object intentionally contains no durable progression, reward, heart,
/// ad, or inventory ownership. It exists only to restore the deterministic
/// in-level state that GameScreen already owns.
final class ActiveRunSession {
  const ActiveRunSession({
    required this.remaining,
    required this.remainingHouses,
    required this.movesRemaining,
    required this.combo,
    required this.bestCombo,
    required this.preparedHints,
    required this.shieldActive,
    required this.madeWrongMove,
    required this.rewardTransactionId,
  });

  final List<CargoItem> remaining;
  final List<int> remainingHouses;
  final int movesRemaining;
  final int combo;
  final int bestCombo;
  final int preparedHints;
  final bool shieldActive;
  final bool madeWrongMove;
  final String rewardTransactionId;

  static ActiveRunSession? fromSnapshot(
    ActiveRunSnapshot snapshot,
    LevelData level,
  ) {
    if (!snapshot.isCompatibleWith(level)) return null;

    final byId = <int, CargoItem>{};
    for (final item in level.items) {
      byId[item.id] = item;
    }

    final remaining = <CargoItem>[];
    for (final itemId in snapshot.remainingItemIds) {
      final item = byId[itemId];
      if (item == null) return null;
      remaining.add(item);
    }

    return ActiveRunSession(
      remaining: List<CargoItem>.unmodifiable(remaining),
      remainingHouses: List<int>.unmodifiable(snapshot.remainingHouseIds),
      movesRemaining: snapshot.movesRemaining,
      combo: snapshot.combo,
      bestCombo: snapshot.bestCombo,
      preparedHints: snapshot.preparedHints,
      shieldActive: snapshot.shieldActive,
      madeWrongMove: snapshot.madeWrongMove,
      rewardTransactionId: snapshot.rewardTransactionId,
    );
  }

  ActiveRunSnapshot toSnapshot(LevelData level) {
    return ActiveRunSnapshot(
      version: ActiveRunSnapshot.currentVersion,
      levelNumber: level.number,
      levelCargoCount: level.items.length,
      remainingItemIds: List<int>.unmodifiable(
        remaining.map((item) => item.id),
      ),
      remainingHouseIds: List<int>.unmodifiable(remainingHouses),
      movesRemaining: movesRemaining,
      combo: combo,
      bestCombo: bestCombo,
      preparedHints: preparedHints,
      shieldActive: shieldActive,
      madeWrongMove: madeWrongMove,
      rewardTransactionId: rewardTransactionId,
    );
  }
}
