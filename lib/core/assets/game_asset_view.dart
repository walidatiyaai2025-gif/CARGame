import 'package:flutter/material.dart';

import 'game_asset.dart';
import 'game_asset_registry.dart';

final class GameAssetView extends StatelessWidget {
  const GameAssetView({
    super.key,
    required this.assetId,
    required this.registry,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final String assetId;
  final GameAssetRegistry registry;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _buildById(context, assetId, <String>{});
  }

  Widget _buildById(BuildContext context, String id, Set<String> visited) {
    if (!visited.add(id)) {
      return _placeholder(context, 'fallback-cycle');
    }

    final descriptor = registry.find(id);
    if (descriptor == null) {
      return _placeholder(context, 'unregistered');
    }

    final image = Image.asset(
      descriptor.path,
      width: width,
      height: height,
      fit: fit,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        return _fallbackFor(context, descriptor, visited);
      },
    );

    if (descriptor.semantics.decorative) {
      return ExcludeSemantics(child: image);
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? descriptor.semantics.englishConcept,
      child: image,
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
        return _iconFallback(context, fallback.token, descriptor);
      case GameAssetFallbackKind.text:
        return _textFallback(context, fallback.token, descriptor);
      case GameAssetFallbackKind.none:
        return _placeholder(context, 'no-fallback', descriptor: descriptor);
    }
  }

  Widget _iconFallback(
    BuildContext context,
    String token,
    GameAssetDescriptor descriptor,
  ) {
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

    return _semanticFallback(
      descriptor,
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(child: Icon(icon, size: _fallbackIconSize)),
        ),
      ),
    );
  }

  Widget _textFallback(
    BuildContext context,
    String token,
    GameAssetDescriptor descriptor,
  ) {
    return _semanticFallback(
      descriptor,
      DecoratedBox(
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
      ),
    );
  }

  Widget _placeholder(
    BuildContext context,
    String reason, {
    GameAssetDescriptor? descriptor,
  }) {
    return Semantics(
      image: true,
      label:
          semanticLabel ??
          descriptor?.semantics.englishConcept ??
          'Game asset unavailable',
      value: reason,
      child: DecoratedBox(
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
      ),
    );
  }

  Widget _semanticFallback(GameAssetDescriptor descriptor, Widget child) {
    if (descriptor.semantics.decorative) {
      return ExcludeSemantics(child: child);
    }
    return Semantics(
      image: true,
      label: semanticLabel ?? descriptor.semantics.englishConcept,
      child: child,
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
