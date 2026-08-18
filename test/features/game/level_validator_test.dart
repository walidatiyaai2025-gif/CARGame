import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/game/level_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelSolvabilityValidator', () {
    test('all 150 generated levels satisfy the solvability contract', () {
      final result = LevelSolvabilityValidator.validateAll(levels);

      expect(result.errors, isEmpty);
      expect(result.isValid, isTrue);
    });

    test('representative world boundaries validate', () {
      for (final levelNumber in <int>[1, 25, 26, 50, 51, 125, 126, 150]) {
        final result = LevelSolvabilityValidator.validate(
          levels[levelNumber - 1],
        );
        expect(result.errors, isEmpty, reason: 'level $levelNumber');
      }
    });

    test('rejects a level with fewer moves than cargo items', () {
      final level = _level(moves: 3);

      final result = LevelSolvabilityValidator.validate(level);

      expect(result.errors, contains('insufficient_moves'));
    });

    test('rejects empty and single-target cargo layouts', () {
      final empty = _level(items: const <CargoItem>[]);
      final oneTarget = _level(
        items: <CargoItem>[productCatalog.first, productCatalog.first],
      );

      expect(
        LevelSolvabilityValidator.validate(empty).errors,
        contains('empty_cargo'),
      );
      expect(
        LevelSolvabilityValidator.validate(oneTarget).errors,
        contains('insufficient_product_types'),
      );
    });

    test('allows single occurrences but rejects unknown products', () {
      final singleOccurrences = _level(
        moves: 4,
        items: <CargoItem>[
          productCatalog[0],
          productCatalog[1],
          productCatalog[2],
          productCatalog[3],
        ],
      );
      final unknown = _level(
        items: <CargoItem>[
          productCatalog[0],
          productCatalog[1],
          CargoItem(
            id: 999,
            name: 'Unknown',
            category: 'Unknown',
            color: productCatalog[1].color,
            accentColor: productCatalog[1].accentColor,
            icon: productCatalog[1].icon,
          ),
          productCatalog[2],
        ],
      );

      expect(
        LevelSolvabilityValidator.validate(singleOccurrences).errors,
        isEmpty,
      );
      expect(
        LevelSolvabilityValidator.validate(unknown).errors,
        contains('unknown_product:999'),
      );
    });

    test('rejects invalid house assignment contracts', () {
      final mismatchedCount = _level(
        houseCount: 3,
        houseAssignments: const <int>[1, 2],
      );
      final outOfRange = _level(
        houseCount: 2,
        houseAssignments: const <int>[1, 2, 3, 1],
      );
      final invalidCount = _level(
        houseCount: 0,
        houseAssignments: const <int>[1, 1, 1, 1],
      );

      expect(
        LevelSolvabilityValidator.validate(mismatchedCount).errors,
        contains('house_assignment_count_mismatch'),
      );
      expect(
        LevelSolvabilityValidator.validate(outOfRange).errors,
        contains('house_assignment_out_of_range:3'),
      );
      expect(
        LevelSolvabilityValidator.validate(invalidCount).errors,
        contains('house_count_not_positive'),
      );
    });

    test('rejects world, difficulty and product metadata mismatches', () {
      final mismatchedProduct = CargoItem(
        id: productCatalog.first.id,
        name: 'Changed Name',
        category: productCatalog.first.category,
        color: productCatalog.first.color,
        accentColor: productCatalog.first.accentColor,
        icon: productCatalog.first.icon,
      );
      final level = _level(
        world: 2,
        difficulty: 11,
        items: <CargoItem>[
          mismatchedProduct,
          productCatalog[1],
          productCatalog[2],
          productCatalog[3],
        ],
      );

      final result = LevelSolvabilityValidator.validate(level);

      expect(result.errors, contains('world_mismatch'));
      expect(result.errors, contains('difficulty_out_of_range'));
      expect(result.errors, contains('product_metadata_mismatch:1'));
    });

    test('validateAll rejects duplicate or incomplete level sets', () {
      final source = <LevelData>[levels.first, levels.first, ...levels.skip(2)];

      final result = LevelSolvabilityValidator.validateAll(source);

      expect(result.errors, contains('duplicate_level:1'));
      expect(result.errors, contains('level_set_incomplete'));
    });
  });
}

LevelData _level({
  int number = 1,
  int world = 1,
  int moves = 4,
  int difficulty = 1,
  List<CargoItem>? items,
  int houseCount = 1,
  List<int> houseAssignments = const <int>[],
}) {
  return LevelData(
    number: number,
    world: world,
    moves: moves,
    difficulty: difficulty,
    items:
        items ??
        <CargoItem>[
          productCatalog[0],
          productCatalog[0],
          productCatalog[1],
          productCatalog[1],
        ],
    houseCount: houseCount,
    houseAssignments: houseAssignments,
  );
}
