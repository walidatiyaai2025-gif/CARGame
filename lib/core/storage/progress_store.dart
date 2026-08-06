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
  static const _gamesKey = 'stats_games';
  static const _winsKey = 'stats_wins';
  static const _lossesKey = 'stats_losses';
  static const _coinsEarnedKey = 'stats_coins_earned';
  static const _perfectWinsKey = 'stats_perfect_wins';
  static const _missionDateKey = 'mission_date';
  static const _missionWinsKey = 'mission_wins';
  static const _missionStarsKey = 'mission_stars';
  static const _missionCoinsKey = 'mission_coins';
  static const _missionClaimedKey = 'mission_claimed';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Map<int, int> _levelStars = <int, int>{};

  int highestUnlockedLevel = 1;
  int coins = 100;
  int hearts = 5;
  int gamesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int lifetimeCoinsEarned = 0;
  int perfectWins = 0;
  int missionWins = 0;
  int missionStars = 0;
  int missionCoins = 0;
  bool missionClaimed = false;
  String? _lastDailyRewardDate;
  String? _missionDate;

  int get completedLevels => (highestUnlockedLevel - 1).clamp(0, totalLevels);
  double get completionProgress => completedLevels / totalLevels;
  int get totalStars => _levelStars.values.fold(0, (sum, stars) => sum + stars);
  int get maximumStars => totalLevels * maxStarsPerLevel;
  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;
  bool get dailyMissionComplete => missionWins >= 3 && missionStars >= 6 && missionCoins >= 150;

  int starsForLevel(int level) => _levelStars[level] ?? 0;

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool get canClaimDailyReward => _lastDailyRewardDate != _today;

  Future<void> load() async {
    highestUnlockedLevel = (await _prefs.getInt(_levelKey) ?? 1).clamp(1, totalLevels);
    coins = await _prefs.getInt(_coinsKey) ?? 100;
    hearts = (await _prefs.getInt(_heartsKey) ?? 5).clamp(0, 5);
    _lastDailyRewardDate = await _prefs.getString(_dailyRewardKey);
    gamesPlayed = await _prefs.getInt(_gamesKey) ?? 0;
    wins = await _prefs.getInt(_winsKey) ?? 0;
    losses = await _prefs.getInt(_lossesKey) ?? 0;
    lifetimeCoinsEarned = await _prefs.getInt(_coinsEarnedKey) ?? 0;
    perfectWins = await _prefs.getInt(_perfectWinsKey) ?? 0;
    _missionDate = await _prefs.getString(_missionDateKey);
    if (_missionDate != _today) {
      await _resetDailyMission();
    } else {
      missionWins = await _prefs.getInt(_missionWinsKey) ?? 0;
      missionStars = await _prefs.getInt(_missionStarsKey) ?? 0;
      missionCoins = await _prefs.getInt(_missionCoinsKey) ?? 0;
      missionClaimed = await _prefs.getBool(_missionClaimedKey) ?? false;
    }

    _levelStars.clear();
    for (var level = 1; level <= totalLevels; level++) {
      final stars = (await _prefs.getInt('$_starsPrefix$level') ?? 0).clamp(0, maxStarsPerLevel);
      if (stars > 0) _levelStars[level] = stars;
    }
    notifyListeners();
  }

  Future<void> _resetDailyMission() async {
    _missionDate = _today;
    missionWins = 0;
    missionStars = 0;
    missionCoins = 0;
    missionClaimed = false;
    await _prefs.setString(_missionDateKey, _missionDate!);
    await _prefs.setInt(_missionWinsKey, 0);
    await _prefs.setInt(_missionStarsKey, 0);
    await _prefs.setInt(_missionCoinsKey, 0);
    await _prefs.setBool(_missionClaimedKey, false);
  }

  Future<void> completeLevel(int level, int reward, {int stars = 1}) async {
    coins += reward;
    gamesPlayed++;
    wins++;
    lifetimeCoinsEarned += reward;
    missionWins++;
    missionCoins += reward;

    if (level >= highestUnlockedLevel && highestUnlockedLevel < totalLevels) {
      highestUnlockedLevel = level + 1;
    }

    final safeStars = stars.clamp(1, maxStarsPerLevel);
    missionStars += safeStars;
    if (safeStars == 3) perfectWins++;
    final previousStars = _levelStars[level] ?? 0;
    if (safeStars > previousStars) {
      _levelStars[level] = safeStars;
      await _prefs.setInt('$_starsPrefix$level', safeStars);
    }

    await _saveProgressAndStats();
    notifyListeners();
  }

  Future<void> recordLoss() async {
    gamesPlayed++;
    losses++;
    await _prefs.setInt(_gamesKey, gamesPlayed);
    await _prefs.setInt(_lossesKey, losses);
    notifyListeners();
  }

  Future<int?> claimDailyMission() async {
    if (!dailyMissionComplete || missionClaimed) return null;
    const reward = 200;
    coins += reward;
    lifetimeCoinsEarned += reward;
    missionClaimed = true;
    await _prefs.setInt(_coinsKey, coins);
    await _prefs.setInt(_coinsEarnedKey, lifetimeCoinsEarned);
    await _prefs.setBool(_missionClaimedKey, true);
    notifyListeners();
    return reward;
  }

  Future<void> _saveProgressAndStats() async {
    await _prefs.setInt(_levelKey, highestUnlockedLevel);
    await _prefs.setInt(_coinsKey, coins);
    await _prefs.setInt(_gamesKey, gamesPlayed);
    await _prefs.setInt(_winsKey, wins);
    await _prefs.setInt(_lossesKey, losses);
    await _prefs.setInt(_coinsEarnedKey, lifetimeCoinsEarned);
    await _prefs.setInt(_perfectWinsKey, perfectWins);
    await _prefs.setInt(_missionWinsKey, missionWins);
    await _prefs.setInt(_missionStarsKey, missionStars);
    await _prefs.setInt(_missionCoinsKey, missionCoins);
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
    hearts--;
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
    _lastDailyRewardDate = _today;
    coins += reward;
    lifetimeCoinsEarned += reward;
    await _prefs.setString(_dailyRewardKey, _lastDailyRewardDate!);
    await _prefs.setInt(_coinsKey, coins);
    await _prefs.setInt(_coinsEarnedKey, lifetimeCoinsEarned);
    notifyListeners();
    return reward;
  }
}
