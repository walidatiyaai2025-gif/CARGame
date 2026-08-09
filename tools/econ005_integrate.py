from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Missing {label} anchor")
    return text.replace(old, new, 1)


# ProgressStore: make the economy domain authoritative while preserving APIs.
path = Path('lib/core/storage/progress_store.dart')
text = path.read_text()
text = replace_once(
    text,
    "import 'package:flutter/foundation.dart';\n\nimport 'recovering_preferences.dart';",
    "import 'package:flutter/foundation.dart';\n\nimport '../economy/economy_config.dart';\nimport 'recovering_preferences.dart';",
    'progress import',
)
text = replace_once(
    text,
    "  static const int maxHearts = 5;\n  static const Duration heartRefillInterval = Duration(minutes: 30);",
    "  static int get maxHearts => EconomyConfig.current.maxHearts;\n  static Duration get heartRefillInterval =>\n      EconomyConfig.current.heartRefillInterval;",
    'compatibility caps',
)
text = replace_once(
    text,
    "  static const _rewardTransactionLedgerKey = 'reward_transaction_ledger_v1';\n  static const int _rewardTransactionLedgerLimit = 128;",
    "  static const _rewardTransactionLedgerKey = 'reward_transaction_ledger_v1';\n  static const _economyVersionKey = 'economy_config_version';\n  static const int _rewardTransactionLedgerLimit = 128;",
    'economy version key',
)
old_fields = """  final RecoveringPreferences _prefs = RecoveringPreferences();
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
"""
new_fields = """  ProgressStore({EconomyConfig? economy})
    : economy = economy ?? EconomyConfig.current {
    coins = this.economy.startingCoins;
    hearts = this.economy.maxHearts;
    freeHints = this.economy.starterFreeHints;
    extraMovesBoosters = this.economy.starterExtraMovesBoosters;
    comboShields = this.economy.starterComboShields;
  }

  final EconomyConfig economy;
  final RecoveringPreferences _prefs = RecoveringPreferences();
  final Map<int, int> _levelStars = <int, int>{};
  final Set<String> _completedRewardTransactions = <String>{};

  int highestUnlockedLevel = 1;
  late int coins;
  late int hearts;
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
  late int freeHints;
  late int extraMovesBoosters;
  late int comboShields;
"""
text = replace_once(text, old_fields, new_fields, 'progress fields')
text = replace_once(
    text,
    """  bool get dailyMissionComplete =>
      missionWins >= 3 && missionStars >= 6 && missionCoins >= 150;
  int get playerLevel => 1 + (playerXp ~/ 500);
  int get xpIntoCurrentLevel => playerXp % 500;
  double get playerLevelProgress => xpIntoCurrentLevel / 500;
""",
    """  bool get dailyMissionComplete =>
      missionWins >= economy.dailyMissionRequiredWins &&
      missionStars >= economy.dailyMissionRequiredStars &&
      missionCoins >= economy.dailyMissionRequiredCoins;
  int get playerLevel => 1 + (playerXp ~/ economy.playerLevelXpStep);
  int get xpIntoCurrentLevel => playerXp % economy.playerLevelXpStep;
  double get playerLevelProgress =>
      xpIntoCurrentLevel / economy.playerLevelXpStep;
""",
    'mission and XP getters',
)
text = text.replace('hearts >= maxHearts', 'hearts >= economy.maxHearts')
text = text.replace('.clamp(0, maxHearts)', '.clamp(0, economy.maxHearts)')
text = replace_once(
    text,
    '    final remaining = heartRefillInterval - elapsed;',
    '    final remaining = economy.heartRefillInterval - elapsed;',
    'heart remaining',
)
text = replace_once(
    text,
    '    final recovered = elapsed.inMinutes ~/ heartRefillInterval.inMinutes;',
    '    final recovered = elapsed.inMinutes ~/ economy.heartRefillInterval.inMinutes;',
    'heart recovery cadence',
)
text = replace_once(
    text,
    '        Duration(minutes: recovered * heartRefillInterval.inMinutes),',
    '        Duration(minutes: recovered * economy.heartRefillInterval.inMinutes),',
    'heart timestamp cadence',
)
text = replace_once(
    text,
    """    await _recoverPendingRewardTransaction();
    await _recoverPendingShopPurchase();

    highestUnlockedLevel =""",
    """    await _recoverPendingRewardTransaction();
    await _recoverPendingShopPurchase();
    await _reconcileEconomyVersion();

    highestUnlockedLevel =""",
    'load economy migration',
)
text = replace_once(
    text,
    '    coins = savedCoins == null ? 100 : (savedCoins < 0 ? 0 : savedCoins);',
    '    coins = savedCoins == null\n        ? economy.startingCoins\n        : (savedCoins < 0 ? 0 : savedCoins);',
    'starting coins',
)
text = replace_once(
    text,
    "    selectedTheme = await _prefs.getString(_selectedThemeKey) ?? 'classic';",
    "    selectedTheme =\n        await _prefs.getString(_selectedThemeKey) ?? EconomyConfig.classicThemeId;",
    'classic selected theme',
)
text = replace_once(
    text,
    """    unlockedThemes = {
      ...?await _prefs.getStringList(_unlockedThemesKey),
      'classic',
    };
    if (!unlockedThemes.contains(selectedTheme)) selectedTheme = 'classic';
""",
    """    unlockedThemes = {
      ...?await _prefs.getStringList(_unlockedThemesKey),
      EconomyConfig.classicThemeId,
    };
    if (!unlockedThemes.contains(selectedTheme)) {
      selectedTheme = EconomyConfig.classicThemeId;
    }
""",
    'classic theme set',
)
text = replace_once(
    text,
    """    freeHints = savedHints == null ? 2 : (savedHints < 0 ? 0 : savedHints);
    extraMovesBoosters = savedMoves == null
        ? 1
        : (savedMoves < 0 ? 0 : savedMoves);
    comboShields = savedShields == null
        ? 1
        : (savedShields < 0 ? 0 : savedShields);
""",
    """    freeHints = savedHints == null
        ? economy.starterFreeHints
        : (savedHints < 0 ? 0 : savedHints);
    extraMovesBoosters = savedMoves == null
        ? economy.starterExtraMovesBoosters
        : (savedMoves < 0 ? 0 : savedMoves);
    comboShields = savedShields == null
        ? economy.starterComboShields
        : (savedShields < 0 ? 0 : savedShields);
""",
    'starter boosters',
)
reconcile_method = """  Future<void> _reconcileEconomyVersion() async {
    final savedVersion = await _prefs.getInt(_economyVersionKey);
    if (savedVersion != null && savedVersion > economy.schemaVersion) {
      throw StateError(
        'Save economy version $savedVersion is newer than supported '
        '${economy.schemaVersion}.',
      );
    }
    if (savedVersion != economy.schemaVersion) {
      // V1 is metadata-only: never rewrite existing wallet or entitlements.
      await _prefs.setInt(_economyVersionKey, economy.schemaVersion);
    }
  }

"""
text = replace_once(
    text,
    '  Future<void> _resetDailyMission() async {',
    reconcile_method + '  Future<void> _resetDailyMission() async {',
    'economy migration method',
)
old_bonus = """    var nextFreeHints = freeHints;
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
"""
new_bonus = """    var nextFreeHints = freeHints;
    var nextExtraMovesBoosters = extraMovesBoosters;
    var nextComboShields = comboShields;
    final configuredBonus = firstClear
        ? economy.firstClearBonusForLevel(level)
        : EconomyCompletionBonus.none;
    final completionBonus = configuredBonus.coins;
    final completionBonusXp = configuredBonus.xp;
    final completionWasWorldReward = configuredBonus.isWorld;

    nextCoins += completionBonus;
    nextPlayerXp += completionBonusXp;
    nextLifetimeCoinsEarned += completionBonus;
    nextMissionCoins += completionBonus;
    nextFreeHints += configuredBonus.freeHints;
    nextExtraMovesBoosters += configuredBonus.extraMovesBoosters;
    nextComboShields += configuredBonus.comboShields;
"""
text = replace_once(text, old_bonus, new_bonus, 'completion bonus')
text = replace_once(
    text,
    """      reason: firstClear
          ? (completionWasWorldReward
                ? 'level_world_first_clear'
                : completionBonus > 0
                ? 'level_milestone_first_clear'
                : 'level_first_clear')
          : 'level_replay',
""",
    """      reason: firstClear
          ? (configuredBonus.kind == EconomyCompletionBonusKind.world
                ? 'level_world_first_clear'
                : configuredBonus.kind == EconomyCompletionBonusKind.milestone
                ? 'level_milestone_first_clear'
                : 'level_first_clear')
          : 'level_replay',
""",
    'reward reason',
)
text = replace_once(text, '    const reward = 200;', '    final reward = economy.dailyMissionRewardCoins;', 'daily mission reward')
old_purchase_theme = """  Future<bool> purchaseTheme(String themeId, int price) async {
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
"""
new_purchase_theme = """  Future<bool> purchaseHearts(String offerId) async {
    final offer = economy.heartOffer(offerId);
    if (_purchaseBusy) return false;
    _purchaseBusy = true;
    try {
      if (hearts >= economy.maxHearts || coins < offer.priceCoins) return false;

      final finalCoins = coins - offer.priceCoins;
      final finalHearts = (hearts + offer.heartAmount).clamp(
        0,
        economy.maxHearts,
      );
      await _commitShopPurchase('heart:${offer.id}', <String, Object?>{
        _coinsKey: finalCoins,
        _heartsKey: finalHearts,
        if (finalHearts >= economy.maxHearts) _heartTimestampKey: null,
      });

      coins = finalCoins;
      hearts = finalHearts;
      if (hearts >= economy.maxHearts) _heartRefillTimestamp = null;
      notifyListeners();
      return true;
    } finally {
      _purchaseBusy = false;
    }
  }

  Future<bool> purchaseTheme(String themeId, [int? _legacyPrice]) async {
    final offer = economy.themeOffer(themeId);
    if (_purchaseBusy) return false;
    _purchaseBusy = true;
    try {
      if (unlockedThemes.contains(themeId)) {
        selectedTheme = themeId;
        await _prefs.setString(_selectedThemeKey, selectedTheme);
        notifyListeners();
        return true;
      }
      if (offer.priceCoins <= 0 || coins < offer.priceCoins) return false;

      final finalCoins = coins - offer.priceCoins;
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

  Future<bool> purchaseBooster(
    String boosterId, [
    int? _legacyAmount,
    int? _legacyPrice,
  ]) async {
    final offer = economy.boosterOffer(boosterId);
    if (coins < offer.priceCoins || _purchaseBusy) return false;

    _purchaseBusy = true;
    try {
      final finalCoins = coins - offer.priceCoins;
      final inventoryKey = switch (boosterId) {
        EconomyConfig.hintBoosterId => _freeHintsKey,
        EconomyConfig.movesBoosterId => _extraMovesKey,
        EconomyConfig.shieldBoosterId => _comboShieldsKey,
        _ => throw StateError('Unsupported booster: $boosterId'),
      };
      final currentInventory = switch (boosterId) {
        EconomyConfig.hintBoosterId => freeHints,
        EconomyConfig.movesBoosterId => extraMovesBoosters,
        EconomyConfig.shieldBoosterId => comboShields,
        _ => throw StateError('Unsupported booster: $boosterId'),
      };
      final finalInventory = currentInventory + offer.quantity;

      await _commitShopPurchase('booster:$boosterId', <String, Object?>{
        inventoryKey: finalInventory,
        _coinsKey: finalCoins,
      });

      coins = finalCoins;
      switch (boosterId) {
        case EconomyConfig.hintBoosterId:
          freeHints = finalInventory;
        case EconomyConfig.movesBoosterId:
          extraMovesBoosters = finalInventory;
        case EconomyConfig.shieldBoosterId:
          comboShields = finalInventory;
      }
      notifyListeners();
      return true;
    } finally {
      _purchaseBusy = false;
    }
  }
"""
text = replace_once(text, old_purchase_theme, new_purchase_theme, 'authoritative purchases')
text = replace_once(
    text,
    """      switch (key) {
        case _coinsKey:
        case _freeHintsKey:
""",
    """      switch (key) {
        case _heartsKey:
          if (value is! int || value < 0 || value > economy.maxHearts) {
            throw const FormatException('Invalid heart purchase value.');
          }
          validated[key] = value;
        case _heartTimestampKey:
          if (value != null) {
            throw const FormatException(
              'Shop purchase may only clear the heart refill timestamp.',
            );
          }
          validated[key] = null;
        case _coinsKey:
        case _freeHintsKey:
""",
    'shop heart validation',
)
text = replace_once(
    text,
    """      } else if (value is List<String>) {
        await _prefs.setStringList(entry.key, value);
      } else {
""",
    """      } else if (value is List<String>) {
        await _prefs.setStringList(entry.key, value);
      } else if (value == null && entry.key == _heartTimestampKey) {
        await _prefs.remove(entry.key);
      } else {
""",
    'shop nullable timestamp apply',
)
text = text.replace('value > maxHearts', 'value > economy.maxHearts')
text = replace_once(text, '    const reward = 50;', '    final reward = economy.dailyRewardCoins;', 'daily reward')
path.write_text(text)

