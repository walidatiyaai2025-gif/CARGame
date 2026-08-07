import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class StorageRecoveryEvent {
  const StorageRecoveryEvent({required this.key, required this.reason});

  final String key;
  final String reason;
}

final class RecoveringPreferences {
  RecoveringPreferences({SharedPreferencesAsync? delegate})
    : _delegate = delegate;

  static const backupKey = 'storage_recovery_backup_v1';

  SharedPreferencesAsync? _delegate;
  final List<StorageRecoveryEvent> _events = <StorageRecoveryEvent>[];
  bool _backupWritten = false;

  SharedPreferencesAsync get _store => _delegate ??= SharedPreferencesAsync();

  List<StorageRecoveryEvent> get recoveryEvents => List.unmodifiable(_events);
  bool get recovered => _events.isNotEmpty;

  Future<Map<String, Object?>> getAll({Set<String>? allowList}) =>
      _store.getAll(allowList: allowList);

  Future<Set<String>> getKeys({Set<String>? allowList}) =>
      _store.getKeys(allowList: allowList);

  Future<bool> containsKey(String key) => _store.containsKey(key);

  Future<int?> getInt(String key) async {
    int? value;
    try {
      value = await _store.getInt(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected int');
      return null;
    }
    if (value == null) return null;

    final normalized = _normalizeInt(key, value);
    if (normalized != value) {
      await _recordRepair(key, 'out-of-range int $value -> $normalized');
      await _store.setInt(key, normalized);
      return normalized;
    }
    return value;
  }

  Future<bool?> getBool(String key) async {
    try {
      return await _store.getBool(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected bool');
      return null;
    }
  }

  Future<double?> getDouble(String key) async {
    try {
      return await _store.getDouble(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected double');
      return null;
    }
  }

  Future<String?> getString(String key) async {
    String? value;
    try {
      value = await _store.getString(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected string');
      return null;
    }
    if (value == null) return null;

    if (key == 'heart_refill_timestamp') {
      final now = DateTime.now().toUtc();
      final parsed = DateTime.tryParse(value)?.toUtc();
      final reason = parsed == null
          ? 'invalid ISO-8601 timestamp'
          : parsed.isAfter(now)
          ? 'future heart refill timestamp'
          : null;
      if (reason != null) {
        await _recordRepair(key, reason);
        final repaired = now.toIso8601String();
        await _store.setString(key, repaired);
        return repaired;
      }
    }
    return value;
  }

  Future<List<String>?> getStringList(String key) async {
    try {
      return await _store.getStringList(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected string list');
      return null;
    }
  }

  Future<void> setBool(String key, bool value) => _store.setBool(key, value);
  Future<void> setDouble(String key, double value) =>
      _store.setDouble(key, value);
  Future<void> setInt(String key, int value) => _store.setInt(key, value);
  Future<void> setString(String key, String value) =>
      _store.setString(key, value);
  Future<void> setStringList(String key, List<String> value) =>
      _store.setStringList(key, value);
  Future<void> remove(String key) => _store.remove(key);
  Future<void> clear({Set<String>? allowList}) =>
      _store.clear(allowList: allowList);

  int _normalizeInt(String key, int value) {
    if (key == 'highest_unlocked_level') return value.clamp(1, 150);
    if (key == 'hearts') return value.clamp(0, 5);
    if (key.startsWith('level_stars_')) return value.clamp(0, 3);

    const nonNegativeKeys = <String>{
      'coins',
      'stats_games',
      'stats_wins',
      'stats_losses',
      'stats_coins_earned',
      'stats_perfect_wins',
      'stats_best_combo',
      'stats_win_streak',
      'stats_best_win_streak',
      'player_xp',
      'mission_wins',
      'mission_stars',
      'mission_coins',
      'booster_free_hints',
      'booster_extra_moves',
      'booster_combo_shields',
    };
    if (nonNegativeKeys.contains(key) && value < 0) return 0;
    return value;
  }

  Future<void> _repairByRemoval(String key, String reason) async {
    await _recordRepair(key, reason);
    await _store.remove(key);
  }

  Future<void> _recordRepair(String key, String reason) async {
    await _ensureBackup();
    _events.add(StorageRecoveryEvent(key: key, reason: reason));
  }

  Future<void> _ensureBackup() async {
    if (_backupWritten) return;
    _backupWritten = true;

    try {
      final snapshot = await _store.getAll();
      snapshot.remove(backupKey);
      final payload = <String, Object?>{
        'schemaVersion': 1,
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
        'values': snapshot,
      };
      await _store.setString(backupKey, jsonEncode(payload));
    } catch (_) {
      // Recovery must continue even if the platform store cannot be snapshotted.
    }
  }
}
