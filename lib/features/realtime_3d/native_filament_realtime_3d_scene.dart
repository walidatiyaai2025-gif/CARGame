import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/application/realtime_3d/realtime_3d_scene_port.dart';
import '../../core/domain/realtime_3d/cargo_interaction.dart';
import '../../core/domain/realtime_3d/geometry.dart';
import 'projected_realtime_3d_scene.dart';

enum NativeFilamentCameraPreset {
  overview('overview', 'Overview'),
  warehouse('warehouse', 'Warehouse'),
  docks('docks', 'Docks');

  const NativeFilamentCameraPreset(this.wireName, this.label);

  final String wireName;
  final String label;
}

/// Production Android adapter. World-space interaction stays in Dart while the
/// visible scene is rendered by the native Filament PlatformView.
class NativeFilamentRealtime3dScene extends ChangeNotifier
    implements Realtime3dScenePort {
  NativeFilamentRealtime3dScene()
    : targets = List<DeliveryTarget3d>.unmodifiable([
        DeliveryTarget3d(
          targetId: 'building.electronics',
          bounds: const Aabb3(
            min: Vec3(2.8, 0.05, 1.65),
            max: Vec3(5.6, 1.35, 4.15),
          ),
          snapPosition: const Vec3(4.2, 0.68, 2.9),
          acceptedCargoTypeIds: const <String>{'electronics'},
        ),
        DeliveryTarget3d(
          targetId: 'building.food',
          bounds: const Aabb3(
            min: Vec3(2.8, 0.05, -4.35),
            max: Vec3(5.6, 1.35, -1.85),
          ),
          snapPosition: const Vec3(4.2, 0.68, -3.1),
          acceptedCargoTypeIds: const <String>{'food'},
        ),
      ]);

  static const viewType = 'cargame/native_filament_scene';
  static const CargoEntity3d cargo = CargoEntity3d(
    entityId: 'cargo.demo.electronics',
    cargoTypeId: 'electronics',
  );
  static const Vec3 cargoOrigin = Vec3(-4.6, 0.62, 1);

  final List<DeliveryTarget3d> targets;
  final ProjectedRealtime3dScene _projectedFallback =
      ProjectedRealtime3dScene();

  MethodChannel? _channel;
  Size _viewport = Size.zero;
  Vec3 _cargoPosition = cargoOrigin;
  bool _cargoSelected = false;
  bool _reducedMotion = false;
  String? _hoveredTargetId;
  bool _hoverCompatible = false;
  double _yaw = 0.82;
  double _cameraHeight = 8.7;
  NativeFilamentCameraPreset? _cameraPreset =
      NativeFilamentCameraPreset.overview;
  Vec3 _cameraEye = const Vec3(9.0, 8.7, 9.3);
  Vec3 _cameraTarget = const Vec3(0, 0.9, 0);

  Vec3 get cargoPosition => _cargoPosition;
  bool get cargoSelected => _cargoSelected;
  String? get hoveredTargetId => _hoveredTargetId;
  bool get hoverCompatible => _hoverCompatible;
  ProjectedRealtime3dScene get projectedFallback => _projectedFallback;
  NativeFilamentCameraPreset? get cameraPreset => _cameraPreset;
  String get cameraLabel => _cameraPreset?.label ?? 'Custom';

  Vec3 get _cameraForward => (_cameraTarget - _cameraEye).normalized();
  Vec3 get _cameraRight => _cameraForward.cross(Vec3.up).normalized();
  Vec3 get _cameraUp => _cameraRight.cross(_cameraForward).normalized();
  double get _tanHalfFov => math.tan(42 * math.pi / 360);

  void attachPlatformView(int viewId) {
    _channel = MethodChannel('$viewType/$viewId');
    unawaited(_syncNativeState());
  }

  void setViewport(Size viewport) {
    if (viewport.width > 0 && viewport.height > 0) _viewport = viewport;
    _projectedFallback.setViewport(viewport);
  }

  void setReducedMotion(bool reducedMotion) {
    _reducedMotion = reducedMotion;
    _projectedFallback.setReducedMotion(reducedMotion);
  }

  void orbitBy(Offset delta) {
    _yaw -= delta.dx * 0.008;
    _cameraHeight = (_cameraHeight + (delta.dy * 0.025))
        .clamp(5.8, 12.5)
        .toDouble();
    _cameraPreset = null;
    _cameraEye = Vec3(
      math.cos(_yaw) * 13.2,
      _cameraHeight,
      math.sin(_yaw) * 13.2,
    );
    _cameraTarget = const Vec3(0, 0.9, 0);
    _projectedFallback.orbitBy(delta);
    unawaited(
      _invoke('orbitBy', <String, double>{'dx': delta.dx, 'dy': delta.dy}),
    );
    notifyListeners();
  }

  Future<void> setCameraPreset(NativeFilamentCameraPreset preset) async {
    final (eye, target) = switch (preset) {
      NativeFilamentCameraPreset.overview => (
        const Vec3(9.0, 8.7, 9.3),
        const Vec3(0, 0.9, 0),
      ),
      NativeFilamentCameraPreset.warehouse => (
        const Vec3(-0.8, 6.3, 10.8),
        const Vec3(-5.6, 1.4, 2.4),
      ),
      NativeFilamentCameraPreset.docks => (
        const Vec3(10.5, 5.8, 1.2),
        const Vec3(4.2, 0.7, -0.1),
      ),
    };
    _cameraPreset = preset;
    _cameraEye = eye;
    _cameraTarget = target;
    await _invoke('setCameraPreset', <String, String>{'preset': preset.wireName});
    notifyListeners();
  }

  Future<void> resetCamera() =>
      setCameraPreset(NativeFilamentCameraPreset.overview);

  void resetCargo() {
    _cargoPosition = cargoOrigin;
    _cargoSelected = false;
    _hoveredTargetId = null;
    _hoverCompatible = false;
    _projectedFallback.resetCargo();
    unawaited(_invoke('resetCargo'));
    unawaited(_sendCargoPosition(cargoOrigin));
    notifyListeners();
  }

  Future<void> _syncNativeState() async {
    await _invoke('resetCargo');
    await _invoke('setCameraPreset', <String, String>{
      'preset': (_cameraPreset ?? NativeFilamentCameraPreset.overview).wireName,
    });
    await _sendCargoPosition(_cargoPosition);
  }

  Future<void> _invoke(String method, [Object? arguments]) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod<Object?>(method, arguments);
    } on MissingPluginException {
      // Native renderer unavailable: screen remains functional via fallback.
    } on PlatformException {
      // Renderer faults do not mutate game-domain interaction truth.
    }
  }

  Future<void> _sendCargoPosition(Vec3 position) =>
      _invoke('setCargoWorldPosition', <String, Object>{
        'id': cargo.entityId,
        'x': position.x,
        'y': position.y,
        'z': position.z,
      });

  @override
  Future<CargoPick3d?> pickCargo(ScreenPoint3 screenPoint) async {
    final ray = screenRay(screenPoint);
    final bounds = Aabb3(
      min: Vec3(
        _cargoPosition.x - 0.68,
        _cargoPosition.y - 0.55,
        _cargoPosition.z - 0.68,
      ),
      max: Vec3(
        _cargoPosition.x + 0.68,
        _cargoPosition.y + 0.55,
        _cargoPosition.z + 0.68,
      ),
    );
    if (!_rayIntersectsAabb(ray, bounds)) return null;
    return CargoPick3d(cargo: cargo, worldPosition: _cargoPosition);
  }

  @override
  Ray3 screenRay(ScreenPoint3 screenPoint) {
    if (_viewport == Size.zero) {
      return Ray3(origin: _cameraEye, direction: _cameraForward);
    }
    final normalizedX = (2 * screenPoint.x / _viewport.width) - 1;
    final normalizedY = 1 - (2 * screenPoint.y / _viewport.height);
    final aspect = _viewport.width / _viewport.height;
    final direction =
        _cameraForward +
        (_cameraRight * (normalizedX * aspect * _tanHalfFov)) +
        (_cameraUp * (normalizedY * _tanHalfFov));
    return Ray3(origin: _cameraEye, direction: direction.normalized());
  }

  @override
  Future<void> setCargoWorldPosition(
    String cargoEntityId,
    Vec3 position,
  ) async {
    if (cargoEntityId != cargo.entityId) return;
    _cargoPosition = position;
    await _sendCargoPosition(position);
    notifyListeners();
  }

  @override
  Future<void> setCargoSelected(String cargoEntityId, bool selected) async {
    if (cargoEntityId != cargo.entityId) return;
    _cargoSelected = selected;
    await _invoke('setCargoSelected', <String, Object>{
      'id': cargoEntityId,
      'selected': selected,
    });
    notifyListeners();
  }

  @override
  Future<void> setTargetHover(
    String targetId, {
    required bool active,
    required bool compatible,
  }) async {
    _hoveredTargetId = active ? targetId : null;
    _hoverCompatible = active && compatible;
    final nativeId = switch (targetId) {
      'building.electronics' => 'delivery.electronics',
      'building.food' => 'delivery.food',
      _ => targetId,
    };
    await _invoke('setTargetHover', <String, Object>{
      'id': nativeId,
      'hovered': active,
      'compatible': compatible,
    });
    notifyListeners();
  }

  @override
  Future<void> animateCargo(
    String cargoEntityId,
    Vec3 destination, {
    required CargoMotion3d motion,
  }) async {
    if (cargoEntityId != cargo.entityId) return;
    if (_reducedMotion) {
      await setCargoWorldPosition(cargoEntityId, destination);
      return;
    }

    final start = _cargoPosition;
    const frames = 12;
    for (var frame = 1; frame <= frames; frame++) {
      final progress = frame / frames;
      final eased = 1 - math.pow(1 - progress, 3).toDouble();
      final lift = motion == CargoMotion3d.snapToTarget
          ? math.sin(progress * math.pi) * 0.32
          : math.sin(progress * math.pi) * 0.14;
      final position = Vec3(
        start.x + ((destination.x - start.x) * eased),
        start.y + ((destination.y - start.y) * eased) + lift,
        start.z + ((destination.z - start.z) * eased),
      );
      _cargoPosition = position;
      await _sendCargoPosition(position);
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    _cargoPosition = destination;
    await _sendCargoPosition(destination);
    notifyListeners();
  }

  bool _rayIntersectsAabb(Ray3 ray, Aabb3 bounds) {
    var near = 0.0;
    var far = double.infinity;

    bool axis(double origin, double direction, double min, double max) {
      if (direction.abs() < 1e-9) {
        return origin >= min && origin <= max;
      }
      var first = (min - origin) / direction;
      var second = (max - origin) / direction;
      if (first > second) {
        final swap = first;
        first = second;
        second = swap;
      }
      near = math.max(near, first);
      far = math.min(far, second);
      return near <= far;
    }

    return axis(ray.origin.x, ray.direction.x, bounds.min.x, bounds.max.x) &&
        axis(ray.origin.y, ray.direction.y, bounds.min.y, bounds.max.y) &&
        axis(ray.origin.z, ray.direction.z, bounds.min.z, bounds.max.z) &&
        far >= 0;
  }

  @override
  void dispose() {
    _projectedFallback.dispose();
    _channel = null;
    super.dispose();
  }
}
