import 'dart:convert';

import 'package:cargo_sort_game/core/storage/progress_store.dart';
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

  test(
    'load clamps persisted wallet, hearts, boosters and level bounds',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', -500);
      await prefs.setInt('hearts', 99);
      await prefs.setInt('highest_unlocked_level', 999);
      await prefs.setInt('booster_free_hints', -4);
      await prefs.setInt('booster_extra_moves', -3);
      await prefs.setInt('booster_combo_shields', -2);

      final store = ProgressStore();
      await store.load();

      expect(store.coins, 0);
      expect(store.hearts, ProgressStore.maxHearts);
      expect(store.highestUnlockedLevel, ProgressStore.totalLevels);
      expect(store.freeHints, 0);
      expect(store.extraMovesBoosters, 0);
      expect(store.comboShields, 0);
      expect(store.recoveryEvents, hasLength(6));
    },
  );

  test(
    'wrong-type progress key is backed up and repaired independently',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('coins', 'not-an-int');
      await prefs.setInt('stats_wins', 17);

      final store = ProgressStore();
      await store.load();

      expect(store.coins, 100);
      expect(store.wins, 17);
      expect(store.recoveryEvents, hasLength(1));
      expect(store.recoveryEvents.single.key, 'coins');
      expect(await prefs.containsKey('coins'), isFalse);

      final backupText = await prefs.getString(RecoveringPreferences.backupKey);
      expect(backupText, isNotNull);
      final backup = jsonDecode(backupText!) as Map<String, dynamic>;
      final values = backup['values'] as Map<String, dynamic>;
      expect(values['coins'], 'not-an-int');
      expect(values['stats_wins'], 17);
    },
  );

  test(
    'malformed heart timestamp is removed without resetting wallet',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('heart_refill_timestamp', 'definitely-not-a-date');
      await prefs.setInt('hearts', 2);
      await prefs.setInt('coins', 450);

      final store = ProgressStore();
      await store.load();

      expect(store.coins, 450);
      expect(store.hearts, 2);
      expect(
        store.recoveryEvents.any(
          (event) => event.key == 'heart_refill_timestamp',
        ),
        isTrue,
      );
      expect(await prefs.containsKey('heart_refill_timestamp'), isTrue);
    },
  );

  test('future heart timestamp is repaired without freezing refill', () async {
    final prefs = SharedPreferencesAsync();
    final future = DateTime.now().toUtc().add(const Duration(days: 2));
    await prefs.setString('heart_refill_timestamp', future.toIso8601String());
    await prefs.setInt('hearts', 2);

    final store = ProgressStore();
    await store.load();

    expect(store.hearts, 2);
    expect(
      store.recoveryEvents.any(
        (event) =>
            event.key == 'heart_refill_timestamp' &&
            event.reason == 'future heart refill timestamp',
      ),
      isTrue,
    );
    final repaired = DateTime.parse(
      (await prefs.getString('heart_refill_timestamp'))!,
    ).toUtc();
    expect(repaired.isAfter(DateTime.now().toUtc()), isFalse);
  });

  test(
    'spendCoins rejects non-positive amounts and insufficient funds',
    () async {
      final store = ProgressStore();
      await store.load();
      final initialCoins = store.coins;

      expect(await store.spendCoins(0), isFalse);
      expect(await store.spendCoins(-10), isFalse);
      expect(await store.spendCoins(initialCoins + 1), isFalse);
      expect(store.coins, initialCoins);

      expect(await store.spendCoins(25), isTrue);
      expect(store.coins, initialCoins - 25);
    },
  );

  test('booster purchase validates input before charging wallet', () async {
    final store = ProgressStore();
    await store.load();
    final initialCoins = store.coins;
    final initialHints = store.freeHints;

    expect(() => store.purchaseBooster('unknown', 1, 10), throwsArgumentError);
    expect(store.coins, initialCoins);

    expect(await store.purchaseBooster('hint', 0, 10), isFalse);
    expect(await store.purchaseBooster('hint', -2, 10), isFalse);
    expect(store.coins, initialCoins);
    expect(store.freeHints, initialHints);

    expect(await store.purchaseBooster('hint', 2, 10), isTrue);
    expect(store.coins, initialCoins - 10);
    expect(store.freeHints, initialHints + 2);
  });

  test('booster use never drives inventory below zero', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('booster_free_hints', 1);
    await prefs.setInt('booster_extra_moves', 1);
    await prefs.setInt('booster_combo_shields', 1);

    final store = ProgressStore();
    await store.load();

    expect(await store.useFreeHint(), isTrue);
    expect(await store.useFreeHint(), isFalse);
    expect(store.freeHints, 0);

    expect(await store.useExtraMoves(), isTrue);
    expect(await store.useExtraMoves(), isFalse);
    expect(store.extraMovesBoosters, 0);

    expect(await store.useComboShield(), isTrue);
    expect(await store.useComboShield(), isFalse);
    expect(store.comboShields, 0);
  });

  test('hearts stay inside bounds while spending and adding', () async {
    final store = ProgressStore();
    await store.load();

    for (var i = 0; i < ProgressStore.maxHearts; i++) {
      expect(await store.spendHeart(), isTrue);
    }
    expect(await store.spendHeart(), isFalse);
    expect(store.hearts, 0);

    await store.addHearts(-50);
    expect(store.hearts, 0);
    await store.addHearts(500);
    expect(store.hearts, ProgressStore.maxHearts);
  });

  test('stars are clamped and best-star progress never regresses', () async {
    final store = ProgressStore();
    await store.load();

    await store.completeLevel(1, 10, stars: 99);
    expect(store.starsForLevel(1), ProgressStore.maxStarsPerLevel);

    await store.completeLevel(1, 10, stars: 1);
    expect(store.starsForLevel(1), ProgressStore.maxStarsPerLevel);
  });

  test('milestone bonus is granted only on first clear', () async {
    final store = ProgressStore();
    await store.load();

    final initialCoins = store.coins;
    await store.completeLevel(5, 10);
    expect(store.lastCompletionBonus, 55);
    expect(store.coins, initialCoins + 65);

    await store.completeLevel(5, 10);
    expect(store.lastCompletionBonus, 0);
    expect(store.coins, initialCoins + 75);
  });

  test('world reward and booster grant are first-clear only', () async {
    final store = ProgressStore();
    await store.load();

    final hints = store.freeHints;
    final moves = store.extraMovesBoosters;
    final shields = store.comboShields;

    await store.completeLevel(25, 10);
    expect(store.lastCompletionWasWorldReward, isTrue);
    expect(store.lastCompletionBonus, 400);
    expect(store.freeHints, hints + 1);
    expect(store.extraMovesBoosters, moves + 1);
    expect(store.comboShields, shields + 1);

    await store.completeLevel(25, 10);
    expect(store.lastCompletionWasWorldReward, isFalse);
    expect(store.lastCompletionBonus, 0);
    expect(store.freeHints, hints + 1);
    expect(store.extraMovesBoosters, moves + 1);
    expect(store.comboShields, shields + 1);
  });

  test('final level never unlocks beyond the configured level count', () async {
    final store = ProgressStore();
    await store.load();

    await store.completeLevel(ProgressStore.totalLevels, 10);

    expect(store.highestUnlockedLevel, ProgressStore.totalLevels);
    expect(store.completedLevels, ProgressStore.totalLevels - 1);
  });

  test('daily mission reward cannot be claimed twice', () async {
    final store = ProgressStore();
    await store.load();

    await store.completeLevel(1, 50, stars: 2);
    await store.completeLevel(2, 50, stars: 2);
    await store.completeLevel(3, 50, stars: 2);
    expect(store.dailyMissionComplete, isTrue);

    final beforeClaim = store.coins;
    expect(await store.claimDailyMission(), 200);
    expect(await store.claimDailyMission(), isNull);
    expect(store.coins, beforeClaim + 200);
  });
}
