import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../core/application/realtime_3d/realtime_3d_scene_port.dart';
import '../../core/domain/realtime_3d/cargo_interaction.dart';
import '../../core/domain/realtime_3d/geometry.dart';

class ThreeJsRealtime3dScene extends ChangeNotifier
    implements Realtime3dScenePort {
  ThreeJsRealtime3dScene()
    : targets = List<DeliveryTarget3d>.unmodifiable([
        DeliveryTarget3d(
          targetId: 'building.electronics',
          bounds: const Aabb3(
            min: Vec3(1.15, 0.1, 1.35),
            max: Vec3(2.95, 1.1, 3.5),
          ),
          snapPosition: const Vec3(2.05, 0.55, 2.4),
          acceptedCargoTypeIds: const <String>{'electronics'},
        ),
        DeliveryTarget3d(
          targetId: 'building.food',
          bounds: const Aabb3(
            min: Vec3(1.15, 0.1, -3.45),
            max: Vec3(2.95, 1.1, -1.25),
          ),
          snapPosition: const Vec3(2.05, 0.55, -2.35),
          acceptedCargoTypeIds: const <String>{'food'},
        ),
      ]) {
    threeJs = three.ThreeJS(
      setup: _setup,
      onSetupComplete: _onSetupComplete,
      settings: three.Settings(
        clearColor: 0x07182F,
        clearAlpha: 1,
        enableShadowMap: true,
        shadowMapType: three.PCFSoftShadowMap,
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 1,
      ),
    );
  }

  static const CargoEntity3d cargo = CargoEntity3d(
    entityId: 'cargo.demo.electronics',
    cargoTypeId: 'electronics',
  );
  static const Vec3 cargoOrigin = Vec3(-2.35, 0.55, 2.25);

  final List<DeliveryTarget3d> targets;
  late final three.ThreeJS threeJs;

  Size _viewport = Size.zero;
  Vec3 _cargoPosition = cargoOrigin;
  bool _cargoSelected = false;
  bool _reducedMotion = false;
  String? _hoveredTargetId;
  bool _hoverCompatible = false;
  double _yaw = 0.82;
  double _cameraHeight = 8.7;
  bool _ready = false;
  Object? _setupError;

  three.Mesh? _cargoMesh;
  three.Mesh? _electronicsPad;
  three.Mesh? _foodPad;

  bool get isReady => _ready;
  Object? get setupError => _setupError;
  Vec3 get cargoPosition => _cargoPosition;
  bool get cargoSelected => _cargoSelected;
  String? get hoveredTargetId => _hoveredTargetId;
  bool get hoverCompatible => _hoverCompatible;

  Vec3 get _cameraTarget => const Vec3(0, 0.9, 0);

  Vec3 get _cameraEye =>
      Vec3(math.cos(_yaw) * 13.2, _cameraHeight, math.sin(_yaw) * 13.2);

  Vec3 get _cameraForward => (_cameraTarget - _cameraEye).normalized();
  Vec3 get _cameraRight => _cameraForward.cross(Vec3.up).normalized();
  Vec3 get _cameraUp => _cameraRight.cross(_cameraForward).normalized();

  double get _tanHalfFov => math.tan(42 * math.pi / 360);

  Widget buildSurface() => threeJs.build();

  void setViewport(Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return;
    _viewport = viewport;
  }

  void setReducedMotion(bool reducedMotion) {
    _reducedMotion = reducedMotion;
  }

  void orbitBy(Offset delta) {
    if (!_ready) return;
    _yaw -= delta.dx * 0.008;
    _cameraHeight = (_cameraHeight + (delta.dy * 0.025))
        .clamp(5.8, 12.5)
        .toDouble();
    _applyCamera();
  }

  void resetCargo() {
    _cargoPosition = cargoOrigin;
    _cargoSelected = false;
    _hoveredTargetId = null;
    _hoverCompatible = false;
    _applyCargoTransform();
    _applyPadState();
    notifyListeners();
  }

  Future<void> _setup() async {
    try {
      threeJs.camera = three.PerspectiveCamera(
        42,
        threeJs.width / threeJs.height,
        0.1,
        100,
      );
      threeJs.scene = three.Scene();
      threeJs.scene.background = three.Color.fromHex32(0x07182F);

      final hemisphere = three.HemisphereLight(0xE8F7FF, 0x315438, 0.72);
      hemisphere.position.setValues(0, 8, 0);
      threeJs.scene.add(hemisphere);

      final keyLight = three.DirectionalLight(0xFFF2D6, 1.15);
      keyLight.position.setValues(-6, 10, -4);
      keyLight.castShadow = true;
      keyLight.shadow?.mapSize.width = 512;
      keyLight.shadow?.mapSize.height = 512;
      keyLight.shadow?.camera?.near = 0.1;
      keyLight.shadow?.camera?.far = 60;
      keyLight.shadow?.camera?.right = 12;
      keyLight.shadow?.camera?.left = -12;
      keyLight.shadow?.camera?.top = 12;
      keyLight.shadow?.camera?.bottom = -12;
      keyLight.shadow?.bias = -0.002;
      keyLight.shadow?.radius = 3;
      threeJs.scene.add(keyLight);

      _addBox(
        size: const Vec3(18, 0.12, 14),
        position: const Vec3(0, -0.06, 0),
        color: 0x75B96F,
        receiveShadow: true,
      );
      _addBox(
        size: const Vec3(1.4, 0.035, 14),
        position: const Vec3(0, 0.025, 0),
        color: 0x596B73,
        receiveShadow: true,
      );
      _addBox(
        size: const Vec3(18, 0.04, 1.3),
        position: const Vec3(0, 0.03, 0),
        color: 0x596B73,
        receiveShadow: true,
      );

      _addBox(
        size: const Vec3(2.65, 3.35, 3.9),
        position: const Vec3(-4.48, 1.68, 2.4),
        color: 0xE99A3D,
      );
      _addBox(
        size: const Vec3(2.3, 3.1, 2.75),
        position: const Vec3(4.2, 1.55, 2.42),
        color: 0x2FAFDC,
      );
      _addBox(
        size: const Vec3(2.3, 2.65, 2.8),
        position: const Vec3(4.2, 1.33, -2.4),
        color: 0x4DBF7C,
      );

      _electronicsPad = _addBox(
        size: const Vec3(1.8, 0.07, 1.75),
        position: const Vec3(2.05, 0.055, 2.4),
        color: 0x42D7FF,
        receiveShadow: true,
      );
      _foodPad = _addBox(
        size: const Vec3(1.8, 0.07, 1.75),
        position: const Vec3(2.05, 0.055, -2.35),
        color: 0x69E59A,
        receiveShadow: true,
      );

      _buildVehicle();

      _cargoMesh = _addBox(
        size: const Vec3(1.36, 1, 1.1),
        position: cargoOrigin,
        color: 0x318DE8,
      );
      _addBox(
        size: const Vec3(1.05, 0.78, 0.9),
        position: const Vec3(-3.8, 0.43, 1.0),
        color: 0xE85252,
      );
      _addBox(
        size: const Vec3(0.92, 0.7, 0.82),
        position: const Vec3(-4.35, 0.39, 3.6),
        color: 0xF2C94C,
      );

      _applyCamera();
      _applyCargoTransform();
    } catch (error) {
      _setupError = error;
    }
  }

  void _onSetupComplete() {
    _ready = _setupError == null;
    notifyListeners();
  }

  three.Mesh _addBox({
    required Vec3 size,
    required Vec3 position,
    required int color,
    bool castShadow = true,
    bool receiveShadow = true,
  }) {
    final material = three.MeshPhongMaterial.fromMap({
      'color': color,
      'shininess': 18,
      'specular': 0x222222,
    });
    final mesh = three.Mesh(
      three.BoxGeometry(size.x, size.y, size.z),
      material,
    );
    mesh.position.setValues(position.x, position.y, position.z);
    mesh.castShadow = castShadow;
    mesh.receiveShadow = receiveShadow;
    threeJs.scene.add(mesh);
    return mesh;
  }

  void _buildVehicle() {
    _addBox(
      size: const Vec3(2.25, 0.55, 1.15),
      position: const Vec3(-2.7, 0.47, -2.55),
      color: 0xD94E42,
    );
    _addBox(
      size: const Vec3(1.0, 0.58, 1.0),
      position: const Vec3(-2.15, 0.94, -2.55),
      color: 0xF2C75C,
    );
    for (final wheel in const [
      Vec3(-3.35, 0.22, -3.08),
      Vec3(-2.15, 0.22, -3.08),
      Vec3(-3.35, 0.22, -2.02),
      Vec3(-2.15, 0.22, -2.02),
    ]) {
      _addBox(
        size: const Vec3(0.46, 0.46, 0.25),
        position: wheel,
        color: 0x20252B,
      );
    }
  }

  void _applyCamera() {
    final eye = _cameraEye;
    threeJs.camera.position.setValues(eye.x, eye.y, eye.z);
    threeJs.camera.lookAt(
      three.Vector3(_cameraTarget.x, _cameraTarget.y, _cameraTarget.z),
    );
  }

  void _applyCargoTransform() {
    final mesh = _cargoMesh;
    if (mesh == null) return;
    mesh.position.setValues(
      _cargoPosition.x,
      _cargoPosition.y,
      _cargoPosition.z,
    );
    final scale = _cargoSelected ? 1.12 : 1.0;
    mesh.scale.setValues(scale, scale, scale);
  }

  void _applyPadState() {
    final electronicsActive = _hoveredTargetId == 'building.electronics';
    final foodActive = _hoveredTargetId == 'building.food';
    final activeScale = _hoverCompatible ? 1.1 : 0.92;

    _electronicsPad?.scale.setValues(
      electronicsActive ? activeScale : 1,
      electronicsActive ? 1.35 : 1,
      electronicsActive ? activeScale : 1,
    );
    _foodPad?.scale.setValues(
      foodActive ? activeScale : 1,
      foodActive ? 1.35 : 1,
      foodActive ? activeScale : 1,
    );
  }

  @override
  Future<CargoPick3d?> pickCargo(ScreenPoint3 screenPoint) async {
    if (!_ready) return null;
    final ray = screenRay(screenPoint);
    final bounds = Aabb3(
      min: Vec3(
        _cargoPosition.x - 0.68,
        _cargoPosition.y - 0.5,
        _cargoPosition.z - 0.55,
      ),
      max: Vec3(
        _cargoPosition.x + 0.68,
        _cargoPosition.y + 0.5,
        _cargoPosition.z + 0.55,
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
    return Ray3(origin: _cameraEye, direction: direction);
  }

  @override
  Future<void> setCargoWorldPosition(
    String cargoEntityId,
    Vec3 position,
  ) async {
    if (cargoEntityId != cargo.entityId) return;
    _cargoPosition = position;
    _applyCargoTransform();
  }

  @override
  Future<void> setCargoSelected(String cargoEntityId, bool selected) async {
    if (cargoEntityId != cargo.entityId) return;
    _cargoSelected = selected;
    _applyCargoTransform();
  }

  @override
  Future<void> setTargetHover(
    String targetId, {
    required bool active,
    required bool compatible,
  }) async {
    _hoveredTargetId = active ? targetId : null;
    _hoverCompatible = active && compatible;
    _applyPadState();
  }

  @override
  Future<void> animateCargo(
    String cargoEntityId,
    Vec3 destination, {
    required CargoMotion3d motion,
  }) async {
    if (cargoEntityId != cargo.entityId) return;
    if (_reducedMotion) {
      _cargoPosition = destination;
      _applyCargoTransform();
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
      _cargoPosition = Vec3(
        start.x + ((destination.x - start.x) * eased),
        start.y + ((destination.y - start.y) * eased) + lift,
        start.z + ((destination.z - start.z) * eased),
      );
      _applyCargoTransform();
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    _cargoPosition = destination;
    _applyCargoTransform();
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
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }
}
