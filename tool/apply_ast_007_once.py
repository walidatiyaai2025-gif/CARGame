#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

FAMILIES = [
    (1, 'special', ['premium_parcel','courier_carton','sealed_box','express_crate','document_case','eco_mailer','fragile_parcel','insulated_mailer']),
    (2, 'travel', ['hard_shell_suitcase','cabin_case','duffel_bag','travel_backpack','garment_case','passport_pouch','rolling_trunk','weekend_case']),
    (3, 'food', ['apple_crate','citrus_box','vegetable_basket','bakery_box','grocery_tote','pantry_case','fruit_basket','dairy_cooler']),
    (4, 'electronics', ['smartphone_box','tablet_case','laptop_carton','camera_case','headphone_box','console_package','speaker_box','wearable_case']),
    (5, 'fashion', ['apparel_box','folded_shirt_case','jacket_bag','accessory_box','handbag_case','boutique_carton','hat_box','textile_pack']),
    (6, 'sports', ['basketball_bag','football_kit','tennis_case','training_bag','helmet_box','fitness_gear','golf_case','cycling_kit']),
    (7, 'office', ['hardcover_crate','textbook_box','magazine_bundle','comic_case','library_carton','journal_pack','archive_box','stationery_bundle']),
    (8, 'toys', ['building_blocks','toy_robot_box','puzzle_case','plush_crate','board_game_box','model_kit','action_figure_box','craft_kit']),
    (9, 'household', ['skincare_case','perfume_box','cosmetics_bag','haircare_pack','spa_kit','grooming_case']),
    (10, 'household', ['wrench_case','drill_box','hand_tool_crate','measuring_kit','workshop_case','hardware_pack']),
    (11, 'beverage', ['water_pack','juice_crate','soda_case','coffee_box','tea_case','energy_drink_pack']),
    (12, 'special', ['ribbon_gift_box','celebration_bag','premium_hamper','surprise_crate','floral_gift_case','holiday_box']),
    (13, 'household', ['lamp_box','cushion_pack','kitchenware_crate','decor_vase_case','storage_basket','linen_box']),
    (14, 'fashion', ['sneaker_box','boot_carton','running_shoe_case','formal_shoe_box','sandal_pack','hiking_shoe_case']),
    (15, 'household', ['pet_food_bag','pet_toy_pack','carrier_box','pet_grooming_kit','bowl_set','collar_case']),
    (16, 'special', ['first_aid_case','medicine_box','wellness_pack','clinic_crate','care_kit','medical_supply_case']),
    (17, 'special', ['brake_parts_box','filter_case','battery_pack','auto_part_crate','light_assembly_box','accessory_carton']),
    (18, 'special', ['jewelry_case','luxury_watch_box','designer_case','collector_crate','gold_package','premium_vault_box']),
]

EXPECTED_VARIANTS = sum(len(slugs) for _, _, slugs in FAMILIES)
assert EXPECTED_VARIANTS == 124


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'{path}: required patch anchor missing:\n{old}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


def humanize(slug: str) -> str:
    return ' '.join(word.capitalize() for word in slug.split('_'))


