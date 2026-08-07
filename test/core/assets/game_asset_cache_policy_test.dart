import 'package:cargo_sort_game/core/assets/game_asset_cache_policy.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _heartPath = 'assets/3d/runtime/ui/cg_ui_heart_pui_v01.webp';
const _coinPath = 'assets/3d/runtime/ui/cg_ui_coin_pui_v01.webp';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('precache is bounded and evicts the least recently used entry', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final evicted = <String>[];
    final policy = GameAssetCachePolicy(
      maxEntries: 1,
      precacheLoader: (_, _) async {},
      evictor: (provider) async => evicted.add(provider.assetName),
    );
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(policy.snapshot.cachedIds, ['ui.heart']);

    expect(await policy.precache(context, registry, 'ui.coin'), isTrue);
    expect(policy.snapshot.cachedIds, ['ui.coin']);
    expect(policy.snapshot.cachedCount, 1);
    expect(policy.snapshot.inFlightCount, 0);
    expect(evicted, [_heartPath]);
  });

  testWidgets('unknown asset is isolated as a bounded failure', (tester) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(maxEntries: 1);
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(await policy.precache(context, registry, 'ui.missing'), isFalse);
    expect(policy.hasFailed('ui.missing'), isTrue);

    expect(await policy.precache(context, registry, 'ui.other_missing'), isFalse);
    expect(policy.snapshot.failedIds, ['ui.other_missing']);
    expect(policy.snapshot.failedCount, 1);
  });

  testWidgets('near-future precache deduplicates IDs and respects its limit', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(maxEntries: 4);
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    await policy.precacheNearFuture(
      context,
      registry,
      const ['missing.a', 'missing.a', 'missing.b', 'missing.c'],
      limit: 2,
    );

    expect(policy.snapshot.failedIds, ['missing.a', 'missing.b']);
  });

  testWidgets('precache loader failures stay isolated and observable', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(
      precacheLoader: (_, _) async => throw StateError('decode failed'),
    );
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(await policy.precache(context, registry, 'ui.heart'), isFalse);
    expect(policy.hasFailed('ui.heart'), isTrue);
    expect(policy.snapshot.inFlightCount, 0);
  });
}

const _manifest = '''
{
  "schemaVersion": 1,
  "assets": [
    {
      "id": "ui.heart",
      "path": "$_heartPath",
      "category": "ui",
      "semantics": {"englishConcept":"Heart","localizationKey":"hearts","decorative":false},
      "fallback": {"kind":"icon","token":"favorite"},
      "dimensions": {"width":256,"height":256},
      "rarity": "common",
      "world": null,
      "profile": "pui"
    },
    {
      "id": "ui.coin",
      "path": "$_coinPath",
      "category": "ui",
      "semantics": {"englishConcept":"Coin","localizationKey":"coins","decorative":false},
      "fallback": {"kind":"icon","token":"paid"},
      "dimensions": {"width":256,"height":256},
      "rarity": "common",
      "world": null,
      "profile": "pui"
    }
  ]
}
''';
