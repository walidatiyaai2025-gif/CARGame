from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    return text.replace(old, new, 1)


progress_path = Path('lib/core/storage/progress_store.dart')
progress = progress_path.read_text()

progress = replace_once(
    progress,
    "import 'package:flutter/foundation.dart';\n\nimport 'recovering_preferences.dart';",
    "import 'package:flutter/foundation.dart';\n\nimport '../economy/economy_config.dart';\nimport 'recovering_preferences.dart';",
    'progress import',
)
progress = replace_once(
    progress,
    "  static const int totalLevels = 150;\n  static const int maxStarsPerLevel = 3;\n  static const int maxHearts = 5;\n  static const Duration heartRefillInterval = Duration(minutes: 30);",
    "  static const int totalLevels = 150;\n  static int get maxStarsPerLevel =>\n      EconomyConfig.current.player.maxStarsPerLevel;\n  static int get maxHearts => EconomyConfig.current.player.maxHearts;\n  static Duration get heartRefillInterval =>\n      EconomyConfig.current.player.heartRefillInterval;",
    'progress static economy values',
)
progress = replace_once(
    progress,
    "  static const _rewardTransactionLedgerKey = 'reward_transaction_ledger_v1';\n  static const int _rewardTransactionLedgerLimit = 128;",
    "  static const _rewardTransactionLedgerKey = 'reward_transaction_ledger_v1';\n  static const _economyConfigVersionKey = 'economy_config_version';\n  static const int _rewardTransactionLedgerLimit = 128;",
    'economy version key',
)
progress = replace_once(
    progress,
    "  int highestUnlockedLevel = 1;\n  int coins = 100;\n  int hearts = maxHearts;",
    "  int highestUnlockedLevel = 1;\n  int coins = EconomyConfig.current.player.startingCoins;\n  int hearts = EconomyConfig.current.player.startingHearts;",
    'wallet defaults',
)
progress = replace_once(
    progress,
    "  int missionCoins = 0;\n  int freeHints = 2;\n  int extraMovesBoosters = 1;\n  int comboShields = 1;",
    "  int missionCoins = 0;\n  int freeHints = EconomyConfig.current.player.startingFreeHints;\n  int extraMovesBoosters =\n      EconomyConfig.current.player.startingExtraMovesBoosters;\n  int comboShields = EconomyConfig.current.player.startingComboShields;",
    'booster defaults',
)
progress = replace_once(
    progress,
    "  int get maximumStars => totalLevels * maxStarsPerLevel;\n  int get worldsCompleted => completedLevels ~/ 25;\n  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;\n  bool get dailyMissionComplete =>\n      missionWins >= 3 && missionStars >= 6 && missionCoins >= 150;\n  int get playerLevel => 1 + (playerXp ~/ 500);\n  int get xpIntoCurrentLevel => playerXp % 500;\n  double get playerLevelProgress => xpIntoCurrentLevel / 500;",
    "  int get maximumStars => totalLevels * maxStarsPerLevel;\n  int get worldsCompleted =>\n      completedLevels ~/ EconomyConfig.current.rewards.worldInterval;\n  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;\n  bool get dailyMissionComplete {\n    final rules = EconomyConfig.current.player;\n    return missionWins >= rules.dailyMissionWinsRequired &&\n        missionStars >= rules.dailyMissionStarsRequired &&\n        missionCoins >= rules.dailyMissionCoinsRequired;\n  }\n\n  int get playerLevel =>\n      1 + (playerXp ~/ EconomyConfig.current.player.xpPerPlayerLevel);\n  int get xpIntoCurrentLevel =>\n      playerXp % EconomyConfig.current.player.xpPerPlayerLevel;\n  double get playerLevelProgress =>\n      xpIntoCurrentLevel / EconomyConfig.current.player.xpPerPlayerLevel;",
    'derived economy getters',
)
progress = replace_once(
    progress,
    "  Future<void> load() async {\n    await _ensureRewardLedgerLoaded();",
    "  Future<void> load() async {\n    await _ensureEconomyConfigVersion();\n    await _ensureRewardLedgerLoaded();",
    'load migration hook',
)
progress = replace_once(
    progress,
    "    final savedCoins = await _prefs.getInt(_coinsKey);\n    coins = savedCoins == null ? 100 : (savedCoins < 0 ? 0 : savedCoins);\n    hearts = (await _prefs.getInt(_heartsKey) ?? maxHearts).clamp(0, maxHearts);",
    "    final savedCoins = await _prefs.getInt(_coinsKey);\n    coins = savedCoins == null\n        ? EconomyConfig.current.player.startingCoins\n        : (savedCoins < 0 ? 0 : savedCoins);\n    hearts =\n        (await _prefs.getInt(_heartsKey) ??\n                EconomyConfig.current.player.startingHearts)\n            .clamp(0, maxHearts);",
    'load wallet defaults',
)
progress = replace_once(
    progress,
    "    freeHints = savedHints == null ? 2 : (savedHints < 0 ? 0 : savedHints);\n    extraMovesBoosters = savedMoves == null\n        ? 1\n        : (savedMoves < 0 ? 0 : savedMoves);\n    comboShields = savedShields == null\n        ? 1\n        : (savedShields < 0 ? 0 : savedShields);",
    "    freeHints = savedHints == null\n        ? EconomyConfig.current.player.startingFreeHints\n        : (savedHints < 0 ? 0 : savedHints);\n    extraMovesBoosters = savedMoves == null\n        ? EconomyConfig.current.player.startingExtraMovesBoosters\n        : (savedMoves < 0 ? 0 : savedMoves);\n    comboShields = savedShields == null\n        ? EconomyConfig.current.player.startingComboShields\n        : (savedShields < 0 ? 0 : savedShields);",
    'load booster defaults',
)

