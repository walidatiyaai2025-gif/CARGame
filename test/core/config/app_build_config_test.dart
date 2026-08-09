import 'package:cargo_sort_game/core/config/app_build_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const productionIds = AdMobUnitIds(
    androidBanner: 'ca-app-pub-1111111111111111/1111111111',
    iosBanner: 'ca-app-pub-2222222222222222/2222222222',
    androidRewarded: 'ca-app-pub-1111111111111111/3333333333',
    iosRewarded: 'ca-app-pub-2222222222222222/4444444444',
    androidInterstitial: 'ca-app-pub-1111111111111111/5555555555',
    iosInterstitial: 'ca-app-pub-2222222222222222/6666666666',
  );

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
        iosBanner: 'ca-app-pub-2222222222222222/2222222222',
        androidRewarded: 'ca-app-pub-1111111111111111/3333333333',
        iosRewarded: 'ca-app-pub-2222222222222222/4444444444',
        androidInterstitial: 'ca-app-pub-1111111111111111/5555555555',
        iosInterstitial: 'ca-app-pub-2222222222222222/6666666666',
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
      final config = AppBuildConfig.fromValues(
        environmentName: 'release',
        enableDiagnostics: false,
        enableAds: true,
        adMob: productionIds,
      );

      expect(config.isRelease, isTrue);
      expect(config.adMob.usesGoogleTestIds, isFalse);
    });

    test('Android release validates only Android runtime ad units', () {
      const androidReleaseIds = AdMobUnitIds(
        androidBanner: 'ca-app-pub-1111111111111111/1111111111',
        iosBanner: AdMobUnitIds.googleTestIosBanner,
        androidRewarded: 'ca-app-pub-1111111111111111/3333333333',
        iosRewarded: AdMobUnitIds.googleTestIosRewarded,
        androidInterstitial: 'ca-app-pub-1111111111111111/5555555555',
        iosInterstitial: AdMobUnitIds.googleTestIosInterstitial,
      );

      final config = AppBuildConfig.fromValues(
        environmentName: 'release',
        enableDiagnostics: false,
        enableAds: true,
        adMobPlatform: AdMobPlatform.android,
        adMob: androidReleaseIds,
      );

      expect(config.isRelease, isTrue);
      expect(config.adMobPlatform, AdMobPlatform.android);
      expect(
        config.adMob.usesGoogleTestIdsFor(AdMobPlatform.android),
        isFalse,
      );
      expect(config.adMob.usesGoogleTestIdsFor(AdMobPlatform.ios), isTrue);
    });

    test('release rejects malformed active-platform ad-unit IDs', () {
      const malformed = AdMobUnitIds(
        androidBanner: 'android-banner-release',
        iosBanner: AdMobUnitIds.googleTestIosBanner,
        androidRewarded: 'ca-app-pub-1111111111111111/3333333333',
        iosRewarded: AdMobUnitIds.googleTestIosRewarded,
        androidInterstitial: 'ca-app-pub-1111111111111111/5555555555',
        iosInterstitial: AdMobUnitIds.googleTestIosInterstitial,
      );

      expect(
        () => AppBuildConfig.fromValues(
          environmentName: 'release',
          enableDiagnostics: false,
          enableAds: true,
          adMobPlatform: AdMobPlatform.android,
          adMob: malformed,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('release still rejects active-platform Google test IDs', () {
      const mixed = AdMobUnitIds(
        androidBanner: AdMobUnitIds.googleTestAndroidBanner,
        iosBanner: 'ca-app-pub-2222222222222222/2222222222',
        androidRewarded: 'ca-app-pub-1111111111111111/3333333333',
        iosRewarded: 'ca-app-pub-2222222222222222/4444444444',
        androidInterstitial: 'ca-app-pub-1111111111111111/5555555555',
        iosInterstitial: 'ca-app-pub-2222222222222222/6666666666',
      );

      expect(
        () => AppBuildConfig.fromValues(
          environmentName: 'release',
          enableDiagnostics: false,
          enableAds: true,
          adMobPlatform: AdMobPlatform.android,
          adMob: mixed,
        ),
        throwsA(isA<StateError>()),
      );
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