# Gameplay: use the same config for source rewards and sink quantities.
path = Path('lib/features/game/game_screen.dart')
text = path.read_text()
text = replace_once(
    text,
    """  int get _xpEarned =>
      50 + widget.level.difficulty * 10 + _earnedStars * 15 + _bestCombo * 3;
""",
    """  int get _xpEarned => widget.store.economy.levelXp(
    difficulty: widget.level.difficulty,
    stars: _earnedStars,
    bestCombo: _bestCombo,
  );
""",
    'game XP formula',
)
text = replace_once(
    text,
    """    _moves =
        widget.level.moves +
        (applyLoadout && widget.loadout.extraMoves ? 5 : 0);
""",
    """    _moves =
        widget.level.moves +
        (applyLoadout && widget.loadout.extraMoves
            ? widget.store.economy.extraMovesPerBoosterUse
            : 0);
""",
    'loadout extra moves',
)
text = replace_once(
    text,
    '    final reward = 25 + widget.level.number * 5 + stars * 10 + _bestCombo * 2;',
    """    final reward = widget.store.economy.levelRewardCoins(
      level: widget.level.number,
      stars: stars,
      bestCombo: _bestCombo,
    );""",
    'level coin formula',
)
text = replace_once(
    text,
    '      used = await widget.store.spendCoins(10);',
    '      used = await widget.store.spendCoins(\n        widget.store.economy.hintFallbackCoinCost,\n      );',
    'hint fallback cost',
)
text = replace_once(
    text,
    '    setState(() => _moves += 5);\n    _message(\'+5 moves added.\');',
    """    final addedMoves = widget.store.economy.extraMovesPerBoosterUse;
    setState(() => _moves += addedMoves);
    _message('+$addedMoves moves added.');""",
    'booster move quantity',
)
text = text.replace('_moves += 5;', '_moves += widget.store.economy.rewardedContinueMoves;')
text = text.replace(
    "? 'شاهد إعلانًا وخذ خمس حركات'\n                            : 'Watch ad for five moves'",
    "? 'شاهد إعلانًا وخذ ${widget.store.economy.rewardedContinueMoves} حركات'\n                            : 'Watch ad for ${widget.store.economy.rewardedContinueMoves} moves'",
)
text = text.replace(
    "? 'شاهد إعلانًا وخذ 5 حركات'\n                                    : 'Watch ad for 5 moves'",
    "? 'شاهد إعلانًا وخذ ${widget.store.economy.rewardedContinueMoves} حركات'\n                                    : 'Watch ad for ${widget.store.economy.rewardedContinueMoves} moves'",
)
path.write_text(text)

