import 'dart:convert';

import '../logging/app_logger.dart';
import '../storage/recovering_preferences.dart';

/// Owns first-party local data export and deletion for PRIV-003.
///
/// This controller deliberately has no network or file-sharing dependency.
/// Export is returned as JSON for an explicit user-driven copy/share surface,
/// while deletion clears the app-owned SharedPreferences namespace and the
/// redacted local diagnostic log.
final class LocalDataController {
  LocalDataController({
    RecoveringPreferences? preferences,
    AppLogger? logger,
    DateTime Function()? now,
  }) : _preferences = preferences ?? RecoveringPreferences(),
       _logger = logger ?? AppLogger.instance,
       _now = now ?? DateTime.now;

  static const int exportSchemaVersion = 1;

  final RecoveringPreferences _preferences;
  final AppLogger _logger;
  final DateTime Function() _now;

  Future<void>? _deleteOperation;

  bool get deleteInProgress => _deleteOperation != null;

  Future<String> exportJson() async {
    final deleting = _deleteOperation;
    if (deleting != null) await deleting;

    final rawValues = await _preferences.getAll();
    final sortedValues = <String, Object?>{};
    final keys = rawValues.keys.toList()..sort();
    for (final key in keys) {
      sortedValues[key] = _jsonSafe(rawValues[key]);
    }

    final payload = <String, Object?>{
      'schemaVersion': exportSchemaVersion,
      'exportedAt': _now().toUtc().toIso8601String(),
      'scope': 'first_party_local_data',
      'networkTransfer': false,
      'sharedPreferences': sortedValues,
      'diagnostics': <String, Object?>{
        'redacted': true,
        'entries': List<String>.from(_logger.entries),
      },
      'thirdPartyData': <String, Object?>{
        'included': false,
        'reason':
            'Google Mobile Ads data is processor-controlled and is not copied '
            'to a CARGame first-party backend.',
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Clears first-party local persistence and diagnostics.
  ///
  /// Concurrent callers join the same deletion operation so the destructive
  /// action is executed at most once at a time.
  Future<void> deleteAllLocalData() {
    final active = _deleteOperation;
    if (active != null) return active;

    final operation = _performDelete();
    _deleteOperation = operation;
    return operation.whenComplete(() {
      if (identical(_deleteOperation, operation)) {
        _deleteOperation = null;
      }
    });
  }

  Future<void> _performDelete() async {
    await _preferences.clear();
    await _logger.clear();
  }

  Object? _jsonSafe(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) {
      return value.map<Object?>((item) => _jsonSafe(item)).toList();
    }
    return value.toString();
  }
}
