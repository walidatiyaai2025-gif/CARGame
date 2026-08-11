import 'package:cargo_sort_game/core/assets/game_manifest_asset_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(GameManifestAssetView.resetRegistryCache);

  testWidgets(
    'registered missing runtime asset resolves to manifest fallback',
    (tester) async {
      await tester.runAsync(() => GameManifestAssetView.preloadRegistry());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameManifestAssetView(
              assetId: 'ui.heart',
              width: 48,
              height: 48,
              fallback: Text('legacy-heart'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('legacy-heart'), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unregistered ID keeps the existing safe UI fallback', (
    tester,
  ) async {
    await tester.runAsync(() => GameManifestAssetView.preloadRegistry());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameManifestAssetView(
            assetId: 'ui.not_registered',
            width: 48,
            height: 48,
            fallback: Text('legacy-safe'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('legacy-safe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
