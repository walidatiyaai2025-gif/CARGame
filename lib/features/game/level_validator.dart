import 'level_data.dart';

class LevelValidationResult {
  const LevelValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class LevelSolvabilityValidator {
  const LevelSolvabilityValidator._();

  static const int totalLevels = 150;
  static const int levelsPerWorld = 25;
  static const int totalWorlds = 6;
  static const int minimumDifficulty = 1;
  static const int maximumDifficulty = 10;

  static LevelValidationResult validate(LevelData level) {
    final errors = <String>[];

    if (level.number < 1 || level.number > totalLevels) {
      errors.add('level_number_out_of_range');
    }

    final expectedWorld = _expectedWorld(level.number);
    if (level.world < 1 ||
        level.world > totalWorlds ||
        expectedWorld == null ||
        level.world != expectedWorld) {
      errors.add('world_mismatch');
    }

    if (level.difficulty < minimumDifficulty ||
        level.difficulty > maximumDifficulty) {
      errors.add('difficulty_out_of_range');
    }

    if (level.items.isEmpty) {
      errors.add('empty_cargo');
      return LevelValidationResult(List<String>.unmodifiable(errors));
    }

    final catalogById = <int, CargoItem>{
      for (final item in productCatalog) item.id: item,
    };
    final itemCounts = <int, int>{};

    for (final item in level.items) {
      final canonical = catalogById[item.id];
      if (canonical == null) {
        errors.add('unknown_product:${item.id}');
        continue;
      }
      if (canonical.name != item.name || canonical.category != item.category) {
        errors.add('product_metadata_mismatch:${item.id}');
      }
      itemCounts.update(item.id, (count) => count + 1, ifAbsent: () => 1);
    }

    if (itemCounts.length < 2) {
      errors.add('insufficient_product_types');
    }

    for (final entry in itemCounts.entries) {
      if (entry.value < 2) {
        errors.add('orphan_product:${entry.key}');
      }
    }

    if (level.moves <= 0) {
      errors.add('moves_not_positive');
    } else if (level.moves < level.items.length) {
      errors.add('insufficient_moves');
    }

    return LevelValidationResult(List<String>.unmodifiable(errors));
  }

  static LevelValidationResult validateAll(Iterable<LevelData> source) {
    final errors = <String>[];
    final seenNumbers = <int>{};

    for (final level in source) {
      if (!seenNumbers.add(level.number)) {
        errors.add('duplicate_level:${level.number}');
      }
      final result = validate(level);
      for (final error in result.errors) {
        errors.add('level_${level.number}:$error');
      }
    }

    if (seenNumbers.length != totalLevels ||
        !seenNumbers.containsAll(
          Iterable<int>.generate(totalLevels, (index) => index + 1),
        )) {
      errors.add('level_set_incomplete');
    }

    return LevelValidationResult(List<String>.unmodifiable(errors));
  }

  static int? _expectedWorld(int levelNumber) {
    if (levelNumber < 1 || levelNumber > totalLevels) return null;
    return ((levelNumber - 1) ~/ levelsPerWorld) + 1;
  }
}
