enum LevelDifficultyBand { tutorial, easy, medium, hard, expert }

class LevelDifficultyBandRule {
  const LevelDifficultyBandRule({
    required this.band,
    required this.minLevel,
    required this.maxLevel,
    required this.minDifficulty,
    required this.maxDifficulty,
    required this.minCargoItems,
    required this.maxCargoItems,
    required this.minDistinctProducts,
    required this.maxDistinctProducts,
    required this.minMoveSlack,
    required this.maxMoveSlack,
  });

  final LevelDifficultyBand band;
  final int minLevel;
  final int maxLevel;
  final int minDifficulty;
  final int maxDifficulty;
  final int minCargoItems;
  final int maxCargoItems;
  final int minDistinctProducts;
  final int maxDistinctProducts;
  final int minMoveSlack;
  final int maxMoveSlack;

  bool containsLevel(int levelNumber) =>
      levelNumber >= minLevel && levelNumber <= maxLevel;
}

class LevelDifficultyPolicy {
  const LevelDifficultyPolicy._();

  static const int totalLevels = 150;

  static const List<LevelDifficultyBandRule> rules = [
    LevelDifficultyBandRule(
      band: LevelDifficultyBand.tutorial,
      minLevel: 1,
      maxLevel: 15,
      minDifficulty: 1,
      maxDifficulty: 1,
      minCargoItems: 9,
      maxCargoItems: 10,
      minDistinctProducts: 3,
      maxDistinctProducts: 3,
      minMoveSlack: 5,
      maxMoveSlack: 7,
    ),
    LevelDifficultyBandRule(
      band: LevelDifficultyBand.easy,
      minLevel: 16,
      maxLevel: 45,
      minDifficulty: 2,
      maxDifficulty: 3,
      minCargoItems: 10,
      maxCargoItems: 13,
      minDistinctProducts: 3,
      maxDistinctProducts: 5,
      minMoveSlack: 4,
      maxMoveSlack: 7,
    ),
    LevelDifficultyBandRule(
      band: LevelDifficultyBand.medium,
      minLevel: 46,
      maxLevel: 75,
      minDifficulty: 4,
      maxDifficulty: 5,
      minCargoItems: 13,
      maxCargoItems: 16,
      minDistinctProducts: 5,
      maxDistinctProducts: 6,
      minMoveSlack: 3,
      maxMoveSlack: 6,
    ),
    LevelDifficultyBandRule(
      band: LevelDifficultyBand.hard,
      minLevel: 76,
      maxLevel: 120,
      minDifficulty: 6,
      maxDifficulty: 8,
      minCargoItems: 16,
      maxCargoItems: 20,
      minDistinctProducts: 6,
      maxDistinctProducts: 8,
      minMoveSlack: 2,
      maxMoveSlack: 4,
    ),
    LevelDifficultyBandRule(
      band: LevelDifficultyBand.expert,
      minLevel: 121,
      maxLevel: 150,
      minDifficulty: 9,
      maxDifficulty: 10,
      minCargoItems: 21,
      maxCargoItems: 23,
      minDistinctProducts: 9,
      maxDistinctProducts: 9,
      minMoveSlack: 1,
      maxMoveSlack: 3,
    ),
  ];

  static LevelDifficultyBandRule ruleForLevel(int levelNumber) {
    if (levelNumber < 1 || levelNumber > totalLevels) {
      throw RangeError.range(levelNumber, 1, totalLevels, 'levelNumber');
    }
    return rules.firstWhere((rule) => rule.containsLevel(levelNumber));
  }

  static LevelDifficultyBand bandForLevel(int levelNumber) =>
      ruleForLevel(levelNumber).band;

  static int declaredDifficultyForLevel(int levelNumber) {
    ruleForLevel(levelNumber);
    final difficulty = 1 + ((levelNumber - 1) ~/ 15);
    return difficulty > 10 ? 10 : difficulty;
  }

  static int safetyMoveBaseForLevel({
    required int levelNumber,
    required int world,
  }) {
    ruleForLevel(levelNumber);
    if (world < 1 || world > 6) {
      throw RangeError.range(world, 1, 6, 'world');
    }

    // Expert missions need a measurable gameplay-pressure increase rather than
    // only a higher metadata/reward difficulty number. Keep the growing cargo
    // curve intact and tighten the perfect-run error budget by one move.
    if (bandForLevel(levelNumber) == LevelDifficultyBand.expert) {
      return 1;
    }

    final worldSlack = 6 - world;
    return worldSlack < 2 ? 2 : worldSlack;
  }
}
