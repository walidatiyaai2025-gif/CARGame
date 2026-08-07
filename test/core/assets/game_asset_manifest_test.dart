import 'dart:convert';

import 'package:cargo_sort_game/core/assets/game_asset_manifest.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the versioned manifest through an injected AssetBundle', () async {
    final bundle = _MemoryAssetBundle({
      GameAssetManifest.assetPath: '{"schemaVersion":1,"assets":[]}',
    });

    final registry = await GameAssetManifest.load(bundle: bundle);

    expect(registry.schemaVersion, 1);
    expect(registry.assets, isEmpty);
    expect(bundle.requestedKeys, [GameAssetManifest.assetPath]);
  });

  test('surfaces malformed manifest data as a FormatException', () async {
    final bundle = _MemoryAssetBundle({
      GameAssetManifest.assetPath: '{not-json',
    });

    expect(
      () => GameAssetManifest.load(bundle: bundle),
      throwsA(isA<FormatException>()),
    );
  });
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, String> assets;
  final List<String> requestedKeys = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    final value = assets[key];
    if (value == null) {
      throw StateError('Missing fake asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }
}
