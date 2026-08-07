import 'package:cargo_sort_game/core/config/app_build_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment', () {
    test('parses supported names case-insensitively', () {
      expect(AppEnvironment.parse('debug'), AppEnvironment.debug);
      expect(AppEnvironment.parse(' STAGING '), AppEnvironment.staging);
      expect(AppEnvironment.parse('Release'), AppEnvironment.release);
    });

    test('rejects unknown environment names', () {
      expect(
        () => AppEnvironment.parse('production'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AppBuildConfig', () {
    test('debug config accepts official Google test IDs', () {
      final config = AppBuildConfig.fromValues(
        environmentName: 'debug',
        enableDiagnostics: true,
        enableAds: true,
        adMob: AdMobUnitIds.googleTest,
      );

      expect(config.isDebug, isTrue);
      expect(config.enableDiagnostics, isTrue);
      expect(config.adMob.usesGoogleTestIds, isTrue);
    });

    test('staging config can use Google test IDs', () {
      final config = AppBuildConfig.fromValues(
        environmentName: 'staging',
        enableDiagnostics: true,
        enableAds: true,
        adMob: AdMobUnitIds.googleTest,
      );

      expect(config.isStaging, isTrue);
    });

    test('release rejects Google test IDs when ads are enabled', () {
      expect(
        () => AppBuildConfig.fromValues(
          environmentName: 'release',
          enableDiagnostics: false,
          enableAds: true,
          adMob: AdMobUnitIds.googleTest,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('ads-enabled config rejects incomplete unit IDs', () {
      const incomplete = AdMobUnitIds(
        androidBanner: '',
        iosBanner: 'ios-banner',
        androidRewarded: 'android-rewarded',
        iosRewarded: 'ios-rewarded',
        androidInterstitial: 'android-interstitial',
        iosInterstitial: 'ios-interstitial',
      );

      expect(
        () => AppBuildConfig.fromValues(
          environmentName: 'debug',
          enableDiagnostics: true,
          enableAds: true,
          adMob: incomplete,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('release accepts explicitly injected non-test ad IDs', () {
      const releaseIds = AdMobUnitIds(
        androidBanner: 'android-banner-release',
        iosBanner: 'ios-banner-release',
        androidRewarded: 'android-rewarded-release',
        iosRewarded: 'ios-rewarded-release',
        androidInterstitial: 'android-interstitial-release',
        iosInterstitial: 'ios-interstitial-release',
      );

      final config = AppBuildConfig.fromValues(
        environmentName: 'release',
        enableDiagnostics: false,
        enableAds: true,
        adMob: releaseIds,
      );

      expect(config.isRelease, isTrue);
      expect(config.adMob.usesGoogleTestIds, isFalse);
    });

    test('ads-disabled release does not require ad IDs', () {
      const emptyIds = AdMobUnitIds(
        androidBanner: '',
        iosBanner: '',
        androidRewarded: '',
        iosRewarded: '',
        androidInterstitial: '',
        iosInterstitial: '',
      );

      final config = AppBuildConfig.fromValues(
        environmentName: 'release',
        enableDiagnostics: false,
        enableAds: false,
        adMob: emptyIds,
      );

      expect(config.isRelease, isTrue);
      expect(config.enableAds, isFalse);
    });
  });
}
