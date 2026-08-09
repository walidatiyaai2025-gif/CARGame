import 'dart:convert';

import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pendingRewardKey = 'pending_reward_transaction_v1';
  const rewardLedgerKey = 'reward_transaction_ledger_v1';

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('legacy save loads with an empty reward ledger', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 345);
    await prefs.setInt('player_xp', 900);
    await prefs.setInt('highest_unlocked_level', 12);

    final store = ProgressStore();
    await store.load();

    expect(store.coins, 345);
    expect(store.playerXp, 900);
    expect(store.highestUnlockedLevel, 12);
    expect(store.completedRewardTransactions, isEmpty);
    expect(await prefs.containsKey(rewardLedgerKey), isFalse);
  });

  test('replayed level transaction with the same id is a no-op', () async {
    final store = ProgressStore();
    await store.load();

    await store.completeLevel(
      1,
      45,
      stars: 3,
      combo: 4,
      xpEarned: 70,
      transactionId: 'attempt-001',
    );
    final snapshot = <String, int>{
      'coins': store.coins,
      'xp': store.playerXp,
      'games': store.gamesPlayed,
      'wins': store.wins,
      'earned': store.lifetimeCoinsEarned,
      'missionWins': store.missionWins,
      'missionStars': store.missionStars,
      'missionCoins': store.missionCoins,
      'perfectWins': store.perfectWins,
    };

    await store.completeLevel(
      1,
      45,
      stars: 3,
      combo: 4,
      xpEarned: 70,
      transactionId: 'attempt-001',
    );

    expect(store.coins, snapshot['coins']);
    expect(store.playerXp, snapshot['xp']);
    expect(store.gamesPlayed, snapshot['games']);
    expect(store.wins, snapshot['wins']);
    expect(store.lifetimeCoinsEarned, snapshot['earned']);
    expect(store.missionWins, snapshot['missionWins']);
    expect(store.missionStars, snapshot['missionStars']);
    expect(store.missionCoins, snapshot['missionCoins']);
    expect(store.perfectWins, snapshot['perfectWins']);
    expect(store.starsForLevel(1), 3);
    expect(store.completedRewardTransactions, contains('level:1:attempt-001'));
  });

  test('load reconciles an interrupted level reward exactly once', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 145);
    await prefs.setInt('stats_games', 0);
    await prefs.setInt('stats_wins', 0);
    await prefs.setString(
      pendingRewardKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'reason': 'level_first_clear',
        'idempotencyKey': 'level:1:attempt-recovery',
        'values': <String, Object?>{
          'highest_unlocked_level': 2,
          'coins': 145,
          'stats_games': 1,
          'stats_wins': 1,
          'stats_losses': 0,
          'stats_coins_earned': 45,
          'stats_perfect_wins': 1,
          'stats_best_combo': 4,
          'stats_win_streak': 1,
          'stats_best_win_streak': 1,
          'player_xp': 70,
          'mission_wins': 1,
          'mission_stars': 3,
          'mission_coins': 45,
          'booster_free_hints': 2,
          'booster_extra_moves': 1,
          'booster_combo_shields': 1,
          'level_stars_1': 3,
        },
      }),
    );

    final recovered = ProgressStore();
    await recovered.load();

    expect(recovered.coins, 145);
    expect(recovered.gamesPlayed, 1);
    expect(recovered.wins, 1);
    expect(recovered.playerXp, 70);
    expect(recovered.starsForLevel(1), 3);
    expect(recovered.highestUnlockedLevel, 2);
    expect(
      recovered.completedRewardTransactions,
      contains('level:1:attempt-recovery'),
    );
    expect(await prefs.containsKey(pendingRewardKey), isFalse);

    final secondLoad = ProgressStore();
    await secondLoad.load();
    expect(secondLoad.coins, 145);
    expect(secondLoad.gamesPlayed, 1);
    expect(secondLoad.wins, 1);
    expect(secondLoad.playerXp, 70);
    expect(secondLoad.starsForLevel(1), 3);
  });

  test('completed journal cleanup never reapplies the reward', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 150);
    await prefs.setInt('stats_coins_earned', 50);
    await prefs.setStringList(rewardLedgerKey, <String>[
      'daily_reward:2026-8-9',
    ]);
    await prefs.setString(
      pendingRewardKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'reason': 'daily_reward_claim',
        'idempotencyKey': 'daily_reward:2026-8-9',
        'values': <String, Object?>{
          'daily_reward_date': '2026-8-9',
          'coins': 150,
          'stats_coins_earned': 50,
        },
      }),
    );

    final store = ProgressStore();
    await store.load();

    expect(store.coins, 150);
    expect(store.lifetimeCoinsEarned, 50);
    expect(await prefs.containsKey(pendingRewardKey), isFalse);
  });

  test(
    'malformed pending reward is discarded without wallet changes',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 90);
      await prefs.setString(pendingRewardKey, '{not-json');

      final store = ProgressStore();
      await store.load();

      expect(store.coins, 90);
      expect(await prefs.containsKey(pendingRewardKey), isFalse);
    },
  );

  test('daily mission claim is persisted through the reward ledger', () async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final prefs = SharedPreferencesAsync();
    await prefs.setString('mission_date', today);
    await prefs.setInt('mission_wins', 3);
    await prefs.setInt('mission_stars', 6);
    await prefs.setInt('mission_coins', 150);
    await prefs.setBool('mission_claimed', false);
    await prefs.setInt('coins', 100);
    await prefs.setInt('stats_coins_earned', 0);

    final store = ProgressStore();
    await store.load();
    expect(await store.claimDailyMission(), 200);
    expect(store.coins, 300);
    expect(store.lifetimeCoinsEarned, 200);
    expect(store.missionClaimed, isTrue);
    expect(store.completedRewardTransactions, contains('daily_mission:$today'));

    expect(await store.claimDailyMission(), isNull);
    expect(store.coins, 300);

    final reloaded = ProgressStore();
    await reloaded.load();
    expect(reloaded.coins, 300);
    expect(reloaded.lifetimeCoinsEarned, 200);
    expect(reloaded.missionClaimed, isTrue);
    expect(await reloaded.claimDailyMission(), isNull);
  });

  test('heart grants replay and recover without double-award', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('hearts', 2);
    await prefs.setString(
      'heart_refill_timestamp',
      DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
    );

    final store = ProgressStore();
    await store.load();
    expect(store.hearts, 2);

    await store.addHearts(2, transactionId: 'revive-001');
    expect(store.hearts, 4);
    await store.addHearts(2, transactionId: 'revive-001');
    expect(store.hearts, 4);
    expect(
      store.completedRewardTransactions,
      contains('heart_grant:revive-001'),
    );

    await prefs.setString(
      pendingRewardKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'reason': 'heart_grant',
        'idempotencyKey': 'heart_grant:revive-recovery',
        'values': <String, Object?>{
          'hearts': 5,
          'heart_refill_timestamp': null,
        },
      }),
    );

    final recovered = ProgressStore();
    await recovered.load();
    expect(recovered.hearts, 5);
    expect(
      recovered.completedRewardTransactions,
      contains('heart_grant:revive-recovery'),
    );
    expect(await prefs.containsKey(pendingRewardKey), isFalse);
    expect(await prefs.containsKey('heart_refill_timestamp'), isFalse);

    final secondLoad = ProgressStore();
    await secondLoad.load();
    expect(secondLoad.hearts, 5);
  });
}
