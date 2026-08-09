enum EconomyShopOfferKind { hearts, booster, theme }

final class EconomyPlayerRules {
  const EconomyPlayerRules({
    required this.startingCoins,
    required this.startingHearts,
    required this.maxHearts,
    required this.heartRefillInterval,
    required this.startingFreeHints,
    required this.startingExtraMovesBoosters,
    required this.startingComboShields,
    required this.maxStarsPerLevel,
    required this.xpPerPlayerLevel,
    required this.dailyMissionWinsRequired,
    required this.dailyMissionStarsRequired,
    required this.dailyMissionCoinsRequired,
  });

  final int startingCoins;
  final int startingHearts;
  final int maxHearts;
  final Duration heartRefillInterval;
  final int startingFreeHints;
  final int startingExtraMovesBoosters;
  final int startingComboShields;
  final int maxStarsPerLevel;
  final int xpPerPlayerLevel;
  final int dailyMissionWinsRequired;
  final int dailyMissionStarsRequired;
  final int dailyMissionCoinsRequired;
}

final class EconomyRewardRules {
  const EconomyRewardRules({
    required this.dailyRewardCoins,
    required this.dailyMissionRewardCoins,
    required this.levelBaseCoins,
    required this.levelCoinsPerLevel,
    required this.levelCoinsPerStar,
    required this.levelCoinsPerCombo,
    required this.levelBaseXp,
    required this.levelXpPerDifficulty,
    required this.levelXpPerStar,
    required this.levelXpPerCombo,
    required this.milestoneInterval,
    required this.milestoneBaseCoins,
    required this.milestoneCoinsPerMilestone,
    required this.milestoneXp,
    required this.worldInterval,
    required this.worldBaseCoins,
    required this.worldCoinsPerWorld,
    required this.worldBaseXp,
    required this.worldXpPerWorld,
    required this.worldFreeHints,
    required this.worldExtraMovesBoosters,
    required this.worldComboShields,
  });

  final int dailyRewardCoins;
  final int dailyMissionRewardCoins;
  final int levelBaseCoins;
  final int levelCoinsPerLevel;
  final int levelCoinsPerStar;
  final int levelCoinsPerCombo;
  final int levelBaseXp;
  final int levelXpPerDifficulty;
  final int levelXpPerStar;
  final int levelXpPerCombo;
  final int milestoneInterval;
  final int milestoneBaseCoins;
  final int milestoneCoinsPerMilestone;
  final int milestoneXp;
  final int worldInterval;
  final int worldBaseCoins;
  final int worldCoinsPerWorld;
  final int worldBaseXp;
  final int worldXpPerWorld;
  final int worldFreeHints;
  final int worldExtraMovesBoosters;
  final int worldComboShields;
}

final class EconomyGameplayRules {
  const EconomyGameplayRules({
    required this.hintCoinCost,
    required this.extraMovesPerBooster,
    required this.preparedHintUses,
  });

  final int hintCoinCost;
  final int extraMovesPerBooster;
  final int preparedHintUses;
}

final class EconomyShopOffer {
  const EconomyShopOffer({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.amount,
    required this.price,
  });

  final String id;
  final EconomyShopOfferKind kind;
  final String targetId;
  final int amount;
  final int price;
}

final class EconomyConfig {
  EconomyConfig._({
    required this.schemaVersion,
    required this.player,
    required this.rewards,
    required this.gameplay,
    required List<EconomyShopOffer> shopOffers,
  }) : shopOffers = List<EconomyShopOffer>.unmodifiable(shopOffers);

  factory EconomyConfig.validated({
    required int schemaVersion,
    required EconomyPlayerRules player,
    required EconomyRewardRules rewards,
    required EconomyGameplayRules gameplay,
    required List<EconomyShopOffer> shopOffers,
  }) {
    final config = EconomyConfig._(
      schemaVersion: schemaVersion,
      player: player,
      rewards: rewards,
      gameplay: gameplay,
      shopOffers: shopOffers,
    );
    config._validate();
    return config;
  }