def dart_catalog() -> str:
    family_blocks = []
    for archetype_id, folder, slugs in FAMILIES:
        slug_lines = ',\n'.join(f"        '{slug}'" for slug in slugs)
        family_blocks.append(
            "    _CargoVisualFamily(\n"
            f"      archetypeId: {archetype_id},\n"
            f"      folder: '{folder}',\n"
            "      subjectSlugs: <String>[\n"
            f"{slug_lines},\n"
            "      ],\n"
            "    ),"
        )
    families = '\n'.join(family_blocks)
    return f"""import '../../core/assets/game_asset.dart';

/// Stable visual identity for one cargo product representation.
///
/// [archetypeId] remains separate from the visual ID: gameplay matching,
/// persistence and rewards continue to use the existing 1..18 CargoItem IDs.
final class CargoVisualVariant {{
  const CargoVisualVariant({{
    required this.assetId,
    required this.archetypeId,
    required this.subjectSlug,
    required this.englishConcept,
    required this.runtimePath,
    required this.profile,
  }});

  final String assetId;
  final int archetypeId;
  final String subjectSlug;
  final String englishConcept;
  final String runtimePath;
  final GameAssetProfile profile;
}}

/// AST-007 source-controlled catalog and deterministic resolver.
///
/// The resolver is deliberately independent from the level generator. Changing
/// visual art must never change cargo ordering, moves, difficulty or save IDs.
final class CargoVisualCatalog {{
  const CargoVisualCatalog._();

  static const int minArchetypeId = 1;
  static const int maxArchetypeId = 18;
  static const int expectedVariantCount = {EXPECTED_VARIANTS};

  static const List<_CargoVisualFamily> _families = <_CargoVisualFamily>[
{families}
  ];

  static final List<CargoVisualVariant> variants =
      List<CargoVisualVariant>.unmodifiable(<CargoVisualVariant>[
        for (final family in _families)
          for (final subject in family.subjectSlugs)
            CargoVisualVariant(
              assetId: 'cargo.$subject',
              archetypeId: family.archetypeId,
              subjectSlug: subject,
              englishConcept: _humanize(subject),
              runtimePath:
                  'assets/3d/runtime/cargo/${{family.folder}}/'
                  'cg_cargo_${{subject}}_pcargo_v01.webp',
              profile: GameAssetProfile.pcargo,
            ),
      ]);

  static final Map<int, List<CargoVisualVariant>> _byArchetype =
      _buildByArchetype();

  static List<CargoVisualVariant> forArchetype(int archetypeId) {{
    final variants = _byArchetype[archetypeId];
    if (variants == null) {{
      throw ArgumentError.value(
        archetypeId,
        'archetypeId',
        'Unknown cargo gameplay archetype',
      );
    }}
    return variants;
  }}

  static CargoVisualVariant resolve({{
    required int levelNumber,
    required int archetypeId,
  }}) {{
    if (levelNumber < 1) {{
      throw ArgumentError.value(levelNumber, 'levelNumber', 'Must be positive');
    }}
    final family = forArchetype(archetypeId);
    final index = ((levelNumber - 1) * 31 + archetypeId * 17) % family.length;
    return family[index];
  }}

  static Map<int, List<CargoVisualVariant>> _buildByArchetype() {{
    if (variants.length != expectedVariantCount) {{
      throw StateError(
        'AST-007 expected $expectedVariantCount cargo variants, '
        'found ${{variants.length}}',
      );
    }}

    final ids = <String>{{}};
    final result = <int, List<CargoVisualVariant>>{{}};
    for (final variant in variants) {{
      if (variant.archetypeId < minArchetypeId ||
          variant.archetypeId > maxArchetypeId) {{
        throw StateError('Unknown cargo archetype: ${{variant.archetypeId}}');
      }}
      if (!ids.add(variant.assetId)) {{
        throw StateError('Duplicate cargo visual asset ID: ${{variant.assetId}}');
      }}
      if (variant.profile != GameAssetProfile.pcargo) {{
        throw StateError('Cargo visual must use pcargo: ${{variant.assetId}}');
      }}
      result.putIfAbsent(variant.archetypeId, () => <CargoVisualVariant>[]).add(
        variant,
      );
    }}

    for (
      var archetypeId = minArchetypeId;
      archetypeId <= maxArchetypeId;
      archetypeId++
    ) {{
      final family = result[archetypeId];
      if (family == null || family.isEmpty) {{
        throw StateError('Cargo archetype $archetypeId has no visual variants');
      }}
      result[archetypeId] = List<CargoVisualVariant>.unmodifiable(family);
    }}
    return Map<int, List<CargoVisualVariant>>.unmodifiable(result);
  }}

  static String _humanize(String slug) => slug
      .split('_')
      .map((word) => word.isEmpty ? word : '${{word[0].toUpperCase()}}${{word.substring(1)}}')
      .join(' ');
}}

final class _CargoVisualFamily {{
  const _CargoVisualFamily({{
    required this.archetypeId,
    required this.folder,
    required this.subjectSlugs,
  }});

  final int archetypeId;
  final String folder;
  final List<String> subjectSlugs;
}}
"""


