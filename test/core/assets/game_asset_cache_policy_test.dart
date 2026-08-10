import 'dart:async';

import 'package:cargo_sort_game/core/assets/game_asset_cache_policy.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _heartPath = 'assets/3d/runtime/ui/cg_ui_heart_pui_v01.webp';
const _coinPath = 'assets/3d/runtime/ui/cg_ui_coin_pui_v01.webp';
const _starPath = 'assets/3d/runtime/ui/cg_ui_star_pui_v01.webp';

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
    final context = await _pumpContext(tester);

    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(await policy.precache(context, registry, 'ui.coin'), isTrue);

    expect(policy.snapshot.cachedIds, ['ui.coin']);
    expect(policy.snapshot.cachedCount, 1);
    expect(policy.snapshot.inFlightCount, 0);
    expect(policy.snapshot.evictionCount, 1);
    expect(evicted, [_heartPath]);
  });

  testWidgets('cache hits promote LRU order without reloading', (tester) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final evicted = <String>[];
    var loadCount = 0;
    final policy = GameAssetCachePolicy(
      maxEntries: 2,
      precacheLoader: (_, _) async => loadCount += 1,
      evictor: (provider) async => evicted.add(provider.assetName),
    );
    final context = await _pumpContext(tester);

    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(await policy.precache(context, registry, 'ui.coin'), isTrue);
    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(await policy.precache(context, registry, 'ui.star'), isTrue);

    expect(loadCount, 3);
    expect(policy.snapshot.cachedIds, ['ui.heart', 'ui.star']);
    expect(policy.snapshot.hitCount, 1);
    expect(evicted, [_coinPath]);
  });

  testWidgets('unknown assets form a bounded observable failure history', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(maxEntries: 2);
    final context = await _pumpContext(tester);

    expect(await policy.precache(context, registry, 'missing.a'), isFalse);
    expect(await policy.precache(context, registry, 'missing.b'), isFalse);
    expect(await policy.precache(context, registry, 'missing.c'), isFalse);

    expect(policy.snapshot.failedIds, ['missing.b', 'missing.c']);
    expect(policy.snapshot.failedCount, 2);
    expect(policy.snapshot.missCount, 3);
    expect(policy.snapshot.loadFailureCount, 3);
  });

  testWidgets('near-future precache deduplicates and clamps work to budget', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(maxEntries: 2);
    final context = await _pumpContext(tester);

    await policy.precacheNearFuture(context, registry, const [
      '',
      'missing.a',
      'missing.a',
      'missing.b',
      'missing.c',
    ], limit: 99);

    expect(policy.snapshot.failedIds, ['missing.a', 'missing.b']);
    expect(policy.snapshot.missCount, 2);
  });

  testWidgets(
    'automatic batches skip known failures unless retry is explicit',
    (tester) async {
      final registry = GameAssetRegistry.fromJsonString(_manifest);
      var loadCount = 0;
      final policy = GameAssetCachePolicy(
        precacheLoader: (_, _) async {
          loadCount += 1;
          throw StateError('decode failed');
        },
      );
      final context = await _pumpContext(tester);

      expect(await policy.precache(context, registry, 'ui.heart'), isFalse);
      await policy.precacheNearFuture(context, registry, const ['ui.heart']);
      expect(loadCount, 1);

      await policy.precacheNearFuture(context, registry, const [
        'ui.heart',
      ], retryFailed: true);
      expect(loadCount, 2);
    },
  );

  testWidgets('precache loader failures stay isolated and manually retryable', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    var shouldFail = true;
    final policy = GameAssetCachePolicy(
      precacheLoader: (_, _) async {
        if (shouldFail) throw StateError('decode failed');
      },
    );
    final context = await _pumpContext(tester);

    expect(await policy.precache(context, registry, 'ui.heart'), isFalse);
    expect(policy.hasFailed('ui.heart'), isTrue);
    shouldFail = false;
    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);

    expect(policy.hasFailed('ui.heart'), isFalse);
    expect(policy.snapshot.inFlightCount, 0);
    expect(policy.snapshot.successfulLoadCount, 1);
    expect(policy.snapshot.loadFailureCount, 1);
  });

  testWidgets('concurrent same-ID callers share one load result', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final gate = Completer<void>();
    var loadCount = 0;
    final policy = GameAssetCachePolicy(
      precacheLoader: (_, _) {
        loadCount += 1;
        return gate.future;
      },
    );
    final context = await _pumpContext(tester);

    final first = policy.precache(context, registry, 'ui.heart');
    final second = policy.precache(context, registry, 'ui.heart');

    expect(identical(first, second), isTrue);
    expect(loadCount, 1);
    expect(policy.snapshot.inFlightIds, ['ui.heart']);
    expect(policy.snapshot.joinedRequestCount, 1);

    gate.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(policy.snapshot.inFlightCount, 0);
    expect(policy.snapshot.successfulLoadCount, 1);
  });

  testWidgets('different asset IDs can load independently', (tester) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final heartGate = Completer<void>();
    final coinGate = Completer<void>();
    final started = <String>[];
    final policy = GameAssetCachePolicy(
      precacheLoader: (provider, _) {
        started.add(provider.assetName);
        return provider.assetName == _heartPath
            ? heartGate.future
            : coinGate.future;
      },
    );
    final context = await _pumpContext(tester);

    final heart = policy.precache(context, registry, 'ui.heart');
    final coin = policy.precache(context, registry, 'ui.coin');

    expect(started, [_heartPath, _coinPath]);
    expect(policy.snapshot.inFlightCount, 2);
    heartGate.complete();
    coinGate.complete();
    expect(await heart, isTrue);
    expect(await coin, isTrue);
    expect(policy.snapshot.cachedCount, 2);
  });

  testWidgets('clear during load prevents late cache resurrection', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final gate = Completer<void>();
    final evicted = <String>[];
    final policy = GameAssetCachePolicy(
      precacheLoader: (_, _) => gate.future,
      evictor: (provider) async => evicted.add(provider.assetName),
    );
    final context = await _pumpContext(tester);

    final pending = policy.precache(context, registry, 'ui.heart');
    await policy.clear();
    expect(policy.isInFlight('ui.heart'), isTrue);

    gate.complete();
    expect(await pending, isFalse);
    expect(policy.isCached('ui.heart'), isFalse);
    expect(policy.snapshot.inFlightCount, 0);
    expect(policy.snapshot.staleCompletionCount, 1);
    expect(evicted, [_heartPath]);
  });

  testWidgets('forget during load prevents late cache resurrection', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final gate = Completer<void>();
    final evicted = <String>[];
    final policy = GameAssetCachePolicy(
      precacheLoader: (_, _) => gate.future,
      evictor: (provider) async => evicted.add(provider.assetName),
    );
    final context = await _pumpContext(tester);

    final pending = policy.precache(context, registry, 'ui.heart');
    await policy.forget('ui.heart');
    expect(policy.isInFlight('ui.heart'), isTrue);

    gate.complete();
    expect(await pending, isFalse);
    expect(policy.isCached('ui.heart'), isFalse);
    expect(policy.hasFailed('ui.heart'), isFalse);
    expect(policy.snapshot.staleCompletionCount, 1);
    expect(evicted, [_heartPath]);
  });

  testWidgets('retry starts safely after an invalidated operation settles', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final firstGate = Completer<void>();
    var loadCount = 0;
    final policy = GameAssetCachePolicy(
      precacheLoader: (_, _) {
        loadCount += 1;
        return loadCount == 1 ? firstGate.future : Future<void>.value();
      },
      evictor: (_) async {},
    );
    final context = await _pumpContext(tester);

    final first = policy.precache(context, registry, 'ui.heart');
    await policy.forget('ui.heart');
    final joined = policy.precache(context, registry, 'ui.heart');
    expect(identical(first, joined), isTrue);
    expect(loadCount, 1);

    firstGate.complete();
    expect(await first, isFalse);
    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(loadCount, 2);
    expect(policy.isCached('ui.heart'), isTrue);
  });

  testWidgets('evictor failures never escape cache operations', (tester) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(
      maxEntries: 1,
      precacheLoader: (_, _) async {},
      evictor: (_) async => throw StateError('cache eviction failed'),
    );
    final context = await _pumpContext(tester);

    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(await policy.precache(context, registry, 'ui.coin'), isTrue);

    expect(policy.snapshot.cachedIds, ['ui.coin']);
    expect(policy.snapshot.evictionCount, 1);
    expect(policy.snapshot.evictionFailureCount, 1);
  });

  testWidgets('statistics reset does not mutate cache state', (tester) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(precacheLoader: (_, _) async {});
    final context = await _pumpContext(tester);

    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(await policy.precache(context, registry, 'ui.heart'), isTrue);
    expect(policy.snapshot.missCount, 1);
    expect(policy.snapshot.hitCount, 1);
    expect(policy.snapshot.successfulLoadCount, 1);

    policy.resetStatistics();

    expect(policy.snapshot.cachedIds, ['ui.heart']);
    expect(policy.snapshot.hitCount, 0);
    expect(policy.snapshot.missCount, 0);
    expect(policy.snapshot.successfulLoadCount, 0);
    expect(policy.snapshot.loadFailureCount, 0);
    expect(policy.snapshot.evictionCount, 0);
    expect(policy.snapshot.staleCompletionCount, 0);
  });

  testWidgets('snapshot collections are immutable', (tester) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(precacheLoader: (_, _) async {});
    final context = await _pumpContext(tester);

    await policy.precache(context, registry, 'ui.heart');
    final snapshot = policy.snapshot;

    expect(() => snapshot.cachedIds.add('ui.coin'), throwsUnsupportedError);
    expect(() => snapshot.inFlightIds.add('ui.coin'), throwsUnsupportedError);
    expect(() => snapshot.failedIds.add('missing.x'), throwsUnsupportedError);
  });
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
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
  return context;
}

const _manifest =
    '''
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
    },
    {
      "id": "ui.star",
      "path": "$_starPath",
      "category": "ui",
      "semantics": {"englishConcept":"Star","localizationKey":"stars","decorative":false},
      "fallback": {"kind":"icon","token":"star"},
      "dimensions": {"width":256,"height":256},
      "rarity": "common",
      "world": null,
      "profile": "pui"
    }
  ]
}
''';
