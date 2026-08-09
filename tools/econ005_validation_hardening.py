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
    """    if (savedVersion == null || savedVersion <= 0) {
      await _prefs.setInt(_economyConfigVersionKey, currentVersion);
      return;
    }
    if (savedVersion > currentVersion) {
""",
    """    if (savedVersion == null) {
      await _prefs.setInt(_economyConfigVersionKey, currentVersion);
      return;
    }
    if (savedVersion <= 0) {
      throw StateError('Invalid economy config version: $savedVersion.');
    }
    if (savedVersion > currentVersion) {
""",
    'economy version migration',
)

progress = replace_once(
    progress,
    """  Future<bool> purchaseShopHeartOffer(String offerId) async {
    final offer = EconomyConfig.current.heartOfferById(offerId);
    if (hearts >= maxHearts) return false;
    final paid = await spendCoins(offer.price);
    if (!paid) return false;
    await addHearts(offer.amount);
    return true;
  }
""",
    """  Future<bool> purchaseShopHeartOffer(String offerId) async {
    final offer = EconomyConfig.current.heartOfferById(offerId);
    if (_purchaseBusy || hearts >= maxHearts || coins < offer.price) {
      return false;
    }

    _purchaseBusy = true;
    try {
      final finalCoins = coins - offer.price;
      final finalHearts = (hearts + offer.amount).clamp(0, maxHearts);
      await _commitShopPurchase('heart:${offer.id}', <String, Object?>{
        _heartsKey: finalHearts,
        if (finalHearts >= maxHearts) _heartTimestampKey: null,
        _coinsKey: finalCoins,
      });

      coins = finalCoins;
      hearts = finalHearts;
      if (hearts >= maxHearts) _heartRefillTimestamp = null;
      notifyListeners();
      return true;
    } finally {
      _purchaseBusy = false;
    }
  }
""",
    'atomic heart purchase',
)

progress = replace_once(
    progress,
    """        case _coinsKey:
        case _freeHintsKey:
        case _extraMovesKey:
        case _comboShieldsKey:
          if (value is! int || value < 0) {
            throw FormatException('Invalid non-negative integer for $key.');
          }
          validated[key] = value;
        case _selectedThemeKey:
""",
    """        case _coinsKey:
        case _freeHintsKey:
        case _extraMovesKey:
        case _comboShieldsKey:
          if (value is! int || value < 0) {
            throw FormatException('Invalid non-negative integer for $key.');
          }
          validated[key] = value;
        case _heartsKey:
          if (value is! int || value < 0 || value > maxHearts) {
            throw const FormatException('Invalid shop heart value.');
          }
          validated[key] = value;
        case _heartTimestampKey:
          if (value != null) {
            throw const FormatException(
              'Shop purchases may only clear the heart refill timestamp.',
            );
          }
          validated[key] = null;
        case _selectedThemeKey:
""",
    'shop journal heart validation',
)

progress = replace_once(
    progress,
    """      } else if (value is List<String>) {
        await _prefs.setStringList(entry.key, value);
      } else {
        throw FormatException('Unsupported shop purchase value: ${entry.key}');
      }
""",
    """      } else if (value is List<String>) {
        await _prefs.setStringList(entry.key, value);
      } else if (value == null && entry.key == _heartTimestampKey) {
        await _prefs.remove(entry.key);
      } else {
        throw FormatException('Unsupported shop purchase value: ${entry.key}');
      }
""",
    'shop journal heart timestamp apply',
)
progress_path.write_text(progress)


integration_path = Path('test/core/economy/economy_integration_test.dart')
integration = integration_path.read_text()
future_marker = """  test(
    'future economy versions fail closed without rewriting wallet',
    () async {
"""
version_test = """  test(
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
if version_test not in integration:
    if integration.count(future_marker) != 1:
        raise SystemExit('migration test insertion marker did not match')
    integration = integration.replace(future_marker, version_test + future_marker, 1)
integration_path.write_text(integration)


shop_test_path = Path('test/core/storage/shop_purchase_recovery_test.dart')
shop_test = shop_test_path.read_text()
malformed_marker = """  test(
    'malformed pending purchase is discarded without changing wallet',
"""
heart_tests = """  test('configured heart purchase persists wallet and hearts together', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 500);
    await prefs.setInt('hearts', 2);
    await prefs.setString(
      'heart_refill_timestamp',
      DateTime.now().toIso8601String(),
    );

    final store = ProgressStore();
    await store.load();
    expect(await store.purchaseShopHeartOffer('heart_single'), isTrue);
    expect(store.coins, 380);
    expect(store.hearts, 3);
    expect(await prefs.containsKey(pendingPurchaseKey), isFalse);

    final reloaded = ProgressStore();
    await reloaded.load();
    expect(reloaded.coins, 380);
    expect(reloaded.hearts, 3);
  });

  test('load completes an interrupted heart purchase idempotently', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 500);
    await prefs.setInt('hearts', 2);
    await prefs.setString(
      'heart_refill_timestamp',
      DateTime.now().toIso8601String(),
    );
    await prefs.setString(
      pendingPurchaseKey,
      jsonEncode({
        'version': 1,
        'reason': 'heart:heart_full',
        'values': {
          'hearts': 5,
          'heart_refill_timestamp': null,
          'coins': 50,
        },
      }),
    );

    final recovered = ProgressStore();
    await recovered.load();
    expect(recovered.coins, 50);
    expect(recovered.hearts, 5);
    expect(await prefs.containsKey('heart_refill_timestamp'), isFalse);
    expect(await prefs.containsKey(pendingPurchaseKey), isFalse);

    final secondLoad = ProgressStore();
    await secondLoad.load();
    expect(secondLoad.coins, 50);
    expect(secondLoad.hearts, 5);
  });

"""
if heart_tests not in shop_test:
    if shop_test.count(malformed_marker) != 1:
        raise SystemExit('shop recovery insertion marker did not match')
    shop_test = shop_test.replace(malformed_marker, heart_tests + malformed_marker, 1)
shop_test_path.write_text(shop_test)


work_path = Path('docs/work/ECON-005.md')
work = work_path.read_text().rstrip()
if '## Review hardening' not in work:
    work += """

## Review hardening

- A present non-positive `economy_config_version` is treated as corrupted metadata and fails closed; only an absent marker is considered a legacy v1 save.
- Configured heart purchases now debit coins and grant hearts inside the existing SHOP-002 absolute-state purchase journal, including atomic refill-timestamp clearing when the cap is reached.
- The v1 schema keeps non-negative price validation semantics; shipped balance values are unchanged.
"""
work_path.write_text(work.rstrip() + '\n')
