import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/recovering_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('corrupt setting falls back without damaging valid settings', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('settings_sound', 'yes');
    await prefs.setBool('settings_music', false);
    await prefs.setBool('settings_vibration', false);

    final settings = AppSettingsStore();
    await settings.load();

    expect(settings.soundEnabled, isTrue);
    expect(settings.musicEnabled, isFalse);
    expect(settings.vibrationEnabled, isFalse);
    expect(await prefs.containsKey('settings_sound'), isFalse);
    expect(await prefs.getString(RecoveringPreferences.backupKey), isNotNull);
  });
}
