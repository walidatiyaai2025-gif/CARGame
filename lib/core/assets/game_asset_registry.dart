import 'dart:convert';

import 'game_asset.dart';

final class GameAssetRegistry {
  GameAssetRegistry._({required this.schemaVersion, required List<GameAssetDescriptor> assets})
    : _assets = List.unmodifiable(assets),
      _byId = Map.unmodifiable({for (final asset in assets) asset.id: asset});

  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final List<GameAssetDescriptor> _assets;
  final Map<String, GameAssetDescriptor> _byId;

  List<GameAssetDescriptor> get assets => _assets;

  factory GameAssetRegistry.fromJsonString(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Asset manifest is not valid JSON: ${error.message}');
    }
    return GameAssetRegistry.fromJson(decoded);
  }

  factory GameAssetRegistry.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Asset manifest root must be an object.');
    }
    final map = value.map((key, item) => MapEntry(key.toString(), item));
    final version = map['schemaVersion'];
    if (version is! int) {
      throw const FormatException('schemaVersion must be an integer.');
    }
    if (version != supportedSchemaVersion) {
      throw FormatException(
        'Unsupported asset manifest schemaVersion $version; expected $supportedSchemaVersion.',
      );
    }

    final rawAssets = map['assets'];
    if (rawAssets is! List) {
      throw const FormatException('assets must be an array.');
    }

    final assets = <GameAssetDescriptor>[];
    final ids = <String>{};
    for (var index = 0; index < rawAssets.length; index++) {
      final descriptor = GameAssetDescriptor.fromJson(rawAssets[index]);
      if (!ids.add(descriptor.id)) {
        throw FormatException(
          'Duplicate stable asset id at assets[$index]: ${descriptor.id}',
        );
      }
      assets.add(descriptor);
    }

    return GameAssetRegistry._(schemaVersion: version, assets: assets);
  }

  GameAssetDescriptor? find(String id) => _byId[id];

  GameAssetDescriptor require(String id) {
    final descriptor = find(id);
    if (descriptor == null) {
      throw StateError('Asset id is not registered: $id');
    }
    return descriptor;
  }

  bool contains(String id) => _byId.containsKey(id);

  List<GameAssetDescriptor> byCategory(GameAssetCategory category) => List.unmodifiable(
    _assets.where((asset) => asset.category == category),
  );

  List<GameAssetDescriptor> byWorld(GameWorldSlug world) => List.unmodifiable(
    _assets.where((asset) => asset.world == world),
  );

  List<GameAssetDescriptor> byProfile(GameAssetProfile profile) => List.unmodifiable(
    _assets.where((asset) => asset.profile == profile),
  );
}