# Shop: UI presents authoritative offers; store performs authoritative debit/grant.
path = Path('lib/features/shop/shop_screen.dart')
text = path.read_text()
old_methods = """  Future<void> _buyHearts(BuildContext context, int amount, int price) async {
    final messenger = ScaffoldMessenger.of(context);
    if (store.hearts >= ProgressStore.maxHearts) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Your hearts are already full.')),
      );
      return;
    }
    final paid = await store.spendCoins(price);
    if (!paid) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Not enough coins.')),
      );
      return;
    }
    await store.addHearts(amount);
    messenger.showSnackBar(
      const SnackBar(content: Text('Hearts added successfully.')),
    );
  }

  Future<void> _buyBooster(
    BuildContext context,
    String id,
    int amount,
    int price,
    String name,
  ) async {
    final paid = await store.purchaseBooster(id, amount, price);
    if (!context.mounted) return;
    _message(context, paid ? '$name added.' : 'Not enough coins.');
  }
"""
new_methods = """  Future<void> _buyHearts(BuildContext context, String offerId) async {
    final paid = await store.purchaseHearts(offerId);
    if (!context.mounted) return;
    _message(
      context,
      paid ? 'Hearts added successfully.' : 'Not enough coins or hearts are full.',
    );
  }

  Future<void> _buyBooster(
    BuildContext context,
    String id,
    String name,
  ) async {
    final paid = await store.purchaseBooster(id);
    if (!context.mounted) return;
    _message(context, paid ? '$name added.' : 'Not enough coins.');
  }
"""
text = replace_once(text, old_methods, new_methods, 'shop purchase methods')
text = replace_once(
    text,
    '    final success = await store.purchaseTheme(offer.id, offer.price);',
    '    final success = await store.purchaseTheme(offer.id);',
    'theme purchase call',
)
text = replace_once(
    text,
    '    final skin = gameSkinById(store.selectedTheme);\n    return Scaffold(',
    """    final skin = gameSkinById(store.selectedTheme);
    final economy = store.economy;
    final singleHeart = economy.heartOffer('heart_single');
    final fullHearts = economy.heartOffer('heart_full');
    final hintOffer = economy.boosterOffer('hint');
    final movesOffer = economy.boosterOffer('moves');
    final shieldOffer = economy.boosterOffer('shield');
    return Scaffold(""",
    'shop config locals',
)
text = replace_once(
    text,
    """                      title: '+1 Heart',
                      subtitle: '120 coins',
                      onTap: () => _buyHearts(context, 1, 120),
""",
    """                      title: '+${singleHeart.heartAmount} Heart',
                      subtitle: '${singleHeart.priceCoins} coins',
                      onTap: () => _buyHearts(context, singleHeart.id),
""",
    'single heart UI',
)
text = replace_once(
    text,
    """                      title: 'Full Hearts',
                      subtitle: '450 coins',
                      onTap: () =>
                          _buyHearts(context, ProgressStore.maxHearts, 450),
""",
    """                      title: 'Full Hearts',
                      subtitle: '${fullHearts.priceCoins} coins',
                      onTap: () => _buyHearts(context, fullHearts.id),
""",
    'full heart UI',
)
text = replace_once(
    text,
    """                price: 180,
                onTap: () =>
                    _buyBooster(context, 'hint', 3, 180, 'Smart hints'),
""",
    """                price: hintOffer.priceCoins,
                onTap: () => _buyBooster(context, hintOffer.id, 'Smart hints'),
""",
    'hint shop UI',
)
text = replace_once(
    text,
    """                price: 260,
                onTap: () => _buyBooster(
                  context,
                  'moves',
                  1,
                  260,
                  'Extra moves booster',
                ),
""",
    """                price: movesOffer.priceCoins,
                onTap: () => _buyBooster(
                  context,
                  movesOffer.id,
                  'Extra moves booster',
                ),
""",
    'moves shop UI',
)
text = replace_once(
    text,
    """                price: 220,
                onTap: () =>
                    _buyBooster(context, 'shield', 1, 220, 'Combo shield'),
""",
    """                price: shieldOffer.priceCoins,
                onTap: () =>
                    _buyBooster(context, shieldOffer.id, 'Combo shield'),
""",
    'shield shop UI',
)
text = replace_once(
    text,
    """                    offer: offer,
                    unlocked: store.isThemeUnlocked(offer.id),
""",
    """                    offer: offer,
                    price: economy.themeOffer(offer.id).priceCoins,
                    unlocked: store.isThemeUnlocked(offer.id),
""",
    'theme price binding',
)
text = text.replace("'${store.hearts}/${ProgressStore.maxHearts}'", "'${store.hearts}/${store.economy.maxHearts}'")
text = replace_once(
    text,
    """    required this.offer,
    required this.unlocked,
""",
    """    required this.offer,
    required this.price,
    required this.unlocked,
""",
    'theme tile constructor price',
)
text = replace_once(
    text,
    """  final _ThemeOffer offer;
  final bool unlocked;
""",
    """  final _ThemeOffer offer;
  final int price;
  final bool unlocked;
""",
    'theme tile field price',
)
text = text.replace("'Buy ${offer.name} for ${offer.price} coins'", "'Buy ${offer.name} for $price coins'")
text = text.replace("'${offer.price}'", "'$price'")
text = replace_once(
    text,
    """    required this.end,
    required this.price,
  });
""",
    """    required this.end,
  });
""",
    'theme offer constructor',
)
text = replace_once(
    text,
    """  final Color start;
  final Color end;
  final int price;
}
""",
    """  final Color start;
  final Color end;
}
""",
    'theme offer price field',
)
for line in ['    price: 0,\n', '    price: 700,\n', '    price: 1200,\n']:
    if line not in text:
        raise SystemExit(f'Missing theme price literal {line.strip()}')
    text = text.replace(line, '', 1)
