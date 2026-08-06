import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore extends ChangeNotifier {
  static const int totalLevels = 150;
  static const int maxStarsPerLevel = 3;
  static const _levelKey = 'highest_unlocked_level';
  static const _coinsKey = 'coins';
  static const _heartsKey = 'hearts';
  static const _dailyRewardKey = 'daily_reward_date';
  static const _starsPrefix = 'level_stars_';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Map<int, int> _levelStars = <int, int>{};

  int highestUnlockedLevel = 1;
  int coins = 100;
  int hearts = 5;
  String? _lastDailyRewardDate;

  int get completedLevels => (highestUnlockedLevel - 1).clamp(0, totalLevels);
  double get completionProgress => completedLevels / totalLevels;
  int get totalStars => _levelStars.values.fold(0, (sum, stars) => sum + stars);
  int get maximumStars => totalLevels * maxStarsPerLevel;

  int starsForLevel(int level) => _levelStars[level] ?? 0;

  bool get canClaimDailyReward {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    return _lastDailyRewardDate != today;
  }

  Future<void> load() async {
    highestUnlockedLevel =
        (await _prefs.getInt(_levelKey) ?? 1).clamp(1, totalLevels);
    coins = await _prefs.getInt(_coinsKey) ?? 100;
    hearts = (await _prefs.getInt(_heartsKey) ?? 5).clamp(0, 5);
    _lastDailyRewardDate = await _prefs.getString(_dailyRewardKey);

    _levelStars.clear();
    for (var level = 1; level <= totalLevels; level++) {
      final stars = (await _prefs.getInt('$_starsPrefix$level') ?? 0)
          .clamp(0, maxStarsPerLevel);
      if (stars > 0) _levelStars[level] = stars;
    }
    notifyListeners();
  }

  Future<void> completeLevel(int level, int reward, {int stars = 1}) async {
    coins += reward;
    if (level >= highestUnlockedLevel && highestUnlockedLevel < totalLevels) {
      highestUnlockedLevel = level + 1;
    }

    final safeStars = stars.clamp(1, maxStarsPerLevel);
    final previousStars = _levelStars[level] ?? 0;
    if (safeStars > previousStars) {
      _levelStars[level] = safeStars;
      await _prefs.setInt('$_starsPrefix$level', safeStars);
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
