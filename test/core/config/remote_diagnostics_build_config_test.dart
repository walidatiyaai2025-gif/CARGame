import 'package:cargo_sort_game/core/config/app_build_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote diagnostics is disabled by default', () {
    final config = AppBuildConfig.fromValues(
      environmentName: 'debug',
      enableDiagnostics: true,
      enableAds: false,
      adMob: AdMobUnitIds.googleTest,
    );

    expect(config.enableRemoteDiagnostics, isFalse);
  });

  test('remote diagnostics requires explicit build opt-in', () {
    final config = AppBuildConfig.fromValues(
      environmentName: 'staging',
      enableDiagnostics: true,
      enableAds: false,
      enableRemoteDiagnostics: true,
      adMob: AdMobUnitIds.googleTest,
    );

    expect(config.enableRemoteDiagnostics, isTrue);
  });
}
