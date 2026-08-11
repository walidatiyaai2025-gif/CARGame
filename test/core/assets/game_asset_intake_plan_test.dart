import 'package:cargo_sort_game/core/assets/game_asset_intake_plan.dart';
import 'package:cargo_sort_game/core/assets/game_asset_provenance_catalog.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prioritizes partial cargo admissions before fully missing assets', () {
    final plan = _plan(
      provenanceIds: <String>['cargo.bravo', 'cargo.delta'],
      runtimePaths: <String>[_pathFor('alpha'), _pathFor('delta')],
    );

    expect(plan.items, hasLength(4));
    expect(plan.admittedCount, 1);
    expect(plan.binaryMissingCount, 2);
    expect(plan.provenanceMissingCount, 2);

    final batch = plan.nextBatch(limit: 3);
    expect(batch.map((item) => item.descriptor.id), <String>[
      'cargo.alpha',
      'cargo.bravo',
      'cargo.charlie',
    ]);
    expect(batch[0].state, GameAssetIntakeState.missingProvenance);
    expect(batch[1].state, GameAssetIntakeState.missingBinary);
    expect(batch[2].state, GameAssetIntakeState.missingBinaryAndProvenance);
  });

  test('normalizes Windows runtime paths before admission matching', () {
    final plan = _plan(
      provenanceIds: <String>['cargo.delta'],
      runtimePaths: <String>[_pathFor('delta').replaceAll('/', '\\')],
    );

    expect(plan.find('cargo.delta')?.state, GameAssetIntakeState.admitted);
  });

  test('normalizes dot prefixes and duplicate separators', () {
    final path = _pathFor('delta').replaceFirst('assets/', './assets//');
    final plan = _plan(
      provenanceIds: <String>['cargo.delta'],
      runtimePaths: <String>[path],
    );

    expect(plan.find('cargo.delta')?.state, GameAssetIntakeState.admitted);
  });

  test('rejects invalid batch limits', () {
    final plan = _plan();
    expect(() => plan.nextBatch(limit: 0), throwsArgumentError);
  });

  test('rejects negative batch offsets', () {
    final plan = _plan();
    expect(() => plan.nextBatch(offset: -1), throwsArgumentError);
  });

  test('offset slicing remains deterministic after priority sorting', () {
    final plan = _plan(
      provenanceIds: <String>['cargo.bravo', 'cargo.delta'],
      runtimePaths: <String>[_pathFor('alpha'), _pathFor('delta')],
    );

    expect(
      plan.nextBatch(limit: 2, offset: 1).map((item) => item.descriptor.id),
      <String>['cargo.bravo', 'cargo.charlie'],
    );
  });

  test('state filtering selects only requested pending state', () {
    final plan = _plan(
      provenanceIds: <String>['cargo.bravo', 'cargo.delta'],
      runtimePaths: <String>[_pathFor('alpha'), _pathFor('delta')],
    );

    final batch = plan.nextBatch(
      states: <GameAssetIntakeState>{GameAssetIntakeState.missingBinary},
    );
    expect(batch.map((item) => item.descriptor.id), <String>['cargo.bravo']);
  });

  test('summary separates exclusive and aggregate missing counts', () {
    final plan = _plan(
      provenanceIds: <String>['cargo.bravo', 'cargo.delta'],
      runtimePaths: <String>[_pathFor('alpha'), _pathFor('delta')],
    );
    final summary = plan.summary;

    expect(summary.totalCount, 4);
    expect(summary.admittedCount, 1);
    expect(summary.remainingCount, 3);
    expect(summary.missingProvenanceOnlyCount, 1);
    expect(summary.missingBinaryOnlyCount, 1);
    expect(summary.missingBinaryAndProvenanceCount, 1);
    expect(summary.binaryMissingCount, 2);
    expect(summary.provenanceMissingCount, 2);
    expect(summary.completionPercent, 25);
    expect(summary.isComplete, isFalse);
  });

  test('complete intake reports 100 percent and no remaining work', () {
    final plan = _plan(
      provenanceIds: <String>[
        'cargo.alpha',
        'cargo.bravo',
        'cargo.charlie',
        'cargo.delta',
      ],
      runtimePaths: <String>[
        _pathFor('alpha'),
        _pathFor('bravo'),
        _pathFor('charlie'),
        _pathFor('delta'),
      ],
    );

    expect(plan.remainingCount, 0);
    expect(plan.completionRatio, 1);
    expect(plan.summary.completionPercent, 100);
    expect(plan.isComplete, isTrue);
  });

  test('detects orphan cargo runtime WebP but ignores other categories', () {
    final plan = _plan(
      runtimePaths: <String>[
        _pathFor('orphan'),
        'assets/3d/runtime/ui/test/ui_orphan_pui_v01.webp',
      ],
    );

    expect(plan.orphanRuntimeBinaryPaths, <String>[_pathFor('orphan')]);
    expect(plan.summary.orphanRuntimeBinaryCount, 1);
    expect(plan.isComplete, isFalse);
  });

  test('detects orphan cargo provenance IDs deterministically', () {
    final registry = GameAssetRegistry.fromJsonString(_manifest());
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      _provenanceCatalog(<String>['cargo.orphan']),
    );

    final plan = GameAssetIntakePlan.build(
      registry: registry,
      provenance: provenance,
      runtimeBinaryPaths: const <String>[],
    );

    expect(plan.orphanProvenanceAssetIds, <String>['cargo.orphan']);
    expect(plan.summary.orphanProvenanceCount, 1);
  });

  test('find and state-specific listings expose stable immutable views', () {
    final plan = _plan();

    expect(plan.find('cargo.alpha')?.descriptor.id, 'cargo.alpha');
    expect(plan.find('cargo.unknown'), isNull);

    final missingBoth = plan.itemsForState(
      GameAssetIntakeState.missingBinaryAndProvenance,
    );
    expect(missingBoth, hasLength(4));
    expect(
      () => missingBoth.add(missingBoth.first),
      throwsUnsupportedError,
    );
  });

  test('item and summary JSON expose deterministic handoff fields', () {
    final plan = _plan();
    final itemJson = plan.items.first.toJson();
    final summaryJson = plan.summary.toJson();

    expect(itemJson['assetId'], 'cargo.alpha');
    expect(itemJson['runtimePath'], _pathFor('alpha'));
    expect(itemJson['profile'], 'pcargo');
    expect(itemJson['width'], 384);
    expect(itemJson['height'], 384);
    expect(summaryJson['total'], 4);
    expect(summaryJson['remaining'], 4);
    expect(summaryJson['completionPercent'], 0);
  });

  test('validates registered provenance against its descriptor', () {
    final registry = GameAssetRegistry.fromJsonString(_manifest());
    final invalidProvenance = _provenanceCatalog(<String>['cargo.bravo'])
        .replaceFirst(
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

GameAssetIntakePlan _plan({
  List<String> provenanceIds = const <String>[],
  List<String> runtimePaths = const <String>[],
}) => GameAssetIntakePlan.build(
  registry: GameAssetRegistry.fromJsonString(_manifest()),
  provenance: GameAssetProvenanceCatalog.fromJsonString(
    _provenanceCatalog(provenanceIds),
  ),
  runtimeBinaryPaths: runtimePaths,
);

String _manifest() {
  final assets = <String>[
    _assetJson('alpha', 'Alpha Parcel'),
    _assetJson('bravo', 'Bravo Carton'),
    _assetJson('charlie', 'Charlie Crate'),
    _assetJson('delta', 'Delta Package'),
  ].join(',');
  return '{"schemaVersion":1,"assets":[$assets]}';
}

String _assetJson(String slug, String concept) =>
    '''
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
  final records = assetIds
      .map((assetId) {
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
      })
      .join(',');
  return '{"schemaVersion":1,"records":[$records]}';
}

String _digest(String value) => List<String>.filled(64, value).join();

String _pathFor(String slug) =>
    'assets/3d/runtime/cargo/test/cg_cargo_${slug}_pcargo_v01.webp';