def cargo_asset_bridge() -> str:
    return """import 'package:flutter/material.dart';

import '../../core/assets/game_manifest_asset_view.dart';
import 'cargo_visual_catalog.dart';
import 'level_data.dart';

/// Resolves AST-007 visual identity without changing CargoItem gameplay truth.
final class CargoVisualAsset extends StatelessWidget {
  const CargoVisualAsset({
    super.key,
    required this.item,
    required this.levelNumber,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final CargoItem item;
  final int levelNumber;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final visual = CargoVisualCatalog.resolve(
      levelNumber: levelNumber,
      archetypeId: item.id,
    );
    return KeyedSubtree(
      key: ValueKey<String>('cargo-visual-${visual.assetId}'),
      child: GameManifestAssetView(
        assetId: visual.assetId,
        fallback: fallback,
        errorFallback: fallback,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel ?? item.name,
      ),
    );
  }
}
"""


def catalog_test() -> str:
    return """import 'dart:convert';
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
      expect(family.every((item) => item.profile == GameAssetProfile.pcargo), isTrue);
    }
  });

  test('resolver is deterministic and does not mutate gameplay level truth', () {
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
  });

  test('real 150-level catalog reaches at least 100 cargo visual identities', () {
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
  });

  test('manifest cargo descriptors exactly match the typed catalog', () async {
    final decoded = jsonDecode(
      await File('assets/3d/manifest.json').readAsString(),
    ) as Map<String, dynamic>;
    final assets = (decoded['assets'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final cargo = assets.where((asset) => asset['category'] == 'cargo').toList();

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
"""


def asset_test() -> str:
    return """import 'package:cargo_sort_game/core/assets/game_manifest_asset_view.dart';
import 'package:cargo_sort_game/features/game/cargo_visual_asset.dart';
import 'package:cargo_sort_game/features/game/cargo_visual_catalog.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(GameManifestAssetView.resetRegistryCache);

  testWidgets('missing cargo runtime binary keeps the explicit Flutter fallback', (
    tester,
  ) async {
    final item = productCatalog.first;
    const fallbackKey = ValueKey<String>('ast007-fallback');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CargoVisualAsset(
              item: item,
              levelNumber: 1,
              width: 48,
              height: 48,
              fallback: Icon(item.icon, key: fallbackKey),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(fallbackKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same level and archetype expose one stable visual identity', (
    tester,
  ) async {
    final item = productCatalog[3];
    final variant = CargoVisualCatalog.resolve(
      levelNumber: 57,
      archetypeId: item.id,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (var index = 0; index < 3; index++)
              CargoVisualAsset(
                item: item,
                levelNumber: 57,
                fallback: Icon(item.icon),
              ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(ValueKey<String>('cargo-visual-${variant.assetId}')),
      findsNWidgets(3),
    );
  });
}
"""


