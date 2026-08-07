enum GameAssetCategory {
  ui('ui'),
  booster('booster'),
  cargo('cargo'),
  world('world'),
  city('city'),
  boss('boss'),
  reward('reward'),
  environment('environment'),
  effect('effect');

  const GameAssetCategory(this.wireName);

  final String wireName;

  static GameAssetCategory parse(Object? value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => throw FormatException('Unsupported asset category: $value'),
  );
}

enum GameAssetProfile {
  pui('pui'),
  pcargo('pcargo'),
  pcity('pcity'),
  phero('phero');

  const GameAssetProfile(this.wireName);

  final String wireName;

  static GameAssetProfile parse(Object? value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => throw FormatException('Unsupported asset profile: $value'),
  );
}

enum GameAssetRarity {
  common('common'),
  uncommon('uncommon'),
  rare('rare'),
  epic('epic'),
  legendary('legendary'),
  special('special');

  const GameAssetRarity(this.wireName);

  final String wireName;

  static GameAssetRarity parse(Object? value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => throw FormatException('Unsupported asset rarity: $value'),
  );
}

enum GameWorldSlug {
  harbor('harbor'),
  desert('desert'),
  forest('forest'),
  snow('snow'),
  neon('neon'),
  sky('sky');

  const GameWorldSlug(this.wireName);

  final String wireName;

  static GameWorldSlug? parseNullable(Object? value) {
    if (value == null) return null;
    return values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unsupported world slug: $value'),
    );
  }
}

enum GameAssetFallbackKind {
  icon('icon'),
  text('text'),
  asset('asset'),
  none('none');

  const GameAssetFallbackKind(this.wireName);

  final String wireName;

  static GameAssetFallbackKind parse(Object? value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => throw FormatException('Unsupported fallback kind: $value'),
  );
}

final class GameAssetDimensions {
  const GameAssetDimensions({required this.width, required this.height});

  final int width;
  final int height;

  factory GameAssetDimensions.fromJson(Object? value) {
    final map = _expectMap(value, 'dimensions');
    final width = map['width'];
    final height = map['height'];
    if (width is! int || height is! int || width <= 0 || height <= 0) {
      throw const FormatException(
        'Asset dimensions must contain positive integer width and height.',
      );
    }
    return GameAssetDimensions(width: width, height: height);
  }
}

final class GameAssetSemantics {
  const GameAssetSemantics({
    required this.englishConcept,
    required this.localizationKey,
    required this.decorative,
  });

  final String englishConcept;
  final String localizationKey;
  final bool decorative;

  factory GameAssetSemantics.fromJson(Object? value) {
    final map = _expectMap(value, 'semantics');
    final concept = _expectNonEmptyString(map['englishConcept'], 'englishConcept');
    final decorative = map['decorative'];
    if (decorative is! bool) {
      throw const FormatException('semantics.decorative must be a boolean.');
    }
    final localizationKey = map['localizationKey'];
    if (localizationKey is! String) {
      throw const FormatException('semantics.localizationKey must be a string.');
    }
    if (!decorative && localizationKey.trim().isEmpty) {
      throw const FormatException(
        'Meaningful assets require a semantics.localizationKey.',
      );
    }
    return GameAssetSemantics(
      englishConcept: concept,
      localizationKey: localizationKey.trim(),
      decorative: decorative,
    );
  }
}

final class GameAssetFallback {
  const GameAssetFallback({required this.kind, required this.token});

  final GameAssetFallbackKind kind;
  final String token;

  factory GameAssetFallback.fromJson(Object? value) {
    final map = _expectMap(value, 'fallback');
    final kind = GameAssetFallbackKind.parse(map['kind']);
    final tokenValue = map['token'];
    if (tokenValue is! String) {
      throw const FormatException('fallback.token must be a string.');
    }
    final token = tokenValue.trim();
    if (kind != GameAssetFallbackKind.none && token.isEmpty) {
      throw const FormatException('Non-none fallback kinds require a token.');
    }
    return GameAssetFallback(kind: kind, token: token);
  }
}

