import 'package:cargo_sort_game/core/assets/game_asset_intake_plan.dart';
import 'package:cargo_sort_game/core/assets/game_asset_provenance_catalog.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prioritizes partial cargo admissions before fully missing assets', () {
    final registry = GameAssetRegistry.fromJsonString(_manifest());
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      _provenanceCatalog(<String>['cargo.bravo', 'cargo.delta']),
    );

    final plan = GameAssetIntakePlan.build(
      registry: registry,
      provenance: provenance,
      runtimeBinaryPaths: <String>[
        _pathFor('alpha'),
        _pathFor('delta'),
      ],
    );

    expect(plan.items, hasLength(4));
    expect(plan.admittedCount, 1);
    expect(plan.binaryMissingCount, 2);
    expect(plan.provenanceMissingCount, 2);

    final batch = plan.nextBatch(limit: 3);
    expect(
      batch.map((item) => item.descriptor.id),
      <String>['cargo.alpha', 'cargo.bravo', 'cargo.charlie'],
    );
    expect(batch[0].state, GameAssetIntakeState.missingProvenance);
    expect(batch[1].state, GameAssetIntakeState.missingBinary);
    expect(
      batch[2].state,
      GameAssetIntakeState.missingBinaryAndProvenance,
    );
  });

  test('normalizes Windows runtime paths before admission matching', () {
    final registry = GameAssetRegistry.fromJsonString(_manifest());
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      _provenanceCatalog(<String>['cargo.delta']),
    );

    final plan = GameAssetIntakePlan.build(
      registry: registry,
      provenance: provenance,
      runtimeBinaryPaths: <String>[_pathFor('delta').replaceAll('/', '\\')],
    );

    final delta = plan.items.singleWhere(
      (item) => item.descriptor.id == 'cargo.delta',
    );
    expect(delta.state, GameAssetIntakeState.admitted);
  });

  test('rejects invalid batch limits', () {
    final registry = GameAssetRegistry.fromJsonString(_manifest());
    final plan = GameAssetIntakePlan.build(
      registry: registry,
      provenance: GameAssetProvenanceCatalog.fromJsonString(
        '{"schemaVersion":1,"records":[]}',
      ),
      runtimeBinaryPaths: const <String>[],
    );

    expect(() => plan.nextBatch(limit: 0), throwsArgumentError);
  });

  test('validates registered provenance against its descriptor', () {
    final registry = GameAssetRegistry.fromJsonString(_manifest());
    final invalidProvenance = _provenanceCatalog(
      <String>['cargo.bravo'],
    ).replaceFirst(
      '"runtimePath":"${_pathFor('bravo')}"',
      '"runtimePath":"${_pathFor('alpha')}"',
    );

    expect(
      () => GameAssetIntakePlan.build(
        registry: registry,
        provenance: GameAssetProvenanceCatalog.fromJsonString(
          invalidProvenance,
        ),
        runtimeBinaryPaths: const <String>[],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

String _manifest() {
  final assets = <String>[
    _assetJson('alpha', 'Alpha Parcel'),
    _assetJson('bravo', 'Bravo Carton'),
    _assetJson('charlie', 'Charlie Crate'),
    _assetJson('delta', 'Delta Package'),
  ].join(',');
  return '{"schemaVersion":1,"assets":[$assets]}';
}

String _assetJson(String slug, String concept) => '''
{
  "id":"cargo.$slug",
  "path":"${_pathFor(slug)}",
  "category":"cargo",
  "semantics":{
    "englishConcept":"$concept",
    "localizationKey":"cargo",
    "decorative":false
  },
  "fallback":{"kind":"icon","token":"inventory_2"},
  "dimensions":{"width":384,"height":384},
  "rarity":"common",
  "world":null,
  "profile":"pcargo"
}
''';

String _provenanceCatalog(List<String> assetIds) {
  final records = assetIds.map((assetId) {
    final slug = assetId.substring('cargo.'.length);
    return '''
{
  "assetId":"$assetId",
  "runtimePath":"${_pathFor(slug)}",
  "sourceType":"original",
  "creatorVendorTool":"CARGame test fixture",
  "creationDate":"2026-08-11",
  "commercialUseReference":"Test fixture only",
  "generation":null,
  "sourceSha256":"${_digest('a')}",
  "exportSha256":"${_digest('b')}",
  "profile":"pcargo",
  "revision":1,
  "dimensions":{"width":384,"height":384},
  "encoder":"test",
  "quality":"test",
  "reviewer":"test",
  "approvalDate":"2026-08-11",
  "attribution":"",
  "prohibitedUse":""
}
''';
  }).join(',');
  return '{"schemaVersion":1,"records":[$records]}';
}

String _digest(String value) => List<String>.filled(64, value).join();

String _pathFor(String slug) =>
    'assets/3d/runtime/cargo/test/cg_cargo_${slug}_pcargo_v01.webp';