  static final EconomyConfig v1 = EconomyConfig.validated(
    schemaVersion: 1,
    player: const EconomyPlayerRules(
      startingCoins: 100,
      startingHearts: 5,
      maxHearts: 5,
      heartRefillInterval: Duration(minutes: 30),
      startingFreeHints: 2,
      startingExtraMovesBoosters: 1,
      startingComboShields: 1,
      maxStarsPerLevel: 3,
      xpPerPlayerLevel: 500,
      dailyMissionWinsRequired: 3,
      dailyMissionStarsRequired: 6,
      dailyMissionCoinsRequired: 150,
    ),
    rewards: const EconomyRewardRules(
      dailyRewardCoins: 50,
      dailyMissionRewardCoins: 200,
      levelBaseCoins: 25,
      levelCoinsPerLevel: 5,
      levelCoinsPerStar: 10,
      levelCoinsPerCombo: 2,
      levelBaseXp: 50,
      levelXpPerDifficulty: 10,
      levelXpPerStar: 15,
      levelXpPerCombo: 3,
      milestoneInterval: 5,
      milestoneBaseCoins: 50,
      milestoneCoinsPerMilestone: 5,
      milestoneXp: 25,
      worldInterval: 25,
      worldBaseCoins: 300,
      worldCoinsPerWorld: 100,
      worldBaseXp: 150,
      worldXpPerWorld: 25,
      worldFreeHints: 1,
      worldExtraMovesBoosters: 1,
      worldComboShields: 1,
    ),
    gameplay: const EconomyGameplayRules(
      hintCoinCost: 10,
      extraMovesPerBooster: 5,
      preparedHintUses: 1,
    ),
    shopOffers: const <EconomyShopOffer>[
      EconomyShopOffer(
        id: 'heart_single',
        kind: EconomyShopOfferKind.hearts,
        targetId: 'hearts',
        amount: 1,
        price: 120,
      ),
      EconomyShopOffer(
        id: 'heart_full',
        kind: EconomyShopOfferKind.hearts,
        targetId: 'hearts',
        amount: 5,
        price: 450,
      ),
      EconomyShopOffer(
        id: 'booster_hint',
        kind: EconomyShopOfferKind.booster,
        targetId: 'hint',
        amount: 3,
        price: 180,
      ),
      EconomyShopOffer(
        id: 'booster_moves',
        kind: EconomyShopOfferKind.booster,
        targetId: 'moves',
        amount: 1,
        price: 260,
      ),
      EconomyShopOffer(
        id: 'booster_shield',
        kind: EconomyShopOfferKind.booster,
        targetId: 'shield',
        amount: 1,
        price: 220,
      ),
      EconomyShopOffer(
        id: 'theme_classic',
        kind: EconomyShopOfferKind.theme,
        targetId: 'classic',
        amount: 1,
        price: 0,
      ),
      EconomyShopOffer(
        id: 'theme_sunset',
        kind: EconomyShopOfferKind.theme,
        targetId: 'sunset',
        amount: 1,
        price: 700,
      ),
      EconomyShopOffer(
        id: 'theme_neon',
        kind: EconomyShopOfferKind.theme,
        targetId: 'neon',
        amount: 1,
        price: 1200,
      ),
    ],
  );

  static EconomyConfig get current => v1;

  final int schemaVersion;
  final EconomyPlayerRules player;
  final EconomyRewardRules rewards;
  final EconomyGameplayRules gameplay;
  final List<EconomyShopOffer> shopOffers;

  int levelCoinReward({
    required int level,
    required int stars,
    required int combo,
  }) {
    _validateLevelInputs(level: level, stars: stars, combo: combo);
    return rewards.levelBaseCoins +
        level * rewards.levelCoinsPerLevel +
        stars * rewards.levelCoinsPerStar +
        combo * rewards.levelCoinsPerCombo;
  }

