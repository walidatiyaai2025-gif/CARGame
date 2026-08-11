import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/application/realtime_3d/realtime_3d_scene_port.dart';
import '../../core/domain/realtime_3d/cargo_interaction.dart';
import '../../core/domain/realtime_3d/geometry.dart';

class ProjectedRealtime3dScene extends ChangeNotifier
    implements Realtime3dScenePort {
  ProjectedRealtime3dScene()
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
      ]);

  static const CargoEntity3d cargo = CargoEntity3d(
    entityId: 'cargo.demo.electronics',
    cargoTypeId: 'electronics',
  );
  static const Vec3 cargoOrigin = Vec3(-2.35, 0.55, 2.25);

  final List<DeliveryTarget3d> targets;

  Size _viewport = Size.zero;
  Vec3 _cargoPosition = cargoOrigin;
  bool _cargoSelected = false;
  bool _reducedMotion = false;
  String? _hoveredTargetId;
  bool _hoverCompatible = false;
  double _yaw = 0.82;
  double _cameraHeight = 8.7;

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

  void setViewport(Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return;
    _viewport = viewport;
  }

  void setReducedMotion(bool reducedMotion) {
    _reducedMotion = reducedMotion;
  }

  void orbitBy(Offset delta) {
    _yaw -= delta.dx * 0.008;
    _cameraHeight = (_cameraHeight + (delta.dy * 0.025))
        .clamp(5.8, 12.5)
        .toDouble();
    notifyListeners();
  }

  void resetCargo() {
    _cargoPosition = cargoOrigin;
    _cargoSelected = false;
    _hoveredTargetId = null;
    _hoverCompatible = false;
    notifyListeners();
  }

  Offset? project(Vec3 point) {
    if (_viewport == Size.zero) return null;
    final relative = point - _cameraEye;
    final depth = relative.dot(_cameraForward);
    if (depth <= 0.05) return null;

    final aspect = _viewport.width / _viewport.height;
    final x = relative.dot(_cameraRight) / (depth * _tanHalfFov * aspect);
    final y = relative.dot(_cameraUp) / (depth * _tanHalfFov);
    return Offset(
      (x + 1) * 0.5 * _viewport.width,
      (1 - y) * 0.5 * _viewport.height,
    );
  }

  double depthOf(Vec3 point) => (point - _cameraEye).dot(_cameraForward);

  @override
  Future<CargoPick3d?> pickCargo(ScreenPoint3 screenPoint) async {
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
    notifyListeners();
  }

  @override
  Future<void> setCargoSelected(String cargoEntityId, bool selected) async {
    if (cargoEntityId != cargo.entityId) return;
    _cargoSelected = selected;
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
      _cargoPosition = destination;
      notifyListeners();
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
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    _cargoPosition = destination;
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
}

class Realtime3dPreviewPainter extends CustomPainter {
  Realtime3dPreviewPainter(this.scene);

