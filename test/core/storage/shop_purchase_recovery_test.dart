import 'dart:convert';

import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pendingPurchaseKey = 'pending_shop_purchase_v1';

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'booster purchase persists authoritative wallet and inventory',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 500);
      final store = ProgressStore();
      await store.load();

      final initialHints = store.freeHints;
      expect(await store.purchaseBooster('hint', 2, 25), isTrue);
      expect(store.coins, 320);
      expect(store.freeHints, initialHints + 3);

      final reloaded = ProgressStore();
      await reloaded.load();
      expect(reloaded.coins, 320);
      expect(reloaded.freeHints, initialHints + 3);
      expect(await prefs.containsKey(pendingPurchaseKey), isFalse);
    },
  );

  test('load completes an interrupted booster purchase idempotently', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 100);
    await prefs.setInt('booster_free_hints', 4);
    await prefs.setString(
      pendingPurchaseKey,
      jsonEncode({
        'version': 1,
        'reason': 'booster:hint',
        'values': {'booster_free_hints': 4, 'coins': 75},
      }),
    );

    final recovered = ProgressStore();
    await recovered.load();
    expect(recovered.coins, 75);
    expect(recovered.freeHints, 4);
    expect(await prefs.containsKey(pendingPurchaseKey), isFalse);

    final secondLoad = ProgressStore();
    await secondLoad.load();
    expect(secondLoad.coins, 75);
    expect(secondLoad.freeHints, 4);
  });

  test(
    'load completes an interrupted theme purchase without double debit',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 100);
      await prefs.setStringList('unlocked_shop_themes', ['classic', 'sunset']);
      await prefs.setString('selected_shop_theme', 'classic');
      await prefs.setString(
        pendingPurchaseKey,
        jsonEncode({
          'version': 1,
          'reason': 'theme:sunset',
          'values': {
            'unlocked_shop_themes': ['classic', 'sunset'],
            'selected_shop_theme': 'sunset',
            'coins': 40,
          },
        }),
      );

      final recovered = ProgressStore();
      await recovered.load();
      expect(recovered.coins, 40);
      expect(recovered.isThemeUnlocked('sunset'), isTrue);
      expect(recovered.selectedTheme, 'sunset');
      expect(await prefs.containsKey(pendingPurchaseKey), isFalse);

      final secondLoad = ProgressStore();
      await secondLoad.load();
      expect(secondLoad.coins, 40);
      expect(secondLoad.isThemeUnlocked('sunset'), isTrue);
      expect(secondLoad.selectedTheme, 'sunset');
    },
  );

  test(
    'malformed pending purchase is discarded without changing wallet',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 90);
      await prefs.setString(pendingPurchaseKey, '{not-json');

      final store = ProgressStore();
      await store.load();

      expect(store.coins, 90);
      expect(await prefs.containsKey(pendingPurchaseKey), isFalse);
    },
  );

  test(
    'heart purchase is atomic and uses the authoritative offer price',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 500);
      await prefs.setInt('hearts', 4);
      await prefs.setString(
        'heart_refill_timestamp',
        DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      );

      final store = ProgressStore();
      await store.load();
      expect(await store.purchaseHearts('heart_single'), isTrue);
      expect(store.coins, 380);
      expect(store.hearts, 5);
      expect(await prefs.containsKey('heart_refill_timestamp'), isFalse);
      expect(await prefs.containsKey(pendingPurchaseKey), isFalse);

      final reloaded = ProgressStore();
      await reloaded.load();
      expect(reloaded.coins, 380);
      expect(reloaded.hearts, 5);
    },
  );

  test('theme purchase ignores spoofed caller price', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 1000);
    final store = ProgressStore();
    await store.load();

    expect(await store.purchaseTheme('sunset', 1), isTrue);
    expect(store.coins, 300);
    expect(store.isThemeUnlocked('sunset'), isTrue);
  });

  test('load completes interrupted heart purchase idempotently', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 500);
    await prefs.setInt('hearts', 4);
    await prefs.setString('heart_refill_timestamp', '2026-08-09T00:00:00Z');
    await prefs.setString(
      pendingPurchaseKey,
      jsonEncode({
        'version': 1,
        'reason': 'heart:heart_single',
        'values': {'coins': 380, 'hearts': 5, 'heart_refill_timestamp': null},
      }),
    );

    final recovered = ProgressStore();
    await recovered.load();
    expect(recovered.coins, 380);
    expect(recovered.hearts, 5);
    expect(await prefs.containsKey('heart_refill_timestamp'), isFalse);
    expect(await prefs.containsKey(pendingPurchaseKey), isFalse);

    final secondLoad = ProgressStore();
    await secondLoad.load();
    expect(secondLoad.coins, 380);
    expect(secondLoad.hearts, 5);
  });
}
