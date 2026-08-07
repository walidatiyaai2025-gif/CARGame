import 'package:cargo_sort_game/core/assets/game_asset_provenance.dart';
import 'package:cargo_sort_game/core/assets/game_asset_provenance_catalog.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty provenance catalog validates an empty runtime registry', () {
    final registry = GameAssetRegistry.fromJsonString(
      '{"schemaVersion":1,"assets":[]}',
    );
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      '{"schemaVersion":1,"records":[]}',
    );

    expect(() => provenance.validateAgainstRegistry(registry), returnsNormally);
  });

  test('complete commercial-use record matches its runtime descriptor', () {
    final registry = GameAssetRegistry.fromJsonString(_registryManifest);
    final provenance = GameAssetProvenanceCatalog.fromJsonString(_provenanceCatalog);

    expect(provenance.records, hasLength(1));
    expect(provenance.require('cargo.orange_juice.closed').sourceType, GameAssetSourceType.original);
    expect(() => provenance.validateAgainstRegistry(registry), returnsNormally);
  });

  test('runtime asset without provenance is rejected', () {
    final registry = GameAssetRegistry.fromJsonString(_registryManifest);
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      '{"schemaVersion":1,"records":[]}',
    );

    expect(
      () => provenance.validateAgainstRegistry(registry),
      throwsA(isA<FormatException>()),
    );
  });

  test('orphan provenance record is rejected', () {
    final registry = GameAssetRegistry.fromJsonString(
      '{"schemaVersion":1,"assets":[]}',
    );
    final provenance = GameAssetProvenanceCatalog.fromJsonString(_provenanceCatalog);

    expect(
      () => provenance.validateAgainstRegistry(registry),
      throwsA(isA<FormatException>()),
    );
  });

  test('registry path, dimensions, profile, and revision must match provenance', () {
    final registry = GameAssetRegistry.fromJsonString(_registryManifest);

    for (final invalid in <String>[
      _provenanceCatalog.replaceFirst(
        'assets/3d/runtime/cargo/beverage/cg_cargo_orange_juice_closed_pcargo_v01.webp',
        'assets/3d/runtime/cargo/beverage/cg_cargo_orange_juice_open_pcargo_v01.webp',
      ),
      _provenanceCatalog.replaceFirst('"width": 384', '"width": 512'),
      _provenanceCatalog.replaceFirst('"profile": "pcargo"', '"profile": "pui"'),
      _provenanceCatalog.replaceFirst('"revision": 1', '"revision": 2'),
    ]) {
      final provenance = GameAssetProvenanceCatalog.fromJsonString(invalid);
      expect(
        () => provenance.validateAgainstRegistry(registry),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('commercial-use reference and valid SHA-256 digests are mandatory', () {
    expect(
      () => GameAssetProvenanceCatalog.fromJsonString(
        _provenanceCatalog.replaceFirst(
          '"commercialUseReference": "internal-original-asset-policy-v1"',
          '"commercialUseReference": ""',
        ),
      ),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => GameAssetProvenanceCatalog.fromJsonString(
        _provenanceCatalog.replaceFirst(
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'not-a-sha256',
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('generated assets require prompt metadata', () {
    final generated = _provenanceCatalog
        .replaceFirst('"sourceType": "original"', '"sourceType": "generated"')
        .replaceFirst('"generation": null', '"generation": {"prompt":"","referenceFileIds":[]}');

    expect(
      () => GameAssetProvenanceCatalog.fromJsonString(generated),
      throwsA(isA<FormatException>()),
    );
  });

  test('invalid dates, duplicate IDs, and unsupported schema are rejected', () {
    expect(
      () => GameAssetProvenanceCatalog.fromJsonString(
        _provenanceCatalog.replaceFirst('"approvalDate": "2026-08-07"', '"approvalDate": "2026-02-30"'),
      ),
      throwsA(isA<FormatException>()),
    );

    final duplicate = _provenanceCatalog.replaceFirst(
      ']\n}',
      ',\n    ${_recordJson.replaceAll('\n', '\n    ')}\n  ]\n}',
    );
    expect(
      () => GameAssetProvenanceCatalog.fromJsonString(duplicate),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => GameAssetProvenanceCatalog.fromJsonString(
        _provenanceCatalog.replaceFirst('"schemaVersion": 1', '"schemaVersion": 2'),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

const _registryManifest = '''
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
      "fallback": {"kind": "icon", "token": "local_drink"},
      "dimensions": {"width": 384, "height": 384},
      "rarity": "common",
      "world": "harbor",
      "profile": "pcargo"
    }
  ]
}
''';

const _recordJson = '''{
  "assetId": "cargo.orange_juice.closed",
  "runtimePath": "assets/3d/runtime/cargo/beverage/cg_cargo_orange_juice_closed_pcargo_v01.webp",
  "sourceType": "original",
  "creatorVendorTool": "Cargo Sort internal art pipeline",
  "creationDate": "2026-08-06",
  "commercialUseReference": "internal-original-asset-policy-v1",
  "generation": null,
  "sourceSha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "exportSha256": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "profile": "pcargo",
  "revision": 1,
  "dimensions": {"width": 384, "height": 384},
  "encoder": "cwebp",
  "quality": "q82 method6",
  "reviewer": "art-lead",
  "approvalDate": "2026-08-07",
  "attribution": "",
  "prohibitedUse": ""
}''';

const _provenanceCatalog = '''
{
  "schemaVersion": 1,
  "records": [
    $_recordJson
  ]
}
''';
