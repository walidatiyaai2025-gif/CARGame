import 'game_asset.dart';

enum GameAssetSourceType {
  original('original'),
  commissioned('commissioned'),
  licensed('licensed'),
  generated('generated');

  const GameAssetSourceType(this.wireName);

  final String wireName;

  static GameAssetSourceType parse(Object? value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => throw FormatException('Unsupported asset source type: $value'),
  );
}

final class GameAssetGenerationProvenance {
  const GameAssetGenerationProvenance({
    required this.prompt,
    required this.referenceFileIds,
  });

  final String prompt;
  final List<String> referenceFileIds;

  factory GameAssetGenerationProvenance.fromJson(Object? value) {
    final map = _expectMap(value, 'generation');
    final prompt = _expectString(map['prompt'], 'generation.prompt');
    final rawReferences = map['referenceFileIds'];
    if (rawReferences is! List) {
      throw const FormatException('generation.referenceFileIds must be an array.');
    }
    final references = <String>[];
    for (var index = 0; index < rawReferences.length; index++) {
      references.add(
        _expectNonEmptyString(
          rawReferences[index],
          'generation.referenceFileIds[$index]',
        ),
      );
    }
    return GameAssetGenerationProvenance(
      prompt: prompt.trim(),
      referenceFileIds: List.unmodifiable(references),
    );
  }
}

final class GameAssetProvenanceRecord {
  GameAssetProvenanceRecord({
    required this.assetId,
    required this.runtimePath,
    required this.sourceType,
    required this.creatorVendorTool,
    required this.creationDate,
    required this.commercialUseReference,
    required this.generation,
    required this.sourceSha256,
    required this.exportSha256,
    required this.profile,
    required this.revision,
    required this.dimensions,
    required this.encoder,
    required this.quality,
    required this.reviewer,
    required this.approvalDate,
    required this.attribution,
    required this.prohibitedUse,
  }) {
    _validateIndependentFields();
  }

  static final RegExp _stableIdPattern = RegExp(
    r'^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+$',
  );
  static final RegExp _sha256Pattern = RegExp(r'^[a-fA-F0-9]{64}$');
  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _revisionPattern = RegExp(r'_v(\d{2})\.webp$');

  final String assetId;
  final String runtimePath;
  final GameAssetSourceType sourceType;
  final String creatorVendorTool;
  final String creationDate;
  final String commercialUseReference;
  final GameAssetGenerationProvenance? generation;
  final String sourceSha256;
  final String exportSha256;
  final GameAssetProfile profile;
  final int revision;
  final GameAssetDimensions dimensions;
  final String encoder;
  final String quality;
  final String reviewer;
  final String approvalDate;
  final String attribution;
  final String prohibitedUse;

  factory GameAssetProvenanceRecord.fromJson(Object? value) {
    final map = _expectMap(value, 'provenance record');
    final sourceType = GameAssetSourceType.parse(map['sourceType']);
    final generationValue = map['generation'];

    return GameAssetProvenanceRecord(
      assetId: _expectNonEmptyString(map['assetId'], 'assetId'),
      runtimePath: _expectNonEmptyString(map['runtimePath'], 'runtimePath'),
      sourceType: sourceType,
      creatorVendorTool: _expectNonEmptyString(
        map['creatorVendorTool'],
        'creatorVendorTool',
      ),
      creationDate: _expectNonEmptyString(map['creationDate'], 'creationDate'),
      commercialUseReference: _expectNonEmptyString(
        map['commercialUseReference'],
        'commercialUseReference',
      ),
      generation: generationValue == null
          ? null
          : GameAssetGenerationProvenance.fromJson(generationValue),
      sourceSha256: _expectNonEmptyString(map['sourceSha256'], 'sourceSha256'),
      exportSha256: _expectNonEmptyString(map['exportSha256'], 'exportSha256'),
      profile: GameAssetProfile.parse(map['profile']),
      revision: _expectPositiveInt(map['revision'], 'revision'),
      dimensions: GameAssetDimensions.fromJson(map['dimensions']),
      encoder: _expectNonEmptyString(map['encoder'], 'encoder'),
      quality: _expectNonEmptyString(map['quality'], 'quality'),
      reviewer: _expectNonEmptyString(map['reviewer'], 'reviewer'),
      approvalDate: _expectNonEmptyString(map['approvalDate'], 'approvalDate'),
      attribution: _expectString(map['attribution'], 'attribution').trim(),
      prohibitedUse: _expectString(map['prohibitedUse'], 'prohibitedUse').trim(),
    );
  }

  void _validateIndependentFields() {
    if (!_stableIdPattern.hasMatch(assetId)) {
      throw FormatException('Invalid provenance assetId: $assetId');
    }
    if (!runtimePath.startsWith('assets/3d/runtime/')) {
      throw FormatException(
        'Provenance runtimePath must stay under assets/3d/runtime/: $runtimePath',
      );
    }
    _validateDate(creationDate, 'creationDate');
    _validateDate(approvalDate, 'approvalDate');
    if (DateTime.parse(approvalDate).isBefore(DateTime.parse(creationDate))) {
      throw const FormatException('approvalDate cannot be before creationDate.');
    }
    if (!_sha256Pattern.hasMatch(sourceSha256)) {
      throw const FormatException('sourceSha256 must be a 64-character SHA-256 hex digest.');
    }
    if (!_sha256Pattern.hasMatch(exportSha256)) {
      throw const FormatException('exportSha256 must be a 64-character SHA-256 hex digest.');
    }
    if (sourceType == GameAssetSourceType.generated) {
      if (generation == null || generation!.prompt.isEmpty) {
        throw const FormatException(
          'Generated assets require a non-empty generation prompt.',
        );
      }
    }
    if (sourceType != GameAssetSourceType.generated &&
        generation != null &&
        generation!.prompt.isNotEmpty) {
      throw const FormatException(
        'generation metadata is reserved for generated assets.',
      );
    }
  }

  void validateAgainst(GameAssetDescriptor asset) {
    if (asset.id != assetId) {
      throw FormatException(
        'Provenance assetId $assetId does not match registry id ${asset.id}.',
      );
    }
    if (asset.path != runtimePath) {
      throw FormatException(
        'Provenance path for $assetId does not match registry path.',
      );
    }
    if (asset.profile != profile) {
      throw FormatException(
        'Provenance profile for $assetId does not match registry profile.',
      );
    }
    if (asset.dimensions.width != dimensions.width ||
        asset.dimensions.height != dimensions.height) {
      throw FormatException(
        'Provenance dimensions for $assetId do not match registry dimensions.',
      );
    }
    final revisionMatch = _revisionPattern.firstMatch(runtimePath);
    if (revisionMatch == null || int.parse(revisionMatch.group(1)!) != revision) {
      throw FormatException(
        'Provenance revision $revision does not match runtime filename for $assetId.',
      );
    }
  }

  static void _validateDate(String value, String field) {
    if (!_datePattern.hasMatch(value)) {
      throw FormatException('$field must use YYYY-MM-DD.');
    }
    try {
      final parsed = DateTime.parse(value);
      final normalized =
          '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      if (normalized != value) {
        throw const FormatException();
      }
    } on FormatException {
      throw FormatException('$field is not a valid calendar date.');
    }
  }
}

Map<String, Object?> _expectMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('$field must be an object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _expectNonEmptyString(Object? value, String field) {
  final result = _expectString(value, field).trim();
  if (result.isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return result;
}

String _expectString(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field must be a string.');
  }
  return value;
}

int _expectPositiveInt(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer.');
  }
  return value;
}
