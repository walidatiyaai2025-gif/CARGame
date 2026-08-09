import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'recovering_preferences.dart';

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
  static const _pendingShopPurchaseKey = 'pending_shop_purchase_v1';
  static const _pendingRewardTransactionKey = 'pending_reward_transaction_v1';
  static const _rewardTransactionLedgerKey = 'reward_transaction_ledger_v1';
  static const int _rewardTransactionLedgerLimit = 128;

  static const Set<String> _rewardNonNegativeIntKeys = <String>{
    _coinsKey,
    _gamesKey,
    _winsKey,
    _lossesKey,
    _coinsEarnedKey,
    _perfectWinsKey,
    _bestComboKey,
    _winStreakKey,
    _bestWinStreakKey,
    _xpKey,
    _missionWinsKey,
    _missionStarsKey,
    _missionCoinsKey,
    _freeHintsKey,
    _extraMovesKey,
    _comboShieldsKey,
  };

  final RecoveringPreferences _prefs = RecoveringPreferences();
  final Map<int, int> _levelStars = <int, int>{};
  final Set<String> _completedRewardTransactions = <String>{};

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
  int lastCompletionBonus = 0;
  int lastCompletionBonusXp = 0;
  bool lastCompletionWasWorldReward = false;
  bool missionClaimed = false;
  String selectedTheme = 'classic';
  Set<String> unlockedThemes = <String>{'classic'};
  String? _lastDailyRewardDate;
  String? _missionDate;
  DateTime? _heartRefillTimestamp;
  bool _purchaseBusy = false;
  bool _rewardLedgerLoaded = false;
  int _rewardSequence = 0;
  Future<void> _rewardQueue = Future<void>.value();

  int get completedLevels => (highestUnlockedLevel - 1).clamp(0, totalLevels);
  double get completionProgress => completedLevels / totalLevels;
  int get totalStars => _levelStars.values.fold(0, (sum, stars) => sum + stars);
  int get maximumStars => totalLevels * maxStarsPerLevel;
  int get worldsCompleted => completedLevels ~/ 25;
  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;
  bool get dailyMissionComplete =>
      missionWins >= 3 && missionStars >= 6 && missionCoins >= 150;
  int get playerLevel => 1 + (playerXp ~/ 500);
  int get xpIntoCurrentLevel => playerXp % 500;
  double get playerLevelProgress => xpIntoCurrentLevel / 500;
  List<StorageRecoveryEvent> get recoveryEvents => _prefs.recoveryEvents;
  List<String> get completedRewardTransactions =>
      List<String>.unmodifiable(_completedRewardTransactions);

  int starsForLevel(int level) => _levelStars[level] ?? 0;
  bool isThemeUnlocked(String themeId) => unlockedThemes.contains(themeId);

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool get canClaimDailyReward => _lastDailyRewardDate != _today;

  Duration get timeUntilNextHeart {
    if (hearts >= maxHearts || _heartRefillTimestamp == null) {
      return Duration.zero;
    }
    final elapsed = DateTime.now().difference(_heartRefillTimestamp!);
    final remaining = heartRefillInterval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> load() async {
    await _ensureRewardLedgerLoaded();
    await _recoverPendingRewardTransaction();
    await _recoverPendingShopPurchase();

    highestUnlockedLevel = (await _prefs.getInt(_levelKey) ?? 1).clamp(
      1,
      totalLevels,
    );
    final savedCoins = await _prefs.getInt(_coinsKey);
    coins = savedCoins == null ? 100 : (savedCoins < 0 ? 0 : savedCoins);
    hearts = (await _prefs.getInt(_heartsKey) ?? maxHearts).clamp(0, maxHearts);
    final heartTimestampText = await _prefs.getString(_heartTimestampKey);
    _heartRefillTimestamp = heartTimestampText == null
        ? null
        : DateTime.tryParse(heartTimestampText);
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
    unlockedThemes = {
      ...?await _prefs.getStringList(_unlockedThemesKey),
      'classic',
    };
    if (!unlockedThemes.contains(selectedTheme)) selectedTheme = 'classic';
    final savedHints = await _prefs.getInt(_freeHintsKey);
    final savedMoves = await _prefs.getInt(_extraMovesKey);
    final savedShields = await _prefs.getInt(_comboShieldsKey);
    freeHints = savedHints == null ? 2 : (savedHints < 0 ? 0 : savedHints);
    extraMovesBoosters = savedMoves == null
        ? 1
        : (savedMoves < 0 ? 0 : savedMoves);
    comboShields = savedShields == null
        ? 1
        : (savedShields < 0 ? 0 : savedShields);

    lastCompletionBonus = 0;
    lastCompletionBonusXp = 0;
    lastCompletionWasWorldReward = false;

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
      final stars = (await _prefs.getInt('$_starsPrefix$level') ?? 0).clamp(
        0,
        maxStarsPerLevel,
      );
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
      await _prefs.setString(
        _heartTimestampKey,
        _heartRefillTimestamp!.toIso8601String(),
      );
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
    String? transactionId,
  }) => _serializeReward<void>(() async {
    if (level < 1 || level > totalLevels) {
      throw ArgumentError.value(level, 'level');
    }
    if (reward < 0) throw ArgumentError.value(reward, 'reward');
    if (xpEarned < 0) throw ArgumentError.value(xpEarned, 'xpEarned');

    await _ensureRewardLedgerLoaded();
    await _recoverPendingRewardTransaction();

    final transactionKey = _rewardTransactionKey(
      reason: 'level:$level',
      idempotencyKey: transactionId,
    );

    lastCompletionBonus = 0;
    lastCompletionBonusXp = 0;
    lastCompletionWasWorldReward = false;
    if (_completedRewardTransactions.contains(transactionKey)) return;

    final previousStars = _levelStars[level] ?? 0;
    final firstClear = previousStars == 0;
    final safeStars = stars.clamp(1, maxStarsPerLevel);

    var nextCoins = coins + reward;
    final nextGamesPlayed = gamesPlayed + 1;
    final nextWins = wins + 1;
    final nextCurrentWinStreak = currentWinStreak + 1;
    var nextBestWinStreak = bestWinStreak;
    if (nextCurrentWinStreak > nextBestWinStreak) {
      nextBestWinStreak = nextCurrentWinStreak;
    }
    var nextBestCombo = bestCombo;
    if (combo > nextBestCombo) nextBestCombo = combo;
    var nextPlayerXp = playerXp + xpEarned;
    var nextLifetimeCoinsEarned = lifetimeCoinsEarned + reward;
    final nextMissionWins = missionWins + 1;
    var nextMissionCoins = missionCoins + reward;
    var nextFreeHints = freeHints;
    var nextExtraMovesBoosters = extraMovesBoosters;
    var nextComboShields = comboShields;
    var completionBonus = 0;
    var completionBonusXp = 0;
    var completionWasWorldReward = false;

    if (firstClear && level % 25 == 0) {
      final worldNumber = level ~/ 25;
      completionBonus = 300 + worldNumber * 100;
      completionBonusXp = 150 + worldNumber * 25;
      completionWasWorldReward = true;

      nextCoins += completionBonus;
      nextPlayerXp += completionBonusXp;
      nextLifetimeCoinsEarned += completionBonus;
      nextMissionCoins += completionBonus;
      nextFreeHints++;
      nextExtraMovesBoosters++;
      nextComboShields++;
    } else if (firstClear && level % 5 == 0) {
      completionBonus = 50 + (level ~/ 5) * 5;
      completionBonusXp = 25;
      nextCoins += completionBonus;
      nextPlayerXp += completionBonusXp;
      nextLifetimeCoinsEarned += completionBonus;
      nextMissionCoins += completionBonus;
    }

    var nextHighestUnlockedLevel = highestUnlockedLevel;
    if (level >= highestUnlockedLevel && highestUnlockedLevel < totalLevels) {
      nextHighestUnlockedLevel = (level + 1).clamp(1, totalLevels);
    }

    final nextMissionStars = missionStars + safeStars;
    final nextPerfectWins = perfectWins + (safeStars == 3 ? 1 : 0);
    final nextLevelStars = safeStars > previousStars
        ? safeStars
        : previousStars;

    final values = <String, Object?>{
      _levelKey: nextHighestUnlockedLevel,
      _coinsKey: nextCoins,
      _gamesKey: nextGamesPlayed,
      _winsKey: nextWins,
      _lossesKey: losses,
      _coinsEarnedKey: nextLifetimeCoinsEarned,
      _perfectWinsKey: nextPerfectWins,
      _bestComboKey: nextBestCombo,
      _winStreakKey: nextCurrentWinStreak,
      _bestWinStreakKey: nextBestWinStreak,
      _xpKey: nextPlayerXp,
      _missionWinsKey: nextMissionWins,
      _missionStarsKey: nextMissionStars,
      _missionCoinsKey: nextMissionCoins,
      _freeHintsKey: nextFreeHints,
      _extraMovesKey: nextExtraMovesBoosters,
      _comboShieldsKey: nextComboShields,
      '$_starsPrefix$level': nextLevelStars,
    };

    final committed = await _commitRewardTransaction(
      reason: firstClear
          ? (completionWasWorldReward
                ? 'level_world_first_clear'
                : completionBonus > 0
                ? 'level_milestone_first_clear'
                : 'level_first_clear')
          : 'level_replay',
      idempotencyKey: transactionKey,
      values: values,
    );
    if (!committed) return;

    highestUnlockedLevel = nextHighestUnlockedLevel;
    coins = nextCoins;
    gamesPlayed = nextGamesPlayed;
    wins = nextWins;
    lifetimeCoinsEarned = nextLifetimeCoinsEarned;
    perfectWins = nextPerfectWins;
    bestCombo = nextBestCombo;
    currentWinStreak = nextCurrentWinStreak;
    bestWinStreak = nextBestWinStreak;
    playerXp = nextPlayerXp;
    missionWins = nextMissionWins;
    missionStars = nextMissionStars;
    missionCoins = nextMissionCoins;
    freeHints = nextFreeHints;
    extraMovesBoosters = nextExtraMovesBoosters;
    comboShields = nextComboShields;
    if (nextLevelStars > 0) _levelStars[level] = nextLevelStars;
    lastCompletionBonus = completionBonus;
    lastCompletionBonusXp = completionBonusXp;
    lastCompletionWasWorldReward = completionWasWorldReward;
    notifyListeners();
  });

  Future<void> recordLoss() async {
    gamesPlayed++;
    losses++;
    currentWinStreak = 0;
    lastCompletionBonus = 0;
    lastCompletionBonusXp = 0;
    lastCompletionWasWorldReward = false;
    await _prefs.setInt(_gamesKey, gamesPlayed);
    await _prefs.setInt(_lossesKey, losses);
    await _prefs.setInt(_winStreakKey, currentWinStreak);
    notifyListeners();
  }

  Future<int?> claimDailyMission() => _serializeReward<int?>(() async {
    await _ensureRewardLedgerLoaded();
    await _recoverPendingRewardTransaction();

    final transactionKey = _rewardTransactionKey(
      reason: 'daily_mission',
      idempotencyKey: _today,
    );
    if (_completedRewardTransactions.contains(transactionKey) ||
        !dailyMissionComplete ||
        missionClaimed) {
      return null;
    }

    const reward = 200;
    final nextCoins = coins + reward;
    final nextLifetimeCoinsEarned = lifetimeCoinsEarned + reward;
    final committed = await _commitRewardTransaction(
      reason: 'daily_mission_claim',
      idempotencyKey: transactionKey,
      values: <String, Object?>{
        _coinsKey: nextCoins,
        _coinsEarnedKey: nextLifetimeCoinsEarned,
        _missionClaimedKey: true,
      },
    );
    if (!committed) return null;

    coins = nextCoins;
    lifetimeCoinsEarned = nextLifetimeCoinsEarned;
    missionClaimed = true;
    notifyListeners();
    return reward;
  });

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
    await _prefs.setInt(_freeHintsKey, freeHints);
    await _prefs.setInt(_extraMovesKey, extraMovesBoosters);
    await _prefs.setInt(_comboShieldsKey, comboShields);
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || coins < amount) return false;
    coins -= amount;
    await _prefs.setInt(_coinsKey, coins);
    notifyListeners();
    return true;
  }

  Future<bool> purchaseTheme(String themeId, int price) async {
    if (_purchaseBusy) return false;
    _purchaseBusy = true;
    try {
      if (unlockedThemes.contains(themeId)) {
        selectedTheme = themeId;
        await _prefs.setString(_selectedThemeKey, selectedTheme);
        notifyListeners();
        return true;
      }
      if (price <= 0 || coins < price) return false;

      final finalCoins = coins - price;
      final finalThemes = <String>{...unlockedThemes, themeId};
      await _commitShopPurchase('theme:$themeId', <String, Object?>{
        _unlockedThemesKey: finalThemes.toList(),
        _selectedThemeKey: themeId,
        _coinsKey: finalCoins,
      });

      unlockedThemes = finalThemes;
      selectedTheme = themeId;
      coins = finalCoins;
      notifyListeners();
      return true;
    } finally {
      _purchaseBusy = false;
    }
  }

  Future<bool> purchaseBooster(String boosterId, int amount, int price) async {
    if (!const {'hint', 'moves', 'shield'}.contains(boosterId)) {
      throw ArgumentError.value(boosterId, 'boosterId');
    }
    if (amount <= 0 || price <= 0 || coins < price || _purchaseBusy) {
      return false;
    }

    _purchaseBusy = true;
    try {
      final finalCoins = coins - price;
      final inventoryKey = switch (boosterId) {
        'hint' => _freeHintsKey,
        'moves' => _extraMovesKey,
        'shield' => _comboShieldsKey,
        _ => throw StateError('Unsupported booster: $boosterId'),
      };
      final currentInventory = switch (boosterId) {
        'hint' => freeHints,
        'moves' => extraMovesBoosters,
        'shield' => comboShields,
        _ => throw StateError('Unsupported booster: $boosterId'),
      };
      final finalInventory = currentInventory + amount;

      await _commitShopPurchase('booster:$boosterId', <String, Object?>{
        inventoryKey: finalInventory,
        _coinsKey: finalCoins,
      });

      coins = finalCoins;
      switch (boosterId) {
        case 'hint':
          freeHints = finalInventory;
        case 'moves':
          extraMovesBoosters = finalInventory;
        case 'shield':
          comboShields = finalInventory;
      }
      notifyListeners();
      return true;
    } finally {
      _purchaseBusy = false;
    }
  }

  Future<void> _commitShopPurchase(
    String reason,
    Map<String, Object?> values,
  ) async {
    final validated = _validateShopPurchaseValues(values);
    final journal = <String, Object?>{
      'version': 1,
      'reason': reason,
      'values': validated,
    };
    await _prefs.setString(_pendingShopPurchaseKey, jsonEncode(journal));
    await _applyShopPurchaseValues(validated);
    await _prefs.remove(_pendingShopPurchaseKey);
  }

  Future<void> _recoverPendingShopPurchase() async {
    final payload = await _prefs.getString(_pendingShopPurchaseKey);
    if (payload == null) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        throw const FormatException('Unsupported shop purchase journal.');
      }
      final rawValues = decoded['values'];
      if (rawValues is! Map<String, dynamic>) {
        throw const FormatException('Shop purchase journal has no values.');
      }
      final values = _validateShopPurchaseValues(rawValues);
      await _applyShopPurchaseValues(values);
      await _prefs.remove(_pendingShopPurchaseKey);
    } on FormatException {
      await _prefs.remove(_pendingShopPurchaseKey);
    }
  }

  Map<String, Object?> _validateShopPurchaseValues(Map values) {
    final validated = <String, Object?>{};
    for (final entry in values.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) {
        throw const FormatException('Shop purchase key must be a string.');
      }
      switch (key) {
        case _coinsKey:
        case _freeHintsKey:
        case _extraMovesKey:
        case _comboShieldsKey:
          if (value is! int || value < 0) {
            throw FormatException('Invalid non-negative integer for $key.');
          }
          validated[key] = value;
        case _selectedThemeKey:
          if (value is! String || value.isEmpty) {
            throw const FormatException('Invalid selected theme.');
          }
          validated[key] = value;
        case _unlockedThemesKey:
          if (value is! List || value.any((item) => item is! String)) {
            throw const FormatException('Invalid unlocked themes.');
          }
          final themes = value.cast<String>().toSet()..add('classic');
          validated[key] = themes.toList();
        default:
          throw FormatException('Unsupported shop purchase key: $key');
      }
    }
    if (!validated.containsKey(_coinsKey)) {
      throw const FormatException('Shop purchase journal has no wallet value.');
    }
    return validated;
  }

  Future<void> _applyShopPurchaseValues(Map<String, Object?> values) async {
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is int) {
        await _prefs.setInt(entry.key, value);
      } else if (value is String) {
        await _prefs.setString(entry.key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(entry.key, value);
      } else {
        throw FormatException('Unsupported shop purchase value: ${entry.key}');
      }
    }
  }

  Future<T> _serializeReward<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _rewardQueue = _rewardQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _ensureRewardLedgerLoaded() async {
    if (_rewardLedgerLoaded) return;
    _rewardLedgerLoaded = true;

    final raw = await _prefs.getStringList(_rewardTransactionLedgerKey);
    if (raw == null) return;

    final sanitized = <String>[];
    final seen = <String>{};
    for (final candidate in raw) {
      final normalized = candidate.trim();
      if (!_isValidJournalToken(normalized) || !seen.add(normalized)) continue;
      sanitized.add(normalized);
    }
    final bounded = sanitized.length <= _rewardTransactionLedgerLimit
        ? sanitized
        : sanitized.sublist(sanitized.length - _rewardTransactionLedgerLimit);
    _completedRewardTransactions
      ..clear()
      ..addAll(bounded);

    if (!listEquals(raw, bounded)) {
      await _prefs.setStringList(_rewardTransactionLedgerKey, bounded);
    }
  }

  String _rewardTransactionKey({
    required String reason,
    String? idempotencyKey,
  }) {
    final normalizedReason = reason.trim();
    if (!_isValidJournalToken(normalizedReason)) {
      throw ArgumentError.value(reason, 'reason');
    }
    final supplied = idempotencyKey?.trim();
    if (supplied != null && supplied.isNotEmpty) {
      if (!_isValidJournalToken(supplied)) {
        throw ArgumentError.value(idempotencyKey, 'idempotencyKey');
      }
      return '$normalizedReason:$supplied';
    }

    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '$normalizedReason:auto-$micros-${_rewardSequence++}';
  }

  bool _isValidJournalToken(String value) =>
      value.isNotEmpty &&
      value.length <= 200 &&
      !value.contains('\n') &&
      !value.contains('\r');

  Future<bool> _commitRewardTransaction({
    required String reason,
    required String idempotencyKey,
    required Map<String, Object?> values,
  }) async {
    await _ensureRewardLedgerLoaded();
    if (_completedRewardTransactions.contains(idempotencyKey)) return false;
    if (!_isValidJournalToken(reason) ||
        !_isValidJournalToken(idempotencyKey)) {
      throw const FormatException('Invalid reward transaction metadata.');
    }

    final validated = _validateRewardTransactionValues(values);
    final journal = <String, Object?>{
      'version': 1,
      'reason': reason,
      'idempotencyKey': idempotencyKey,
      'values': validated,
    };
    await _prefs.setString(_pendingRewardTransactionKey, jsonEncode(journal));
    await _applyRewardTransactionValues(validated);
    await _recordCompletedRewardTransaction(idempotencyKey);
    await _prefs.remove(_pendingRewardTransactionKey);
    return true;
  }

  Future<void> _recoverPendingRewardTransaction() async {
    await _ensureRewardLedgerLoaded();
    final payload = await _prefs.getString(_pendingRewardTransactionKey);
    if (payload == null) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        throw const FormatException('Unsupported reward transaction journal.');
      }
      final reason = decoded['reason'];
      final idempotencyKey = decoded['idempotencyKey'];
      final rawValues = decoded['values'];
      if (reason is! String || !_isValidJournalToken(reason)) {
        throw const FormatException('Reward journal has invalid reason.');
      }
      if (idempotencyKey is! String || !_isValidJournalToken(idempotencyKey)) {
        throw const FormatException(
          'Reward journal has invalid idempotency key.',
        );
      }
      if (rawValues is! Map<String, dynamic>) {
        throw const FormatException('Reward journal has no values.');
      }

      if (_completedRewardTransactions.contains(idempotencyKey)) {
        await _prefs.remove(_pendingRewardTransactionKey);
        return;
      }

      final values = _validateRewardTransactionValues(rawValues);
      await _applyRewardTransactionValues(values);
      _applyRewardTransactionValuesToMemory(values);
      await _recordCompletedRewardTransaction(idempotencyKey);
      await _prefs.remove(_pendingRewardTransactionKey);
    } on FormatException {
      await _prefs.remove(_pendingRewardTransactionKey);
    }
  }

  Map<String, Object?> _validateRewardTransactionValues(Map values) {
    final validated = <String, Object?>{};
    for (final entry in values.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) {
        throw const FormatException('Reward transaction key must be a string.');
      }

      if (key == _levelKey) {
        if (value is! int || value < 1 || value > totalLevels) {
          throw const FormatException('Invalid unlocked level value.');
        }
        validated[key] = value;
        continue;
      }

      if (key.startsWith(_starsPrefix)) {
        final level = int.tryParse(key.substring(_starsPrefix.length));
        if (level == null ||
            level < 1 ||
            level > totalLevels ||
            value is! int ||
            value < 0 ||
            value > maxStarsPerLevel) {
          throw FormatException('Invalid level stars value for $key.');
        }
        validated[key] = value;
        continue;
      }

      if (_rewardNonNegativeIntKeys.contains(key)) {
        if (value is! int || value < 0) {
          throw FormatException('Invalid non-negative integer for $key.');
        }
        validated[key] = value;
        continue;
      }

      if (key == _heartsKey) {
        if (value is! int || value < 0 || value > maxHearts) {
          throw const FormatException('Invalid heart grant value.');
        }
        validated[key] = value;
        continue;
      }

      if (key == _heartTimestampKey) {
        if (value != null) {
          throw const FormatException(
            'Reward transactions may only clear the heart refill timestamp.',
          );
        }
        validated[key] = null;
        continue;
      }

      if (key == _missionClaimedKey) {
        if (value is! bool) {
          throw const FormatException('Invalid mission claim value.');
        }
        validated[key] = value;
        continue;
      }

      if (key == _dailyRewardKey) {
        if (value is! String || value.isEmpty || value.length > 32) {
          throw const FormatException('Invalid daily reward date.');
        }
        validated[key] = value;
        continue;
      }

      throw FormatException('Unsupported reward transaction key: $key');
    }

    if (!validated.containsKey(_coinsKey) &&
        !validated.containsKey(_heartsKey)) {
      throw const FormatException(
        'Reward transaction has no supported grant value.',
      );
    }
    return validated;
  }

  Future<void> _applyRewardTransactionValues(
    Map<String, Object?> values,
  ) async {
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is int) {
        await _prefs.setInt(entry.key, value);
      } else if (value is bool) {
        await _prefs.setBool(entry.key, value);
      } else if (value is String) {
        await _prefs.setString(entry.key, value);
      } else if (value == null && entry.key == _heartTimestampKey) {
        await _prefs.remove(entry.key);
      } else {
        throw FormatException('Unsupported reward value: ${entry.key}');
      }
    }
  }

  void _applyRewardTransactionValuesToMemory(Map<String, Object?> values) {
    for (final entry in values.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key.startsWith(_starsPrefix) && value is int) {
        final level = int.tryParse(key.substring(_starsPrefix.length));
        if (level != null) {
          if (value > 0) {
            _levelStars[level] = value;
          } else {
            _levelStars.remove(level);
          }
        }
        continue;
      }

      switch (key) {
        case _levelKey:
          highestUnlockedLevel = value as int;
        case _coinsKey:
          coins = value as int;
        case _heartsKey:
          hearts = value as int;
        case _heartTimestampKey:
          _heartRefillTimestamp = null;
        case _gamesKey:
          gamesPlayed = value as int;
        case _winsKey:
          wins = value as int;
        case _lossesKey:
          losses = value as int;
        case _coinsEarnedKey:
          lifetimeCoinsEarned = value as int;
        case _perfectWinsKey:
          perfectWins = value as int;
        case _bestComboKey:
          bestCombo = value as int;
        case _winStreakKey:
          currentWinStreak = value as int;
        case _bestWinStreakKey:
          bestWinStreak = value as int;
        case _xpKey:
          playerXp = value as int;
        case _missionWinsKey:
          missionWins = value as int;
        case _missionStarsKey:
          missionStars = value as int;
        case _missionCoinsKey:
          missionCoins = value as int;
        case _missionClaimedKey:
          missionClaimed = value as bool;
        case _freeHintsKey:
          freeHints = value as int;
        case _extraMovesKey:
          extraMovesBoosters = value as int;
        case _comboShieldsKey:
          comboShields = value as int;
        case _dailyRewardKey:
          _lastDailyRewardDate = value as String;
      }
    }
  }

  Future<void> _recordCompletedRewardTransaction(String idempotencyKey) async {
    await _ensureRewardLedgerLoaded();
    if (!_completedRewardTransactions.add(idempotencyKey)) return;
    while (_completedRewardTransactions.length >
        _rewardTransactionLedgerLimit) {
      _completedRewardTransactions.remove(_completedRewardTransactions.first);
    }
    await _prefs.setStringList(
      _rewardTransactionLedgerKey,
      _completedRewardTransactions.toList(),
    );
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
    await _prefs.setString(
      _heartTimestampKey,
      _heartRefillTimestamp!.toIso8601String(),
    );
    notifyListeners();
    return true;
  }

  Future<bool> loseHeart() => spendHeart();

  Future<void> addHearts(int amount, {String? transactionId}) =>
      _serializeReward<void>(() async {
        await _ensureRewardLedgerLoaded();
        await _recoverPendingRewardTransaction();

        final transactionKey = _rewardTransactionKey(
          reason: 'heart_grant',
          idempotencyKey: transactionId,
        );
        if (_completedRewardTransactions.contains(transactionKey)) return;

        final nextHearts = (hearts + amount).clamp(0, maxHearts);
        final values = <String, Object?>{
          _heartsKey: nextHearts,
          if (nextHearts >= maxHearts) _heartTimestampKey: null,
        };
        final committed = await _commitRewardTransaction(
          reason: 'heart_grant',
          idempotencyKey: transactionKey,
          values: values,
        );
        if (!committed) return;

        hearts = nextHearts;
        if (hearts >= maxHearts) _heartRefillTimestamp = null;
        notifyListeners();
      });

  Future<int?> claimDailyReward() => _serializeReward<int?>(() async {
    await _ensureRewardLedgerLoaded();
    await _recoverPendingRewardTransaction();

    final transactionKey = _rewardTransactionKey(
      reason: 'daily_reward',
      idempotencyKey: _today,
    );
    if (_completedRewardTransactions.contains(transactionKey) ||
        !canClaimDailyReward) {
      return null;
    }

    const reward = 50;
    final nextCoins = coins + reward;
    final nextLifetimeCoinsEarned = lifetimeCoinsEarned + reward;
    final committed = await _commitRewardTransaction(
      reason: 'daily_reward_claim',
      idempotencyKey: transactionKey,
      values: <String, Object?>{
        _dailyRewardKey: _today,
        _coinsKey: nextCoins,
        _coinsEarnedKey: nextLifetimeCoinsEarned,
      },
    );
    if (!committed) return null;

    _lastDailyRewardDate = _today;
    coins = nextCoins;
    lifetimeCoinsEarned = nextLifetimeCoinsEarned;
    notifyListeners();
    return reward;
  });
}
