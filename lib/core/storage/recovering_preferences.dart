import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class StorageRecoveryEvent {
  const StorageRecoveryEvent({required this.key, required this.reason});

  final String key;
  final String reason;
}

final class RecoveringPreferences {
  RecoveringPreferences({SharedPreferencesAsync? delegate})
      : _delegate = delegate ?? SharedPreferencesAsync();

  static const backupKey = 'storage_recovery_backup_v1';

  final SharedPreferencesAsync _delegate;
  final List<StorageRecoveryEvent> _events = <StorageRecoveryEvent>[];
  bool _backupWritten = false;

  List<StorageRecoveryEvent> get recoveryEvents => List.unmodifiable(_events);
  bool get recovered => _events.isNotEmpty;

  Future<Map<String, Object?>> getAll({Set<String>? allowList}) =>
      _delegate.getAll(allowList: allowList);

  Future<Set<String>> getKeys({Set<String>? allowList}) =>
      _delegate.getKeys(allowList: allowList);

  Future<bool> containsKey(String key) => _delegate.containsKey(key);

  Future<int?> getInt(String key) async {
    int? value;
    try {
      value = await _delegate.getInt(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected int');
      return null;
    }
    if (value == null) return null;

    final normalized = _normalizeInt(key, value);
    if (normalized != value) {
      await _recordRepair(key, 'out-of-range int $value -> $normalized');
      await _delegate.setInt(key, normalized);
      return normalized;
    }
    return value;
  }

  Future<bool?> getBool(String key) async {
    try {
      return await _delegate.getBool(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected bool');
      return null;
    }
  }

  Future<double?> getDouble(String key) async {
    try {
      return await _delegate.getDouble(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected double');
      return null;
    }
  }

  Future<String?> getString(String key) async {
    String? value;
    try {
      value = await _delegate.getString(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected string');
      return null;
    }
    if (value == null) return null;

    if (key == 'heart_refill_timestamp' && DateTime.tryParse(value) == null) {
      await _repairByRemoval(key, 'invalid ISO-8601 timestamp');
      return null;
    }
    return value;
  }

  Future<List<String>?> getStringList(String key) async {
    try {
      return await _delegate.getStringList(key);
    } on TypeError {
      await _repairByRemoval(key, 'expected string list');
      return null;
    }
  }

  Future<void> setBool(String key, bool value) => _delegate.setBool(key, value);
  Future<void> setDouble(String key, double value) =>
      _delegate.setDouble(key, value);
  Future<void> setInt(String key, int value) => _delegate.setInt(key, value);
  Future<void> setString(String key, String value) =>
      _delegate.setString(key, value);
  Future<void> setStringList(String key, List<String> value) =>
      _delegate.setStringList(key, value);
  Future<void> remove(String key) => _delegate.remove(key);
  Future<void> clear({Set<String>? allowList}) =>
      _delegate.clear(allowList: allowList);

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
    await _delegate.remove(key);
  }

  Future<void> _recordRepair(String key, String reason) async {
    await _ensureBackup();
    _events.add(StorageRecoveryEvent(key: key, reason: reason));
  }

  Future<void> _ensureBackup() async {
    if (_backupWritten) return;
    _backupWritten = true;

    try {
      final snapshot = await _delegate.getAll();
      snapshot.remove(backupKey);
      final payload = <String, Object?>{
        'schemaVersion': 1,
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
        'values': snapshot,
      };
      await _delegate.setString(backupKey, jsonEncode(payload));
    } catch (_) {
      // Recovery must continue even if the platform store cannot be snapshotted.
    }
  }
}
