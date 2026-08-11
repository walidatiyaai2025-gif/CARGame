import 'dart:convert';
import 'dart:io';

import 'package:cargo_sort_game/core/assets/game_asset.dart';
import 'package:cargo_sort_game/features/game/cargo_visual_catalog.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AST-007 owns 124 unique visuals across all 18 stable archetypes', () {
    expect(CargoVisualCatalog.variants, hasLength(124));
    expect(
      CargoVisualCatalog.variants.map((variant) => variant.assetId).toSet(),
      hasLength(124),
    );
    expect(
      productCatalog.map((item) => item.id).toList(),
      List<int>.generate(18, (index) => index + 1),
    );

    for (var archetypeId = 1; archetypeId <= 18; archetypeId++) {
      final family = CargoVisualCatalog.forArchetype(archetypeId);
      expect(family.length, greaterThanOrEqualTo(6));
      expect(family.every((item) => item.archetypeId == archetypeId), isTrue);
      expect(
        family.every((item) => item.profile == GameAssetProfile.pcargo),
        isTrue,
      );
    }
  });

  test(
    'resolver is deterministic and does not mutate gameplay level truth',
    () {
      for (final level in levels) {
        final idsBefore = level.items.map((item) => item.id).toList();
        final movesBefore = level.moves;
        final difficultyBefore = level.difficulty;

        for (final item in level.items) {
          final first = CargoVisualCatalog.resolve(
            levelNumber: level.number,
            archetypeId: item.id,
          );
          final second = CargoVisualCatalog.resolve(
            levelNumber: level.number,
            archetypeId: item.id,
          );
          expect(second.assetId, first.assetId);
        }

        expect(level.items.map((item) => item.id).toList(), idsBefore);
        expect(level.moves, movesBefore);
        expect(level.difficulty, difficultyBefore);
      }
    },
  );

  test(
    'real 150-level catalog reaches at least 100 cargo visual identities',
    () {
      final reachable = <String>{};
      for (final level in levels) {
        for (final item in level.items) {
          reachable.add(
            CargoVisualCatalog.resolve(
              levelNumber: level.number,
              archetypeId: item.id,
            ).assetId,
          );
        }
      }
      expect(reachable.length, greaterThanOrEqualTo(100));
    },
  );

  test('manifest cargo descriptors exactly match the typed catalog', () async {
    final decoded =
        jsonDecode(await File('assets/3d/manifest.json').readAsString())
            as Map<String, dynamic>;
    final assets = (decoded['assets'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final cargo = assets
        .where((asset) => asset['category'] == 'cargo')
        .toList();

    expect(cargo, hasLength(124));
    expect(
      cargo.map((asset) => asset['id'] as String).toSet(),
      CargoVisualCatalog.variants.map((variant) => variant.assetId).toSet(),
    );
    for (final descriptor in cargo) {
      expect(descriptor['profile'], 'pcargo');
      expect(descriptor['dimensions'], {'width': 384, 'height': 384});
    }
  });

  test('invalid resolver inputs fail closed', () {
    expect(
      () => CargoVisualCatalog.resolve(levelNumber: 0, archetypeId: 1),
      throwsArgumentError,
    );
    expect(
      () => CargoVisualCatalog.resolve(levelNumber: 1, archetypeId: 99),
      throwsArgumentError,
    );
  });
}
