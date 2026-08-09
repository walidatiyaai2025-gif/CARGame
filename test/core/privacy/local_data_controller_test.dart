import 'dart:convert';

import 'package:cargo_sort_game/core/economy/economy_config.dart';
import 'package:cargo_sort_game/core/logging/app_logger.dart';
import 'package:cargo_sort_game/core/privacy/local_data_controller.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await AppLogger.instance.clear();
  });

  tearDown(() async {
    await AppLogger.instance.clear();
  });

  test(
    'export is versioned JSON with local preferences and diagnostics',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 725);
      await prefs.setBool('settings_sound', false);
      await prefs.setInt('level_stars_1', 3);
      await prefs.setString(
        'storage_recovery_backup_v1',
        '{"schemaVersion":1}',
      );
      await AppLogger.instance.info('Exportable redacted diagnostic');

      final controller = LocalDataController(
        now: () => DateTime.utc(2026, 8, 10, 1, 2, 3),
      );
      final decoded =
          jsonDecode(await controller.exportJson()) as Map<String, dynamic>;

      expect(decoded['schemaVersion'], LocalDataController.exportSchemaVersion);
      expect(decoded['exportedAt'], '2026-08-10T01:02:03.000Z');
      expect(decoded['scope'], 'first_party_local_data');
      expect(decoded['networkTransfer'], isFalse);

      final values = decoded['sharedPreferences'] as Map<String, dynamic>;
      expect(values['coins'], 725);
      expect(values['settings_sound'], isFalse);
      expect(values['level_stars_1'], 3);
      expect(values['storage_recovery_backup_v1'], '{"schemaVersion":1}');

      final diagnostics = decoded['diagnostics'] as Map<String, dynamic>;
      expect(diagnostics['redacted'], isTrue);
      expect(
        (diagnostics['entries'] as List<dynamic>).join('\n'),
        contains('Exportable redacted diagnostic'),
      );

      final thirdPartyData = decoded['thirdPartyData'] as Map<String, dynamic>;
      expect(thirdPartyData['included'], isFalse);
    },
  );

  test('delete clears all SharedPreferences and local diagnostics', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 999);
    await prefs.setString('pending_reward_transaction_v1', 'pending');
    await prefs.setString('storage_recovery_backup_v1', 'backup');
    await AppLogger.instance.info('Delete me');

    final controller = LocalDataController();
    await controller.deleteAllLocalData();

    expect(await prefs.getKeys(), isEmpty);
    expect(AppLogger.instance.entries, isEmpty);
    expect(controller.deleteInProgress, isFalse);
  });

  test(
    'concurrent delete callers share one safe completion boundary',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 321);
      await AppLogger.instance.info('Delete once');

      final controller = LocalDataController();
      await Future.wait<void>([
        controller.deleteAllLocalData(),
        controller.deleteAllLocalData(),
        controller.deleteAllLocalData(),
      ]);

      expect(await prefs.getKeys(), isEmpty);
      expect(AppLogger.instance.entries, isEmpty);
      expect(controller.deleteInProgress, isFalse);
    },
  );

  test(
    'fresh stores rehydrate safe defaults after destructive reset',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 9999);
      await prefs.setInt('highest_unlocked_level', 75);
      await prefs.setInt('level_stars_1', 3);
      await prefs.setBool('settings_sound', false);
      await prefs.setStringList('reward_transaction_ledger_v1', [
        'daily_reward:2026-8-10',
      ]);
      await prefs.setString('storage_recovery_backup_v1', 'old-backup');

      final controller = LocalDataController();
      await controller.deleteAllLocalData();

      final store = ProgressStore();
      final settings = AppSettingsStore();
      await Future.wait<void>([store.load(), settings.load()]);

      expect(store.highestUnlockedLevel, 1);
      expect(store.coins, EconomyConfig.current.player.startingCoins);
      expect(store.starsForLevel(1), 0);
      expect(store.completedRewardTransactions, isEmpty);
      expect(store.recoveryEvents, isEmpty);
      expect(settings.soundEnabled, isTrue);
      expect(settings.musicEnabled, isTrue);
      expect(settings.vibrationEnabled, isTrue);
      expect(await prefs.containsKey('storage_recovery_backup_v1'), isFalse);
    },
  );
}
