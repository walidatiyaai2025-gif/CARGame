import 'package:flutter/material.dart';

import '../../core/assets/game_manifest_asset_view.dart';
import 'cargo_visual_catalog.dart';
import 'level_data.dart';

/// Resolves AST-007 visual identity without changing CargoItem gameplay truth.
final class CargoVisualAsset extends StatelessWidget {
  const CargoVisualAsset({
    super.key,
    required this.item,
    required this.levelNumber,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final CargoItem item;
  final int levelNumber;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final visual = CargoVisualCatalog.resolve(
      levelNumber: levelNumber,
      archetypeId: item.id,
    );
    return KeyedSubtree(
      key: ValueKey<String>('cargo-visual-${visual.assetId}'),
      child: GameManifestAssetView(
        assetId: visual.assetId,
        fallback: fallback,
        errorFallback: fallback,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel ?? item.name,
      ),
    );
  }
}
