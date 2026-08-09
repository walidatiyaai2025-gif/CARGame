import 'package:cargo_sort_game/core/economy/economy_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EconomyConfig v1 parity', () {
    final config = EconomyConfig.v1;

    test('keeps shipped player defaults, caps, and mission thresholds', () {
      expect(config.schemaVersion, 1);
      expect(config.player.startingCoins, 100);
      expect(config.player.startingHearts, 5);
      expect(config.player.maxHearts, 5);
      expect(config.player.heartRefillInterval, const Duration(minutes: 30));
      expect(config.player.startingFreeHints, 2);
      expect(config.player.startingExtraMovesBoosters, 1);
      expect(config.player.startingComboShields, 1);
      expect(config.player.maxStarsPerLevel, 3);
      expect(config.player.xpPerPlayerLevel, 500);
      expect(config.player.dailyMissionWinsRequired, 3);
      expect(config.player.dailyMissionStarsRequired, 6);
      expect(config.player.dailyMissionCoinsRequired, 150);
    });

    test('keeps shipped gameplay reward and XP formulas', () {
      expect(config.levelCoinReward(level: 1, stars: 3, combo: 4), 68);
      expect(config.levelCoinReward(level: 25, stars: 1, combo: 0), 160);
      expect(config.levelXpReward(difficulty: 2, stars: 3, combo: 4), 127);
      expect(config.levelXpReward(difficulty: 5, stars: 1, combo: 0), 115);
      expect(config.gameplay.hintCoinCost, 10);
      expect(config.gameplay.extraMovesPerBooster, 5);
      expect(config.gameplay.preparedHintUses, 1);
    });

    test('keeps shipped daily, milestone, and world grants', () {
      expect(config.rewards.dailyRewardCoins, 50);
      expect(config.rewards.dailyMissionRewardCoins, 200);
      expect(config.milestoneCoinsForLevel(5), 55);
      expect(config.milestoneCoinsForLevel(20), 70);
      expect(config.milestoneXpForLevel(5), 25);
      expect(config.worldCoinsForLevel(25), 400);
      expect(config.worldXpForLevel(25), 175);
      expect(config.worldCoinsForLevel(150), 900);
      expect(config.worldXpForLevel(150), 300);
      expect(config.rewards.worldFreeHints, 1);
      expect(config.rewards.worldExtraMovesBoosters, 1);
      expect(config.rewards.worldComboShields, 1);
    });

    test('owns authoritative shop prices and quantities', () {
      final singleHeart = config.heartOfferById('heart_single');
      expect(singleHeart.amount, 1);
      expect(singleHeart.price, 120);

      final fullHeart = config.heartOfferById('heart_full');
      expect(fullHeart.amount, 5);
      expect(fullHeart.price, 450);

      final hint = config.boosterOfferFor('hint');
      expect(hint.id, 'booster_hint');
      expect(hint.amount, 3);
      expect(hint.price, 180);

      final moves = config.boosterOfferFor('moves');
      expect(moves.amount, 1);
      expect(moves.price, 260);

      final shield = config.boosterOfferFor('shield');
      expect(shield.amount, 1);
      expect(shield.price, 220);

      expect(config.themeOfferFor('classic').price, 0);
      expect(config.themeOfferFor('sunset').price, 700);
      expect(config.themeOfferFor('neon').price, 1200);
    });
  });

  group('EconomyConfig validation', () {
    final v1 = EconomyConfig.v1;

    test('rejects invalid schema versions and player caps', () {
      expect(
        () => EconomyConfig.validated(
          schemaVersion: 0,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: v1.shopOffers,
        ),
        throwsArgumentError,
      );

      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: const EconomyPlayerRules(
            startingCoins: 100,
            startingHearts: 6,
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
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: v1.shopOffers,
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate offer IDs and authoritative targets', () {
      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: <EconomyShopOffer>[...v1.shopOffers, v1.shopOffers.first],
        ),
        throwsArgumentError,
      );

      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: <EconomyShopOffer>[
            ...v1.shopOffers,
            const EconomyShopOffer(
              id: 'booster_hint_duplicate',
              kind: EconomyShopOfferKind.booster,
              targetId: 'hint',
              amount: 99,
              price: 1,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsafe formula inputs and unknown offers', () {
      expect(
        () => v1.levelCoinReward(level: 0, stars: 3, combo: 0),
        throwsArgumentError,
      );
      expect(
        () => v1.levelXpReward(difficulty: -1, stars: 3, combo: 0),
        throwsArgumentError,
      );
      expect(
        () => v1.levelCoinReward(level: 1, stars: 4, combo: 0),
        throwsArgumentError,
      );
      expect(() => v1.offerById('missing'), throwsArgumentError);
      expect(() => v1.boosterOfferFor('missing'), throwsArgumentError);
      expect(() => v1.themeOfferFor('missing'), throwsArgumentError);
    });
  });
}
