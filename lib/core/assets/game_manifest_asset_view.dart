import 'package:flutter/material.dart';

import 'game_asset_manifest.dart';
import 'game_asset_registry.dart';
import 'game_asset_view.dart';

/// Runtime bridge between a stable manifest asset ID and an existing safe UI
/// fallback. Manifest loading is cached for the process lifetime so individual
/// widgets never trigger repeated bundle reads.
final class GameManifestAssetView extends StatelessWidget {
  const GameManifestAssetView({
    super.key,
    required this.assetId,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final String assetId;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  static Future<GameAssetRegistry>? _registryFuture;

  static Future<GameAssetRegistry> _loadRegistry() =>
      _registryFuture ??= GameAssetManifest.load();

  @visibleForTesting
  static void resetRegistryCache() {
    _registryFuture = null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameAssetRegistry>(
      future: _loadRegistry(),
      builder: (context, snapshot) {
        final registry = snapshot.data;
        if (registry == null || !registry.contains(assetId)) {
          return fallback;
        }

        return GameAssetView(
          assetId: assetId,
          registry: registry,
          width: width,
          height: height,
          fit: fit,
          semanticLabel: semanticLabel,
        );
      },
    );
  }
}
