import 'dart:async';

import 'package:cargo_sort_game/core/application/realtime_3d/cargo_drag_controller.dart';
import 'package:cargo_sort_game/core/application/realtime_3d/realtime_3d_scene_port.dart';
import 'package:cargo_sort_game/core/domain/realtime_3d/cargo_interaction.dart';
import 'package:cargo_sort_game/core/domain/realtime_3d/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cargo = CargoEntity3d(
    entityId: 'cargo.electronics.01',
    cargoTypeId: 'electronics',
  );
  const origin = Vec3(0, 0, 0);
  const pick = CargoPick3d(cargo: cargo, worldPosition: origin);

  DeliveryTarget3d compatibleTarget() => DeliveryTarget3d(
    targetId: 'building.electronics',
    bounds: const Aabb3(min: Vec3(4, -0.5, 4), max: Vec3(6, 0.5, 6)),
    snapPosition: const Vec3(5, 0, 5),
    acceptedCargoTypeIds: const <String>{'electronics'},
  );

  DeliveryTarget3d incompatibleTarget() => DeliveryTarget3d(
    targetId: 'building.food',
    bounds: const Aabb3(min: Vec3(8, -0.5, 8), max: Vec3(10, 0.5, 10)),
    snapPosition: const Vec3(9, 0, 9),
    acceptedCargoTypeIds: const <String>{'food'},
  );

  test('dragging compatible cargo snaps to the delivery target', () async {
    final scene = _FakeScenePort(pick: pick);
    final controller = CargoDragController(
      scene: scene,
      targets: <DeliveryTarget3d>[compatibleTarget(), incompatibleTarget()],
      dragLift: 0.25,
    );

    final started = await controller.beginDrag(const ScreenPoint3(0, 0));
    final moved = await controller.updateDrag(const ScreenPoint3(5, 5));
    final completed = await controller.endDrag();

    expect(started.outcome, CargoInteractionOutcome.picked);
    expect(moved.outcome, CargoInteractionOutcome.moved);
    expect(moved.targetId, 'building.electronics');
    expect(moved.worldPosition, const Vec3(5, 0.25, 5));
    expect(completed.outcome, CargoInteractionOutcome.accepted);
    expect(completed.targetId, 'building.electronics');
    expect(completed.worldPosition, const Vec3(5, 0, 5));
    expect(controller.phase, CargoDragPhase.idle);
    expect(scene.animations.single, (
      cargo.entityId,
      const Vec3(5, 0, 5),
      CargoMotion3d.snapToTarget,
    ));
    expect(scene.hoverEvents, <(String, bool, bool)>[
      ('building.electronics', true, true),
      ('building.electronics', false, true),
    ]);
    expect(scene.selectionEvents, <(String, bool)>[
      (cargo.entityId, true),
      (cargo.entityId, false),
    ]);
  });

  test('wrong building returns cargo to its exact pickup origin', () async {
    final scene = _FakeScenePort(pick: pick);
    final controller = CargoDragController(
      scene: scene,
      targets: <DeliveryTarget3d>[compatibleTarget(), incompatibleTarget()],
    );

    await controller.beginDrag(const ScreenPoint3(0, 0));
    final moved = await controller.updateDrag(const ScreenPoint3(9, 9));
    final completed = await controller.endDrag();

    expect(moved.targetId, 'building.food');
    expect(completed.outcome, CargoInteractionOutcome.wrongTarget);
    expect(completed.targetId, 'building.food');
    expect(completed.worldPosition, origin);
    expect(scene.animations.single, (
      cargo.entityId,
      origin,
      CargoMotion3d.returnToOrigin,
    ));
  });

  test(
    'drop outside all target volumes returns cargo without false success',
    () async {
      final scene = _FakeScenePort(pick: pick);
      final controller = CargoDragController(
        scene: scene,
        targets: <DeliveryTarget3d>[compatibleTarget()],
      );

      await controller.beginDrag(const ScreenPoint3(0, 0));
      await controller.updateDrag(const ScreenPoint3(20, 20));
      final completed = await controller.endDrag();

      expect(completed.outcome, CargoInteractionOutcome.missed);
      expect(completed.targetId, isNull);
      expect(completed.worldPosition, origin);
    },
  );

  test('cancel returns cargo and releases interaction state', () async {
    final scene = _FakeScenePort(pick: pick);
    final controller = CargoDragController(
      scene: scene,
      targets: <DeliveryTarget3d>[compatibleTarget()],
    );

    await controller.beginDrag(const ScreenPoint3(0, 0));
    await controller.updateDrag(const ScreenPoint3(3, 3));
    final cancelled = await controller.cancelDrag();

    expect(cancelled.outcome, CargoInteractionOutcome.cancelled);
    expect(cancelled.worldPosition, origin);
    expect(controller.phase, CargoDragPhase.idle);
    expect(scene.animations.single, (
      cargo.entityId,
      origin,
      CargoMotion3d.returnToOrigin,
    ));
  });

  test(
    'second pickup is rejected while the first ray pick is pending',
    () async {
      final delayedPick = Completer<CargoPick3d?>();
      final scene = _FakeScenePort(pickCompleter: delayedPick);
      final controller = CargoDragController(
        scene: scene,
        targets: <DeliveryTarget3d>[compatibleTarget()],
      );

      final first = controller.beginDrag(const ScreenPoint3(0, 0));
      await Future<void>.delayed(Duration.zero);
      expect(controller.phase, CargoDragPhase.selecting);

      final duplicate = await controller.beginDrag(const ScreenPoint3(1, 1));
      expect(duplicate.outcome, CargoInteractionOutcome.busy);

      delayedPick.complete(pick);
      final started = await first;
      expect(started.outcome, CargoInteractionOutcome.picked);
    },
  );

  test(
    'parallel screen ray does not move cargo or resolve a fake target',
    () async {
      final scene = _FakeScenePort(
        pick: pick,
        rayFactory: (_) =>
            Ray3(origin: const Vec3(0, 2, 0), direction: const Vec3(1, 0, 0)),
      );
      final controller = CargoDragController(
        scene: scene,
        targets: <DeliveryTarget3d>[compatibleTarget()],
      );

      await controller.beginDrag(const ScreenPoint3(0, 0));
      final moved = await controller.updateDrag(const ScreenPoint3(5, 5));

      expect(moved.outcome, CargoInteractionOutcome.rayMiss);
      expect(scene.positions, isEmpty);
      expect(controller.phase, CargoDragPhase.dragging);
    },
  );

  test('empty pick leaves controller idle', () async {
    final scene = _FakeScenePort();
    final controller = CargoDragController(
      scene: scene,
      targets: <DeliveryTarget3d>[compatibleTarget()],
    );

    final started = await controller.beginDrag(const ScreenPoint3(0, 0));

    expect(started.outcome, CargoInteractionOutcome.noCargo);
    expect(controller.phase, CargoDragPhase.idle);
  });
}

