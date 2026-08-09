class EconomyHeartOffer {
  const EconomyHeartOffer({
    required this.id,
    required this.priceCoins,
    required this.heartAmount,
  });

  final String id;
  final int priceCoins;
  final int heartAmount;
}

class EconomyBoosterOffer {
  const EconomyBoosterOffer({
    required this.id,
    required this.priceCoins,
    required this.quantity,
  });

  final String id;
  final int priceCoins;
  final int quantity;
}

class EconomyThemeOffer {
  const EconomyThemeOffer({required this.id, required this.priceCoins});

  final String id;
  final int priceCoins;
}

enum EconomyCompletionBonusKind { none, milestone, world }

class EconomyCompletionBonus {
  const EconomyCompletionBonus({
    required this.kind,
    required this.coins,
    required this.xp,
    this.freeHints = 0,
    this.extraMovesBoosters = 0,
    this.comboShields = 0,
  });

  static const none = EconomyCompletionBonus(
    kind: EconomyCompletionBonusKind.none,
    coins: 0,
    xp: 0,
  );

  final EconomyCompletionBonusKind kind;
  final int coins;
  final int xp;
  final int freeHints;
  final int extraMovesBoosters;
  final int comboShields;

  bool get isWorld => kind == EconomyCompletionBonusKind.world;
}

/// Versioned source of truth for release-critical balance values.
///
/// Version 1 intentionally mirrors the values that shipped before ECON-005.
/// Future versions must be introduced through an explicit save migration; callers
/// must never silently reinterpret an existing wallet or entitlement balance.
class EconomyConfig {
  EconomyConfig({
    required this.schemaVersion,
    required this.startingCoins,
    required this.maxHearts,
    required this.heartRefillInterval,
    required this.starterFreeHints,
    required this.starterExtraMovesBoosters,
    required this.starterComboShields,
    required this.playerLevelXpStep,
    required this.dailyMissionRequiredWins,
    required this.dailyMissionRequiredStars,
    required this.dailyMissionRequiredCoins,
    required this.dailyRewardCoins,
    required this.dailyMissionRewardCoins,
    required this.hintFallbackCoinCost,
    required this.extraMovesPerBoosterUse,
    required this.rewardedContinueMoves,
    required this.levelRewardBaseCoins,
    required this.levelRewardPerLevel,
    required this.levelRewardPerStar,
    required this.levelRewardPerCombo,
    required this.levelXpBase,
    required this.levelXpPerDifficulty,
    required this.levelXpPerStar,
    required this.levelXpPerCombo,
    required this.milestoneInterval,
    required this.milestoneBaseCoins,
    required this.milestoneCoinsPerIndex,
    required this.milestoneXp,
    required this.worldInterval,
    required this.worldBaseCoins,
    required this.worldCoinsPerIndex,
    required this.worldBaseXp,
    required this.worldXpPerIndex,
    required this.worldFreeHintGrant,
    required this.worldExtraMovesGrant,
    required this.worldComboShieldGrant,
    required Iterable<EconomyHeartOffer> heartOffers,
    required Iterable<EconomyBoosterOffer> boosterOffers,
    required Iterable<EconomyThemeOffer> themeOffers,
  }) : heartOffers = List<EconomyHeartOffer>.unmodifiable(heartOffers),
       boosterOffers = List<EconomyBoosterOffer>.unmodifiable(boosterOffers),
       themeOffers = List<EconomyThemeOffer>.unmodifiable(themeOffers) {
    validate();
  }

  static const heartSingleId = 'heart_single';
  static const heartFullId = 'heart_full';
  static const hintBoosterId = 'hint';
  static const movesBoosterId = 'moves';
  static const shieldBoosterId = 'shield';
  static const classicThemeId = 'classic';