def validator() -> str:
    return r'''#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

EXPECTED_CARGO_COUNT = 124
REQUIRED_FILES = [
    'assets/3d/manifest.json',
    'lib/features/game/cargo_visual_catalog.dart',
    'lib/features/game/cargo_visual_asset.dart',
    'lib/features/game/gameplay_operations_deck.dart',
    'lib/features/game/game_screen.dart',
    'lib/features/game/level_data.dart',
    'test/features/game/cargo_visual_catalog_test.dart',
    'test/features/game/cargo_visual_asset_test.dart',
    'docs/FEATURE_CATALOG.md',
    '.github/workflows/flutter_ci.yml',
]


class ValidationError(RuntimeError):
    pass


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise ValidationError(f'missing AST-007 file: {relative}')
    return path.read_text(encoding='utf-8')


def validate(root: Path = Path('.')) -> None:
    for relative in REQUIRED_FILES:
        if not (root / relative).is_file():
            raise ValidationError(f'missing AST-007 file: {relative}')

    manifest = json.loads(_read(root, 'assets/3d/manifest.json'))
    assets = manifest.get('assets')
    if not isinstance(assets, list):
        raise ValidationError('manifest assets must be a list')
    cargo = [item for item in assets if item.get('category') == 'cargo']
    if len(cargo) != EXPECTED_CARGO_COUNT:
        raise ValidationError(
            f'expected {EXPECTED_CARGO_COUNT} cargo descriptors, found {len(cargo)}'
        )
    cargo_ids = [item.get('id') for item in cargo]
    if len(set(cargo_ids)) != EXPECTED_CARGO_COUNT:
        raise ValidationError('cargo descriptor IDs must be unique')

    path_pattern = re.compile(
        r'^assets/3d/runtime/cargo/[a-z0-9_]+/cg_cargo_[a-z0-9_]+_pcargo_v01\.webp$'
    )
    for item in cargo:
        if not isinstance(item.get('id'), str) or not item['id'].startswith('cargo.'):
            raise ValidationError('cargo descriptor ID must use cargo.* namespace')
        if item.get('profile') != 'pcargo':
            raise ValidationError(f"cargo descriptor {item.get('id')} must use pcargo")
        if item.get('dimensions') != {'width': 384, 'height': 384}:
            raise ValidationError(f"cargo descriptor {item.get('id')} must be 384x384")
        if not isinstance(item.get('path'), str) or not path_pattern.match(item['path']):
            raise ValidationError(f"cargo descriptor {item.get('id')} has invalid runtime path")

    catalog = _read(root, 'lib/features/game/cargo_visual_catalog.dart')
    families = re.findall(r'_CargoVisualFamily\(\s*archetypeId:\s*(\d+),', catalog)
    if sorted(map(int, families)) != list(range(1, 19)):
        raise ValidationError('typed catalog must define archetypes 1..18 exactly once')
    slugs = re.findall(r"^\s+'([a-z0-9_]+)',?$", catalog, flags=re.M)
    if len(slugs) != EXPECTED_CARGO_COUNT or len(set(slugs)) != EXPECTED_CARGO_COUNT:
        raise ValidationError('typed catalog must own 124 unique subject slugs')
    if {f'cargo.{slug}' for slug in slugs} != set(cargo_ids):
        raise ValidationError('typed catalog and manifest cargo IDs must match exactly')
    for token in [
        'expectedVariantCount = 124',
        'required int levelNumber',
        'required int archetypeId',
        "'assets/3d/runtime/cargo/",
        'GameAssetProfile.pcargo',
    ]:
        if token not in catalog:
            raise ValidationError(f'cargo visual catalog missing contract: {token}')

    level_data = _read(root, 'lib/features/game/level_data.dart')
    archetype_ids = [
        int(value)
        for value in re.findall(r'CargoItem\(\s*id:\s*(\d+),', level_data)
    ]
    if archetype_ids != list(range(1, 19)):
        raise ValidationError('gameplay CargoItem IDs must remain exactly 1..18')
    if 'Random(number * 7919 + 2026)' not in level_data:
        raise ValidationError('deterministic level generator seed changed')

    bridge = _read(root, 'lib/features/game/cargo_visual_asset.dart')
    for token in [
        'CargoVisualCatalog.resolve(',
        'GameManifestAssetView(',
        'errorFallback: fallback',
        "'cargo-visual-${visual.assetId}'",
    ]:
        if token not in bridge:
            raise ValidationError(f'cargo visual bridge missing contract: {token}')

    deck = _read(root, 'lib/features/game/gameplay_operations_deck.dart')
    if deck.count('CargoVisualAsset(') < 3:
        raise ValidationError('cargo bay, warehouse and flight must all use CargoVisualAsset')
    if "import 'cargo_visual_asset.dart';" not in deck:
        raise ValidationError('gameplay deck missing cargo visual bridge import')

    game = _read(root, 'lib/features/game/game_screen.dart')
    if game.count('levelNumber: widget.level.number') < 3:
        raise ValidationError('game screen must pass level identity to all cargo visual surfaces')

    catalog_doc = _read(root, 'docs/FEATURE_CATALOG.md')
    if '| AST-007 | 100+ 3D cargo product pack | P1 | IN PROGRESS |' not in catalog_doc and \
       '| AST-007 | 100+ 3D cargo product pack | P1 | IMPLEMENTED |' not in catalog_doc:
        raise ValidationError('AST-007 catalog tracking is not owned by this workstream')

    ci = _read(root, '.github/workflows/flutter_ci.yml')
    for token in [
        'Verify AST-007 cargo visual pack',
        'Test AST-007 cargo visual validator',
        'Test AST-007 cargo visual pack',
    ]:
        if token not in ci:
            raise ValidationError(f'normal Flutter CI missing AST-007 gate: {token}')


if __name__ == '__main__':
    validate()
    print('AST-007 CARGO VISUAL CONTRACT PASSED (124 descriptors / 18 archetypes)')
'''


