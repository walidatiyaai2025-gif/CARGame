import 'package:cargo_sort_game/features/game/city_catalog.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('capital stage catalog', () {
    test('contains exactly 150 sequential unique country stages', () {
      expect(capitalStages, hasLength(150));
      expect(
        capitalStages.map((stage) => stage.level),
        orderedEquals(List<int>.generate(150, (index) => index + 1)),
      );
      expect(
        capitalStages.map((stage) => stage.countryCode).toSet(),
        hasLength(150),
      );
      expect(
        capitalStages.map((stage) => stage.countryEn).toSet(),
        hasLength(150),
      );
    });

    test('all coordinates and bilingual names are valid', () {
      for (final stage in capitalStages) {
        expect(stage.latitude, inInclusiveRange(-90, 90));
        expect(stage.longitude, inInclusiveRange(-180, 180));
        expect(stage.countryCode, hasLength(2));
        expect(stage.countryEn, isNotEmpty);
        expect(stage.countryAr, isNotEmpty);
        expect(stage.capitalEn, isNotEmpty);
        expect(stage.capitalAr, isNotEmpty);
      }
    });

    test('six campaign routes retain 25 levels each', () {
      expect(capitalRoutes, hasLength(6));
      expect(worldCities, hasLength(6));
      for (var world = 1; world <= 6; world++) {
        expect(
          capitalStages.where((stage) => stage.world == world),
          hasLength(25),
        );
        expect(worldCities[world - 1], hasLength(25));
      }
    });

    test('representative levels map to real capital destinations', () {
      expect(capitalStageForLevel(1).capitalEn, 'Lisbon');
      expect(capitalStageForLevel(1).countryEn, 'Portugal');
      expect(capitalStageForLevel(20).capitalEn, 'Warsaw');
      expect(capitalStageForLevel(51).capitalEn, 'Beijing');
      expect(capitalStageForLevel(76).capitalEn, 'Kuwait City');
      expect(capitalStageForLevel(126).capitalEn, 'Ottawa');
      expect(capitalStageForLevel(150).capitalEn, 'Wellington');
    });

    test('level extension preserves numeric identity and localizes labels', () {
      final first = levels.first;
      final last = levels.last;

      expect(first.number, 1);
      expect(first.cityName, 'Lisbon');
      expect(first.countryName, 'Portugal');
      expect(first.localizedDestinationLabel(false), 'Lisbon, Portugal');
      expect(first.localizedDestinationLabel(true), 'لشبونة - البرتغال');
      expect(last.number, 150);
      expect(last.cityName, 'Wellington');
      expect(last.countryName, 'New Zealand');
    });

    test('catalog rejects levels outside the production range', () {
      expect(() => capitalStageForLevel(0), throwsRangeError);
      expect(() => capitalStageForLevel(151), throwsRangeError);
      expect(() => capitalRouteForWorld(0), throwsRangeError);
      expect(() => capitalRouteForWorld(7), throwsRangeError);
    });
  });
}
