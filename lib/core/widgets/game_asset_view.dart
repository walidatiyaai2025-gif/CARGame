import 'package:flutter/material.dart';

import '../assets/game_asset.dart';
import '../assets/game_asset_registry.dart';

class GameAssetView extends StatelessWidget {
  const GameAssetView({
    super.key,
    required this.asset,
    this.registry,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final GameAssetDescriptor asset;
  final GameAssetRegistry? registry;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: width,
      height: height,
      child: _buildImage(context, asset, <String>{asset.id}),
    );

    if (asset.semantics.decorative) {
      return ExcludeSemantics(child: content);
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? asset.semantics.englishConcept,
      child: ExcludeSemantics(child: content),
    );
  }

  Widget _buildImage(
    BuildContext context,
    GameAssetDescriptor descriptor,
    Set<String> visited,
  ) => Image.asset(
    descriptor.path,
    width: width,
    height: height,
    fit: fit,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stackTrace) => _buildFallback(
      context,
      descriptor,
      visited,
    ),
  );

  Widget _buildFallback(
    BuildContext context,
    GameAssetDescriptor descriptor,
    Set<String> visited,
  ) {
    final fallback = descriptor.fallback;
    switch (fallback.kind) {
      case GameAssetFallbackKind.asset:
        final fallbackAsset = registry?.find(fallback.token);
        if (fallbackAsset != null && !visited.contains(fallbackAsset.id)) {
          return _buildImage(
            context,
            fallbackAsset,
            {...visited, fallbackAsset.id},
          );
        }
        return _genericFallback(descriptor.id);
      case GameAssetFallbackKind.icon:
        return Center(
          child: Icon(
            _iconForToken(fallback.token),
            key: ValueKey('asset-fallback:${descriptor.id}'),
            size: _fallbackIconSize(),
          ),
        );
      case GameAssetFallbackKind.text:
        return Center(
          child: Text(
            fallback.token,
            key: ValueKey('asset-fallback:${descriptor.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        );
      case GameAssetFallbackKind.none:
        return _genericFallback(descriptor.id);
    }
  }

  Widget _genericFallback(String id) => Center(
    child: Icon(
      Icons.image_not_supported_rounded,
      key: ValueKey('asset-fallback:$id'),
      size: _fallbackIconSize(),
    ),
  );

  double _fallbackIconSize() {
    final shortest = switch ((width, height)) {
      (final double w, final double h) => w < h ? w : h,
      (final double w, null) => w,
      (null, final double h) => h,
      _ => 32.0,
    };
    return shortest.clamp(18.0, 64.0).toDouble();
  }

  static IconData _iconForToken(String token) => switch (token) {
    'lock' => Icons.lock_rounded,
    'local_drink' => Icons.local_drink_rounded,
    'inventory' => Icons.inventory_2_rounded,
    'star' => Icons.star_rounded,
    'favorite' => Icons.favorite_rounded,
    'paid' => Icons.paid_rounded,
    'redeem' => Icons.redeem_rounded,
    _ => Icons.image_not_supported_rounded,
  };
}
