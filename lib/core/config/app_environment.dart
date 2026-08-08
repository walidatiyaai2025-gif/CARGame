enum AppEnvironment { debug, staging, release }

/// Typed, compile-time build configuration for Android release candidates.
///
/// Values are injected with `--dart-define` and intentionally default to safe,
/// non-production behavior. Secrets must never be committed to source control.
final class AppBuildConfig {
  const AppBuildConfig({
    required this.environment,
    required this.enableAds,
    required this.admobBannerUnitId,
  });

  final AppEnvironment environment;
  final bool enableAds;
  final String admobBannerUnitId;

  bool get isRelease => environment == AppEnvironment.release;

  bool get hasConfiguredBannerAd =>
      enableAds && admobBannerUnitId.trim().isNotEmpty;

  static const _environmentDefine = String.fromEnvironment(
    'CARGAME_ENV',
    defaultValue: 'debug',
  );
  static const _adsEnabledDefine = bool.fromEnvironment(
    'CARGAME_ENABLE_ADS',
    defaultValue: false,
  );
  static const _bannerUnitDefine = String.fromEnvironment(
    'CARGAME_ADMOB_BANNER_UNIT_ID',
    defaultValue: '',
  );

  factory AppBuildConfig.fromEnvironment() => AppBuildConfig.resolve(
    environment: _environmentDefine,
    enableAds: _adsEnabledDefine,
    admobBannerUnitId: _bannerUnitDefine,
  );

  factory AppBuildConfig.resolve({
    required String environment,
    required bool enableAds,
    required String admobBannerUnitId,
  }) {
    final normalizedEnvironment = environment.trim().toLowerCase();
    final resolvedEnvironment = switch (normalizedEnvironment) {
      'release' => AppEnvironment.release,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.debug,
    };

    final normalizedBannerId = admobBannerUnitId.trim();

    return AppBuildConfig(
      environment: resolvedEnvironment,
      enableAds: enableAds,
      admobBannerUnitId: normalizedBannerId,
    );
  }

  /// Release candidates may run without ads, but ads must never be enabled with
  /// a missing unit ID. This keeps no-fill/misconfiguration from blocking play.
  void validateForReleaseCandidate() {
    if (enableAds && admobBannerUnitId.isEmpty) {
      throw StateError(
        'CARGAME_ENABLE_ADS=true requires CARGAME_ADMOB_BANNER_UNIT_ID.',
      );
    }
  }
}