migration_marker = "  Future<void> completeLevel(\n"
migration_method = """  Future<void> _ensureEconomyConfigVersion() async {
    final currentVersion = EconomyConfig.current.schemaVersion;
    final savedVersion = await _prefs.getInt(_economyConfigVersionKey);
    if (savedVersion == null || savedVersion <= 0) {
      await _prefs.setInt(_economyConfigVersionKey, currentVersion);
      return;
    }
    if (savedVersion > currentVersion) {
      throw StateError(
        'Unsupported future economy config version: $savedVersion.',
      );
    }
    if (savedVersion < currentVersion) {
      throw StateError(
        'No economy migration registered from version $savedVersion '
        'to $currentVersion.',
      );
    }
  }

"""
if migration_method not in progress:
    if migration_marker not in progress:
        raise SystemExit('economy migration insertion marker missing')
    progress = progress.replace(migration_marker, migration_method + migration_marker, 1)

old_bonus = """    if (firstClear && level % 25 == 0) {
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
new_bonus = """    final economy = EconomyConfig.current;
    if (firstClear && economy.isWorldLevel(level)) {
      completionBonus = economy.worldCoinsForLevel(level);
      completionBonusXp = economy.worldXpForLevel(level);
      completionWasWorldReward = true;

      nextCoins += completionBonus;
      nextPlayerXp += completionBonusXp;
      nextLifetimeCoinsEarned += completionBonus;
      nextMissionCoins += completionBonus;
      nextFreeHints += economy.rewards.worldFreeHints;
      nextExtraMovesBoosters += economy.rewards.worldExtraMovesBoosters;
      nextComboShields += economy.rewards.worldComboShields;
    } else if (firstClear && economy.isMilestoneLevel(level)) {
      completionBonus = economy.milestoneCoinsForLevel(level);
      completionBonusXp = economy.milestoneXpForLevel(level);
      nextCoins += completionBonus;
      nextPlayerXp += completionBonusXp;
      nextLifetimeCoinsEarned += completionBonus;
      nextMissionCoins += completionBonus;
    }
"""
progress = replace_once(progress, old_bonus, new_bonus, 'reward bonus rules')
progress = replace_once(
    progress,
    "    final nextPerfectWins = perfectWins + (safeStars == 3 ? 1 : 0);",
    "    final nextPerfectWins =\n        perfectWins + (safeStars == maxStarsPerLevel ? 1 : 0);",
    'perfect win cap',
)
progress = replace_once(
    progress,
    "    const reward = 200;",
    "    final reward = EconomyConfig.current.rewards.dailyMissionRewardCoins;",
    'daily mission reward',
)
progress = replace_once(
    progress,
    "    const reward = 50;",
    "    final reward = EconomyConfig.current.rewards.dailyRewardCoins;",
    'daily reward',
)

shop_wrapper_marker = "  Future<bool> purchaseTheme(String themeId, int price) async {\n"
shop_wrappers = """  Future<bool> purchaseShopHeartOffer(String offerId) async {
    final offer = EconomyConfig.current.heartOfferById(offerId);
    if (hearts >= maxHearts) return false;
    final paid = await spendCoins(offer.price);
    if (!paid) return false;
    await addHearts(offer.amount);
    return true;
  }

  Future<bool> purchaseShopBooster(String boosterId) {
    final offer = EconomyConfig.current.boosterOfferFor(boosterId);
    return purchaseBooster(offer.targetId, offer.amount, offer.price);
  }

  Future<bool> purchaseShopTheme(String themeId) {
    final offer = EconomyConfig.current.themeOfferFor(themeId);
    return purchaseTheme(offer.targetId, offer.price);
  }