  int levelXpReward({
    required int difficulty,
    required int stars,
    required int combo,
  }) {
    if (difficulty < 0) {
      throw ArgumentError.value(difficulty, 'difficulty');
    }
    _validateStarsAndCombo(stars: stars, combo: combo);
    return rewards.levelBaseXp +
        difficulty * rewards.levelXpPerDifficulty +
        stars * rewards.levelXpPerStar +
        combo * rewards.levelXpPerCombo;
  }

  bool isMilestoneLevel(int level) =>
      level > 0 && level % rewards.milestoneInterval == 0;

  bool isWorldLevel(int level) =>
      level > 0 && level % rewards.worldInterval == 0;

  int milestoneCoinsForLevel(int level) {
    if (!isMilestoneLevel(level)) {
      throw ArgumentError.value(level, 'level', 'Not a milestone level.');
    }
    return rewards.milestoneBaseCoins +
        (level ~/ rewards.milestoneInterval) *
            rewards.milestoneCoinsPerMilestone;
  }

  int milestoneXpForLevel(int level) {
    if (!isMilestoneLevel(level)) {
      throw ArgumentError.value(level, 'level', 'Not a milestone level.');
    }
    return rewards.milestoneXp;
  }

  int worldCoinsForLevel(int level) {
    final world = _worldNumberForLevel(level);
    return rewards.worldBaseCoins + world * rewards.worldCoinsPerWorld;
  }

  int worldXpForLevel(int level) {
    final world = _worldNumberForLevel(level);
    return rewards.worldBaseXp + world * rewards.worldXpPerWorld;
  }

  EconomyShopOffer offerById(String offerId) {
    final normalized = offerId.trim();
    for (final offer in shopOffers) {
      if (offer.id == normalized) return offer;
    }
    throw ArgumentError.value(offerId, 'offerId', 'Unknown economy offer.');
  }

  EconomyShopOffer heartOfferById(String offerId) {
    final offer = offerById(offerId);
    if (offer.kind != EconomyShopOfferKind.hearts) {
      throw ArgumentError.value(offerId, 'offerId', 'Not a heart offer.');
    }
    return offer;
  }

  EconomyShopOffer boosterOfferFor(String boosterId) => _offerForTarget(
    EconomyShopOfferKind.booster,
    boosterId,
    'boosterId',
  );

  EconomyShopOffer themeOfferFor(String themeId) =>
      _offerForTarget(EconomyShopOfferKind.theme, themeId, 'themeId');

  EconomyShopOffer _offerForTarget(
    EconomyShopOfferKind kind,
    String targetId,
    String argumentName,
  ) {
    final normalized = targetId.trim();
    for (final offer in shopOffers) {
      if (offer.kind == kind && offer.targetId == normalized) return offer;
    }
    throw ArgumentError.value(targetId, argumentName, 'Unknown economy target.');
  }

  int _worldNumberForLevel(int level) {
    if (!isWorldLevel(level)) {
      throw ArgumentError.value(level, 'level', 'Not a world-completion level.');
    }
    return level ~/ rewards.worldInterval;
  }

  void _validateLevelInputs({
    required int level,
    required int stars,
    required int combo,
  }) {
    if (level <= 0) throw ArgumentError.value(level, 'level');
    _validateStarsAndCombo(stars: stars, combo: combo);
  }

  void _validateStarsAndCombo({required int stars, required int combo}) {
    if (stars < 0 || stars > player.maxStarsPerLevel) {
      throw ArgumentError.value(stars, 'stars');
    }
    if (combo < 0) throw ArgumentError.value(combo, 'combo');
  }

