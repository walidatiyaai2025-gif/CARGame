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
  static GameAssetRegistry? _registry;

  /// Starts (or joins) the one process-wide manifest load.
  ///
  /// Callers that need a deterministic ready boundary, such as startup warmup
  /// or widget tests, can await this without causing a second bundle read.
  static Future<GameAssetRegistry> preloadRegistry() {
    final registry = _registry;
    if (registry != null) {
      return Future<GameAssetRegistry>.value(registry);
    }

    final inFlight = _registryFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final load = GameAssetManifest.load().then((loaded) {
      _registry = loaded;
      return loaded;
    });
    _registryFuture = load;
    return load;
  }

  @visibleForTesting
  static void resetRegistryCache() {
    _registryFuture = null;
    _registry = null;
  }

  Widget _buildResolved(GameAssetRegistry registry) {
    if (!registry.contains(assetId)) {
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
  }

  @override
  Widget build(BuildContext context) {
    final registry = _registry;
    if (registry != null) {
      return _buildResolved(registry);
    }

    return FutureBuilder<GameAssetRegistry>(
      future: preloadRegistry(),
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded == null) {
          return fallback;
        }
        return _buildResolved(loaded);
      },
    );
  }
}