path.write_text(text)

# Update existing storage tests to assert authoritative pricing and migration metadata.
path = Path('test/core/storage/progress_store_test.dart')
text = path.read_text()
text = replace_once(
    text,
    "import 'package:cargo_sort_game/core/storage/progress_store.dart';",
    "import 'package:cargo_sort_game/core/economy/economy_config.dart';\nimport 'package:cargo_sort_game/core/storage/progress_store.dart';",
    'progress test economy import',
)
old_booster_test = """  test('booster purchase validates input before charging wallet', () async {
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
"""
new_booster_test = """  test('booster purchase ignores spoofed caller price and quantity', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 500);
    final store = ProgressStore();
    await store.load();
    final initialHints = store.freeHints;

    expect(() => store.purchaseBooster('unknown', 1, 10), throwsArgumentError);
    expect(await store.purchaseBooster('hint', 999, 1), isTrue);
    expect(store.coins, 320);
    expect(store.freeHints, initialHints + 3);
  });
"""
text = replace_once(text, old_booster_test, new_booster_test, 'booster authority test')
legacy_anchor = """      expect(store.recoveryEvents, isEmpty);
    },
  );
"""
legacy_replacement = """      expect(store.recoveryEvents, isEmpty);
      expect(
        await prefs.getInt('economy_config_version'),
        EconomyConfig.current.schemaVersion,
      );

      final reloaded = ProgressStore();
      await reloaded.load();
      expect(reloaded.coins, 725);
      expect(reloaded.hearts, 3);
    },
  );
"""
text = replace_once(text, legacy_anchor, legacy_replacement, 'legacy economy version')
future_test = """

  test('newer saved economy version fails closed without rewriting wallet', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 725);
    await prefs.setInt('economy_config_version', 99);

    final store = ProgressStore();
    await expectLater(store.load(), throwsStateError);
    expect(await prefs.getInt('coins'), 725);
    expect(await prefs.getInt('economy_config_version'), 99);
  });
"""
idx = text.rfind('\n}')
if idx < 0:
    raise SystemExit('progress test closing brace missing')
