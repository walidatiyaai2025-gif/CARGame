import '../../domain/realtime_3d/cargo_interaction.dart';
import '../../domain/realtime_3d/geometry.dart';
import 'realtime_3d_scene_port.dart';

enum CargoDragPhase { idle, selecting, dragging, resolving }

class CargoDragController {
  CargoDragController({
    required this.scene,
    required Iterable<DeliveryTarget3d> targets,
    this.dragLift = 0.2,
  }) : targets = List<DeliveryTarget3d>.unmodifiable(targets) {
    if (dragLift < 0) {
      throw ArgumentError.value(dragLift, 'dragLift', 'Must be non-negative');
    }
  }

  final Realtime3dScenePort scene;
  final List<DeliveryTarget3d> targets;
  final double dragLift;

  CargoDragPhase _phase = CargoDragPhase.idle;
  _DragSession? _session;
  String? _hoveredTargetId;

  CargoDragPhase get phase => _phase;

  bool get isBusy => _phase != CargoDragPhase.idle;

  Future<CargoInteractionResult> beginDrag(ScreenPoint3 screenPoint) async {
    if (_phase != CargoDragPhase.idle) {
      return const CargoInteractionResult(
        outcome: CargoInteractionOutcome.busy,
      );
    }

    _phase = CargoDragPhase.selecting;
    CargoPick3d? pick;
    try {
      pick = await scene.pickCargo(screenPoint);
    } catch (_) {
      _phase = CargoDragPhase.idle;
      return const CargoInteractionResult(
        outcome: CargoInteractionOutcome.rendererError,
      );
    }

    if (pick == null) {
      _phase = CargoDragPhase.idle;
      return const CargoInteractionResult(
        outcome: CargoInteractionOutcome.noCargo,
      );
    }

    final session = _DragSession(
      pick: pick,
      dragPlane: Plane3.fromPointNormal(pick.worldPosition, Vec3.up),
      surfacePoint: pick.worldPosition,
    );
    _session = session;
    _phase = CargoDragPhase.dragging;

    try {
      await scene.setCargoSelected(pick.cargo.entityId, true);
    } catch (_) {
      _clearSession();
      return CargoInteractionResult(
        outcome: CargoInteractionOutcome.rendererError,
        cargoEntityId: pick.cargo.entityId,
      );
    }

    return CargoInteractionResult(
      outcome: CargoInteractionOutcome.picked,
      cargoEntityId: pick.cargo.entityId,
      worldPosition: pick.worldPosition,
    );
  }

  Future<CargoInteractionResult> updateDrag(ScreenPoint3 screenPoint) async {
    final session = _session;
    if (_phase != CargoDragPhase.dragging || session == null) {
      return const CargoInteractionResult(
        outcome: CargoInteractionOutcome.busy,
      );
    }

    final surfacePoint = session.dragPlane.intersectRay(
      scene.screenRay(screenPoint),
    );
    if (surfacePoint == null) {
      return CargoInteractionResult(
        outcome: CargoInteractionOutcome.rayMiss,
        cargoEntityId: session.pick.cargo.entityId,
      );
    }

    session.surfacePoint = surfacePoint;
    final renderPoint = surfacePoint + Vec3(0, dragLift, 0);

    try {
      await scene.setCargoWorldPosition(
        session.pick.cargo.entityId,
        renderPoint,
      );
      await _syncTargetHover(session, surfacePoint);
    } catch (_) {
      return CargoInteractionResult(
        outcome: CargoInteractionOutcome.rendererError,
        cargoEntityId: session.pick.cargo.entityId,
        worldPosition: renderPoint,
      );
    }

    return CargoInteractionResult(
      outcome: CargoInteractionOutcome.moved,
      cargoEntityId: session.pick.cargo.entityId,
      targetId: _hoveredTargetId,
      worldPosition: renderPoint,
    );
  }

