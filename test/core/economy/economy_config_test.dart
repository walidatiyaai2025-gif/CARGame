import 'package:cargo_sort_game/core/economy/economy_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EconomyConfig v1 parity', () {
    final economy = EconomyConfig.current;

    test('preserves shipped starter, cap, mission and daily values', () {
      expect(economy.schemaVersion, 1);
      expect(economy.startingCoins, 100);
      expect(economy.maxHearts, 5);
      expect(economy.heartRefillInterval, const Duration(minutes: 30));
      expect(economy.starterFreeHints, 2);
      expect(economy.starterExtraMovesBoosters, 1);
      expect(economy.starterComboShields, 1);
      expect(economy.playerLevelXpStep, 500);
      expect(economy.dailyMissionRequiredWins, 3);
      expect(economy.dailyMissionRequiredStars, 6);
      expect(economy.dailyMissionRequiredCoins, 150);
      expect(economy.dailyRewardCoins, 50);
      expect(economy.dailyMissionRewardCoins, 200);
      expect(economy.hintFallbackCoinCost, 10);
      expect(economy.extraMovesPerBoosterUse, 5);
      expect(economy.rewardedContinueMoves, 5);
    });

    test('preserves gameplay reward and XP formulas', () {
      expect(
        economy.levelRewardCoins(level: 1, stars: 3, bestCombo: 2),
        64,
      );
      expect(
        economy.levelRewardCoins(level: 25, stars: 3, bestCombo: 4),
        188,
      );
      expect(
        economy.levelXp(difficulty: 2, stars: 3, bestCombo: 4),
        127,
      );
    });

    test('preserves milestone and world first-clear bonuses', () {
      final milestone = economy.firstClearBonusForLevel(5);
      expect(milestone.kind, EconomyCompletionBonusKind.milestone);
      expect(milestone.coins, 55);
      expect(milestone.xp, 25);

      final world = economy.firstClearBonusForLevel(25);
      expect(world.kind, EconomyCompletionBonusKind.world);
      expect(world.coins, 400);
      expect(world.xp, 175);
      expect(world.freeHints, 1);
      expect(world.extraMovesBoosters, 1);
      expect(world.comboShields, 1);

      expect(
        economy.firstClearBonusForLevel(4).kind,
        EconomyCompletionBonusKind.none,
      );
    });

    test('preserves authoritative shop catalog prices and quantities', () {
      expect(economy.heartOffer(EconomyConfig.heartSingleId).priceCoins, 120);
      expect(economy.heartOffer(EconomyConfig.heartSingleId).heartAmount, 1);
      expect(economy.heartOffer(EconomyConfig.heartFullId).priceCoins, 450);
      expect(economy.heartOffer(EconomyConfig.heartFullId).heartAmount, 5);

      final hints = economy.boosterOffer(EconomyConfig.hintBoosterId);
      expect(hints.priceCoins, 180);
      expect(hints.quantity, 3);
      expect(
        economy.boosterOffer(EconomyConfig.movesBoosterId).priceCoins,
        260,
      );
      expect(
        economy.boosterOffer(EconomyConfig.shieldBoosterId).priceCoins,
        220,
      );
      expect(economy.themeOffer('classic').priceCoins, 0);
      expect(economy.themeOffer('sunset').priceCoins, 700);
      expect(economy.themeOffer('neon').priceCoins, 1200);
    });
  });

  group('EconomyConfig validation', () {
    test('fails closed for invalid caps and version data', () {
      expect(
        () => EconomyConfig.current.copyWith(maxHearts: 0),
        throwsStateError,
      );
      expect(
        () => EconomyConfig.current.copyWith(schemaVersion: 0),
        throwsStateError,
      );
      expect(
        () => EconomyConfig.current.copyWith(
          heartRefillInterval: Duration.zero,
        ),
        throwsStateError,
      );
    });

    test('fails closed for duplicate or unstable catalog IDs', () {
      expect(
        () => EconomyConfig.current.copyWith(
          themeOffers: const <EconomyThemeOffer>[
            EconomyThemeOffer(id: 'classic', priceCoins: 0),
            EconomyThemeOffer(id: 'classic', priceCoins: 700),
          ],
        ),
        throwsStateError,
      );
      expect(
        () => EconomyConfig.current.copyWith(
          themeOffers: const <EconomyThemeOffer>[
            EconomyThemeOffer(id: 'classic', priceCoins: 0),
            EconomyThemeOffer(id: 'Bad-ID', priceCoins: 700),
          ],
        ),
        throwsStateError,
      );
    });

    test('catalog lists are immutable and unknown IDs fail closed', () {
      expect(
        () => EconomyConfig.current.heartOffers.add(
          const EconomyHeartOffer(id: 'other', priceCoins: 1, heartAmount: 1),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => EconomyConfig.current.boosterOffer('unknown'),
        throwsArgumentError,
      );
      expect(
        () => EconomyConfig.current.themeOffer('unknown'),
        throwsArgumentError,
      );
    });
  });
}
