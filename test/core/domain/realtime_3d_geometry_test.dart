import 'package:cargo_sort_game/core/domain/realtime_3d/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('realtime 3D geometry', () {
    test('normalizes ray direction and intersects a horizontal drag plane', () {
      final ray = Ray3(
        origin: const Vec3(4, 10, 7),
        direction: const Vec3(0, -5, 0),
      );
      final plane = Plane3.fromPointNormal(Vec3.zero, Vec3.up);

      expect(ray.direction, const Vec3(0, -1, 0));
      expect(plane.intersectRay(ray), const Vec3(4, 0, 7));
    });

    test('parallel ray does not produce an invalid drag position', () {
      final ray = Ray3(
        origin: const Vec3(0, 2, 0),
        direction: const Vec3(1, 0, 0),
      );
      final plane = Plane3.fromPointNormal(Vec3.zero, Vec3.up);

      expect(plane.intersectRay(ray), isNull);
    });

    test('intersection behind the camera is rejected', () {
      final ray = Ray3(
        origin: const Vec3(0, 2, 0),
        direction: const Vec3(0, 1, 0),
      );
      final plane = Plane3.fromPointNormal(Vec3.zero, Vec3.up);

      expect(plane.intersectRay(ray), isNull);
    });

    test('delivery AABB includes its boundaries', () {
      const bounds = Aabb3(min: Vec3(-1, 0, -1), max: Vec3(1, 2, 1));

      expect(bounds.contains(const Vec3(-1, 0, -1)), isTrue);
      expect(bounds.contains(const Vec3(1, 2, 1)), isTrue);
      expect(bounds.contains(const Vec3(1.01, 1, 0)), isFalse);
    });

    test('zero ray direction is rejected', () {
      expect(
        () => Ray3(origin: Vec3.zero, direction: Vec3.zero),
        throwsArgumentError,
      );
    });
  });
}