  static final EconomyConfig current = EconomyConfig(
    schemaVersion: 1,
    startingCoins: 100,
    maxHearts: 5,
    heartRefillInterval: const Duration(minutes: 30),
    starterFreeHints: 2,
    starterExtraMovesBoosters: 1,
    starterComboShields: 1,
    playerLevelXpStep: 500,
    dailyMissionRequiredWins: 3,
    dailyMissionRequiredStars: 6,
    dailyMissionRequiredCoins: 150,
    dailyRewardCoins: 50,
    dailyMissionRewardCoins: 200,
    hintFallbackCoinCost: 10,
    extraMovesPerBoosterUse: 5,
    rewardedContinueMoves: 5,
    levelRewardBaseCoins: 25,
    levelRewardPerLevel: 5,
    levelRewardPerStar: 10,
    levelRewardPerCombo: 2,
    levelXpBase: 50,
    levelXpPerDifficulty: 10,
    levelXpPerStar: 15,
    levelXpPerCombo: 3,
    milestoneInterval: 5,
    milestoneBaseCoins: 50,
    milestoneCoinsPerIndex: 5,
    milestoneXp: 25,
    worldInterval: 25,
    worldBaseCoins: 300,
    worldCoinsPerIndex: 100,
    worldBaseXp: 150,
    worldXpPerIndex: 25,
    worldFreeHintGrant: 1,
    worldExtraMovesGrant: 1,
    worldComboShieldGrant: 1,
    heartOffers: const <EconomyHeartOffer>[
      EconomyHeartOffer(id: heartSingleId, priceCoins: 120, heartAmount: 1),
      EconomyHeartOffer(id: heartFullId, priceCoins: 450, heartAmount: 5),
    ],
    boosterOffers: const <EconomyBoosterOffer>[
      EconomyBoosterOffer(id: hintBoosterId, priceCoins: 180, quantity: 3),
      EconomyBoosterOffer(id: movesBoosterId, priceCoins: 260, quantity: 1),
      EconomyBoosterOffer(id: shieldBoosterId, priceCoins: 220, quantity: 1),
    ],
    themeOffers: const <EconomyThemeOffer>[
      EconomyThemeOffer(id: classicThemeId, priceCoins: 0),
      EconomyThemeOffer(id: 'sunset', priceCoins: 700),
      EconomyThemeOffer(id: 'neon', priceCoins: 1200),
    ],
  );

  final int schemaVersion;
  final int startingCoins;
  final int maxHearts;
  final Duration heartRefillInterval;
  final int starterFreeHints;
  final int starterExtraMovesBoosters;
  final int starterComboShields;
  final int playerLevelXpStep;
  final int dailyMissionRequiredWins;
  final int dailyMissionRequiredStars;
  final int dailyMissionRequiredCoins;
  final int dailyRewardCoins;
  final int dailyMissionRewardCoins;
  final int hintFallbackCoinCost;
  final int extraMovesPerBoosterUse;
  final int rewardedContinueMoves;
  final int levelRewardBaseCoins;
  final int levelRewardPerLevel;
  final int levelRewardPerStar;
  final int levelRewardPerCombo;
  final int levelXpBase;
  final int levelXpPerDifficulty;
  final int levelXpPerStar;
  final int levelXpPerCombo;
  final int milestoneInterval;
  final int milestoneBaseCoins;
  final int milestoneCoinsPerIndex;
  final int milestoneXp;
  final int worldInterval;
  final int worldBaseCoins;
  final int worldCoinsPerIndex;
  final int worldBaseXp;
  final int worldXpPerIndex;
  final int worldFreeHintGrant;
  final int worldExtraMovesGrant;
  final int worldComboShieldGrant;
  final List<EconomyHeartOffer> heartOffers;
  final List<EconomyBoosterOffer> boosterOffers;
  final List<EconomyThemeOffer> themeOffers;

  int levelRewardCoins({
    required int level,
    required int stars,
    required int bestCombo,
  }) {
    _requirePositive(level, 'level');
    _requirePositive(stars, 'stars');
    _requireNonNegative(bestCombo, 'bestCombo');
    return levelRewardBaseCoins +
        level * levelRewardPerLevel +
        stars * levelRewardPerStar +
        bestCombo * levelRewardPerCombo;
  }

  int levelXp({
    required int difficulty,
    required int stars,
    required int bestCombo,
  }) {
    _requireNonNegative(difficulty, 'difficulty');
    _requirePositive(stars, 'stars');
    _requireNonNegative(bestCombo, 'bestCombo');
    return levelXpBase +
        difficulty * levelXpPerDifficulty +
        stars * levelXpPerStar +
        bestCombo * levelXpPerCombo;
  }

  EconomyCompletionBonus firstClearBonusForLevel(int level) {
    _requirePositive(level, 'level');
    if (level % worldInterval == 0) {
      final worldNumber = level ~/ worldInterval;
      return EconomyCompletionBonus(
        kind: EconomyCompletionBonusKind.world,
        coins: worldBaseCoins + worldNumber * worldCoinsPerIndex,
        xp: worldBaseXp + worldNumber * worldXpPerIndex,
        freeHints: worldFreeHintGrant,
        extraMovesBoosters: worldExtraMovesGrant,
        comboShields: worldComboShieldGrant,
      );
    }
    if (level % milestoneInterval == 0) {
      final milestoneNumber = level ~/ milestoneInterval;
      return EconomyCompletionBonus(
        kind: EconomyCompletionBonusKind.milestone,
        coins: milestoneBaseCoins + milestoneNumber * milestoneCoinsPerIndex,
        xp: milestoneXp,
      );
    }
    return EconomyCompletionBonus.none;
  }

  EconomyHeartOffer heartOffer(String id) {
    for (final offer in heartOffers) {
      if (offer.id == id) return offer;
    }
    throw ArgumentError.value(id, 'offerId', 'Unknown heart offer');
  }