  void _validate() {
    void nonNegative(String name, int value) {
      if (value < 0) throw ArgumentError.value(value, name);
    }

    void positive(String name, int value) {
      if (value <= 0) throw ArgumentError.value(value, name);
    }

    positive('schemaVersion', schemaVersion);
    nonNegative('startingCoins', player.startingCoins);
    positive('maxHearts', player.maxHearts);
    if (player.startingHearts < 0 ||
        player.startingHearts > player.maxHearts) {
      throw ArgumentError.value(player.startingHearts, 'startingHearts');
    }
    if (player.heartRefillInterval.inMicroseconds <= 0) {
      throw ArgumentError.value(
        player.heartRefillInterval,
        'heartRefillInterval',
      );
    }
    nonNegative('startingFreeHints', player.startingFreeHints);
    nonNegative(
      'startingExtraMovesBoosters',
      player.startingExtraMovesBoosters,
    );
    nonNegative('startingComboShields', player.startingComboShields);
    positive('maxStarsPerLevel', player.maxStarsPerLevel);
    positive('xpPerPlayerLevel', player.xpPerPlayerLevel);
    positive('dailyMissionWinsRequired', player.dailyMissionWinsRequired);
    positive('dailyMissionStarsRequired', player.dailyMissionStarsRequired);
    positive('dailyMissionCoinsRequired', player.dailyMissionCoinsRequired);

    nonNegative('dailyRewardCoins', rewards.dailyRewardCoins);
    nonNegative('dailyMissionRewardCoins', rewards.dailyMissionRewardCoins);
    nonNegative('levelBaseCoins', rewards.levelBaseCoins);
    nonNegative('levelCoinsPerLevel', rewards.levelCoinsPerLevel);
    nonNegative('levelCoinsPerStar', rewards.levelCoinsPerStar);
    nonNegative('levelCoinsPerCombo', rewards.levelCoinsPerCombo);
    nonNegative('levelBaseXp', rewards.levelBaseXp);
    nonNegative('levelXpPerDifficulty', rewards.levelXpPerDifficulty);
    nonNegative('levelXpPerStar', rewards.levelXpPerStar);
    nonNegative('levelXpPerCombo', rewards.levelXpPerCombo);
    positive('milestoneInterval', rewards.milestoneInterval);
    nonNegative('milestoneBaseCoins', rewards.milestoneBaseCoins);
    nonNegative(
      'milestoneCoinsPerMilestone',
      rewards.milestoneCoinsPerMilestone,
    );
    nonNegative('milestoneXp', rewards.milestoneXp);
    positive('worldInterval', rewards.worldInterval);
    if (rewards.worldInterval % rewards.milestoneInterval != 0) {
      throw ArgumentError.value(
        rewards.worldInterval,
        'worldInterval',
        'World interval must align with milestone interval.',
      );
    }
    nonNegative('worldBaseCoins', rewards.worldBaseCoins);
    nonNegative('worldCoinsPerWorld', rewards.worldCoinsPerWorld);
    nonNegative('worldBaseXp', rewards.worldBaseXp);
    nonNegative('worldXpPerWorld', rewards.worldXpPerWorld);
    nonNegative('worldFreeHints', rewards.worldFreeHints);
    nonNegative(
      'worldExtraMovesBoosters',
      rewards.worldExtraMovesBoosters,
    );
    nonNegative('worldComboShields', rewards.worldComboShields);

    nonNegative('hintCoinCost', gameplay.hintCoinCost);
    positive('extraMovesPerBooster', gameplay.extraMovesPerBooster);
    positive('preparedHintUses', gameplay.preparedHintUses);

    final ids = <String>{};
    final uniqueTargets = <String>{};
    for (final offer in shopOffers) {
      final id = offer.id.trim();
      final targetId = offer.targetId.trim();
      if (id.isEmpty) throw ArgumentError.value(offer.id, 'offer.id');
      if (targetId.isEmpty) {
        throw ArgumentError.value(offer.targetId, 'offer.targetId');
      }
      if (!ids.add(id)) {
        throw ArgumentError.value(id, 'offer.id', 'Duplicate offer ID.');
      }
      positive('offer.amount', offer.amount);
      nonNegative('offer.price', offer.price);
      if (offer.kind != EconomyShopOfferKind.hearts) {
        final key = '${offer.kind.name}:$targetId';
        if (!uniqueTargets.add(key)) {
          throw ArgumentError.value(
            targetId,
            'offer.targetId',
            'Duplicate authoritative target.',
          );
        }
      }
    }
  }
}