  Future<CargoInteractionResult> endDrag() async {
    final session = _session;
    if (_phase != CargoDragPhase.dragging || session == null) {
      return const CargoInteractionResult(
        outcome: CargoInteractionOutcome.busy,
      );
    }

    _phase = CargoDragPhase.resolving;
    final target = _targetContaining(session.surfacePoint);
    final isAccepted = target?.accepts(session.pick.cargo.cargoTypeId) ?? false;
    final outcome = target == null
        ? CargoInteractionOutcome.missed
        : isAccepted
        ? CargoInteractionOutcome.accepted
        : CargoInteractionOutcome.wrongTarget;
    final destination = isAccepted
        ? target!.snapPosition
        : session.pick.worldPosition;
    final motion = isAccepted
        ? CargoMotion3d.snapToTarget
        : CargoMotion3d.returnToOrigin;

    try {
      await scene.animateCargo(
        session.pick.cargo.entityId,
        destination,
        motion: motion,
      );
      await _clearVisualState(session);
      return CargoInteractionResult(
        outcome: outcome,
        cargoEntityId: session.pick.cargo.entityId,
        targetId: target?.targetId,
        worldPosition: destination,
      );
    } catch (_) {
      await _bestEffortClearVisualState(session);
      return CargoInteractionResult(
        outcome: CargoInteractionOutcome.rendererError,
        cargoEntityId: session.pick.cargo.entityId,
        targetId: target?.targetId,
      );
    } finally {
      _clearSession();
    }
  }

  Future<CargoInteractionResult> cancelDrag() async {
    final session = _session;
    if (_phase != CargoDragPhase.dragging || session == null) {
      return const CargoInteractionResult(
        outcome: CargoInteractionOutcome.busy,
      );
    }

    _phase = CargoDragPhase.resolving;
    try {
      await scene.animateCargo(
        session.pick.cargo.entityId,
        session.pick.worldPosition,
        motion: CargoMotion3d.returnToOrigin,
      );
      await _clearVisualState(session);
      return CargoInteractionResult(
        outcome: CargoInteractionOutcome.cancelled,
        cargoEntityId: session.pick.cargo.entityId,
        worldPosition: session.pick.worldPosition,
      );
    } catch (_) {
      await _bestEffortClearVisualState(session);
      return CargoInteractionResult(
        outcome: CargoInteractionOutcome.rendererError,
        cargoEntityId: session.pick.cargo.entityId,
      );
    } finally {
      _clearSession();
    }
  }

  Future<void> _syncTargetHover(_DragSession session, Vec3 worldPoint) async {
    final nextTarget = _targetContaining(worldPoint);
    final nextTargetId = nextTarget?.targetId;
    if (nextTargetId == _hoveredTargetId) {
      return;
    }

    final previous = _targetById(_hoveredTargetId);
    if (previous != null) {
      await scene.setTargetHover(
        previous.targetId,
        active: false,
        compatible: previous.accepts(session.pick.cargo.cargoTypeId),
      );
    }

    if (nextTarget != null) {
      await scene.setTargetHover(
        nextTarget.targetId,
        active: true,
        compatible: nextTarget.accepts(session.pick.cargo.cargoTypeId),
      );
    }
    _hoveredTargetId = nextTargetId;
  }

  DeliveryTarget3d? _targetContaining(Vec3 worldPoint) {
    for (final target in targets) {
      if (target.contains(worldPoint)) {
        return target;
      }
    }
    return null;
  }

  DeliveryTarget3d? _targetById(String? targetId) {
    if (targetId == null) {
      return null;
    }
    for (final target in targets) {
      if (target.targetId == targetId) {
        return target;
      }
    }
    return null;
  }

  Future<void> _clearVisualState(_DragSession session) async {
    final hovered = _targetById(_hoveredTargetId);
    if (hovered != null) {
      await scene.setTargetHover(
        hovered.targetId,
        active: false,
        compatible: hovered.accepts(session.pick.cargo.cargoTypeId),
      );
    }
    await scene.setCargoSelected(session.pick.cargo.entityId, false);
  }

  Future<void> _bestEffortClearVisualState(_DragSession session) async {
    try {
      await _clearVisualState(session);
    } catch (_) {
      // Renderer recovery is best-effort. The interaction state is still released.
    }
  }

  void _clearSession() {
    _session = null;
    _hoveredTargetId = null;
    _phase = CargoDragPhase.idle;
  }
}

class _DragSession {
  _DragSession({
    required this.pick,
    required this.dragPlane,
    required this.surfacePoint,
  });

  final CargoPick3d pick;
  final Plane3 dragPlane;
  Vec3 surfacePoint;
}