text = text[:idx] + future_test + text[idx:]
path.write_text(text)

path = Path('test/core/storage/shop_purchase_recovery_test.dart')
text = path.read_text()
old_purchase = """  test('booster purchase persists wallet and inventory together', () async {
    final store = ProgressStore();
    await store.load();

    final initialCoins = store.coins;
    final initialHints = store.freeHints;

    expect(await store.purchaseBooster('hint', 2, 25), isTrue);
    expect(store.coins, initialCoins - 25);
    expect(store.freeHints, initialHints + 2);

    final reloaded = ProgressStore();
    await reloaded.load();
    expect(reloaded.coins, initialCoins - 25);
    expect(reloaded.freeHints, initialHints + 2);

    final prefs = SharedPreferencesAsync();
    expect(await prefs.containsKey(pendingPurchaseKey), isFalse);
  });
"""
new_purchase = """  test('booster purchase persists authoritative wallet and inventory', () async {
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
  });
"""
text = replace_once(text, old_purchase, new_purchase, 'shop booster recovery test')
extra_tests = """

  test('heart purchase is atomic and uses the authoritative offer price', () async {
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
  });

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
        'values': {
          'coins': 380,
          'hearts': 5,
          'heart_refill_timestamp': null,
        },
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
"""
idx = text.rfind('\n}')
if idx < 0:
    raise SystemExit('shop recovery test closing brace missing')
