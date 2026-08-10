import 'package:cargo_sort_game/core/assets/game_asset.dart';
import 'package:cargo_sort_game/core/assets/game_image_memory_policy.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameImageMemoryPolicy', () {
    test('configures explicit global ImageCache entry and byte ceilings', () {
      const policy = GameImageMemoryPolicy.standard;
      final cache = ImageCache();

      policy.configureImageCache(cache);

      expect(cache.maximumSize, 96);
      expect(cache.maximumSizeBytes, 48 * 1024 * 1024);
    });

    test('decodes a large image near its physical display size', () {
      const policy = GameImageMemoryPolicy.standard;
      const native = GameAssetDimensions(width: 2000, height: 1000);

      final target = policy.targetForDisplay(
        native: native,
        devicePixelRatio: 2,
        logicalWidth: 100,
        logicalHeight: 50,
      );

      expect(target.width, 200);
      expect(target.height, 100);
      expect(target.estimatedBytes, 200 * 100 * 4);
    });

    test('never upsamples beyond native dimensions', () {
      const policy = GameImageMemoryPolicy.standard;
      const native = GameAssetDimensions(width: 256, height: 128);

      final target = policy.targetForDisplay(
        native: native,
        devicePixelRatio: 4,
        logicalWidth: 500,
        logicalHeight: 250,
      );

      expect(target.width, 256);
      expect(target.height, 128);
    });

    test(
      'cover requests enough pixels while preserving source aspect ratio',
      () {
        const policy = GameImageMemoryPolicy.standard;
        const native = GameAssetDimensions(width: 1200, height: 600);

        final target = policy.targetForDisplay(
          native: native,
          devicePixelRatio: 2,
          logicalWidth: 100,
          logicalHeight: 100,
          fit: BoxFit.cover,
        );

        expect(target.width, 400);
        expect(target.height, 200);
        expect(target.width / target.height, closeTo(2, .001));
      },
    );

    test('contain fits within the physical display box', () {
      const policy = GameImageMemoryPolicy.standard;
      const native = GameAssetDimensions(width: 1200, height: 600);

      final target = policy.targetForDisplay(
        native: native,
        devicePixelRatio: 2,
        logicalWidth: 100,
        logicalHeight: 100,
      );

      expect(target.width, 200);
      expect(target.height, 100);
    });

    test('precache without layout hints remains bounded', () {
      const policy = GameImageMemoryPolicy.standard;
      const native = GameAssetDimensions(width: 4000, height: 2000);

      final target = policy.targetForPrecache(native);

      expect(target.width, 1024);
      expect(target.height, 512);
      expect(target.width, lessThanOrEqualTo(policy.maxDecodeDimension));
      expect(
        target.estimatedBytes,
        lessThanOrEqualTo(policy.maxDecodedImageBytes),
      );
    });

    test('hard dimension cap bounds extreme authored dimensions', () {
      const policy = GameImageMemoryPolicy(
        maxDecodedImageBytes: 64 * 1024 * 1024,
        maxDecodeDimension: 1000,
        defaultPrecachePhysicalExtent: 5000,
      );
      const native = GameAssetDimensions(width: 5000, height: 2500);

      final target = policy.targetForPrecache(native);

      expect(target.width, 1000);
      expect(target.height, 500);
    });

    test('decoded RGBA estimate never exceeds per-image byte budget', () {
      const policy = GameImageMemoryPolicy(
        maxDecodedImageBytes: 1024 * 1024,
        maxDecodeDimension: 4096,
        defaultPrecachePhysicalExtent: 4096,
      );
      const native = GameAssetDimensions(width: 4000, height: 4000);

      final target = policy.targetForPrecache(native);

      expect(target.estimatedBytes, lessThanOrEqualTo(1024 * 1024));
      expect(target.width, target.height);
      expect(target.width, lessThan(1000));
    });

    test('invalid display hints fall back to the bounded precache target', () {
      const policy = GameImageMemoryPolicy.standard;
      const native = GameAssetDimensions(width: 3000, height: 1500);

      final target = policy.targetForDisplay(
        native: native,
        devicePixelRatio: double.nan,
        logicalWidth: -1,
        logicalHeight: 0,
      );
      final fallback = policy.targetForPrecache(native);

      expect(target.width, fallback.width);
      expect(target.height, fallback.height);
    });

    test('resize provider carries the exact bounded decode target', () {
      const policy = GameImageMemoryPolicy.standard;
      const target = GameImageDecodeTarget(
        width: 320,
        height: 160,
        estimatedBytes: 320 * 160 * 4,
      );

      final provider = policy.resizeProvider(
        const AssetImage('assets/example.webp'),
        target,
      );

      expect(provider, isA<ResizeImage>());
      final resized = provider as ResizeImage;
      expect(resized.width, 320);
      expect(resized.height, 160);
      expect(resized.allowUpscaling, isFalse);
      expect(resized.imageProvider, isA<AssetImage>());
    });
  });
}