def validator_tests() -> str:
    return r'''#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

import verify_ast_007_cargo_visuals as verifier

ROOT = Path(__file__).resolve().parents[1]


def fixture() -> Path:
    root = Path(tempfile.mkdtemp(prefix='ast007-validator-'))
    for relative in verifier.REQUIRED_FILES:
        source = ROOT / relative
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return root


def expect_failure(root: Path, expected: str) -> None:
    try:
        verifier.validate(root)
    except verifier.ValidationError as error:
        assert expected in str(error), (expected, str(error))
    else:
        raise AssertionError(f'expected failure containing {expected!r}')


def replace(root: Path, relative: str, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text(encoding='utf-8')
    assert old in text, (relative, old)
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


def test_valid() -> None:
    root = fixture()
    try:
        verifier.validate(root)
    finally:
        shutil.rmtree(root)


def test_rejects_missing_descriptor() -> None:
    root = fixture()
    try:
        path = root / 'assets/3d/manifest.json'
        data = json.loads(path.read_text(encoding='utf-8'))
        data['assets'] = [item for item in data['assets'] if item.get('id') != 'cargo.premium_parcel']
        path.write_text(json.dumps(data), encoding='utf-8')
        expect_failure(root, 'expected 124 cargo descriptors')
    finally:
        shutil.rmtree(root)


def test_rejects_wrong_profile() -> None:
    root = fixture()
    try:
        replace(root, 'assets/3d/manifest.json', '"profile": "pcargo"', '"profile": "pui"')
        expect_failure(root, 'must use pcargo')
    finally:
        shutil.rmtree(root)


def test_rejects_catalog_manifest_drift() -> None:
    root = fixture()
    try:
        replace(root, 'lib/features/game/cargo_visual_catalog.dart', "'premium_parcel'", "'premium_parcel_changed'")
        expect_failure(root, 'typed catalog and manifest cargo IDs')
    finally:
        shutil.rmtree(root)


def test_rejects_gameplay_id_drift() -> None:
    root = fixture()
    try:
        replace(root, 'lib/features/game/level_data.dart', 'id: 18,', 'id: 118,')
        expect_failure(root, 'CargoItem IDs must remain exactly 1..18')
    finally:
        shutil.rmtree(root)


def test_rejects_missing_ui_bridge() -> None:
    root = fixture()
    try:
        replace(root, 'lib/features/game/gameplay_operations_deck.dart', 'CargoVisualAsset(', 'SizedBox(')
        replace(root, 'lib/features/game/gameplay_operations_deck.dart', 'CargoVisualAsset(', 'SizedBox(')
        replace(root, 'lib/features/game/gameplay_operations_deck.dart', 'CargoVisualAsset(', 'SizedBox(')
        expect_failure(root, 'cargo bay, warehouse and flight')
    finally:
        shutil.rmtree(root)


def test_rejects_ci_drift() -> None:
    root = fixture()
    try:
        replace(root, '.github/workflows/flutter_ci.yml', 'Verify AST-007 cargo visual pack', 'Verify removed cargo visual pack')
        expect_failure(root, 'normal Flutter CI missing AST-007 gate')
    finally:
        shutil.rmtree(root)


def main() -> None:
    tests = [
        test_valid,
        test_rejects_missing_descriptor,
        test_rejects_wrong_profile,
        test_rejects_catalog_manifest_drift,
        test_rejects_gameplay_id_drift,
        test_rejects_missing_ui_bridge,
        test_rejects_ci_drift,
    ]
    for test in tests:
        test()
        print(f'PASS: {test.__name__}')
    print(f'AST-007 validator regressions: {len(tests)}/{len(tests)} PASS')


if __name__ == '__main__':
    main()
'''


# Generate typed source + tests.
Path('lib/features/game/cargo_visual_catalog.dart').write_text(dart_catalog(), encoding='utf-8')
Path('lib/features/game/cargo_visual_asset.dart').write_text(cargo_asset_bridge(), encoding='utf-8')
Path('test/features/game/cargo_visual_catalog_test.dart').write_text(catalog_test(), encoding='utf-8')
Path('test/features/game/cargo_visual_asset_test.dart').write_text(asset_test(), encoding='utf-8')
Path('tool/verify_ast_007_cargo_visuals.py').write_text(validator(), encoding='utf-8')
Path('tool/test_ast_007_cargo_visuals.py').write_text(validator_tests(), encoding='utf-8')

