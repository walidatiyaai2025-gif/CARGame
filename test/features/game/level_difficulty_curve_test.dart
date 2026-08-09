import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/game/level_difficulty_curve.dart';
import 'package:cargo_sort_game/features/game/level_difficulty_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelDifficultyPolicy', () {
    test('maps every documented boundary to exactly one band', () {
      const expected = <int, LevelDifficultyBand>{
        1: LevelDifficultyBand.tutorial,
        15: LevelDifficultyBand.tutorial,
        16: LevelDifficultyBand.easy,
        45: LevelDifficultyBand.easy,
        46: LevelDifficultyBand.medium,
        75: LevelDifficultyBand.medium,
        76: LevelDifficultyBand.hard,
        120: LevelDifficultyBand.hard,
        121: LevelDifficultyBand.expert,
        150: LevelDifficultyBand.expert,
      };

      for (final entry in expected.entries) {
        expect(
          LevelDifficultyPolicy.bandForLevel(entry.key),
          entry.value,
          reason: 'level ${entry.key}',
        );
      }
    });

    test('rejects level numbers outside the 150-level catalog', () {
      expect(
        () => LevelDifficultyPolicy.bandForLevel(0),
        throwsRangeError,
      );
      expect(
        () => LevelDifficultyPolicy.bandForLevel(151),
        throwsRangeError,
      );
    });

    test('expert missions have a tighter base error budget', () {
      expect(
        LevelDifficultyPolicy.safetyMoveBaseForLevel(
          levelNumber: 120,
          world: 5,
        ),
        2,
      );
      expect(
        LevelDifficultyPolicy.safetyMoveBaseForLevel(
          levelNumber: 121,
          world: 5,
        ),
        1,
      );
      expect(
        LevelDifficultyPolicy.safetyMoveBaseForLevel(
          levelNumber: 150,
          world: 6,
        ),
        1,
      );
    });
  });

  group('LevelDifficultyCurve', () {
    test('all 150 generated levels satisfy quantitative band targets', () {
      final result = LevelDifficultyCurve.validateAll(levels);

      expect(result.errors, isEmpty);
      expect(result.isValid, isTrue);
    });

    test('boundary metrics remain inside their documented envelopes', () {
      for (final levelNumber in <int>[1, 15, 16, 45, 46, 75, 76, 120, 121, 150]) {
        final level = levels[levelNumber - 1];
        final rule = LevelDifficultyPolicy.ruleForLevel(levelNumber);
        final metrics = LevelBalanceMetrics.fromLevel(level);

        expect(metrics.band, rule.band, reason: 'level $levelNumber band');
        expect(
          metrics.declaredDifficulty,
          inInclusiveRange(rule.minDifficulty, rule.maxDifficulty),
          reason: 'level $levelNumber difficulty',
        );
        expect(
          metrics.cargoItems,
          inInclusiveRange(rule.minCargoItems, rule.maxCargoItems),
          reason: 'level $levelNumber cargo',
        );
        expect(
          metrics.distinctProducts,
          inInclusiveRange(
            rule.minDistinctProducts,
            rule.maxDistinctProducts,
          ),
          reason: 'level $levelNumber products',
        );
        expect(
          metrics.moveSlack,
          inInclusiveRange(rule.minMoveSlack, rule.maxMoveSlack),
          reason: 'level $levelNumber move slack',
        );
      }
    });

    test('expert band increases average move pressure over hard', () {
      final hard = levels
          .where(
            (level) =>
                LevelDifficultyPolicy.bandForLevel(level.number) ==
                LevelDifficultyBand.hard,
          )
          .map(LevelBalanceMetrics.fromLevel)
          .toList();
      final expert = levels
          .where(
            (level) =>
                LevelDifficultyPolicy.bandForLevel(level.number) ==
                LevelDifficultyBand.expert,
          )
          .map(LevelBalanceMetrics.fromLevel)
          .toList();

      expect(_averagePressure(expert), greaterThan(_averagePressure(hard)));
      expect(
        expert.map((metrics) => metrics.moveSlack),
        everyElement(inInclusiveRange(1, 3)),
      );
    });

    test('rejects out-of-band difficulty and move slack', () {
      final source = levels[120];
      final invalid = _copyLevel(
        source,
        difficulty: 8,
        moves: source.items.length + 4,
      );

      final result = LevelDifficultyCurve.validate(invalid);

      expect(result.errors, contains('difficulty_out_of_band'));
      expect(result.errors, contains('move_slack_out_of_band'));
    });

    test('rejects duplicate or incomplete generated sets', () {
      final source = [...levels]..removeLast();
      source.add(levels.first);

      final result = LevelDifficultyCurve.validateAll(source);

      expect(result.errors, contains('duplicate_level:1'));
      expect(result.errors, contains('level_set_incomplete'));
    });

    test('detects macro pressure regression within valid envelopes', () {
      final source = <LevelData>[
        for (final level in levels)
          if (LevelDifficultyPolicy.bandForLevel(level.number) ==
              LevelDifficultyBand.hard)
            _copyLevel(level, moves: level.items.length + 2)
          else if (LevelDifficultyPolicy.bandForLevel(level.number) ==
              LevelDifficultyBand.expert)
            _copyLevel(level, moves: level.items.length + 3)
          else
            level,
      ];

      final result = LevelDifficultyCurve.validateAll(source);

      expect(
        result.errors,
        contains('macro_move_pressure_not_increasing:expert'),
      );
    });
  });
}

double _averagePressure(Iterable<LevelBalanceMetrics> source) {
  final values = source.toList();
  return values.fold<double>(0, (sum, item) => sum + item.movePressure) /
      values.length;
}

LevelData _copyLevel(
  LevelData source, {
  int? moves,
  int? difficulty,
}) {
  return LevelData(
    number: source.number,
    world: source.world,
    moves: moves ?? source.moves,
    items: source.items,
    difficulty: difficulty ?? source.difficulty,
  );
}
