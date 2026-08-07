import 'package:cargo_sort_game/core/assets/game_manifest_asset_view.dart';
import 'package:cargo_sort_game/core/theme/three_d_game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(GameManifestAssetView.resetRegistryCache);

  testWidgets('manifest-backed resource icon keeps procedural 3D fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ThreeDGameIcon(
              type: ThreeDIconType.heart,
              size: 48,
              semanticLabel: 'Energy',
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(ThreeDGameIcon),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Energy'), findsOneWidget);
  });

  testWidgets('unregistered icon type renders procedural path immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ThreeDGameIcon(type: ThreeDIconType.city, size: 52),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(ThreeDGameIcon),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('city'), findsOneWidget);
  });
}
