enum AppEnvironment {
  debug,
  staging,
  release;

  static AppEnvironment parse(String value) {
    switch (value.trim().toLowerCase()) {
      case 'debug':
        return AppEnvironment.debug;
      case 'staging':
        return AppEnvironment.staging;
      case 'release':
        return AppEnvironment.release;
      default:
        throw FormatException('Unsupported APP_ENV: $value');
    }
  }
}

final class AdMobUnitIds {
  const AdMobUnitIds({
    required this.androidBanner,
    required this.iosBanner,
    required this.androidRewarded,
    required this.iosRewarded,
    required this.androidInterstitial,
    required this.iosInterstitial,
  });

  static const googleTestAndroidBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const googleTestIosBanner =
      'ca-app-pub-3940256099942544/2934735716';
  static const googleTestAndroidRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const googleTestIosRewarded =
      'ca-app-pub-3940256099942544/1712485313';
  static const googleTestAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const googleTestIosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  static const googleTest = AdMobUnitIds(
    androidBanner: googleTestAndroidBanner,
    iosBanner: googleTestIosBanner,
    androidRewarded: googleTestAndroidRewarded,
    iosRewarded: googleTestIosRewarded,
    androidInterstitial: googleTestAndroidInterstitial,
    iosInterstitial: googleTestIosInterstitial,
  );

  final String androidBanner;
  final String iosBanner;
  final String androidRewarded;
  final String iosRewarded;
  final String androidInterstitial;
  final String iosInterstitial;

  Iterable<String> get values sync* {
    yield androidBanner;
    yield iosBanner;
    yield androidRewarded;
    yield iosRewarded;
    yield androidInterstitial;
    yield iosInterstitial;
  }

  bool get isComplete => values.every((value) => value.trim().isNotEmpty);

  bool get usesGoogleTestIds =>
      values.any((value) => value.startsWith('ca-app-pub-3940256099942544/'));
}

final class AppBuildConfig {
  const AppBuildConfig._({
    required this.environment,
    required this.enableDiagnostics,
    required this.enableAds,
    required this.adMob,
  });

  static final AppBuildConfig current = AppBuildConfig.fromValues(
    environmentName: const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'debug',
    ),
    enableDiagnostics: const bool.fromEnvironment(
      'ENABLE_DIAGNOSTICS',
      defaultValue: true,
    ),
    enableAds: const bool.fromEnvironment('ENABLE_ADS', defaultValue: true),
    adMob: const AdMobUnitIds(
      androidBanner: String.fromEnvironment(
        'ADMOB_ANDROID_BANNER_ID',
        defaultValue: AdMobUnitIds.googleTestAndroidBanner,
      ),
      iosBanner: String.fromEnvironment(
        'ADMOB_IOS_BANNER_ID',
        defaultValue: AdMobUnitIds.googleTestIosBanner,
      ),
      androidRewarded: String.fromEnvironment(
        'ADMOB_ANDROID_REWARDED_ID',
        defaultValue: AdMobUnitIds.googleTestAndroidRewarded,
      ),
      iosRewarded: String.fromEnvironment(
        'ADMOB_IOS_REWARDED_ID',
        defaultValue: AdMobUnitIds.googleTestIosRewarded,
      ),
      androidInterstitial: String.fromEnvironment(
        'ADMOB_ANDROID_INTERSTITIAL_ID',
        defaultValue: AdMobUnitIds.googleTestAndroidInterstitial,
      ),
      iosInterstitial: String.fromEnvironment(
        'ADMOB_IOS_INTERSTITIAL_ID',
        defaultValue: AdMobUnitIds.googleTestIosInterstitial,
      ),
    ),
  );

  factory AppBuildConfig.fromValues({
    required String environmentName,
    required bool enableDiagnostics,
    required bool enableAds,
    required AdMobUnitIds adMob,
  }) {
    final environment = AppEnvironment.parse(environmentName);
    final config = AppBuildConfig._(
      environment: environment,
      enableDiagnostics: enableDiagnostics,
      enableAds: enableAds,
      adMob: adMob,
    );
    config.validate();
    return config;
  }

  final AppEnvironment environment;
  final bool enableDiagnostics;
  final bool enableAds;
  final AdMobUnitIds adMob;

  bool get isDebug => environment == AppEnvironment.debug;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isRelease => environment == AppEnvironment.release;

  void validate() {
    if (!enableAds) return;

    if (!adMob.isComplete) {
      throw StateError('AdMob unit IDs must be complete when ads are enabled.');
    }

    if (isRelease && adMob.usesGoogleTestIds) {
      throw StateError(
        'Release builds cannot use Google test AdMob unit IDs. '
        'Inject release IDs with --dart-define.',
      );
    }
  }
}
