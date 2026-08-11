import '../../domain/realtime_3d/cargo_interaction.dart';
import '../../domain/realtime_3d/geometry.dart';

enum CargoMotion3d { snapToTarget, returnToOrigin }

abstract interface class Realtime3dScenePort {
  Future<CargoPick3d?> pickCargo(ScreenPoint3 screenPoint);

  Ray3 screenRay(ScreenPoint3 screenPoint);

  Future<void> setCargoWorldPosition(String cargoEntityId, Vec3 position);

  Future<void> setCargoSelected(String cargoEntityId, bool selected);

  Future<void> setTargetHover(
    String targetId, {
    required bool active,
    required bool compatible,
  });

  Future<void> animateCargo(
    String cargoEntityId,
    Vec3 destination, {
    required CargoMotion3d motion,
  });
}
