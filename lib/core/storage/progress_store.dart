import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore extends ChangeNotifier {
  static const _levelKey = 'highest_unlocked_level';
  static const _coinsKey = 'coins';
  static const _heartsKey = 'hearts';
  static const _dailyRewardKey = 'daily_reward_date';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  int highestUnlockedLevel = 1;
  int coins = 100;
  int hearts = 5;
  String? _lastDailyRewardDate;

  bool get canClaimDailyReward {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    return _lastDailyRewardDate != today;
  }

  Future<void> load() async {
    highestUnlockedLevel = await _prefs.getInt(_levelKey) ?? 1;
    coins = await _prefs.getInt(_coinsKey) ?? 100;
    hearts = await _prefs.getInt(_heartsKey) ?? 5;
    _lastDailyRewardDate = await _prefs.getString(_dailyRewardKey);
    notifyListeners();
  }

  Future<void> completeLevel(int level, int reward) async {
    coins += reward;
    if (level >= highestUnlockedLevel && highestUnlockedLevel < 5) {
      highestUnlockedLevel = level + 1;
    }
    await _prefs.setInt(_levelKey, highestUnlockedLevel);
    await _prefs.setInt(_coinsKey, coins);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    coins -= amount;
    await _prefs.setInt(_coinsKey, coins);
    notifyListeners();
    return true;
  }

  Future<bool> spendHeart() async {
    if (hearts <= 0) return false;
    hearts -= 1;
    await _prefs.setInt(_heartsKey, hearts);
    notifyListeners();
    return true;
  }

  Future<bool> loseHeart() => spendHeart();

  Future<void> addHearts(int amount) async {
    hearts = (hearts + amount).clamp(0, 5);
    await _prefs.setInt(_heartsKey, hearts);
    notifyListeners();
  }

  Future<int?> claimDailyReward() async {
    if (!canClaimDailyReward) return null;

    const reward = 50;
    final now = DateTime.now();
    _lastDailyRewardDate = '${now.year}-${now.month}-${now.day}';
    coins += reward;

    await _prefs.setString(_dailyRewardKey, _lastDailyRewardDate!);
    await _prefs.setInt(_coinsKey, coins);
    notifyListeners();
    return reward;
  }
}
