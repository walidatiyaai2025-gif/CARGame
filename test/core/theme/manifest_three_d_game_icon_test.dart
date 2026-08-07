import 'package:cargo_sort_game/core/assets/game_manifest_asset_view.dart';
import 'package:cargo_sort_game/core/theme/manifest_three_d_game_icon.dart';
import 'package:cargo_sort_game/core/theme/three_d_game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(GameManifestAssetView.resetRegistryCache);

  testWidgets('dynamic unregistered asset falls back to procedural 3D icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ManifestThreeDGameIcon(
            assetId: 'city.harbor.missing',
            type: ThreeDIconType.city,
            semanticLabel: 'Harbor city',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ThreeDGameIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registered asset with missing binary preserves procedural fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ManifestThreeDGameIcon(
            assetId: 'ui.heart',
            type: ThreeDIconType.heart,
            semanticLabel: 'Heart energy',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ThreeDGameIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
