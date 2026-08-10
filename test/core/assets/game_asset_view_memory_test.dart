import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:cargo_sort_game/core/assets/game_asset_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'GameAssetView passes a near-display decode target to Image.asset',
    (tester) async {
      final registry = GameAssetRegistry.fromJsonString(_manifest);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2),
          child: MaterialApp(
            home: Center(
              child: GameAssetView(
                assetId: 'ui.hero',
                registry: registry,
                width: 100,
                height: 50,
              ),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
      final provider = image.image as ResizeImage;
      expect(provider.width, 200);
      expect(provider.height, 100);
      expect(provider.allowUpscaling, isFalse);
    },
  );

  testWidgets('unbounded layout hints still use a bounded decode target', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_manifest);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 3),
        child: MaterialApp(
          home: Center(
            child: GameAssetView(assetId: 'world.hero', registry: registry),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, 1024);
    expect(provider.height, 512);
  });
}

const _manifest = '''
{
  "schemaVersion": 1,
  "assets": [
    {
      "id": "ui.hero",
      "path": "assets/3d/runtime/ui/cg_ui_hero_pui_v01.webp",
      "category": "ui",
      "semantics": {"englishConcept":"Hero","localizationKey":"hero","decorative":false},
      "fallback": {"kind":"icon","token":"star"},
      "dimensions": {"width":2000,"height":1000},
      "rarity": "common",
      "world": null,
      "profile": "pui"
    },
    {
      "id": "world.hero",
      "path": "assets/3d/runtime/world/cg_world_hero_phero_v01.webp",
      "category": "world",
      "semantics": {"englishConcept":"World","localizationKey":"world","decorative":false},
      "fallback": {"kind":"icon","token":"star"},
      "dimensions": {"width":4000,"height":2000},
      "rarity": "common",
      "world": "harbor",
      "profile": "phero"
    }
  ]
}
''';