# Extend manifest with descriptor-only cargo identities. Actual binaries remain absent.
manifest_path = Path('assets/3d/manifest.json')
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
manifest['assets'] = [asset for asset in manifest['assets'] if asset.get('category') != 'cargo']
for archetype_id, folder, slugs in FAMILIES:
    for slug in slugs:
        manifest['assets'].append({
            'id': f'cargo.{slug}',
            'path': f'assets/3d/runtime/cargo/{folder}/cg_cargo_{slug}_pcargo_v01.webp',
            'category': 'cargo',
            'semantics': {
                'englishConcept': humanize(slug),
                'localizationKey': 'cargo',
                'decorative': False,
            },
            'fallback': {'kind': 'icon', 'token': 'inventory_2'},
            'dimensions': {'width': 384, 'height': 384},
            'rarity': 'common',
            'world': None,
            'profile': 'pcargo',
        })
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')

# Production gameplay bridge.
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "import 'cargo_motion_tile.dart';\nimport 'level_data.dart';",
    "import 'cargo_motion_tile.dart';\nimport 'cargo_visual_asset.dart';\nimport 'level_data.dart';",
)
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "    required this.isArabic,\n    required this.accent,\n  });\n\n  final List<CargoItem> items;",
    "    required this.isArabic,\n    required this.accent,\n    this.levelNumber = 1,\n  });\n\n  final List<CargoItem> items;",
)
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "  final bool isArabic;\n  final Color accent;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    padding: EdgeInsets.fromLTRB(\n      compact ? 7 : 10,",
    "  final bool isArabic;\n  final Color accent;\n  final int levelNumber;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    padding: EdgeInsets.fromLTRB(\n      compact ? 7 : 10,",
)
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "                            Icon(\n                              item.icon,\n                              color: Colors.white,\n                              size: compact ? 25 : 33,\n                            ),",
    "                            CargoVisualAsset(\n                              item: item,\n                              levelNumber: levelNumber,\n                              width: compact ? 28 : 36,\n                              height: compact ? 28 : 36,\n                              fallback: Icon(\n                                item.icon,\n                                color: Colors.white,\n                                size: compact ? 25 : 33,\n                              ),\n                            ),",
)
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "    required this.isArabic,\n    required this.accent,\n  });\n\n  final List<CargoItem> warehouses;",
    "    required this.isArabic,\n    required this.accent,\n    this.levelNumber = 1,\n  });\n\n  final List<CargoItem> warehouses;",
)
# Replace the second matching field block (first one now includes levelNumber).
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "  final bool isArabic;\n  final Color accent;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    padding: EdgeInsets.fromLTRB(\n      compact ? 7 : 10,",
    "  final bool isArabic;\n  final Color accent;\n  final int levelNumber;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    padding: EdgeInsets.fromLTRB(\n      compact ? 7 : 10,",
)
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "                                Icon(\n                                  Icons.warehouse_rounded,\n                                  color: item.color,\n                                  size: compact ? 27 : 37,\n                                ),",
    "                                CargoVisualAsset(\n                                  item: item,\n                                  levelNumber: levelNumber,\n                                  width: compact ? 30 : 40,\n                                  height: compact ? 30 : 40,\n                                  fallback: Icon(\n                                    item.icon,\n                                    color: item.color,\n                                    size: compact ? 27 : 37,\n                                  ),\n                                ),",
)
replace_once(
    'lib/features/game/gameplay_operations_deck.dart',
    "class GameplayFlightCargo extends StatelessWidget {\n  const GameplayFlightCargo({super.key, required this.item});\n\n  final CargoItem item;\n\n  @override\n  Widget build(BuildContext context) => DecoratedBox(\n    decoration: BoxDecoration(\n      gradient: LinearGradient(colors: [item.accentColor, item.color]),\n      borderRadius: BorderRadius.circular(18),\n      border: Border.all(color: Colors.white, width: 3),\n      boxShadow: [\n        BoxShadow(\n          color: item.color.withValues(alpha: .46),\n          blurRadius: 20,\n          offset: const Offset(0, 10),\n        ),\n      ],\n    ),\n    child: Icon(item.icon, color: Colors.white, size: 32),\n  );\n}",
    "class GameplayFlightCargo extends StatelessWidget {\n  const GameplayFlightCargo({\n    super.key,\n    required this.item,\n    this.levelNumber = 1,\n  });\n\n  final CargoItem item;\n  final int levelNumber;\n\n  @override\n  Widget build(BuildContext context) => DecoratedBox(\n    decoration: BoxDecoration(\n      gradient: LinearGradient(colors: [item.accentColor, item.color]),\n      borderRadius: BorderRadius.circular(18),\n      border: Border.all(color: Colors.white, width: 3),\n      boxShadow: [\n        BoxShadow(\n          color: item.color.withValues(alpha: .46),\n          blurRadius: 20,\n          offset: const Offset(0, 10),\n        ),\n      ],\n    ),\n    child: CargoVisualAsset(\n      item: item,\n      levelNumber: levelNumber,\n      width: 42,\n      height: 42,\n      fallback: Icon(item.icon, color: Colors.white, size: 32),\n    ),\n  );\n}",
)

