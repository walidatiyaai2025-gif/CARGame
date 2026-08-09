import 'level_data.dart';
import 'level_difficulty_policy.dart';

class LevelBalanceMetrics {
  const LevelBalanceMetrics({
    required this.levelNumber,
    required this.band,
    required this.declaredDifficulty,
    required this.cargoItems,
    required this.distinctProducts,
    required this.moveSlack,
    required this.movePressure,
  });

  factory LevelBalanceMetrics.fromLevel(LevelData level) {
    final cargoItems = level.items.length;
    final distinctProducts = level.items.map((item) => item.id).toSet().length;
    final moveSlack = level.moves - cargoItems;
    final movePressure = level.moves <= 0 ? 1.0 : cargoItems / level.moves;

    return LevelBalanceMetrics(
      levelNumber: level.number,
      band: LevelDifficultyPolicy.bandForLevel(level.number),
      declaredDifficulty: level.difficulty,
      cargoItems: cargoItems,
      distinctProducts: distinctProducts,
      moveSlack: moveSlack,
      movePressure: movePressure,
    );
  }

  final int levelNumber;
  final LevelDifficultyBand band;
  final int declaredDifficulty;
  final int cargoItems;
  final int distinctProducts;
  final int moveSlack;
  final double movePressure;
}

class LevelDifficultyValidationResult {
  const LevelDifficultyValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class LevelDifficultyCurve {
  const LevelDifficultyCurve._();

  static LevelDifficultyValidationResult validate(LevelData level) {
    final errors = <String>[];
    LevelDifficultyBandRule rule;
    try {
      rule = LevelDifficultyPolicy.ruleForLevel(level.number);
    } on RangeError {
      return const LevelDifficultyValidationResult([
        'level_number_out_of_range',
      ]);
    }

    final metrics = LevelBalanceMetrics.fromLevel(level);

    if (metrics.declaredDifficulty < rule.minDifficulty ||
        metrics.declaredDifficulty > rule.maxDifficulty) {
      errors.add('difficulty_out_of_band');
    }
    if (metrics.cargoItems < rule.minCargoItems ||
        metrics.cargoItems > rule.maxCargoItems) {
      errors.add('cargo_count_out_of_band');
    }
    if (metrics.distinctProducts < rule.minDistinctProducts ||
        metrics.distinctProducts > rule.maxDistinctProducts) {
      errors.add('distinct_products_out_of_band');
    }
    if (metrics.moveSlack < rule.minMoveSlack ||
        metrics.moveSlack > rule.maxMoveSlack) {
      errors.add('move_slack_out_of_band');
    }

    return LevelDifficultyValidationResult(List<String>.unmodifiable(errors));
  }

  static LevelDifficultyValidationResult validateAll(
    Iterable<LevelData> source,
  ) {
    final errors = <String>[];
    errors.addAll(_validateBandDefinitions());

    final levelsByNumber = <int, LevelData>{};
    for (final level in source) {
      if (levelsByNumber.containsKey(level.number)) {
        errors.add('duplicate_level:${level.number}');
        continue;
      }
      levelsByNumber[level.number] = level;

      final result = validate(level);
      for (final error in result.errors) {
        errors.add('level_${level.number}:$error');
      }
    }

    final expectedNumbers = Iterable<int>.generate(
      LevelDifficultyPolicy.totalLevels,
      (index) => index + 1,
    );
    if (levelsByNumber.length != LevelDifficultyPolicy.totalLevels ||
        !levelsByNumber.keys.toSet().containsAll(expectedNumbers)) {
      errors.add('level_set_incomplete');
      return LevelDifficultyValidationResult(List<String>.unmodifiable(errors));
    }

    double? previousAveragePressure;
    double? previousAverageCargo;
    for (final rule in LevelDifficultyPolicy.rules) {
      final metrics = <LevelBalanceMetrics>[
        for (
          var levelNumber = rule.minLevel;
          levelNumber <= rule.maxLevel;
          levelNumber++
        )
          LevelBalanceMetrics.fromLevel(levelsByNumber[levelNumber]!),
      ];
      final averagePressure =
          metrics.fold<double>(0, (sum, item) => sum + item.movePressure) /
          metrics.length;
      final averageCargo =
          metrics.fold<double>(0, (sum, item) => sum + item.cargoItems) /
          metrics.length;

      if (previousAveragePressure != null &&
          averagePressure <= previousAveragePressure) {
        errors.add('macro_move_pressure_not_increasing:${rule.band.name}');
      }
      if (previousAverageCargo != null && averageCargo < previousAverageCargo) {
        errors.add('macro_cargo_regression:${rule.band.name}');
      }

      previousAveragePressure = averagePressure;
      previousAverageCargo = averageCargo;
    }

    return LevelDifficultyValidationResult(List<String>.unmodifiable(errors));
  }

  static List<String> _validateBandDefinitions() {
    final errors = <String>[];
    final rules = LevelDifficultyPolicy.rules;
    if (rules.isEmpty) return const ['difficulty_bands_empty'];

    if (rules.first.minLevel != 1 ||
        rules.last.maxLevel != LevelDifficultyPolicy.totalLevels) {
      errors.add('difficulty_band_range_incomplete');
    }

    for (var index = 0; index < rules.length; index++) {
      final rule = rules[index];
      if (rule.minLevel > rule.maxLevel ||
          rule.minDifficulty > rule.maxDifficulty ||
          rule.minCargoItems > rule.maxCargoItems ||
          rule.minDistinctProducts > rule.maxDistinctProducts ||
          rule.minMoveSlack > rule.maxMoveSlack) {
        errors.add('invalid_band_rule:${rule.band.name}');
      }

      if (index == 0) continue;
      final previous = rules[index - 1];
      if (previous.maxLevel + 1 != rule.minLevel) {
        errors.add('difficulty_band_gap_or_overlap:${rule.band.name}');
      }
      if (previous.maxDifficulty >= rule.minDifficulty) {
        errors.add('difficulty_rating_not_increasing:${rule.band.name}');
      }
    }

    return errors;
  }
}
