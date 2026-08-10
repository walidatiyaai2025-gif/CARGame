import 'package:flutter/material.dart';

import 'game_asset.dart';
import 'game_asset_registry.dart';
import 'game_image_memory_policy.dart';

final class GameAssetView extends StatelessWidget {
  const GameAssetView({
    super.key,
    required this.assetId,
    required this.registry,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.errorFallback,
    this.memoryPolicy = GameImageMemoryPolicy.standard,
  });

  final String assetId;
  final GameAssetRegistry registry;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final Widget? errorFallback;
  final GameImageMemoryPolicy memoryPolicy;

  @override
  Widget build(BuildContext context) {
    final descriptor = registry.find(assetId);
    final visual = _buildById(context, assetId, <String>{});

    if (descriptor == null) {
      return Semantics(
        image: true,
        label: semanticLabel ?? 'Game asset unavailable',
        value: 'unregistered',
        child: ExcludeSemantics(child: visual),
      );
    }

    if (descriptor.semantics.decorative && semanticLabel == null) {
      return ExcludeSemantics(child: visual);
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? descriptor.semantics.englishConcept,
      child: ExcludeSemantics(child: visual),
    );
  }

  Widget _buildById(BuildContext context, String id, Set<String> visited) {
    if (!visited.add(id)) {
      return errorFallback ?? _placeholder(context);
    }

    final descriptor = registry.find(id);
    if (descriptor == null) {
      return errorFallback ?? _placeholder(context);
    }

    final dpr =
        MediaQuery.maybeOf(context)?.devicePixelRatio ??
        View.of(context).devicePixelRatio;
    final decodeTarget = memoryPolicy.targetForDisplay(
      native: descriptor.dimensions,
      devicePixelRatio: dpr,
      logicalWidth: width,
      logicalHeight: height,
      fit: fit,
    );

    return Image.asset(
      descriptor.path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: decodeTarget.width,
      cacheHeight: decodeTarget.height,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        return errorFallback ?? _fallbackFor(context, descriptor, visited);
      },
    );
  }

  Widget _fallbackFor(
    BuildContext context,
    GameAssetDescriptor descriptor,
    Set<String> visited,
  ) {
    final fallback = descriptor.fallback;
    switch (fallback.kind) {
      case GameAssetFallbackKind.asset:
        return _buildById(context, fallback.token, <String>{...visited});
      case GameAssetFallbackKind.icon:
        return _iconFallback(context, fallback.token);
      case GameAssetFallbackKind.text:
        return _textFallback(context, fallback.token);
      case GameAssetFallbackKind.none:
        return _placeholder(context);
    }
  }

  Widget _iconFallback(BuildContext context, String token) {
    final icon = switch (token) {
      'favorite' => Icons.favorite_rounded,
      'paid' => Icons.monetization_on_rounded,
      'star' => Icons.star_rounded,
      'lock' => Icons.lock_rounded,
      'local_drink' => Icons.local_drink_rounded,
      'inventory' || 'inventory_2' => Icons.inventory_2_rounded,
      'redeem' => Icons.redeem_rounded,
      'bolt' => Icons.bolt_rounded,
      _ => Icons.category_rounded,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: Icon(icon, size: _fallbackIconSize)),
      ),
    );
  }

  Widget _textFallback(BuildContext context, String token) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            token,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            size: _fallbackIconSize,
          ),
        ),
      ),
    );
  }

  double get _fallbackIconSize {
    double shortest = 40;
    if (width != null && height != null) {
      shortest = width! < height! ? width! : height!;
    } else if (width != null) {
      shortest = width!;
    } else if (height != null) {
      shortest = height!;
    }
    return (shortest * 0.45).clamp(20.0, 56.0).toDouble();
  }
}
