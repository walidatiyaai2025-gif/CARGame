import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'game_asset.dart';

@immutable
final class GameImageDecodeTarget {
  const GameImageDecodeTarget({
    required this.width,
    required this.height,
    required this.estimatedBytes,
  });

  final int width;
  final int height;
  final int estimatedBytes;

  int get pixels => width * height;
}

@immutable
final class GameImageMemoryPolicy {
  const GameImageMemoryPolicy({
    this.globalCacheEntries = 96,
    this.globalCacheBytes = 48 * 1024 * 1024,
    this.maxDecodedImageBytes = 6 * 1024 * 1024,
    this.maxDecodeDimension = 1536,
    this.defaultPrecachePhysicalExtent = 1024,
  }) : assert(globalCacheEntries > 0),
       assert(globalCacheBytes > 0),
       assert(maxDecodedImageBytes > 0),
       assert(maxDecodeDimension > 0),
       assert(defaultPrecachePhysicalExtent > 0);

  static const GameImageMemoryPolicy standard = GameImageMemoryPolicy();
  static const int bytesPerPixel = 4;

  final int globalCacheEntries;
  final int globalCacheBytes;
  final int maxDecodedImageBytes;
  final int maxDecodeDimension;
  final int defaultPrecachePhysicalExtent;

  void configureImageCache(ImageCache cache) {
    cache.maximumSize = globalCacheEntries;
    cache.maximumSizeBytes = globalCacheBytes;
  }

  GameImageDecodeTarget targetForDisplay({
    required GameAssetDimensions native,
    required double devicePixelRatio,
    double? logicalWidth,
    double? logicalHeight,
    BoxFit fit = BoxFit.contain,
  }) {
    final safeDpr = devicePixelRatio.isFinite && devicePixelRatio > 0
        ? devicePixelRatio
        : 1.0;
    final width = _positiveFinite(logicalWidth);
    final height = _positiveFinite(logicalHeight);

    if (width == null && height == null) {
      return targetForPrecache(native);
    }

    final physicalWidth = width == null ? null : width * safeDpr;
    final physicalHeight = height == null ? null : height * safeDpr;
    final requestedScale = _scaleForBox(
      native: native,
      physicalWidth: physicalWidth,
      physicalHeight: physicalHeight,
      fit: fit,
    );
    return _boundedTarget(native, requestedScale);
  }

  GameImageDecodeTarget targetForPrecache(GameAssetDimensions native) {
    final longestSide = math.max(native.width, native.height);
    final requestedScale = defaultPrecachePhysicalExtent / longestSide;
    return _boundedTarget(native, requestedScale);
  }

  ImageProvider<Object> resizeProvider(
    AssetImage provider,
    GameImageDecodeTarget target,
  ) {
    return ResizeImage.resizeIfNeeded(target.width, target.height, provider);
  }

  double _scaleForBox({
    required GameAssetDimensions native,
    required double? physicalWidth,
    required double? physicalHeight,
    required BoxFit fit,
  }) {
    if (physicalWidth != null && physicalHeight != null) {
      final widthScale = physicalWidth / native.width;
      final heightScale = physicalHeight / native.height;
      return switch (fit) {
        BoxFit.contain || BoxFit.scaleDown => math.min(widthScale, heightScale),
        BoxFit.fitWidth => widthScale,
        BoxFit.fitHeight => heightScale,
        BoxFit.cover ||
        BoxFit.fill ||
        BoxFit.none => math.max(widthScale, heightScale),
      };
    }
    if (physicalWidth != null) return physicalWidth / native.width;
    return physicalHeight! / native.height;
  }

  GameImageDecodeTarget _boundedTarget(
    GameAssetDimensions native,
    double requestedScale,
  ) {
    var scale = requestedScale.isFinite && requestedScale > 0
        ? requestedScale
        : 1.0;

    // Never upsample beyond the authored asset dimensions.
    scale = math.min(scale, 1.0);

    final longestSide = math.max(native.width, native.height);
    scale = math.min(scale, maxDecodeDimension / longestSide);

    final nativeBytes = native.width * native.height * bytesPerPixel;
    if (nativeBytes > maxDecodedImageBytes) {
      scale = math.min(scale, math.sqrt(maxDecodedImageBytes / nativeBytes));
    }

    // Floor keeps the estimated RGBA footprint on the conservative side of
    // the configured byte ceiling after floating-point scale calculations.
    final width = math.max(1, (native.width * scale).floor());
    final height = math.max(1, (native.height * scale).floor());
    final bytes = width * height * bytesPerPixel;
    return GameImageDecodeTarget(
      width: width,
      height: height,
      estimatedBytes: bytes,
    );
  }

  static double? _positiveFinite(double? value) {
    if (value == null || !value.isFinite || value <= 0) return null;
    return value;
  }
}
