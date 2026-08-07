import 'package:flutter/material.dart';

import '../assets/game_manifest_asset_view.dart';
import 'three_d_game_icon.dart';

/// Manifest-backed 3D icon for dynamic IDs such as cities, bosses, and rewards.
///
/// The procedural [ThreeDGameIcon] remains the guaranteed visual fallback, so a
/// missing, corrupt, or not-yet-admitted runtime asset never leaves an empty slot.
final class ManifestThreeDGameIcon extends StatelessWidget {
  const ManifestThreeDGameIcon({
    super.key,
    required this.assetId,
    required this.type,
    this.size = 48,
    this.animate = false,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  final String assetId;
  final ThreeDIconType type;
  final double size;
  final bool animate;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = ThreeDGameIcon(
      type: type,
      size: size,
      animate: animate,
      semanticLabel: semanticLabel,
    );

    return GameManifestAssetView(
      assetId: assetId,
      width: size,
      height: size,
      fit: fit,
      semanticLabel: semanticLabel,
      fallback: fallback,
      errorFallback: fallback,
    );
  }
}