class _FakeScenePort implements Realtime3dScenePort {
  _FakeScenePort({
    this.pick,
    this.pickCompleter,
    Ray3 Function(ScreenPoint3)? rayFactory,
  }) : _rayFactory =
           rayFactory ??
           ((point) => Ray3(
             origin: Vec3(point.x, 10, point.y),
             direction: const Vec3(0, -1, 0),
           ));

  final CargoPick3d? pick;
  final Completer<CargoPick3d?>? pickCompleter;
  final Ray3 Function(ScreenPoint3) _rayFactory;
  final Map<String, Vec3> positions = <String, Vec3>{};
  final List<(String, bool)> selectionEvents = <(String, bool)>[];
  final List<(String, bool, bool)> hoverEvents = <(String, bool, bool)>[];
  final List<(String, Vec3, CargoMotion3d)> animations =
      <(String, Vec3, CargoMotion3d)>[];

  @override
  Future<CargoPick3d?> pickCargo(ScreenPoint3 screenPoint) =>
      pickCompleter?.future ?? Future<CargoPick3d?>.value(pick);

  @override
  Ray3 screenRay(ScreenPoint3 screenPoint) => _rayFactory(screenPoint);

  @override
  Future<void> setCargoWorldPosition(
    String cargoEntityId,
    Vec3 position,
  ) async {
    positions[cargoEntityId] = position;
  }

  @override
  Future<void> setCargoSelected(String cargoEntityId, bool selected) async {
    selectionEvents.add((cargoEntityId, selected));
  }

  @override
  Future<void> setTargetHover(
    String targetId, {
    required bool active,
    required bool compatible,
  }) async {
    hoverEvents.add((targetId, active, compatible));
  }

  @override
  Future<void> animateCargo(
    String cargoEntityId,
    Vec3 destination, {
    required CargoMotion3d motion,
  }) async {
    animations.add((cargoEntityId, destination, motion));
    positions[cargoEntityId] = destination;
  }
}
