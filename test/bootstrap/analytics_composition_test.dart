import 'package:cargo_sort_game/bootstrap/app_composition.dart';
import 'package:cargo_sort_game/core/application/analytics_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production composition exposes analytics but keeps collection off',
    () async {
      final composition = AppComposition.production();

      expect(composition.analytics, isA<AnalyticsPort>());
      expect(composition.analytics.isCollectionEnabled, isFalse);

      await composition.dispose();
    },
  );
}