text = text[:idx] + extra_tests + text[idx:]
path.write_text(text)

# Tracking follows the team's source-of-truth discipline.
path = Path('docs/FEATURE_CATALOG.md')
text = path.read_text()
text = replace_once(
    text,
    '| ECON-005 | Versioned economy configuration and balance rules | P0 | PLANNED | ECON-001, REW-007 | Prices, rewards, sinks, sources, caps, and migrations are versioned and validated. |',
    '| ECON-005 | Versioned economy configuration and balance rules | P0 | IN PROGRESS | ECON-001, REW-007 | Issue #122 / `agent/econ-005-versioned-economy` centralize current shipped balance values in validated schema v1, make shop IDs authoritative for price/quantity, add non-destructive economy-version metadata, and preserve REW-007/SHOP-002 guarantees without rebalance. |',
    'catalog ECON-005 row',
)
text = replace_once(
    text,
    '## IN PROGRESS\n\n- None after `GAME-016` verification.',
    '## IN PROGRESS\n\n- `ECON-005` Versioned economy configuration and balance rules — issue #122 / `agent/econ-005-versioned-economy`.',
    'catalog active queue',
)
path.write_text(text)

path = Path('docs/STATUS.md')
text = path.read_text()
text = replace_once(
    text,
    '| Primary feature | `REW-007` VERIFIED — implementation PR #120 merged; reconciliation evidence is being finalized on `agent/rew-007-reconciliation`. |',
    '| Primary feature | `ECON-005` IN PROGRESS — issue #122 on `agent/econ-005-versioned-economy`. |',
    'status primary',
)
text = replace_once(
    text,
    '| Completed checkpoint | `GAME-016` input determinism — PR #111 merged as `093d9a9384aec2d18503284a8edc95ba1ce1ecfb` after Flutter CI #580 passed formatting, Analyze, all 215 Flutter tests, Debug APK build, and artifact upload. |',
    '| Completed checkpoint | `REW-007` reward transaction ledger/reconciliation — implementation PR #120 and reconciliation PR #121 are merged; CI #623/#624/#625 verified transaction/recovery behavior and Android build evidence. |',
    'status completed',
)
text = replace_once(
    text,
    '| Status | `REW-007` VERIFIED: level, daily reward, daily mission, and explicit heart grants use interruption-safe absolute-state journaling/idempotency; Flutter CI #623 and Debug APK artifact #9032765167 are green evidence. |',
    '| Status | `ECON-005` audit found duplicated balance authority across ProgressStore/GameScreen/ShopScreen; implementation is moving shipped v1 values behind one validated config and authoritative offer IDs with no rebalance. |',
    'status state',
)
text = replace_once(
    text,
    '| Next recommended feature | `ECON-005` versioned economy configuration and balance rules — its `REW-007` dependency is now VERIFIED and it continues the RC save/economy/reward integrity audit. |',
    '| Next recommended feature | Complete `ECON-005` parity/migration/transaction verification, then select the next unblocked RC P0 from the catalog. |',
    'status next',
)
path.write_text(text)
