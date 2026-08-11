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
    this.errorFallback,
  });

  final String assetId;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final Widget? errorFallback;

  static Future<GameAssetRegistry>? _registryFuture;

  /// Starts (or joins) the one process-wide manifest load.
  ///
  /// Callers that need a deterministic ready boundary, such as startup warmup
  /// or widget tests, can await this without causing a second bundle read.
  static Future<GameAssetRegistry> preloadRegistry() =>
      _registryFuture ??= GameAssetManifest.load();

  @visibleForTesting
  static void resetRegistryCache() {
    _registryFuture = null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameAssetRegistry>(
      future: preloadRegistry(),
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
          errorFallback: errorFallback,
        );
      },
    );
  }
}