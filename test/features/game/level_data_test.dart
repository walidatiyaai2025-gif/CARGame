import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/game/level_difficulty_policy.dart';
import 'package:cargo_sort_game/features/game/level_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('level generation', () {
    test('catalog exposes exactly 150 sequential levels', () {
      expect(levels, hasLength(150));
      expect(
        levels.map((level) => level.number),
        orderedEquals(List<int>.generate(150, (index) => index + 1)),
      );
    });

    test('generation is deterministic and matches the cached catalog', () {
      for (var number = 1; number <= 150; number++) {
        final first = generateLevel(number);
        final second = generateLevel(number);
        final cached = levels[number - 1];

        expect(first.number, number);
        expect(first.world, second.world, reason: 'level $number world');
        expect(first.moves, second.moves, reason: 'level $number moves');
        expect(
          first.difficulty,
          second.difficulty,
          reason: 'level $number difficulty',
        );
        expect(first.houseCount, second.houseCount, reason: 'level $number houses');
        expect(
          first.items.map((item) => item.id),
          orderedEquals(second.items.map((item) => item.id)),
          reason: 'level $number item sequence',
        );
        expect(
          first.houseAssignments,
          orderedEquals(second.houseAssignments),
          reason: 'level $number house sequence',
        );
        expect(first.world, cached.world, reason: 'level $number cached world');
        expect(first.moves, cached.moves, reason: 'level $number cached moves');
        expect(
          first.difficulty,
          cached.difficulty,
          reason: 'level $number cached difficulty',
        );
        expect(first.houseCount, cached.houseCount, reason: 'level $number cached houses');
        expect(
          first.items.map((item) => item.id),
          orderedEquals(cached.items.map((item) => item.id)),
          reason: 'level $number cached items',
        );
        expect(
          first.houseAssignments,
          orderedEquals(cached.houseAssignments),
          reason: 'level $number cached house assignments',
        );
      }
    });

    test('world boundaries remain 25 levels wide', () {
      const expected = <int, int>{
        1: 1,
        25: 1,
        26: 2,
        50: 2,
        51: 3,
        75: 3,
        76: 4,
        100: 4,
        101: 5,
        125: 5,
        126: 6,
        150: 6,
      };

      for (final entry in expected.entries) {
        expect(
          generateLevel(entry.key).world,
          entry.value,
          reason: 'level ${entry.key}',
        );
      }
    });

    test('campaign starts at nine cargo items and grows progressively', () {
      const expected = <int, int>{
        1: 9,
        10: 9,
        11: 10,
        25: 11,
        50: 13,
        75: 16,
        100: 18,
        125: 21,
        150: 23,
      };

      for (final entry in expected.entries) {
        expect(
          generateLevel(entry.key).items,
          hasLength(entry.value),
          reason: 'level ${entry.key}',
        );
      }

      var previousCount = 0;
      for (final level in levels) {
        expect(
          level.items.length,
          greaterThanOrEqualTo(previousCount),
          reason: 'level ${level.number}',
        );
        previousCount = level.items.length;
      }
    });

    test('cargo is balanced across a growing house count', () {
      const expectedHouseCounts = <int, int>{
        1: 3,
        40: 3,
        41: 4,
        80: 4,
        81: 5,
        120: 5,
        121: 6,
        150: 6,
      };

      for (final entry in expectedHouseCounts.entries) {
        expect(
          generateLevel(entry.key).houseCount,
          entry.value,
          reason: 'level ${entry.key}',
        );
      }

      for (final level in levels) {
        expect(level.houseAssignments, hasLength(level.items.length));
        expect(
          level.houseAssignments,
          everyElement(inInclusiveRange(1, level.houseCount)),
          reason: 'level ${level.number}',
        );

        final counts = <int, int>{
          for (var house = 1; house <= level.houseCount; house++) house: 0,
        };
        for (final house in level.houseAssignments) {
          counts[house] = counts[house]! + 1;
        }
        final values = counts.values.toList()..sort();
        expect(
          values.last - values.first,
          lessThanOrEqualTo(1),
          reason: 'level ${level.number} house balance',
        );
      }
    });

    test('key level difficulty shapes remain stable', () {
      final level1 = generateLevel(1);
      final level25 = generateLevel(25);
      final level26 = generateLevel(26);
      final level150 = generateLevel(150);

      expect(level1.items, hasLength(9));
      expect(level1.difficulty, 1);
      expect(level25.items, hasLength(11));
      expect(level25.difficulty, 2);
      expect(level26.items, hasLength(11));
      expect(level26.difficulty, 2);
      expect(level150.items, hasLength(23));
      expect(level150.difficulty, 10);
    });

    test('every generated configuration stays inside move budget rules', () {
      for (final level in levels) {
        final safetyMoves = LevelDifficultyPolicy.safetyMoveBaseForLevel(
          levelNumber: level.number,
          world: level.world,
        );
        final extraMoves = level.moves - level.items.length;

        expect(
          extraMoves,
          inInclusiveRange(safetyMoves, safetyMoves + 2),
          reason: 'level ${level.number}',
        );
        expect(
          LevelSolvabilityValidator.validate(level).isValid,
          isTrue,
          reason: 'level ${level.number}',
        );
      }
    });

    test('every product occurrence belongs to the stable catalog', () {
      final validIds = productCatalog.map((item) => item.id).toSet();

      for (final level in levels) {
        final distinctIds = <int>{};
        for (final item in level.items) {
          expect(validIds, contains(item.id), reason: 'level ${level.number}');
          distinctIds.add(item.id);
        }
        expect(
          distinctIds.length,
          greaterThanOrEqualTo(3),
          reason: 'level ${level.number}',
        );
      }
    });

    test('generated collections are immutable', () {
      expect(() => levels.add(generateLevel(1)), throwsUnsupportedError);
      expect(
        () => generateLevel(1).items.add(productCatalog.first),
        throwsUnsupportedError,
      );
      expect(
        () => generateLevel(1).houseAssignments.add(1),
        throwsUnsupportedError,
      );
    });

    test('generation rejects level numbers outside the production range', () {
      expect(() => generateLevel(0), throwsRangeError);
      expect(() => generateLevel(151), throwsRangeError);
      expect(() => LevelCargoProgression.cargoCountForLevel(0), throwsRangeError);
      expect(() => LevelCargoProgression.houseCountForLevel(151), throwsRangeError);
    });
  });
}
