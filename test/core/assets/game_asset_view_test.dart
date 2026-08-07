import 'dart:typed_data';

import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:cargo_sort_game/core/assets/game_asset_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unregistered IDs render a visible placeholder without throwing', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(
      '{"schemaVersion":1,"assets":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameAssetView(
            assetId: 'cargo.unknown.default',
            registry: registry,
            width: 96,
            height: 96,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_not_supported_rounded), findsOneWidget);
  });

  testWidgets('missing bundled files use the registered icon fallback', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString('''
{
  "schemaVersion": 1,
  "assets": [
    {
      "id": "cargo.orange_juice.closed",
      "path": "assets/3d/runtime/cargo/beverage/cg_cargo_orange_juice_closed_pcargo_v01.webp",
      "category": "cargo",
      "semantics": {
        "englishConcept": "Orange juice bottle",
        "localizationKey": "assetOrangeJuice",
        "decorative": false
      },
      "fallback": {"kind": "icon", "token": "local_drink"},
      "dimensions": {"width": 384, "height": 384},
      "rarity": "common",
      "world": "harbor",
      "profile": "pcargo"
    }
  ]
}
''');

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _MissingAssetBundle(),
        child: MaterialApp(
          home: Scaffold(
            body: GameAssetView(
              assetId: 'cargo.orange_juice.closed',
              registry: registry,
              width: 96,
              height: 96,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.local_drink_rounded), findsOneWidget);
  });
}

final class _MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    throw FlutterError('Missing test asset: $key');
  }
}
