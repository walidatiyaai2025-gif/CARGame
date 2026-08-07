import 'package:cargo_sort_game/core/assets/game_asset.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validManifest = '''
{
  "schemaVersion": 1,
  "assets": [
    {
      "id": "cargo.orange_juice.closed",
      "path": "assets/3d/runtime/cargo/beverage/cg_cargo_orange_juice_closed_pcargo_v01.webp",
      "category": "cargo",
      "semantics": {
        "englishConcept": "Orange juice bottle",
        "localizationKey": "assetOrangeJuice",
        "decorative": false
      },
      "fallback": {
        "kind": "icon",
        "token": "local_drink"
      },
      "dimensions": {
        "width": 384,
        "height": 384
      },
      "rarity": "common",
      "world": "harbor",
      "profile": "pcargo"
    },
    {
      "id": "city.harbor_gate.locked",
      "path": "assets/3d/runtime/cities/harbor/cg_city_harbor_gate_locked_pcity_v01.webp",
      "category": "city",
      "semantics": {
        "englishConcept": "Locked harbor city gate",
        "localizationKey": "assetHarborGateLocked",
        "decorative": false
      },
      "fallback": {
        "kind": "icon",
        "token": "lock"
      },
      "dimensions": {
        "width": 512,
        "height": 512
      },
      "rarity": "special",
      "world": "harbor",
      "profile": "pcity"
    }
  ]
}
''';

  test('accepts an empty versioned manifest while binary admission is gated', () {
    final registry = GameAssetRegistry.fromJsonString(
      '{"schemaVersion":1,"assets":[]}',
    );

    expect(registry.schemaVersion, GameAssetRegistry.supportedSchemaVersion);
    expect(registry.assets, isEmpty);
  });

  test('parses typed records and supports stable queries', () {
    final registry = GameAssetRegistry.fromJsonString(validManifest);

    expect(registry.assets, hasLength(2));
    expect(registry.require('cargo.orange_juice.closed').category, GameAssetCategory.cargo);
    expect(registry.require('cargo.orange_juice.closed').profile, GameAssetProfile.pcargo);
    expect(registry.byCategory(GameAssetCategory.city), hasLength(1));
    expect(registry.byWorld(GameWorldSlug.harbor), hasLength(2));
    expect(registry.find('cargo.missing'), isNull);
  });

  test('rejects duplicate stable IDs', () {
    final duplicate = validManifest.replaceFirst(
      '"id": "city.harbor_gate.locked"',
      '"id": "cargo.orange_juice.closed"',
    ).replaceFirst(
      '"category": "city"',
      '"category": "cargo"',
    ).replaceFirst(
      'cg_city_harbor_gate_locked_pcity_v01.webp',
      'cg_cargo_harbor_gate_locked_pcargo_v01.webp',
    ).replaceFirst(
      '"profile": "pcity"',
      '"profile": "pcargo"',
    );

    expect(
      () => GameAssetRegistry.fromJsonString(duplicate),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects duplicate runtime paths', () {
    final duplicate = validManifest.replaceFirst(
      'assets/3d/runtime/cities/harbor/cg_city_harbor_gate_locked_pcity_v01.webp',
      'assets/3d/runtime/cargo/beverage/cg_cargo_orange_juice_closed_pcargo_v01.webp',
    );

    expect(
      () => GameAssetRegistry.fromJsonString(duplicate),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects paths outside the governed runtime taxonomy', () {
    final invalid = validManifest.replaceFirst(
      'assets/3d/runtime/cargo/beverage/',
      'assets/images/',
    );

    expect(
      () => GameAssetRegistry.fromJsonString(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects category and profile mismatches', () {
    final invalid = validManifest.replaceFirst(
      '"profile": "pcargo"',
      '"profile": "pui"',
    ).replaceFirst('_pcargo_', '_pui_');

    expect(
      () => GameAssetRegistry.fromJsonString(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('requires localization keys for meaningful assets', () {
    final invalid = validManifest.replaceFirst(
      '"localizationKey": "assetOrangeJuice"',
      '"localizationKey": ""',
    );

    expect(
      () => GameAssetRegistry.fromJsonString(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects missing asset fallback references', () {
    final invalid = validManifest.replaceFirst(
      '"kind": "icon",\n        "token": "local_drink"',
      '"kind": "asset",\n        "token": "cargo.missing.fallback"',
    );

    expect(
      () => GameAssetRegistry.fromJsonString(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects unsupported schema versions and enum values', () {
    expect(
      () => GameAssetRegistry.fromJsonString(
        validManifest.replaceFirst('"schemaVersion": 1', '"schemaVersion": 2'),
      ),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => GameAssetRegistry.fromJsonString(
        validManifest.replaceFirst('"rarity": "common"', '"rarity": "mythic"'),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