replace_once(
    'lib/features/game/game_screen.dart',
    "                          child: GameplayCargoBoard(\n                            items: _remaining,",
    "                          child: GameplayCargoBoard(\n                            levelNumber: widget.level.number,\n                            items: _remaining,",
)
replace_once(
    'lib/features/game/game_screen.dart',
    "                          child: GameplayWarehouseBoard(\n                            warehouses: _warehouses,",
    "                          child: GameplayWarehouseBoard(\n                            levelNumber: widget.level.number,\n                            warehouses: _warehouses,",
)
replace_once(
    'lib/features/game/game_screen.dart',
    "                child: GameplayFlightCargo(item: flight.item),",
    "                child: GameplayFlightCargo(\n                  item: flight.item,\n                  levelNumber: widget.level.number,\n                ),",
)

# CI ownership gates.
replace_once(
    '.github/workflows/flutter_ci.yml',
    "      - name: Test A11Y-003 reduced-motion validator\n        run: python3 tool/test_a11y_003_reduced_motion.py\n\n      - name: Restore packages",
    "      - name: Test A11Y-003 reduced-motion validator\n        run: python3 tool/test_a11y_003_reduced_motion.py\n\n      - name: Verify AST-007 cargo visual pack\n        run: python3 tool/verify_ast_007_cargo_visuals.py\n\n      - name: Test AST-007 cargo visual validator\n        run: python3 tool/test_ast_007_cargo_visuals.py\n\n      - name: Restore packages",
)
replace_once(
    '.github/workflows/flutter_ci.yml',
    "      - name: Analyze\n        run: flutter analyze --no-fatal-infos --no-fatal-warnings\n\n      - name: Test AST-004 asset cache policy",
    "      - name: Analyze\n        run: flutter analyze --no-fatal-infos --no-fatal-warnings\n\n      - name: Test AST-007 cargo visual pack\n        run: >-\n          flutter test\n          test/features/game/cargo_visual_catalog_test.dart\n          test/features/game/cargo_visual_asset_test.dart\n\n      - name: Test AST-004 asset cache policy",
)

# Record the staged checkpoint without claiming runtime art admission.
work_path = Path('docs/work/AST-007.md')
work_text = work_path.read_text(encoding='utf-8')
work_text += f'''\n## Implementation candidate\n\n- Typed catalog staged with {EXPECTED_VARIANTS} stable visual identities across all 18 gameplay archetypes.\n- Existing `CargoItem.id` values and `level_data.dart` generation remain untouched.\n- Manifest gains descriptor-only `cargo.*` entries using `pcargo` / 384x384; runtime WebP count remains unchanged until real provenance-backed art is supplied.\n- Cargo Bay, Sorting Docks and travel flight resolve the same level/archetype visual through `CargoVisualAsset` and keep explicit Flutter fallbacks.\n- AST-007 validator/regressions and focused Flutter tests are wired into normal CI.\n- Final source status remains IN PROGRESS until the implementation branch passes focused and full CI evidence.\n'''
work_path.write_text(work_text, encoding='utf-8')

print(f'AST-007 implementation staged: {EXPECTED_VARIANTS} descriptor-only cargo visuals')
