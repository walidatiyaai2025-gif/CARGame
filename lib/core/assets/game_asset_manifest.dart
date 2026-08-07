import 'package:flutter/services.dart';

import 'game_asset_registry.dart';

final class GameAssetManifest {
  const GameAssetManifest._();

  static const String assetPath = 'assets/3d/manifest.json';

  static Future<GameAssetRegistry> load({AssetBundle? bundle}) async {
    final source = await (bundle ?? rootBundle).loadString(assetPath);
    return GameAssetRegistry.fromJsonString(source);
  }
}
