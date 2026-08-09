import 'package:cargo_sort_game/core/config/app_build_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analytics is disabled by default for explicit config values', () {
    final config = AppBuildConfig.fromValues(
      environmentName: 'debug',
      enableDiagnostics: true,
      enableAds: false,
      adMob: AdMobUnitIds.googleTest,
    );

    expect(config.enableAnalytics, isFalse);
  });

  test('analytics requires an explicit build configuration opt-in', () {
    final config = AppBuildConfig.fromValues(
      environmentName: 'debug',
      enableDiagnostics: true,
      enableAds: false,
      enableAnalytics: true,
      adMob: AdMobUnitIds.googleTest,
    );

    expect(config.enableAnalytics, isTrue);
  });
}
