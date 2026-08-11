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

  test('visual effects default automatic and persist reduced mode', () async {
    final first = AppSettingsStore();
    await first.load();
    expect(first.reducedVisualEffects, isFalse);

    await first.setReducedVisualEffects(true);
    expect(first.reducedVisualEffects, isTrue);

    final second = AppSettingsStore();
    await second.load();
    expect(second.reducedVisualEffects, isTrue);
  });

  test('unknown visual effects value falls back to automatic', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('settings_visual_effects', 'future-mode');

    final settings = AppSettingsStore();
    await settings.load();

    expect(settings.reducedVisualEffects, isFalse);
  });

  test('setting the current visual mode is a notifier no-op', () async {
    final settings = AppSettingsStore();
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.setReducedVisualEffects(false);
    expect(notifications, 0);

    await settings.setReducedVisualEffects(true);
    expect(notifications, 1);

    await settings.setReducedVisualEffects(true);
    expect(notifications, 1);
  });
}
