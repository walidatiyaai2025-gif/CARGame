import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore extends ChangeNotifier {
  static const int totalLevels = 150;
  static const int maxStarsPerLevel = 3;
  static const int maxHearts = 5;
  static const Duration heartRefillInterval = Duration(minutes: 30);

  static const _levelKey = 'highest_unlocked_level';
  static const _coinsKey = 'coins';
  static const _heartsKey = 'hearts';
  static const _heartTimestampKey = 'heart_refill_timestamp';
  static const _dailyRewardKey = 'daily_reward_date';
  static const _starsPrefix = 'level_stars_';
  static const _gamesKey = 'stats_games';
  static const _winsKey = 'stats_wins';
  static const _lossesKey = 'stats_losses';
  static const _coinsEarnedKey = 'stats_coins_earned';
  static const _perfectWinsKey = 'stats_perfect_wins';
  static const _bestComboKey = 'stats_best_combo';
  static const _winStreakKey = 'stats_win_streak';
  static const _bestWinStreakKey = 'stats_best_win_streak';
  static const _xpKey = 'player_xp';
  static const _missionDateKey = 'mission_date';
  static const _missionWinsKey = 'mission_wins';
  static const _missionStarsKey = 'mission_stars';
  static const _missionCoinsKey = 'mission_coins';
  static const _missionClaimedKey = 'mission_claimed';
  static const _selectedThemeKey = 'selected_shop_theme';
  static const _unlockedThemesKey = 'unlocked_shop_themes';
  static const _freeHintsKey = 'booster_free_hints';
  static const _extraMovesKey = 'booster_extra_moves';
  static const _comboShieldsKey = 'booster_combo_shields';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Map<int, int> _levelStars = <int, int>{};

  int highestUnlockedLevel = 1;
  int coins = 100;
  int hearts = maxHearts;
  int gamesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int lifetimeCoinsEarned = 0;
  int perfectWins = 0;
  int bestCombo = 0;
  int currentWinStreak = 0;
  int bestWinStreak = 0;
  int playerXp = 0;
  int missionWins = 0;
  int missionStars = 0;
  int missionCoins = 0;
  int freeHints = 2;
  int extraMovesBoosters = 1;
  int comboShields = 1;
  bool missionClaimed = false;
  String selectedTheme = 'classic';
  Set<String> unlockedThemes = <String>{'classic'};
  String? _lastDailyRewardDate;
  String? _missionDate;
  DateTime? _heartRefillTimestamp;

  int get completedLevels => (highestUnlockedLevel - 1).clamp(0, totalLevels);
  double get completionProgress => completedLevels / totalLevels;
  int get totalStars => _levelStars.values.fold(0, (sum, stars) => sum + stars);
  int get maximumStars => totalLevels * maxStarsPerLevel;
  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;
  bool get dailyMissionComplete => missionWins >= 3 && missionStars >= 6 && missionCoins >= 150;
  int get playerLevel => 1 + (playerXp ~/ 500);
  int get xpIntoCurrentLevel => playerXp % 500;
  double get playerLevelProgress => xpIntoCurrentLevel / 500;

  int starsForLevel(int level) => _levelStars[level] ?? 0;
  bool isThemeUnlocked(String themeId) => unlockedThemes.contains(themeId);

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool get canClaimDailyReward => _lastDailyRewardDate != _today;

  Duration get timeUntilNextHeart {
    if (hearts >= maxHearts || _heartRefillTimestamp == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_heartRefillTimestamp!);
    final remaining = heartRefillInterval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> load() async {
    highestUnlockedLevel = (await _prefs.getInt(_levelKey) ?? 1).clamp(1, totalLevels);
    coins = await _prefs.getInt(_coinsKey) ?? 100;
    hearts = (await _prefs.getInt(_heartsKey) ?? maxHearts).clamp(0, maxHearts);
    final heartTimestampText = await _prefs.getString(_heartTimestampKey);
    _heartRefillTimestamp = heartTimestampText == null ? null : DateTime.tryParse(heartTimestampText);
    await refreshHearts();

    _lastDailyRewardDate = await _prefs.getString(_dailyRewardKey);
    gamesPlayed = await _prefs.getInt(_gamesKey) ?? 0;
    wins = await _prefs.getInt(_winsKey) ?? 0;
    losses = await _prefs.getInt(_lossesKey) ?? 0;
    lifetimeCoinsEarned = await _prefs.getInt(_coinsEarnedKey) ?? 0;
    perfectWins = await _prefs.getInt(_perfectWinsKey) ?? 0;
    bestCombo = await _prefs.getInt(_bestComboKey) ?? 0;
    currentWinStreak = await _prefs.getInt(_winStreakKey) ?? 0;
    bestWinStreak = await _prefs.getInt(_bestWinStreakKey) ?? 0;
    playerXp = await _prefs.getInt(_xpKey) ?? 0;
    selectedTheme = await _prefs.getString(_selectedThemeKey) ?? 'classic';
    unlockedThemes = {...?await _prefs.getStringList(_unlockedThemesKey), 'classic'};
    if (!unlockedThemes.contains(selectedTheme)) selectedTheme = 'classic';
    freeHints = await _prefs.getInt(_freeHintsKey) ?? 2;
    extraMovesBoosters = await _prefs.getInt(_extraMovesKey) ?? 1;
    comboShields = await _prefs.getInt(_comboShieldsKey) ?? 1;

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

  Future<void> refreshHearts() async {
    if (hearts >= maxHearts) {
      _heartRefillTimestamp = null;
      await _prefs.remove(_heartTimestampKey);
      return;
    }

    final now = DateTime.now();
    _heartRefillTimestamp ??= now;
    final elapsed = now.difference(_heartRefillTimestamp!);
    final recovered = elapsed.inMinutes ~/ heartRefillInterval.inMinutes;
    if (recovered <= 0) return;

    hearts = (hearts + recovered).clamp(0, maxHearts);
    if (hearts >= maxHearts) {
      _heartRefillTimestamp = null;
      await _prefs.remove(_heartTimestampKey);
    } else {
      _heartRefillTimestamp = _heartRefillTimestamp!.add(
        Duration(minutes: recovered * heartRefillInterval.inMinutes),
      );
      await _prefs.setString(_heartTimestampKey, _heartRefillTimestamp!.toIso8601String());
    }
    await _prefs.setInt(_heartsKey, hearts);
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

  Future<void> completeLevel(
    int level,
    int reward, {
    int stars = 1,
    int combo = 0,
    int xpEarned = 0,
  }) async {
    coins += reward;
    gamesPlayed++;
    wins++;
    currentWinStreak++;
    if (currentWinStreak > bestWinStreak) bestWinStreak = currentWinStreak;
    if (combo > bestCombo) bestCombo = combo;
    playerXp += xpEarned;
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
    currentWinStreak = 0;
    await _prefs.setInt(_gamesKey, gamesPlayed);
    await _prefs.setInt(_lossesKey, losses);
    await _prefs.setInt(_winStreakKey, currentWinStreak);
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
    await _prefs.setInt(_bestComboKey, bestCombo);
    await _prefs.setInt(_winStreakKey, currentWinStreak);
    await _prefs.setInt(_bestWinStreakKey, bestWinStreak);
    await _prefs.setInt(_xpKey, playerXp);
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

  Future<bool> purchaseTheme(String themeId, int price) async {
    if (!unlockedThemes.contains(themeId)) {
      final paid = await spendCoins(price);
      if (!paid) return false;
      unlockedThemes.add(themeId);
      await _prefs.setStringList(_unlockedThemesKey, unlockedThemes.toList());
    }
    selectedTheme = themeId;
    await _prefs.setString(_selectedThemeKey, selectedTheme);
    notifyListeners();
    return true;
  }

  Future<bool> purchaseBooster(String boosterId, int amount, int price) async {
    final paid = await spendCoins(price);
    if (!paid) return false;
    switch (boosterId) {
      case 'hint':
        freeHints += amount;
        await _prefs.setInt(_freeHintsKey, freeHints);
      case 'moves':
        extraMovesBoosters += amount;
        await _prefs.setInt(_extraMovesKey, extraMovesBoosters);
      case 'shield':
        comboShields += amount;
        await _prefs.setInt(_comboShieldsKey, comboShields);
      default:
        throw ArgumentError.value(boosterId, 'boosterId');
    }
    notifyListeners();
    return true;
  }

  Future<bool> useFreeHint() async {
    if (freeHints <= 0) return false;
    freeHints--;
    await _prefs.setInt(_freeHintsKey, freeHints);
    notifyListeners();
    return true;
  }

  Future<bool> useExtraMoves() async {
    if (extraMovesBoosters <= 0) return false;
    extraMovesBoosters--;
    await _prefs.setInt(_extraMovesKey, extraMovesBoosters);
    notifyListeners();
    return true;
  }

  Future<bool> useComboShield() async {
    if (comboShields <= 0) return false;
    comboShields--;
    await _prefs.setInt(_comboShieldsKey, comboShields);
    notifyListeners();
    return true;
  }

  Future<bool> spendHeart() async {
    await refreshHearts();
    if (hearts <= 0) return false;
    hearts--;
    _heartRefillTimestamp ??= DateTime.now();
    await _prefs.setInt(_heartsKey, hearts);
    await _prefs.setString(_heartTimestampKey, _heartRefillTimestamp!.toIso8601String());
    notifyListeners();
    return true;
  }

  Future<bool> loseHeart() => spendHeart();

  Future<void> addHearts(int amount) async {
    hearts = (hearts + amount).clamp(0, maxHearts);
    if (hearts >= maxHearts) {
      _heartRefillTimestamp = null;
      await _prefs.remove(_heartTimestampKey);
    }
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
