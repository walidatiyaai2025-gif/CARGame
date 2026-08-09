from pathlib import Path

config_path = Path('lib/core/economy/economy_config.dart')
text = config_path.read_text()
old = """    nonNegative('hintCoinCost', gameplay.hintCoinCost);
    positive('extraMovesPerBooster', gameplay.extraMovesPerBooster);
"""
new = """    positive('hintCoinCost', gameplay.hintCoinCost);
    positive('extraMovesPerBooster', gameplay.extraMovesPerBooster);
"""
if text.count(old) != 1:
    raise SystemExit('gameplay validation anchor did not match')
text = text.replace(old, new, 1)
old = """      positive('offer.amount', offer.amount);
      nonNegative('offer.price', offer.price);
      if (offer.kind != EconomyShopOfferKind.hearts) {
"""
new = """      positive('offer.amount', offer.amount);
      final zeroPricedClassicTheme =
          offer.kind == EconomyShopOfferKind.theme &&
          targetId == 'classic' &&
          offer.price == 0;
      if (!zeroPricedClassicTheme) {
        positive('offer.price', offer.price);
      }
      if (offer.kind != EconomyShopOfferKind.hearts) {
"""
if text.count(old) != 1:
    raise SystemExit('shop price validation anchor did not match')
config_path.write_text(text)


test_path = Path('test/core/economy/economy_config_test.dart')
test_text = test_path.read_text()
marker = """    test('rejects unsafe formula inputs and unknown offers', () {
"""
addition = """    test('rejects economy values that runtime cannot transact', () {
      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: const EconomyGameplayRules(
            hintCoinCost: 0,
            extraMovesPerBooster: 5,
            preparedHintUses: 1,
          ),
          shopOffers: v1.shopOffers,
        ),
        throwsArgumentError,
      );

      final zeroPricedHint = v1.shopOffers
          .map(
            (offer) => offer.id == 'booster_hint'
                ? EconomyShopOffer(
                    id: offer.id,
                    kind: offer.kind,
                    targetId: offer.targetId,
                    amount: offer.amount,
                    price: 0,
                  )
                : offer,
          )
          .toList();
      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: zeroPricedHint,
        ),
        throwsArgumentError,
      );

      final zeroPricedPaidTheme = v1.shopOffers
          .map(
            (offer) => offer.id == 'theme_sunset'
                ? EconomyShopOffer(
                    id: offer.id,
                    kind: offer.kind,
                    targetId: offer.targetId,
                    amount: offer.amount,
                    price: 0,
                  )
                : offer,
          )
          .toList();
      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: zeroPricedPaidTheme,
        ),
        throwsArgumentError,
      );
    });

"""
if addition not in test_text:
    if test_text.count(marker) != 1:
        raise SystemExit('test insertion marker did not match')
    test_text = test_text.replace(marker, addition + marker, 1)
test_path.write_text(test_text)