  EconomyBoosterOffer boosterOffer(String id) {
    for (final offer in boosterOffers) {
      if (offer.id == id) return offer;
    }
    throw ArgumentError.value(id, 'boosterId', 'Unknown booster offer');
  }

  EconomyThemeOffer themeOffer(String id) {
    for (final offer in themeOffers) {
      if (offer.id == id) return offer;
    }
    throw ArgumentError.value(id, 'themeId', 'Unknown theme offer');
  }

  void validate() {
    _positive(schemaVersion, 'schemaVersion');
    _nonNegative(startingCoins, 'startingCoins');
    _positive(maxHearts, 'maxHearts');
    if (heartRefillInterval <= Duration.zero) {
      throw StateError('heartRefillInterval must be positive.');
    }
    _nonNegative(starterFreeHints, 'starterFreeHints');
    _nonNegative(starterExtraMovesBoosters, 'starterExtraMovesBoosters');
    _nonNegative(starterComboShields, 'starterComboShields');
    _positive(playerLevelXpStep, 'playerLevelXpStep');
    _positive(dailyMissionRequiredWins, 'dailyMissionRequiredWins');
    _positive(dailyMissionRequiredStars, 'dailyMissionRequiredStars');
    _positive(dailyMissionRequiredCoins, 'dailyMissionRequiredCoins');
    _nonNegative(dailyRewardCoins, 'dailyRewardCoins');
    _nonNegative(dailyMissionRewardCoins, 'dailyMissionRewardCoins');
    _positive(hintFallbackCoinCost, 'hintFallbackCoinCost');
    _positive(extraMovesPerBoosterUse, 'extraMovesPerBoosterUse');
    _positive(rewardedContinueMoves, 'rewardedContinueMoves');

    for (final entry in <MapEntry<String, int>>[
      MapEntry('levelRewardBaseCoins', levelRewardBaseCoins),
      MapEntry('levelRewardPerLevel', levelRewardPerLevel),
      MapEntry('levelRewardPerStar', levelRewardPerStar),
      MapEntry('levelRewardPerCombo', levelRewardPerCombo),
      MapEntry('levelXpBase', levelXpBase),
      MapEntry('levelXpPerDifficulty', levelXpPerDifficulty),
      MapEntry('levelXpPerStar', levelXpPerStar),
      MapEntry('levelXpPerCombo', levelXpPerCombo),
      MapEntry('milestoneBaseCoins', milestoneBaseCoins),
      MapEntry('milestoneCoinsPerIndex', milestoneCoinsPerIndex),
      MapEntry('milestoneXp', milestoneXp),
      MapEntry('worldBaseCoins', worldBaseCoins),
      MapEntry('worldCoinsPerIndex', worldCoinsPerIndex),
      MapEntry('worldBaseXp', worldBaseXp),
      MapEntry('worldXpPerIndex', worldXpPerIndex),
      MapEntry('worldFreeHintGrant', worldFreeHintGrant),
      MapEntry('worldExtraMovesGrant', worldExtraMovesGrant),
      MapEntry('worldComboShieldGrant', worldComboShieldGrant),
    ]) {
      _nonNegative(entry.value, entry.key);
    }
    _positive(milestoneInterval, 'milestoneInterval');
    _positive(worldInterval, 'worldInterval');
    if (worldInterval <= milestoneInterval ||
        worldInterval % milestoneInterval != 0) {
      throw StateError(
        'worldInterval must be a larger multiple of milestoneInterval.',
      );
    }

    _validateStableUniqueIds(heartOffers.map((offer) => offer.id), 'heart');
    _validateStableUniqueIds(boosterOffers.map((offer) => offer.id), 'booster');
    _validateStableUniqueIds(themeOffers.map((offer) => offer.id), 'theme');

    for (final offer in heartOffers) {
      _positive(offer.priceCoins, 'heart ${offer.id} priceCoins');
      _positive(offer.heartAmount, 'heart ${offer.id} heartAmount');
      if (offer.heartAmount > maxHearts) {
        throw StateError('Heart offer ${offer.id} exceeds maxHearts.');
      }
    }
    for (final offer in boosterOffers) {
      _positive(offer.priceCoins, 'booster ${offer.id} priceCoins');
      _positive(offer.quantity, 'booster ${offer.id} quantity');
    }
    for (final offer in themeOffers) {
      _nonNegative(offer.priceCoins, 'theme ${offer.id} priceCoins');
    }

    const supportedBoosters = <String>{
      hintBoosterId,
      movesBoosterId,
      shieldBoosterId,
    };
    if (boosterOffers
        .map((offer) => offer.id)
        .toSet()
        .difference(supportedBoosters)
        .isNotEmpty) {
      throw StateError('Economy config contains an unsupported booster ID.');
    }
    if (!supportedBoosters.every(
      (id) => boosterOffers.any((offer) => offer.id == id),
    )) {
      throw StateError('Economy config is missing a required booster offer.');
    }
    if (!heartOffers.any((offer) => offer.id == heartSingleId) ||
        !heartOffers.any((offer) => offer.id == heartFullId)) {
      throw StateError('Economy config is missing a required heart offer.');
    }
    final classic = themeOffers.where((offer) => offer.id == classicThemeId);
    if (classic.length != 1 || classic.single.priceCoins != 0) {
      throw StateError('Classic theme must exist exactly once and be free.');
    }
  }

