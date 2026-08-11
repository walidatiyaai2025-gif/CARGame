import '../../core/assets/game_asset.dart';

/// Stable visual identity for one cargo product representation.
///
/// [archetypeId] remains separate from the visual ID: gameplay matching,
/// persistence and rewards continue to use the existing 1..18 CargoItem IDs.
final class CargoVisualVariant {
  const CargoVisualVariant({
    required this.assetId,
    required this.archetypeId,
    required this.subjectSlug,
    required this.englishConcept,
    required this.runtimePath,
    required this.profile,
  });

  final String assetId;
  final int archetypeId;
  final String subjectSlug;
  final String englishConcept;
  final String runtimePath;
  final GameAssetProfile profile;
}

/// AST-007 source-controlled catalog and deterministic resolver.
///
/// The resolver is deliberately independent from the level generator. Changing
/// visual art must never change cargo ordering, moves, difficulty or save IDs.
final class CargoVisualCatalog {
  const CargoVisualCatalog._();

  static const int minArchetypeId = 1;
  static const int maxArchetypeId = 18;
  static const int expectedVariantCount = 124;

  static const List<_CargoVisualFamily> _families = <_CargoVisualFamily>[
    _CargoVisualFamily(
      archetypeId: 1,
      folder: 'special',
      subjectSlugs: <String>[
        'premium_parcel',
        'courier_carton',
        'sealed_box',
        'express_crate',
        'document_case',
        'eco_mailer',
        'fragile_parcel',
        'insulated_mailer',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 2,
      folder: 'travel',
      subjectSlugs: <String>[
        'hard_shell_suitcase',
        'cabin_case',
        'duffel_bag',
        'travel_backpack',
        'garment_case',
        'passport_pouch',
        'rolling_trunk',
        'weekend_case',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 3,
      folder: 'food',
      subjectSlugs: <String>[
        'apple_crate',
        'citrus_box',
        'vegetable_basket',
        'bakery_box',
        'grocery_tote',
        'pantry_case',
        'fruit_basket',
        'dairy_cooler',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 4,
      folder: 'electronics',
      subjectSlugs: <String>[
        'smartphone_box',
        'tablet_case',
        'laptop_carton',
        'camera_case',
        'headphone_box',
        'console_package',
        'speaker_box',
        'wearable_case',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 5,
      folder: 'fashion',
      subjectSlugs: <String>[
        'apparel_box',
        'folded_shirt_case',
        'jacket_bag',
        'accessory_box',
        'handbag_case',
        'boutique_carton',
        'hat_box',
        'textile_pack',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 6,
      folder: 'sports',
      subjectSlugs: <String>[
        'basketball_bag',
        'football_kit',
        'tennis_case',
        'training_bag',
        'helmet_box',
        'fitness_gear',
        'golf_case',
        'cycling_kit',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 7,
      folder: 'office',
      subjectSlugs: <String>[
        'hardcover_crate',
        'textbook_box',
        'magazine_bundle',
        'comic_case',
        'library_carton',
        'journal_pack',
        'archive_box',
        'stationery_bundle',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 8,
      folder: 'toys',
      subjectSlugs: <String>[
        'building_blocks',
        'toy_robot_box',
        'puzzle_case',
        'plush_crate',
        'board_game_box',
        'model_kit',
        'action_figure_box',
        'craft_kit',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 9,
      folder: 'household',
      subjectSlugs: <String>[
        'skincare_case',
        'perfume_box',
        'cosmetics_bag',
        'haircare_pack',
        'spa_kit',
        'grooming_case',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 10,
      folder: 'household',
      subjectSlugs: <String>[
        'wrench_case',
        'drill_box',
        'hand_tool_crate',
        'measuring_kit',
        'workshop_case',
        'hardware_pack',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 11,
      folder: 'beverage',
      subjectSlugs: <String>[
        'water_pack',
        'juice_crate',
        'soda_case',
        'coffee_box',
        'tea_case',
        'energy_drink_pack',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 12,
      folder: 'special',
      subjectSlugs: <String>[
        'ribbon_gift_box',
        'celebration_bag',
        'premium_hamper',
        'surprise_crate',
        'floral_gift_case',
        'holiday_box',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 13,
      folder: 'household',
      subjectSlugs: <String>[
        'lamp_box',
        'cushion_pack',
        'kitchenware_crate',
        'decor_vase_case',
        'storage_basket',
        'linen_box',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 14,
      folder: 'fashion',
      subjectSlugs: <String>[
        'sneaker_box',
        'boot_carton',
        'running_shoe_case',
        'formal_shoe_box',
        'sandal_pack',
        'hiking_shoe_case',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 15,
      folder: 'household',
      subjectSlugs: <String>[
        'pet_food_bag',
        'pet_toy_pack',
        'carrier_box',
        'pet_grooming_kit',
        'bowl_set',
        'collar_case',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 16,
      folder: 'special',
      subjectSlugs: <String>[
        'first_aid_case',
        'medicine_box',
        'wellness_pack',
        'clinic_crate',
        'care_kit',
        'medical_supply_case',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 17,
      folder: 'special',
      subjectSlugs: <String>[
        'brake_parts_box',
        'filter_case',
        'battery_pack',
        'auto_part_crate',
        'light_assembly_box',
        'accessory_carton',
      ],
    ),
    _CargoVisualFamily(
      archetypeId: 18,
      folder: 'special',
      subjectSlugs: <String>[
        'jewelry_case',
        'luxury_watch_box',
        'designer_case',
        'collector_crate',
        'gold_package',
        'premium_vault_box',
      ],
    ),
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
                  'assets/3d/runtime/cargo/${family.folder}/'
                  'cg_cargo_${subject}_pcargo_v01.webp',
              profile: GameAssetProfile.pcargo,
            ),
      ]);

  static final Map<int, List<CargoVisualVariant>> _byArchetype =
      _buildByArchetype();

  static List<CargoVisualVariant> forArchetype(int archetypeId) {
    final variants = _byArchetype[archetypeId];
    if (variants == null) {
      throw ArgumentError.value(
        archetypeId,
        'archetypeId',
        'Unknown cargo gameplay archetype',
      );
    }
    return variants;
  }

  static CargoVisualVariant resolve({
    required int levelNumber,
    required int archetypeId,
  }) {
    if (levelNumber < 1) {
      throw ArgumentError.value(levelNumber, 'levelNumber', 'Must be positive');
    }
    final family = forArchetype(archetypeId);
    final index = ((levelNumber - 1) * 31 + archetypeId * 17) % family.length;
    return family[index];
  }

  static Map<int, List<CargoVisualVariant>> _buildByArchetype() {
    if (variants.length != expectedVariantCount) {
      throw StateError(
        'AST-007 expected $expectedVariantCount cargo variants, '
        'found ${variants.length}',
      );
    }

    final ids = <String>{};
    final result = <int, List<CargoVisualVariant>>{};
    for (final variant in variants) {
      if (variant.archetypeId < minArchetypeId ||
          variant.archetypeId > maxArchetypeId) {
        throw StateError('Unknown cargo archetype: ${variant.archetypeId}');
      }
      if (!ids.add(variant.assetId)) {
        throw StateError('Duplicate cargo visual asset ID: ${variant.assetId}');
      }
      if (variant.profile != GameAssetProfile.pcargo) {
        throw StateError('Cargo visual must use pcargo: ${variant.assetId}');
      }
      result
          .putIfAbsent(variant.archetypeId, () => <CargoVisualVariant>[])
          .add(variant);
    }

    for (
      var archetypeId = minArchetypeId;
      archetypeId <= maxArchetypeId;
      archetypeId++
    ) {
      final family = result[archetypeId];
      if (family == null || family.isEmpty) {
        throw StateError('Cargo archetype $archetypeId has no visual variants');
      }
      result[archetypeId] = List<CargoVisualVariant>.unmodifiable(family);
    }
    return Map<int, List<CargoVisualVariant>>.unmodifiable(result);
  }

  static String _humanize(String slug) => slug
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

final class _CargoVisualFamily {
  const _CargoVisualFamily({
    required this.archetypeId,
    required this.folder,
    required this.subjectSlugs,
  });

  final int archetypeId;
  final String folder;
  final List<String> subjectSlugs;
}
