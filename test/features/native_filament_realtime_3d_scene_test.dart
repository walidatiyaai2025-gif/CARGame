import 'package:cargo_sort_game/core/domain/realtime_3d/geometry.dart';
import 'package:cargo_sort_game/features/realtime_3d/native_filament_realtime_3d_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native slice targets match their GLB snap coordinates', () {
    final scene = NativeFilamentRealtime3dScene();
    addTearDown(scene.dispose);

    expect(scene.targets, hasLength(2));
    for (final target in scene.targets) {
      expect(target.bounds.contains(target.snapPosition), isTrue);
    }
    expect(
      scene.targets.first.snapPosition,
      const Vec3(4.2, 0.68, 2.9),
    );
  });

  test('native interaction camera emits normalized screen rays', () {
    final scene = NativeFilamentRealtime3dScene();
    addTearDown(scene.dispose);
    scene.setViewport(const Size(1080, 1920));

    final ray = scene.screenRay(const ScreenPoint3(540, 960));
    expect(ray.direction.length, closeTo(1, 1e-9));
    expect(ray.origin.y, 8.7);
  });

  test('cargo state mutates without requiring a platform channel', () async {
    final scene = NativeFilamentRealtime3dScene();
    addTearDown(scene.dispose);
    const moved = Vec3(-3.4, 0.8, 1.8);

    await scene.setCargoWorldPosition(
      NativeFilamentRealtime3dScene.cargo.entityId,
      moved,
    );
    expect(scene.cargoPosition, moved);

    scene.resetCargo();
    expect(scene.cargoPosition, NativeFilamentRealtime3dScene.cargoOrigin);
  });
}