  EconomyConfig copyWith({
    int? schemaVersion,
    int? startingCoins,
    int? maxHearts,
    Duration? heartRefillInterval,
    int? playerLevelXpStep,
    int? dailyMissionRequiredWins,
    int? dailyMissionRequiredStars,
    int? dailyMissionRequiredCoins,
    int? dailyRewardCoins,
    int? dailyMissionRewardCoins,
    int? milestoneInterval,
    int? worldInterval,
    Iterable<EconomyHeartOffer>? heartOffers,
    Iterable<EconomyBoosterOffer>? boosterOffers,
    Iterable<EconomyThemeOffer>? themeOffers,
  }) => EconomyConfig(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    startingCoins: startingCoins ?? this.startingCoins,
    maxHearts: maxHearts ?? this.maxHearts,
    heartRefillInterval: heartRefillInterval ?? this.heartRefillInterval,
    starterFreeHints: starterFreeHints,
    starterExtraMovesBoosters: starterExtraMovesBoosters,
    starterComboShields: starterComboShields,
    playerLevelXpStep: playerLevelXpStep ?? this.playerLevelXpStep,
    dailyMissionRequiredWins:
        dailyMissionRequiredWins ?? this.dailyMissionRequiredWins,
    dailyMissionRequiredStars:
        dailyMissionRequiredStars ?? this.dailyMissionRequiredStars,
    dailyMissionRequiredCoins:
        dailyMissionRequiredCoins ?? this.dailyMissionRequiredCoins,
    dailyRewardCoins: dailyRewardCoins ?? this.dailyRewardCoins,
    dailyMissionRewardCoins:
        dailyMissionRewardCoins ?? this.dailyMissionRewardCoins,
    hintFallbackCoinCost: hintFallbackCoinCost,
    extraMovesPerBoosterUse: extraMovesPerBoosterUse,
    rewardedContinueMoves: rewardedContinueMoves,
    levelRewardBaseCoins: levelRewardBaseCoins,
    levelRewardPerLevel: levelRewardPerLevel,
    levelRewardPerStar: levelRewardPerStar,
    levelRewardPerCombo: levelRewardPerCombo,
    levelXpBase: levelXpBase,
    levelXpPerDifficulty: levelXpPerDifficulty,
    levelXpPerStar: levelXpPerStar,
    levelXpPerCombo: levelXpPerCombo,
    milestoneInterval: milestoneInterval ?? this.milestoneInterval,
    milestoneBaseCoins: milestoneBaseCoins,
    milestoneCoinsPerIndex: milestoneCoinsPerIndex,
    milestoneXp: milestoneXp,
    worldInterval: worldInterval ?? this.worldInterval,
    worldBaseCoins: worldBaseCoins,
    worldCoinsPerIndex: worldCoinsPerIndex,
    worldBaseXp: worldBaseXp,
    worldXpPerIndex: worldXpPerIndex,
    worldFreeHintGrant: worldFreeHintGrant,
    worldExtraMovesGrant: worldExtraMovesGrant,
    worldComboShieldGrant: worldComboShieldGrant,
    heartOffers: heartOffers ?? this.heartOffers,
    boosterOffers: boosterOffers ?? this.boosterOffers,
    themeOffers: themeOffers ?? this.themeOffers,
  );

  void _validateStableUniqueIds(Iterable<String> ids, String group) {
    final seen = <String>{};
    final pattern = RegExp(r'^[a-z0-9_]+$');
    for (final id in ids) {
      if (!pattern.hasMatch(id) || !seen.add(id)) {
        throw StateError('$group offer IDs must be stable and unique: $id');
      }
    }
    if (seen.isEmpty) throw StateError('$group offer list cannot be empty.');
  }

  void _positive(int value, String field) {
    if (value <= 0) throw StateError('$field must be positive.');
  }

  void _nonNegative(int value, String field) {
    if (value < 0) throw StateError('$field cannot be negative.');
  }

  void _requirePositive(int value, String field) {
    if (value <= 0) throw ArgumentError.value(value, field);
  }

  void _requireNonNegative(int value, String field) {
    if (value < 0) throw ArgumentError.value(value, field);
  }
}
