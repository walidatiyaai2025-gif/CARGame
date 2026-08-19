import '../../core/storage/recovering_preferences.dart';
import 'active_run_snapshot.dart';
import 'level_data.dart';

/// Persistence boundary for unfinished mission checkpoints.
///
/// Active-run state is intentionally isolated from ProgressStore durable truth.
/// Invalid, stale, terminal, or future-version data is removed instead of
/// being partially recovered.
final class ActiveRunStore {
  ActiveRunStore({RecoveringPreferences? preferences})
      : _preferences = preferences ?? RecoveringPreferences();

  static const storageKey = 'active_run_snapshot_v1';

  final RecoveringPreferences _preferences;

  Future<void> save(ActiveRunSnapshot snapshot, LevelData level) async {
    if (!snapshot.isCompatibleWith(level)) {
      throw ArgumentError.value(snapshot, 'snapshot', 'Unsafe active run');
    }
    await _preferences.setString(storageKey, snapshot.encode());
  }

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

  Future<void> clear() => _preferences.remove(storageKey);
}
