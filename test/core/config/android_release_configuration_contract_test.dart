import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const googleTestAppId = 'ca-app-pub-3940256099942544~3347511713';

  String read(String path) => File(path).readAsStringSync();

  test('main manifest externalizes the AdMob application id', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    expect(manifest, contains(r'android:value="${admobApplicationId}"'));
    expect(manifest, isNot(contains(googleTestAppId)));
  });

  test('Gradle release configuration never falls back to debug signing', () {
    final gradle = read('android/app/build.gradle.kts');

    expect(gradle, contains('ADMOB_ANDROID_APP_ID'));
    expect(gradle, contains('validateReleaseConfiguration'));
    expect(gradle, contains('ANDROID_KEYSTORE_PATH'));
    expect(gradle, contains('key.properties'));
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
  });

  test(
    'RC builder forces release runtime configuration and external inputs',
    () {
      final script = read('BUILD_RC.ps1');

      expect(script, contains('--dart-define=APP_ENV=release'));
      expect(script, contains('AndroidAdMobAppId'));
      expect(script, contains('ADMOB_ANDROID_APP_ID'));
      expect(script, contains('Assert-ReleaseSigningConfigured'));
      expect(script, contains('ANDROID_KEYSTORE_PASSWORD'));
    },
  );

  test('generic release builds cannot inherit debug runtime defaults', () {
    final script = read('BUILD_COMMON.ps1');

    expect(script, contains('--dart-define=APP_ENV=release'));
    expect(script, contains('--dart-define=ENABLE_ADS=false'));
  });
}
