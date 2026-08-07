import 'dart:convert';

import 'game_asset_provenance.dart';
import 'game_asset_registry.dart';

final class GameAssetProvenanceCatalog {
  GameAssetProvenanceCatalog._({
    required this.schemaVersion,
    required List<GameAssetProvenanceRecord> records,
  }) : _records = List.unmodifiable(records),
       _byId = Map.unmodifiable({for (final record in records) record.assetId: record});

  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final List<GameAssetProvenanceRecord> _records;
  final Map<String, GameAssetProvenanceRecord> _byId;

  List<GameAssetProvenanceRecord> get records => _records;

  factory GameAssetProvenanceCatalog.fromJsonString(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException(
        'Asset provenance catalog is not valid JSON: ${error.message}',
      );
    }
    return GameAssetProvenanceCatalog.fromJson(decoded);
  }

  factory GameAssetProvenanceCatalog.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Provenance catalog root must be an object.');
    }
    final map = value.map((key, item) => MapEntry(key.toString(), item));
    final version = map['schemaVersion'];
    if (version is! int) {
      throw const FormatException('schemaVersion must be an integer.');
    }
    if (version != supportedSchemaVersion) {
      throw FormatException(
        'Unsupported provenance schemaVersion $version; expected $supportedSchemaVersion.',
      );
    }

    final rawRecords = map['records'];
    if (rawRecords is! List) {
      throw const FormatException('records must be an array.');
    }

    final records = <GameAssetProvenanceRecord>[];
    final ids = <String>{};
    for (var index = 0; index < rawRecords.length; index++) {
      final record = GameAssetProvenanceRecord.fromJson(rawRecords[index]);
      if (!ids.add(record.assetId)) {
        throw FormatException(
          'Duplicate provenance assetId at records[$index]: ${record.assetId}',
        );
      }
      records.add(record);
    }

    return GameAssetProvenanceCatalog._(
      schemaVersion: version,
      records: records,
    );
  }

  GameAssetProvenanceRecord? find(String assetId) => _byId[assetId];

  GameAssetProvenanceRecord require(String assetId) {
    final record = find(assetId);
    if (record == null) {
      throw StateError('Provenance record is not registered: $assetId');
    }
    return record;
  }

  void validateAgainstRegistry(GameAssetRegistry registry) {
    for (final asset in registry.assets) {
      final record = _byId[asset.id];
      if (record == null) {
        throw FormatException(
          'Runtime asset ${asset.id} has no commercial-use provenance record.',
        );
      }
      record.validateAgainst(asset);
    }

    for (final record in _records) {
      if (!registry.contains(record.assetId)) {
        throw FormatException(
          'Provenance record ${record.assetId} is orphaned from the runtime registry.',
        );
      }
    }
  }
}
