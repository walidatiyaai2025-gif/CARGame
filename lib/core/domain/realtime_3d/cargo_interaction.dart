import 'geometry.dart';

class CargoEntity3d {
  const CargoEntity3d({required this.entityId, required this.cargoTypeId});

  final String entityId;
  final String cargoTypeId;
}

class CargoPick3d {
  const CargoPick3d({required this.cargo, required this.worldPosition});

  final CargoEntity3d cargo;
  final Vec3 worldPosition;
}

class DeliveryTarget3d {
  DeliveryTarget3d({
    required this.targetId,
    required this.bounds,
    required this.snapPosition,
    required Iterable<String> acceptedCargoTypeIds,
  }) : acceptedCargoTypeIds = Set<String>.unmodifiable(acceptedCargoTypeIds);

  final String targetId;
  final Aabb3 bounds;
  final Vec3 snapPosition;
  final Set<String> acceptedCargoTypeIds;

  bool accepts(String cargoTypeId) =>
      acceptedCargoTypeIds.contains(cargoTypeId);

  bool contains(Vec3 worldPoint) => bounds.contains(worldPoint);
}

enum CargoInteractionOutcome {
  picked,
  moved,
  accepted,
  wrongTarget,
  missed,
  cancelled,
  busy,
  noCargo,
  rayMiss,
  rendererError,
}

class CargoInteractionResult {
  const CargoInteractionResult({
    required this.outcome,
    this.cargoEntityId,
    this.targetId,
    this.worldPosition,
  });

  final CargoInteractionOutcome outcome;
  final String? cargoEntityId;
  final String? targetId;
  final Vec3? worldPosition;

  bool get isAccepted => outcome == CargoInteractionOutcome.accepted;
}
