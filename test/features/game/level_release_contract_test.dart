import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/game/level_difficulty_curve.dart';
import 'package:cargo_sort_game/features/game/level_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TEST-002 production level release contract', () {
    test('catalog is exact deterministic solvable and balanced', () {
      final expectedNumbers = List<int>.generate(150, (index) => index + 1);

      expect(levels, hasLength(150));
      expect(
        levels.map((level) => level.number),
        orderedEquals(expectedNumbers),
      );

      final solvability = LevelSolvabilityValidator.validateAll(levels);
      final difficulty = LevelDifficultyCurve.validateAll(levels);

      expect(
        solvability.errors,
        isEmpty,
        reason: 'solvability errors: ${solvability.errors.join(', ')}',
      );
      expect(
        difficulty.errors,
        isEmpty,
        reason: 'difficulty errors: ${difficulty.errors.join(', ')}',
      );

      for (var number = 1; number <= 150; number++) {
        final cached = levels[number - 1];
        final regenerated = generateLevel(number);

        expect(
          regenerated.number,
          cached.number,
          reason: 'level $number number',
        );
        expect(regenerated.world, cached.world, reason: 'level $number world');
        expect(regenerated.moves, cached.moves, reason: 'level $number moves');
        expect(
          regenerated.difficulty,
          cached.difficulty,
          reason: 'level $number difficulty',
        );
        expect(
          regenerated.houseCount,
          cached.houseCount,
          reason: 'level $number house count',
        );
        expect(
          regenerated.items.map((item) => item.id),
          orderedEquals(cached.items.map((item) => item.id)),
          reason: 'level $number product sequence',
        );
        expect(
          regenerated.houseAssignments,
          orderedEquals(cached.houseAssignments),
          reason: 'level $number house sequence',
        );
      }
    });

    test('required release boundaries pass both validation contracts', () {
      for (final number in <int>[1, 25, 26, 150]) {
        final level = levels[number - 1];
        final solvability = LevelSolvabilityValidator.validate(level);
        final difficulty = LevelDifficultyCurve.validate(level);

        expect(level.number, number, reason: 'boundary level $number identity');
        expect(
          solvability.errors,
          isEmpty,
          reason: 'level $number solvability: ${solvability.errors.join(', ')}',
        );
        expect(
          difficulty.errors,
          isEmpty,
          reason: 'level $number difficulty: ${difficulty.errors.join(', ')}',
        );
      }
    });
  });
}
