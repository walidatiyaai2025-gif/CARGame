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

  testWidgets('asset fallback preserves the requested semantic identity', (
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
      "fallback": {"kind": "asset", "token": "cargo.generic_drink.closed"},
      "dimensions": {"width": 384, "height": 384},
      "rarity": "common",
      "world": "harbor",
      "profile": "pcargo"
    },
    {
      "id": "cargo.generic_drink.closed",
      "path": "assets/3d/runtime/cargo/beverage/cg_cargo_generic_drink_closed_pcargo_v01.webp",
      "category": "cargo",
      "semantics": {
        "englishConcept": "Generic drink bottle",
        "localizationKey": "assetGenericDrink",
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
    expect(find.bySemanticsLabel('Orange juice bottle'), findsOneWidget);
    expect(find.bySemanticsLabel('Generic drink bottle'), findsNothing);
  });

  testWidgets('decorative assets remain excluded when their fallback is visible', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString('''
{
  "schemaVersion": 1,
  "assets": [
    {
      "id": "effect.sparkle.default",
      "path": "assets/3d/runtime/effects/cg_effect_sparkle_default_pui_v01.webp",
      "category": "effect",
      "semantics": {
        "englishConcept": "Decorative sparkle",
        "localizationKey": "",
        "decorative": true
      },
      "fallback": {"kind": "icon", "token": "star"},
      "dimensions": {"width": 256, "height": 256},
      "rarity": "common",
      "world": null,
      "profile": "pui"
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
              assetId: 'effect.sparkle.default',
              registry: registry,
              width: 64,
              height: 64,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Decorative sparkle'), findsNothing);
  });
}

final class _MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    throw FlutterError('Missing test asset: $key');
  }
}
