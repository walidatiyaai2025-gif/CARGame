import 'dart:typed_data';

import 'package:cargo_sort_game/core/assets/game_asset.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';
import 'package:cargo_sort_game/core/widgets/game_asset_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('missing bundle asset renders a visible icon fallback', (tester) async {
    final asset = _descriptor(
      id: 'ui.coin',
      path: 'assets/3d/runtime/ui/resources/cg_ui_coin_pui_v01.webp',
      fallback: const GameAssetFallback(
        kind: GameAssetFallbackKind.icon,
        token: 'paid',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameAssetView(asset: asset, width: 48, height: 48),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('asset-fallback:ui.coin')), findsOneWidget);
    expect(find.byIcon(Icons.paid_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('corrupt image bytes render fallback without escaping an exception', (
    tester,
  ) async {
    final asset = _descriptor(
      id: 'ui.star',
      path: 'assets/3d/runtime/ui/resources/cg_ui_star_pui_v01.webp',
      fallback: const GameAssetFallback(
        kind: GameAssetFallbackKind.icon,
        token: 'star',
      ),
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _CorruptAssetBundle(),
        child: MaterialApp(
          home: Scaffold(
            body: GameAssetView(asset: asset, width: 52, height: 52),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('asset-fallback:ui.star')), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registered fallback chains terminate when a cycle is detected', (
    tester,
  ) async {
    final registry = GameAssetRegistry.fromJsonString(_cyclicManifest);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameAssetView(
            asset: registry.require('ui.primary'),
            registry: registry,
            width: 56,
            height: 56,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('asset-fallback:ui.secondary')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.image_not_supported_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meaningful assets expose one image semantic label', (tester) async {
    final asset = _descriptor(
      id: 'ui.coin',
      path: 'assets/3d/runtime/ui/resources/cg_ui_coin_pui_v01.webp',
      fallback: const GameAssetFallback(
        kind: GameAssetFallbackKind.text,
        token: 'COIN',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameAssetView(
            asset: asset,
            semanticLabel: 'Coin balance',
            width: 48,
            height: 48,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Coin balance'), findsOneWidget);
    expect(find.text('COIN'), findsOneWidget);
  });

  testWidgets('decorative assets do not expose image semantics', (tester) async {
    final asset = GameAssetDescriptor(
      id: 'effect.sparkle',
      path: 'assets/3d/runtime/effects/cg_effect_sparkle_pui_v01.webp',
      category: GameAssetCategory.effect,
      semantics: const GameAssetSemantics(
        englishConcept: 'Decorative sparkle',
        localizationKey: '',
        decorative: true,
      ),
      fallback: const GameAssetFallback(
        kind: GameAssetFallbackKind.none,
        token: '',
      ),
      dimensions: const GameAssetDimensions(width: 256, height: 256),
      rarity: GameAssetRarity.common,
      world: null,
      profile: GameAssetProfile.pui,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameAssetView(asset: asset, width: 40, height: 40),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Decorative sparkle'), findsNothing);
    expect(
      find.byKey(const ValueKey('asset-fallback:effect.sparkle')),
      findsOneWidget,
    );
  });
}

GameAssetDescriptor _descriptor({
  required String id,
  required String path,
  required GameAssetFallback fallback,
}) => GameAssetDescriptor(
  id: id,
  path: path,
  category: GameAssetCategory.ui,
  semantics: const GameAssetSemantics(
    englishConcept: 'Game resource',
    localizationKey: 'assetGameResource',
    decorative: false,
  ),
  fallback: fallback,
  dimensions: const GameAssetDimensions(width: 256, height: 256),
  rarity: GameAssetRarity.common,
  world: null,
  profile: GameAssetProfile.pui,
);

class _CorruptAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(<int>[0, 1, 2, 3, 4, 5]);
    return ByteData.view(bytes.buffer);
  }
}

const _cyclicManifest = '''
{
  "schemaVersion": 1,
  "assets": [
    {
      "id": "ui.primary",
      "path": "assets/3d/runtime/ui/resources/cg_ui_primary_pui_v01.webp",
      "category": "ui",
      "semantics": {
        "englishConcept": "Primary resource",
        "localizationKey": "assetPrimary",
        "decorative": false
      },
      "fallback": {"kind": "asset", "token": "ui.secondary"},
      "dimensions": {"width": 256, "height": 256},
      "rarity": "common",
      "world": null,
      "profile": "pui"
    },
    {
      "id": "ui.secondary",
      "path": "assets/3d/runtime/ui/resources/cg_ui_secondary_pui_v01.webp",
      "category": "ui",
      "semantics": {
        "englishConcept": "Secondary resource",
        "localizationKey": "assetSecondary",
        "decorative": false
      },
      "fallback": {"kind": "asset", "token": "ui.primary"},
      "dimensions": {"width": 256, "height": 256},
      "rarity": "common",
      "world": null,
      "profile": "pui"
    }
  ]
}
''';
