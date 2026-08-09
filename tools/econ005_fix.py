from pathlib import Path

path = Path('lib/core/storage/progress_store.dart')
text = path.read_text()

old_booster = """  Future<bool> purchaseShopBooster(String boosterId) {
    final offer = EconomyConfig.current.boosterOfferFor(boosterId);
    return purchaseBooster(offer.targetId, offer.amount, offer.price);
  }

  Future<bool> purchaseShopTheme(String themeId) {
    final offer = EconomyConfig.current.themeOfferFor(themeId);
    return purchaseTheme(offer.targetId, offer.price);
  }
"""
new_booster = """  Future<bool> purchaseShopBooster(String boosterId) async {
    final offer = EconomyConfig.current.boosterOfferFor(boosterId);
    return purchaseBooster(offer.targetId, offer.amount, offer.price);
  }

  Future<bool> purchaseShopTheme(String themeId) async {
    final offer = EconomyConfig.current.themeOfferFor(themeId);
    return purchaseTheme(offer.targetId, offer.price);
  }
"""
if text.count(old_booster) != 1:
    raise SystemExit('configured shop wrapper block did not match')
text = text.replace(old_booster, new_booster, 1)

start = text.find('  Future<void> _saveProgressAndStats() async {')
if start != -1:
    end = text.find('  Future<bool> spendCoins(int amount) async {', start)
    if end == -1:
        raise SystemExit('could not bound unused save helper')
    text = text[:start] + text[end:]

path.write_text(text)
