import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/application/realtime_3d/realtime_3d_scene_port.dart';
import '../../core/domain/realtime_3d/cargo_interaction.dart';
import '../../core/domain/realtime_3d/geometry.dart';
import 'projected_realtime_3d_scene.dart';

/// Production Android adapter: interaction/raycast math stays in Dart while the
/// visible scene is rendered by the native Filament PlatformView.
class NativeFilamentRealtime3dScene extends ChangeNotifier
    implements Realtime3dScenePort {
  NativeFilamentRealtime3dScene() {
    _interaction.addListener(notifyListeners);
  }

  static const viewType = 'cargame/native_filament_scene';

  final ProjectedRealtime3dScene _interaction = ProjectedRealtime3dScene();
  MethodChannel? _channel;
  bool _reducedMotion = false;

  List<DeliveryTarget3d> get targets => _interaction.targets;
  Vec3 get cargoPosition => _interaction.cargoPosition;
  bool get cargoSelected => _interaction.cargoSelected;
  String? get hoveredTargetId => _interaction.hoveredTargetId;
  bool get hoverCompatible => _interaction.hoverCompatible;

  /// Used only on platforms where the native Android renderer is unavailable.
  ProjectedRealtime3dScene get projectedFallback => _interaction;

  void attachPlatformView(int viewId) {
    _channel = MethodChannel('$viewType/$viewId');
    unawaited(_syncNativeState());
  }

  void setViewport(Size viewport) => _interaction.setViewport(viewport);

  void setReducedMotion(bool reducedMotion) {
    _reducedMotion = reducedMotion;
    _interaction.setReducedMotion(reducedMotion);
  }

  void orbitBy(Offset delta) {
    _interaction.orbitBy(delta);
    unawaited(
      _invoke('orbitBy', <String, double>{
        'dx': delta.dx,
        'dy': delta.dy,
      }),
    );
  }

  void resetCargo() {
    _interaction.resetCargo();
    unawaited(_invoke('resetCargo'));
  }

  Future<void> _syncNativeState() async {
    await _invoke('resetCargo');
    await _sendCargoPosition(_interaction.cargoPosition);
  }

  Future<void> _invoke(String method, [Object? arguments]) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod<Object?>(method, arguments);
    } on MissingPluginException {
      // Platform renderer is unavailable; the screen keeps its safe fallback.
    } on PlatformException {
      // A renderer failure must not corrupt interaction state.
    }
  }

  Future<void> _sendCargoPosition(Vec3 position) =>
      _invoke('setCargoWorldPosition', <String, Object>{
        'id': ProjectedRealtime3dScene.cargo.entityId,
        'x': position.x,
        'y': position.y,
        'z': position.z,
      });

  @override
  Future<CargoPick3d?> pickCargo(ScreenPoint3 screenPoint) =>
      _interaction.pickCargo(screenPoint);

  @override
  Ray3 screenRay(ScreenPoint3 screenPoint) =>
      _interaction.screenRay(screenPoint);

  @override
  Future<void> setCargoWorldPosition(
    String cargoEntityId,
    Vec3 position,
  ) async {
    await _interaction.setCargoWorldPosition(cargoEntityId, position);
    if (cargoEntityId == ProjectedRealtime3dScene.cargo.entityId) {
      await _sendCargoPosition(position);
    }
  }

  @override
  Future<void> setCargoSelected(String cargoEntityId, bool selected) async {
    await _interaction.setCargoSelected(cargoEntityId, selected);
    await _invoke('setCargoSelected', <String, Object>{
      'id': cargoEntityId,
      'selected': selected,
    });
  }

  @override
  Future<void> setTargetHover(
    String targetId, {
    required bool active,
    required bool compatible,
  }) async {
    await _interaction.setTargetHover(
      targetId,
      active: active,
      compatible: compatible,
    );
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
  }

  @override
  Future<void> animateCargo(
    String cargoEntityId,
    Vec3 destination, {
    required CargoMotion3d motion,
  }) async {
    if (cargoEntityId != ProjectedRealtime3dScene.cargo.entityId) return;
    if (_reducedMotion) {
      await setCargoWorldPosition(cargoEntityId, destination);
      return;
    }

    final start = _interaction.cargoPosition;
    const frames = 12;
    for (var frame = 1; frame <= frames; frame++) {
      final progress = frame / frames;
      final eased = 1 - (1 - progress) * (1 - progress) * (1 - progress);
      final position = Vec3(
        start.x + ((destination.x - start.x) * eased),
        start.y + ((destination.y - start.y) * eased),
        start.z + ((destination.z - start.z) * eased),
      );
      await _interaction.setCargoWorldPosition(cargoEntityId, position);
      await _sendCargoPosition(position);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    await _interaction.setCargoWorldPosition(cargoEntityId, destination);
    await _sendCargoPosition(destination);
  }

  @override
  void dispose() {
    _interaction.removeListener(notifyListeners);
    _interaction.dispose();
    _channel = null;
    super.dispose();
  }
}
