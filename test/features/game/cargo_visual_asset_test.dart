import 'package:cargo_sort_game/core/assets/game_manifest_asset_view.dart';
import 'package:cargo_sort_game/features/game/cargo_visual_asset.dart';
import 'package:cargo_sort_game/features/game/cargo_visual_catalog.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(GameManifestAssetView.resetRegistryCache);

  testWidgets(
    'missing cargo runtime binary keeps the explicit Flutter fallback',
    (tester) async {
      final item = productCatalog.first;
      const fallbackKey = ValueKey<String>('ast007-fallback');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CargoVisualAsset(
                item: item,
                levelNumber: 1,
                width: 48,
                height: 48,
                fallback: Icon(item.icon, key: fallbackKey),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(fallbackKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('same level and archetype expose one stable visual identity', (
    tester,
  ) async {
    final item = productCatalog[3];
    final variant = CargoVisualCatalog.resolve(
      levelNumber: 57,
      archetypeId: item.id,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (var index = 0; index < 3; index++)
              CargoVisualAsset(
                item: item,
                levelNumber: 57,
                fallback: Icon(item.icon),
              ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(ValueKey<String>('cargo-visual-${variant.assetId}')),
      findsNWidgets(3),
    );
  });
}
