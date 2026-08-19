import '../../core/storage/recovering_preferences.dart';
import 'active_run_snapshot.dart';
import 'level_data.dart';

/// Narrow persistence contract for reward-neutral unfinished mission state.
abstract interface class ActiveRunPersistence {
  Future<void> save(ActiveRunSnapshot snapshot, LevelData level);
  Future<ActiveRunSnapshot?> restoreFor(LevelData level);
  Future<void> clear();
}

/// Persistence boundary for unfinished mission checkpoints.
///
/// Active-run state is intentionally isolated from ProgressStore durable truth.
/// Invalid, stale, terminal, or future-version data is removed instead of
/// being partially recovered.
final class ActiveRunStore implements ActiveRunPersistence {
  ActiveRunStore({RecoveringPreferences? preferences})
    : _preferences = preferences ?? RecoveringPreferences();

  static const storageKey = 'active_run_snapshot_v1';

  final RecoveringPreferences _preferences;

  @override
  Future<void> save(ActiveRunSnapshot snapshot, LevelData level) async {
    if (!snapshot.isCompatibleWith(level)) {
      throw ArgumentError.value(snapshot, 'snapshot', 'Unsafe active run');
    }
    await _preferences.setString(storageKey, snapshot.encode());
  }

  @override
  Future<ActiveRunSnapshot?> restoreFor(LevelData level) async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return null;

    final snapshot = ActiveRunSnapshot.tryDecode(raw);
    if (snapshot == null || !snapshot.isCompatibleWith(level)) {
      await clear();
      return null;
    }
    return snapshot;
  }

  @override
  Future<void> clear() => _preferences.remove(storageKey);
}
