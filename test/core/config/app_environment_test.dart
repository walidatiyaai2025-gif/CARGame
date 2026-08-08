import 'package:cargo_sort_game/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBuildConfig', () {
    test('defaults unknown environments to debug-safe behavior', () {
      final config = AppBuildConfig.resolve(
        environment: 'unexpected',
        enableAds: false,
        admobBannerUnitId: '',
      );

      expect(config.environment, AppEnvironment.debug);
      expect(config.isRelease, isFalse);
      expect(config.hasConfiguredBannerAd, isFalse);
      expect(config.validateForReleaseCandidate, returnsNormally);
    });

    test('normalizes release configuration', () {
      final config = AppBuildConfig.resolve(
        environment: ' RELEASE ',
        enableAds: true,
        admobBannerUnitId: ' ca-app-pub-test/banner ',
      );

      expect(config.environment, AppEnvironment.release);
      expect(config.isRelease, isTrue);
      expect(config.admobBannerUnitId, 'ca-app-pub-test/banner');
      expect(config.hasConfiguredBannerAd, isTrue);
      expect(config.validateForReleaseCandidate, returnsNormally);
    });

    test('rejects ads enabled without an injected banner unit id', () {
      final config = AppBuildConfig.resolve(
        environment: 'release',
        enableAds: true,
        admobBannerUnitId: '   ',
      );

      expect(config.hasConfiguredBannerAd, isFalse);
      expect(config.validateForReleaseCandidate, throwsStateError);
    });

    test('allows release candidate with ads disabled', () {
      final config = AppBuildConfig.resolve(
        environment: 'release',
        enableAds: false,
        admobBannerUnitId: '',
      );

      expect(config.isRelease, isTrue);
      expect(config.validateForReleaseCandidate, returnsNormally);
    });
  });
}
