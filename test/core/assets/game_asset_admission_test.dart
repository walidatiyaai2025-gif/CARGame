import 'package:cargo_sort_game/core/assets/game_asset_admission.dart';
import 'package:cargo_sort_game/core/assets/game_asset_provenance_catalog.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planned manifest entries may exist before binary art is authored', () {
    final registry = GameAssetRegistry.fromJsonString(_registryManifest);
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      '{"schemaVersion":1,"records":[]}',
    );

    expect(
      () => GameAssetAdmission.validate(
        registry: registry,
        provenance: provenance,
        runtimeBinaryPaths: const <String>[],
      ),
      returnsNormally,
    );
  });

  test('unregistered runtime binary is rejected', () {
    final registry = GameAssetRegistry.fromJsonString(
      '{"schemaVersion":1,"assets":[]}',
    );
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      '{"schemaVersion":1,"records":[]}',
    );

    expect(
      () => GameAssetAdmission.validate(
        registry: registry,
        provenance: provenance,
        runtimeBinaryPaths: const [
          'assets/3d/runtime/ui/cg_ui_heart_pui_v01.webp',
        ],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('registered runtime binary without provenance is rejected', () {
    final registry = GameAssetRegistry.fromJsonString(_registryManifest);
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      '{"schemaVersion":1,"records":[]}',
    );

    expect(
      () => GameAssetAdmission.validate(
        registry: registry,
        provenance: provenance,
        runtimeBinaryPaths: const [_runtimePath],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('complete matching registry, provenance, and binary are accepted', () {
    final registry = GameAssetRegistry.fromJsonString(_registryManifest);
    final provenance = GameAssetProvenanceCatalog.fromJsonString(_provenanceCatalog);

    expect(
      () => GameAssetAdmission.validate(
        registry: registry,
        provenance: provenance,
        runtimeBinaryPaths: const [_runtimePath],
      ),
      returnsNormally,
    );
  });

  test('approved provenance without its binary is rejected', () {
    final registry = GameAssetRegistry.fromJsonString(_registryManifest);
    final provenance = GameAssetProvenanceCatalog.fromJsonString(_provenanceCatalog);

    expect(
      () => GameAssetAdmission.validate(
        registry: registry,
        provenance: provenance,
        runtimeBinaryPaths: const <String>[],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

const _runtimePath =
    'assets/3d/runtime/cargo/beverage/cg_cargo_orange_juice_closed_pcargo_v01.webp';

const _registryManifest = '''
{
  "schemaVersion": 1,
  "assets": [
    {
      "id": "cargo.orange_juice.closed",
      "path": "$_runtimePath",
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

const _provenanceCatalog = '''
{
  "schemaVersion": 1,
  "records": [
    {
      "assetId": "cargo.orange_juice.closed",
      "runtimePath": "$_runtimePath",
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
    }
  ]
}
''';
