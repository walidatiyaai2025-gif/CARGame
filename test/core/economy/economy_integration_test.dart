import 'package:cargo_sort_game/core/economy/economy_config.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('legacy save adopts v1 marker without rewriting player economy', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 725);
    await prefs.setInt('hearts', 3);
    await prefs.setInt('booster_free_hints', 8);
    await prefs.setInt('booster_extra_moves', 4);
    await prefs.setInt('booster_combo_shields', 6);

    final store = ProgressStore();
    await store.load();

    expect(store.coins, 725);
    expect(store.hearts, 3);
    expect(store.freeHints, 8);
    expect(store.extraMovesBoosters, 4);
    expect(store.comboShields, 6);
    expect(
      await prefs.getInt('economy_config_version'),
      EconomyConfig.current.schemaVersion,
    );

    final reloaded = ProgressStore();
    await reloaded.load();
    expect(reloaded.coins, 725);
    expect(reloaded.hearts, 3);
    expect(reloaded.freeHints, 8);
    expect(reloaded.extraMovesBoosters, 4);
    expect(reloaded.comboShields, 6);
  });

  test('future economy versions fail closed without rewriting wallet', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 333);
    await prefs.setInt(
      'economy_config_version',
      EconomyConfig.current.schemaVersion + 1,
    );

    final store = ProgressStore();
    await expectLater(store.load(), throwsStateError);

    expect(await prefs.getInt('coins'), 333);
    expect(
      await prefs.getInt('economy_config_version'),
      EconomyConfig.current.schemaVersion + 1,
    );
  });

  test('shop production wrappers use authoritative v1 offer values', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 1000);
    await prefs.setInt('hearts', 2);

    final store = ProgressStore();
    await store.load();

    expect(await store.purchaseShopHeartOffer('heart_single'), isTrue);
    expect(store.hearts, 3);
    expect(store.coins, 880);

    expect(await store.purchaseShopBooster('hint'), isTrue);
    expect(store.freeHints, EconomyConfig.current.player.startingFreeHints + 3);
    expect(store.coins, 700);

    expect(await store.purchaseShopTheme('sunset'), isTrue);
    expect(store.isThemeUnlocked('sunset'), isTrue);
    expect(store.selectedTheme, 'sunset');
    expect(store.coins, 0);
  });

  test('shop production wrappers reject unknown configured targets', () async {
    final store = ProgressStore();
    await store.load();

    await expectLater(
      store.purchaseShopHeartOffer('not-an-offer'),
      throwsArgumentError,
    );
    await expectLater(store.purchaseShopBooster('unknown'), throwsArgumentError);
    await expectLater(store.purchaseShopTheme('unknown'), throwsArgumentError);
  });
}