  final ProjectedRealtime3dScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07182F), Color(0xFF155B78), Color(0xFF8BD7DC)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    _drawSun(canvas, size);
    _drawGround(canvas);
    _drawRoads(canvas);
    _drawGrid(canvas);
    _drawDeliveryPad(canvas, scene.targets[0], const Color(0xFF47D8FF));
    _drawDeliveryPad(canvas, scene.targets[1], const Color(0xFF6DE69B));

    final boxes =
        <_SceneBox>[
          const _SceneBox(
            min: Vec3(-5.8, 0, 0.45),
            max: Vec3(-3.15, 3.35, 4.35),
            color: Color(0xFFF6A644),
            label: 'WAREHOUSE',
          ),
          const _SceneBox(
            min: Vec3(3.05, 0, 1.05),
            max: Vec3(5.35, 3.1, 3.8),
            color: Color(0xFF35B9E9),
            label: 'ELECTRONICS',
          ),
          const _SceneBox(
            min: Vec3(3.05, 0, -3.8),
            max: Vec3(5.35, 2.65, -1.0),
            color: Color(0xFF58C987),
            label: 'FOOD',
          ),
          _SceneBox(
            min: Vec3(
              scene.cargoPosition.x - 0.68,
              scene.cargoPosition.y - 0.5,
              scene.cargoPosition.z - 0.55,
            ),
            max: Vec3(
              scene.cargoPosition.x + 0.68,
              scene.cargoPosition.y + 0.5,
              scene.cargoPosition.z + 0.55,
            ),
            color: scene.cargoSelected
                ? const Color(0xFF7EE7FF)
                : const Color(0xFF318DE8),
            label: 'CARGO',
            isCargo: true,
          ),
        ]..sort(
          (a, b) => scene.depthOf(b.center).compareTo(scene.depthOf(a.center)),
        );

    for (final box in boxes) {
      _drawBox(canvas, box);
    }

    _drawCargoBeacon(canvas);
    _drawCompass(canvas, size);
  }

  void _drawSun(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.18, size.height * 0.19);
    final radius = size.shortestSide * 0.15;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.34),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawGround(Canvas canvas) {
    final points = _projectAll(const [
      Vec3(-9, 0, -7),
      Vec3(9, 0, -7),
      Vec3(9, 0, 7),
      Vec3(-9, 0, 7),
    ]);
    if (points == null) return;
    _drawPolygon(canvas, points, const Color(0xFF77B96F));
  }

  void _drawRoads(Canvas canvas) {
    final vertical = _projectAll(const [
      Vec3(-0.7, 0.012, -7),
      Vec3(0.7, 0.012, -7),
      Vec3(0.7, 0.012, 7),
      Vec3(-0.7, 0.012, 7),
    ]);
    final horizontal = _projectAll(const [
      Vec3(-9, 0.014, -0.65),
      Vec3(9, 0.014, -0.65),
      Vec3(9, 0.014, 0.65),
      Vec3(-9, 0.014, 0.65),
    ]);
    if (vertical != null) {
      _drawPolygon(canvas, vertical, const Color(0xFF61747C));
    }
    if (horizontal != null) {
      _drawPolygon(canvas, horizontal, const Color(0xFF61747C));
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..strokeWidth = 1;
    for (var index = -8; index <= 8; index++) {
      final a = scene.project(Vec3(index.toDouble(), 0.02, -7));
      final b = scene.project(Vec3(index.toDouble(), 0.02, 7));
      if (a != null && b != null) canvas.drawLine(a, b, paint);

      final c = scene.project(Vec3(-9, 0.02, index * 0.8));
      final d = scene.project(Vec3(9, 0.02, index * 0.8));
      if (c != null && d != null) canvas.drawLine(c, d, paint);
    }
  }

  void _drawDeliveryPad(Canvas canvas, DeliveryTarget3d target, Color color) {
    final active = scene.hoveredTargetId == target.targetId;
    final compatible = !active || scene.hoverCompatible;
    final padColor = active
        ? compatible
              ? const Color(0xFF7CFFB2)
              : const Color(0xFFFF6B6B)
        : color;
    final points = _projectAll([
      Vec3(target.bounds.min.x, 0.04, target.bounds.min.z),
      Vec3(target.bounds.max.x, 0.04, target.bounds.min.z),
      Vec3(target.bounds.max.x, 0.04, target.bounds.max.z),
      Vec3(target.bounds.min.x, 0.04, target.bounds.max.z),
    ]);
    if (points == null) return;

    final path = Path()..addPolygon(points, true);
    canvas.drawPath(
      path,
      Paint()..color = padColor.withValues(alpha: active ? 0.55 : 0.28),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = padColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 4 : 2,
    );
  }

  void _drawBox(Canvas canvas, _SceneBox box) {
    final min = box.min;
    final max = box.max;
    final vertices = <Vec3>[
      Vec3(min.x, min.y, min.z),
      Vec3(max.x, min.y, min.z),
      Vec3(max.x, min.y, max.z),
      Vec3(min.x, min.y, max.z),
      Vec3(min.x, max.y, min.z),
      Vec3(max.x, max.y, min.z),
      Vec3(max.x, max.y, max.z),
      Vec3(min.x, max.y, max.z),
    ];
    final faces =
        <_BoxFace>[
          _BoxFace(const [0, 1, 5, 4], 0.78),
          _BoxFace(const [1, 2, 6, 5], 0.9),
          _BoxFace(const [2, 3, 7, 6], 0.68),
          _BoxFace(const [3, 0, 4, 7], 0.82),
          _BoxFace(const [4, 5, 6, 7], 1.0),
        ]..sort((a, b) {
          final depthA =
              a.indices
                  .map((index) => scene.depthOf(vertices[index]))
                  .reduce((a, b) => a + b) /
              a.indices.length;
          final depthB =
              b.indices
                  .map((index) => scene.depthOf(vertices[index]))
                  .reduce((a, b) => a + b) /
              b.indices.length;
          return depthB.compareTo(depthA);
        });

    if (box.isCargo) {
      final shadow = scene.project(Vec3(box.center.x, 0.04, box.center.z));
      if (shadow != null) {
        canvas.drawOval(
          Rect.fromCenter(center: shadow, width: 54, height: 22),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      }
    }

    for (final face in faces) {
      final projected = _projectAll(
        face.indices.map((index) => vertices[index]).toList(growable: false),
      );
      if (projected == null) continue;
      final faceColor = Color.lerp(
        Colors.black,
        box.color,
        face.brightness.clamp(0.0, 1.0).toDouble(),
      )!;
      _drawPolygon(canvas, projected, faceColor);
      canvas.drawPath(
        Path()..addPolygon(projected, true),
        Paint()
          ..color = Colors.white.withValues(alpha: box.isCargo ? 0.34 : 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = box.isCargo && scene.cargoSelected ? 2.8 : 1.1,
      );
    }

    if (box.isCargo) {
      _drawCargoMark(canvas, box);
    } else {
      _drawBuildingLabel(canvas, box);
      _drawBuildingDoor(canvas, box);
    }
  }

  void _drawBuildingLabel(Canvas canvas, _SceneBox box) {
    final anchor = scene.project(
      Vec3(box.center.x, box.max.y + 0.34, box.center.z),
    );
    if (anchor == null) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: box.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      anchor - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawBuildingDoor(Canvas canvas, _SceneBox box) {
    final center = box.center;
    final base = scene.project(Vec3(box.min.x, 0.1, center.z));
    final top = scene.project(Vec3(box.min.x, box.max.y * 0.55, center.z));
    if (base == null || top == null) return;
    final height = (base.dy - top.dy).abs().clamp(12, 48).toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset((base.dx + top.dx) / 2, base.dy - height / 2),
          width: 18,
          height: height,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF17354A).withValues(alpha: 0.72),
    );
  }

  void _drawCargoMark(Canvas canvas, _SceneBox box) {
    final anchor = scene.project(
      Vec3(box.center.x, box.max.y + 0.02, box.center.z),
    );
    if (anchor == null) return;
    canvas.drawCircle(
      anchor,
      scene.cargoSelected ? 8 : 6,
      Paint()..color = const Color(0xFFE8FBFF).withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      anchor,
      scene.cargoSelected ? 4 : 3,
      Paint()..color = const Color(0xFF1977CD),
    );
  }

  void _drawCargoBeacon(Canvas canvas) {
    if (!scene.cargoSelected) return;
    final anchor = scene.project(scene.cargoPosition);
    if (anchor == null) return;
    canvas.drawCircle(
      anchor,
      34,
      Paint()
        ..color = const Color(0xFF66DFFF).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  void _drawCompass(Canvas canvas, Size size) {
    final center = Offset(size.width - 44, size.height * 0.78);
    canvas.drawCircle(center, 24, Paint()..color = const Color(0x99071D36));
    final north = scene.project(const Vec3(0, 0.2, -2));
    final origin = scene.project(const Vec3(0, 0.2, 0));
    if (north == null || origin == null) return;
    final direction = north - origin;
    if (direction.distance == 0) return;
    final unit = direction / direction.distance;
    canvas.drawLine(
      center,
      center + (unit * 15),
      Paint()
        ..color = const Color(0xFFFFD166)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final label = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }

  List<Offset>? _projectAll(List<Vec3> points) {
    final projected = <Offset>[];
    for (final point in points) {
      final screenPoint = scene.project(point);
      if (screenPoint == null) return null;
      projected.add(screenPoint);
    }
    return projected;
  }

  void _drawPolygon(Canvas canvas, List<Offset> points, Color color) {
    canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant Realtime3dPreviewPainter oldDelegate) => true;
}

class _SceneBox {
  const _SceneBox({
    required this.min,
    required this.max,
    required this.color,
    required this.label,
    this.isCargo = false,
  });

  final Vec3 min;
  final Vec3 max;
  final Color color;
  final String label;
  final bool isCargo;

  Vec3 get center =>
      Vec3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2);
}

class _BoxFace {
  const _BoxFace(this.indices, this.brightness);

  final List<int> indices;
  final double brightness;
}
