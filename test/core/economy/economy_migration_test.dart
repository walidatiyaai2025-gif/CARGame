import 'dart:convert';

import 'package:cargo_sort_game/core/economy/economy_config.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
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

  test('injected economy cap owns fresh-save heart defaults', () async {
    final economy = EconomyConfig.current.copyWith(maxHearts: 7);
    final store = ProgressStore(economy: economy);

    await store.load();

    expect(store.hearts, 7);
    expect(store.economy.maxHearts, 7);
  });

  test('newer economy save version is rejected before journal replay', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('economy_config_version', 99);
    await prefs.setInt('coins', 100);
    await prefs.setString(
      'pending_reward_transaction_v1',
      jsonEncode(<String, Object?>{
        'version': 1,
        'reason': 'daily_reward_claim',
        'idempotencyKey': 'daily_reward:future-version-test',
        'values': <String, Object?>{
          'coins': 150,
          'stats_coins_earned': 50,
          'daily_reward_date': '2026-8-9',
        },
      }),
    );

    final store = ProgressStore();
    await expectLater(store.load(), throwsStateError);

    expect(await prefs.getInt('coins'), 100);
    expect(await prefs.containsKey('pending_reward_transaction_v1'), isTrue);
    expect(await prefs.getInt('economy_config_version'), 99);
  });
}
