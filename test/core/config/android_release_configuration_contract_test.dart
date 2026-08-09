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

  test('Gradle release debug signing requires explicit QA opt-in', () {
    final gradle = read('android/app/build.gradle.kts');

    expect(gradle, contains('ADMOB_ANDROID_APP_ID'));
    expect(gradle, contains('validateReleaseConfiguration'));
    expect(gradle, contains('ANDROID_KEYSTORE_PATH'));
    expect(gradle, contains('key.properties'));
    expect(gradle, contains('ALLOW_DEBUG_SIGNING_IN_RELEASE'));
    expect(gradle, contains('allowDebugSigningInRelease'));
    expect(gradle, contains('signingConfigs.getByName("debug")'));
    expect(
      gradle,
      contains('!hasCompleteReleaseSigning && !allowDebugSigningInRelease'),
    );
  });

  test(
    'RC builder forces release runtime configuration through shared preflight',
    () {
      final script = read('BUILD_RC.ps1');
      final preflight = read('VERIFY_RELEASE_INPUTS.ps1');

      expect(script, contains('--dart-define=APP_ENV=release'));
      expect(script, contains('AndroidAdMobAppId'));
      expect(script, contains('ADMOB_ANDROID_APP_ID'));
      expect(script, contains('VERIFY_RELEASE_INPUTS.ps1'));
      expect(script, contains(r'$preflight.Ready'));

      expect(preflight, contains('ANDROID_KEYSTORE_PATH'));
      expect(preflight, contains('ANDROID_KEYSTORE_PASSWORD'));
      expect(preflight, contains('ANDROID_KEY_ALIAS'));
      expect(preflight, contains('ANDROID_KEY_PASSWORD'));
      expect(preflight, contains('key.properties'));
      expect(preflight, contains('Google test configuration'));
    },
  );

  test('generic release builds cannot inherit debug runtime defaults', () {
    final script = read('BUILD_COMMON.ps1');

    expect(script, contains('--dart-define=APP_ENV=release'));
    expect(script, contains('--dart-define=ENABLE_ADS=false'));
  });
}
