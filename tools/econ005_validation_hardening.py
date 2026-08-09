from pathlib import Path
import subprocess

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

      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: const <EconomyShopOffer>[
            EconomyShopOffer(
              id: 'invalid_zero_booster',
              kind: EconomyShopOfferKind.booster,
              targetId: 'hint',
              amount: 1,
              price: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => EconomyConfig.validated(
          schemaVersion: 1,
          player: v1.player,
          rewards: v1.rewards,
          gameplay: v1.gameplay,
          shopOffers: const <EconomyShopOffer>[
            EconomyShopOffer(
              id: 'invalid_zero_paid_theme',
              kind: EconomyShopOfferKind.theme,
              targetId: 'sunset',
              amount: 1,
              price: 0,
            ),
          ],
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


progress_path = Path('lib/core/storage/progress_store.dart')
progress = progress_path.read_text()
old = """    if (savedVersion == null || savedVersion <= 0) {
      await _prefs.setInt(_economyConfigVersionKey, currentVersion);
      return;
    }
    if (savedVersion > currentVersion) {
"""
new = """    if (savedVersion == null) {
      await _prefs.setInt(_economyConfigVersionKey, currentVersion);
      return;
    }
    if (savedVersion <= 0) {
      throw StateError('Invalid economy config version: $savedVersion.');
    }
    if (savedVersion > currentVersion) {
"""
if progress.count(old) != 1:
    raise SystemExit('economy version migration anchor did not match')
progress_path.write_text(progress.replace(old, new, 1))


integration_path = Path('test/core/economy/economy_integration_test.dart')
integration = integration_path.read_text()
marker = """  test(
    'future economy versions fail closed without rewriting wallet',
    () async {
"""
addition = """  test(
    'invalid economy version markers fail closed without rewrites',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 444);
      await prefs.setInt('economy_config_version', 0);

      final store = ProgressStore();
      await expectLater(store.load(), throwsStateError);

      expect(await prefs.getInt('coins'), 444);
      expect(await prefs.getInt('economy_config_version'), 0);
    },
  );

"""
if addition not in integration:
    if integration.count(marker) != 1:
        raise SystemExit('migration test insertion marker did not match')
    integration = integration.replace(marker, addition + marker, 1)
integration_path.write_text(integration)

subprocess.run(
    [
        'dart',
        'format',
        'lib/core/storage/progress_store.dart',
        'test/core/economy/economy_integration_test.dart',
    ],
    check=True,
)
subprocess.run(
    [
        'git',
        'add',
        'lib/core/storage/progress_store.dart',
        'test/core/economy/economy_integration_test.dart',
    ],
    check=True,
)