final class GameAssetDescriptor {
  GameAssetDescriptor({
    required this.id,
    required this.path,
    required this.category,
    required this.semantics,
    required this.fallback,
    required this.dimensions,
    required this.rarity,
    required this.world,
    required this.profile,
  }) {
    validate();
  }

  static final RegExp _idPattern = RegExp(
    r'^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+$',
  );
  static final RegExp _filePattern = RegExp(
    r'^cg_(ui|booster|cargo|world|city|boss|reward|environment|effect)_[a-z0-9_]+_(pui|pcargo|pcity|phero)_v\d{2}\.webp$',
  );

  final String id;
  final String path;
  final GameAssetCategory category;
  final GameAssetSemantics semantics;
  final GameAssetFallback fallback;
  final GameAssetDimensions dimensions;
  final GameAssetRarity rarity;
  final GameWorldSlug? world;
  final GameAssetProfile profile;

  factory GameAssetDescriptor.fromJson(Object? value) {
    final map = _expectMap(value, 'asset');
    return GameAssetDescriptor(
      id: _expectNonEmptyString(map['id'], 'id'),
      path: _expectNonEmptyString(map['path'], 'path'),
      category: GameAssetCategory.parse(map['category']),
      semantics: GameAssetSemantics.fromJson(map['semantics']),
      fallback: GameAssetFallback.fromJson(map['fallback']),
      dimensions: GameAssetDimensions.fromJson(map['dimensions']),
      rarity: GameAssetRarity.parse(map['rarity']),
      world: GameWorldSlug.parseNullable(map['world']),
      profile: GameAssetProfile.parse(map['profile']),
    );
  }

  void validate() {
    if (!_idPattern.hasMatch(id)) {
      throw FormatException('Invalid stable asset id: $id');
    }
    if (!id.startsWith('${category.wireName}.')) {
      throw FormatException(
        'Asset id $id must begin with ${category.wireName}.',
      );
    }
    const runtimePrefix = 'assets/3d/runtime/';
    if (!path.startsWith(runtimePrefix)) {
      throw FormatException('Asset path must stay under $runtimePrefix: $path');
    }
    final fileName = path.substring(path.lastIndexOf('/') + 1);
    if (!_filePattern.hasMatch(fileName)) {
      throw FormatException('Asset filename does not match the catalog grammar: $fileName');
    }
    final expectedFamily = 'cg_${category.wireName}_';
    if (!fileName.startsWith(expectedFamily)) {
      throw FormatException(
        'Asset filename family must match category ${category.wireName}: $fileName',
      );
    }
    final expectedProfile = '_${profile.wireName}_';
    if (!fileName.contains(expectedProfile)) {
      throw FormatException(
        'Asset filename profile must match ${profile.wireName}: $fileName',
      );
    }
    if (category == GameAssetCategory.cargo && profile != GameAssetProfile.pcargo) {
      throw const FormatException('Cargo assets must use the pcargo profile.');
    }
    if ((category == GameAssetCategory.city || category == GameAssetCategory.boss) &&
        profile != GameAssetProfile.pcity) {
      throw const FormatException('City and boss assets must use the pcity profile.');
    }
    if ((category == GameAssetCategory.ui ||
            category == GameAssetCategory.booster ||
            category == GameAssetCategory.reward ||
            category == GameAssetCategory.effect) &&
        profile != GameAssetProfile.pui) {
      throw const FormatException(
        'UI, booster, reward, and effect assets must use the pui profile.',
      );
    }
    if ((category == GameAssetCategory.world ||
            category == GameAssetCategory.environment) &&
        profile != GameAssetProfile.phero) {
      throw const FormatException('World and environment assets must use phero.');
    }
    if ((category == GameAssetCategory.world || category == GameAssetCategory.city) &&
        world == null) {
      throw const FormatException('World and city assets require a world slug.');
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
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value.trim();
}
