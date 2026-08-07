import 'dart:convert';

import 'package:cargo_sort_game/core/assets/game_asset_cache_policy.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _heartPath = 'assets/3d/runtime/ui/cg_ui_heart_pui_v01.webp';
const _coinPath = 'assets/3d/runtime/ui/cg_ui_coin_pui_v01.webp';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('precache is bounded and evicts the least recently used entry', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);
    final policy = GameAssetCachePolicy(maxEntries: 1);
    final bundle = _MemoryBinaryBundle({
      'AssetManifest.bin': _assetManifestBin([_heartPath, _coinPath]),
      _heartPath: _onePixelPng,
      _coinPath: _onePixelPng,
    });
    late BuildContext context;

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(
      await _precacheWithFrame(tester, policy, context, registry, 'ui.heart'),
      isTrue,
    );
    expect(policy.snapshot.cachedIds, ['ui.heart']);

    expect(
      await _precacheWithFrame(tester, policy, context, registry, 'ui.coin'),
      isTrue,
    );
    expect(policy.snapshot.cachedIds, ['ui.coin']);
    expect(policy.snapshot.cachedCount, 1);
    expect(policy.snapshot.inFlightCount, 0);
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
}

Future<bool> _precacheWithFrame(
  WidgetTester tester,
  GameAssetCachePolicy policy,
  BuildContext context,
  GameAssetRegistry registry,
  String assetId,
) async {
  final result = policy.precache(context, registry, assetId);
  await tester.pump();
  await tester.pump();
  return result;
}

final class _MemoryBinaryBundle extends CachingAssetBundle {
  _MemoryBinaryBundle(this.assets);

  final Map<String, Uint8List> assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = assets[key];
    if (bytes == null) throw StateError('Missing fake asset: $key');
    return ByteData.sublistView(bytes);
  }
}

Uint8List _assetManifestBin(Iterable<String> paths) {
  final data = const StandardMessageCodec().encodeMessage(<String, Object?>{
    for (final path in paths)
      path: <Object?>[
        <String, Object?>{'asset': path},
      ],
  });
  if (data == null) {
    throw StateError('Unable to encode the fake AssetManifest.bin');
  }
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

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