"""
if shop_wrappers not in progress:
    if shop_wrapper_marker not in progress:
        raise SystemExit('shop wrapper insertion marker missing')
    progress = progress.replace(shop_wrapper_marker, shop_wrappers + shop_wrapper_marker, 1)

progress_path.write_text(progress)


game_path = Path('lib/features/game/game_screen.dart')
game = game_path.read_text()
game = replace_once(
    game,
    "import '../../core/ads/ad_service.dart';\nimport '../../core/motion/game_action_feedback.dart';",
    "import '../../core/ads/ad_service.dart';\nimport '../../core/economy/economy_config.dart';\nimport '../../core/motion/game_action_feedback.dart';",
    'game economy import',
)
game = replace_once(
    game,
    "  int get _xpEarned =>\n      50 + widget.level.difficulty * 10 + _earnedStars * 15 + _bestCombo * 3;",
    "  int get _xpEarned => EconomyConfig.current.levelXpReward(\n    difficulty: widget.level.difficulty,\n    stars: _earnedStars,\n    combo: _bestCombo,\n  );",
    'game xp formula',
)
game = replace_once(
    game,
    "    _moves =\n        widget.level.moves +\n        (applyLoadout && widget.loadout.extraMoves ? 5 : 0);\n    _preparedHints = applyLoadout && widget.loadout.smartHint ? 1 : 0;",
    "    final economy = EconomyConfig.current;\n    _moves =\n        widget.level.moves +\n        (applyLoadout && widget.loadout.extraMoves\n            ? economy.gameplay.extraMovesPerBooster\n            : 0);\n    _preparedHints = applyLoadout && widget.loadout.smartHint\n        ? economy.gameplay.preparedHintUses\n        : 0;",
    'game loadout values',
)
game = replace_once(
    game,
    "    final reward = 25 + widget.level.number * 5 + stars * 10 + _bestCombo * 2;",
    "    final reward = EconomyConfig.current.levelCoinReward(\n      level: widget.level.number,\n      stars: stars,\n      combo: _bestCombo,\n    );",
    'game coin formula',
)
game = replace_once(
    game,
    "      used = await widget.store.spendCoins(10);",
    "      used = await widget.store.spendCoins(\n        EconomyConfig.current.gameplay.hintCoinCost,\n      );",
    'game hint sink',
)
game = replace_once(
    game,
    "    setState(() => _moves += 5);\n    _message('+5 moves added.');",
    "    final extraMoves = EconomyConfig.current.gameplay.extraMovesPerBooster;\n    setState(() => _moves += extraMoves);\n    _message('+$extraMoves moves added.');",
    'game extra moves',
)
game_path.write_text(game)


shop_path = Path('lib/features/shop/shop_screen.dart')
shop = shop_path.read_text()
shop = replace_once(
    shop,
    "import 'package:flutter/material.dart';\n\nimport '../../core/storage/progress_store.dart';",
    "import 'package:flutter/material.dart';\n\nimport '../../core/economy/economy_config.dart';\nimport '../../core/storage/progress_store.dart';",
    'shop economy import',
)
shop = replace_once(
    shop,
    """  Future<void> _buyHearts(BuildContext context, int amount, int price) async {
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
""",
    """  Future<void> _buyHearts(BuildContext context, String offerId) async {
    final messenger = ScaffoldMessenger.of(context);
    if (store.hearts >= ProgressStore.maxHearts) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Your hearts are already full.')),
      );
      return;
    }
    final paid = await store.purchaseShopHeartOffer(offerId);
    if (!paid) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Not enough coins.')),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Hearts added successfully.')),
    );
  }

  Future<void> _buyBooster(
    BuildContext context,
    String id,
    String name,
  ) async {
    final paid = await store.purchaseShopBooster(id);
""",
    'shop purchase methods',
)
shop = replace_once(
    shop,
    "    final success = await store.purchaseTheme(offer.id, offer.price);",
    "    final success = await store.purchaseShopTheme(offer.id);",
    'shop theme wrapper',
)
shop = replace_once(
    shop,
    "  Widget build(BuildContext context) {\n    final skin = gameSkinById(store.selectedTheme);",
    "  Widget build(BuildContext context) {\n    final economy = EconomyConfig.current;\n    final singleHeart = economy.heartOfferById('heart_single');\n    final fullHearts = economy.heartOfferById('heart_full');\n    final hintBooster = economy.boosterOfferFor('hint');\n    final movesBooster = economy.boosterOfferFor('moves');\n    final shieldBooster = economy.boosterOfferFor('shield');\n    final skin = gameSkinById(store.selectedTheme);",
    'shop offer bindings',
)
shop = replace_once(
    shop,
    """                    child: _OfferCard(
                      iconType: ThreeDIconType.heart,
                      title: '+1 Heart',
                      subtitle: '120 coins',
                      onTap: () => _buyHearts(context, 1, 120),
                    ),
""",
    """                    child: _OfferCard(
                      iconType: ThreeDIconType.heart,
                      title: '+${singleHeart.amount} Heart',
                      subtitle: '${singleHeart.price} coins',
                      onTap: () => _buyHearts(context, singleHeart.id),
                    ),
""",
    'single heart offer',
)
shop = replace_once(
    shop,
    """                    child: _OfferCard(
                      iconType: ThreeDIconType.heart,
                      title: 'Full Hearts',
                      subtitle: '450 coins',
                      onTap: () =>
                          _buyHearts(context, ProgressStore.maxHearts, 450),
                    ),
""",
    """                    child: _OfferCard(
                      iconType: ThreeDIconType.heart,
                      title: 'Full Hearts',
                      subtitle: '${fullHearts.price} coins',
                      onTap: () => _buyHearts(context, fullHearts.id),
                    ),
""",
    'full heart offer',
)
shop = replace_once(
    shop,
    """              _BoosterTile(
                iconType: ThreeDIconType.hint,
                title: 'Smart Hint Pack',
                description: '3 free hints without spending coins',
                inventory: store.freeHints,
                price: 180,
                onTap: () =>
                    _buyBooster(context, 'hint', 3, 180, 'Smart hints'),
              ),
""",
    """              _BoosterTile(
                iconType: ThreeDIconType.hint,
                title: 'Smart Hint Pack',
                description:
                    '${hintBooster.amount} free hints without spending coins',
                inventory: store.freeHints,
                price: hintBooster.price,
                onTap: () => _buyBooster(context, 'hint', 'Smart hints'),
              ),
""",
    'hint booster offer',
)
shop = replace_once(
    shop,
    """              _BoosterTile(
                iconType: ThreeDIconType.extraMoves,
                title: 'Extra Moves Pack',
                description: 'Adds 5 moves during a city mission',
                inventory: store.extraMovesBoosters,
                price: 260,
                onTap: () => _buyBooster(
                  context,
                  'moves',
                  1,
                  260,
                  'Extra moves booster',
                ),
              ),
""",
    """              _BoosterTile(
                iconType: ThreeDIconType.extraMoves,
                title: 'Extra Moves Pack',
                description:
                    'Adds ${economy.gameplay.extraMovesPerBooster} moves during a city mission',
                inventory: store.extraMovesBoosters,
                price: movesBooster.price,
                onTap: () =>
                    _buyBooster(context, 'moves', 'Extra moves booster'),
              ),
""",
    'moves booster offer',
)
shop = replace_once(
    shop,
    """              _BoosterTile(
                iconType: ThreeDIconType.shield,
                title: 'Combo Shield',
                description: 'Protects one combo from a wrong match',
                inventory: store.comboShields,
                price: 220,
                onTap: () =>
                    _buyBooster(context, 'shield', 1, 220, 'Combo shield'),
              ),
""",
    """              _BoosterTile(
                iconType: ThreeDIconType.shield,
                title: 'Combo Shield',
                description: 'Protects one combo from a wrong match',
                inventory: store.comboShields,
                price: shieldBooster.price,
                onTap: () => _buyBooster(context, 'shield', 'Combo shield'),
              ),
""",
    'shield booster offer',
)
shop = replace_once(
    shop,
    """  const _ThemeOffer({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.start,
    required this.end,
    required this.price,
  });
""",
    """  const _ThemeOffer({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.start,
    required this.end,
  });
""",
    'theme offer constructor',
)
shop = replace_once(
    shop,
    "  final Color start;\n  final Color end;\n  final int price;\n}",
    "  final Color start;\n  final Color end;\n\n  int get price => EconomyConfig.current.themeOfferFor(id).price;\n}",
    'theme price getter',
)
for price_line in ("    price: 0,\n", "    price: 700,\n", "    price: 1200,\n"):
    if shop.count(price_line) != 1:
        raise SystemExit(f'theme price line mismatch: {price_line.strip()}')
    shop = shop.replace(price_line, '', 1)
shop_path.write_text(shop)


work_path = Path('docs/work/ECON-005.md')
work = work_path.read_text().rstrip()
if '## Migration policy' not in work:
    work += """

## Migration policy

- Legacy saves without `economy_config_version` are adopted as v1 by writing only the version marker; wallet, hearts, boosters, themes, progression, and reward state are not rewritten.
- Re-loading the same v1 marker is a no-op.
- A save stamped with a future economy schema fails closed before reward/shop recovery so an older build cannot silently apply stale prices or reward formulas.
- Future positive versions below the runtime schema require an explicit registered migration before the runtime may advance the marker; implicit balance rewrites are forbidden.
"""
work_path.write_text(work.rstrip() + '\n')
