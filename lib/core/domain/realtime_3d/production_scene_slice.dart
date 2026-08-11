enum Realtime3dModelFormat { glb, gltf }

enum Realtime3dSceneRole {
  vehicle,
  cargo,
  environment,
  deliveryTarget,
  ground,
  road,
}

final class Realtime3dModelAsset {
  const Realtime3dModelAsset({
    required this.assetId,
    required this.path,
    required this.format,
    required this.provenanceRef,
  });

  final String assetId;
  final String path;
  final Realtime3dModelFormat format;
  final String provenanceRef;

  bool get usesLocalRuntimePath => path.startsWith('assets/3d/runtime/models/');

  bool get extensionMatchesFormat => switch (format) {
    Realtime3dModelFormat.glb => path.toLowerCase().endsWith('.glb'),
    Realtime3dModelFormat.gltf => path.toLowerCase().endsWith('.gltf'),
  };

  bool get hasProvenance => provenanceRef.trim().isNotEmpty;
}

final class Realtime3dSceneNode {
  const Realtime3dSceneNode({
    required this.nodeId,
    required this.assetId,
    required this.role,
  });

  final String nodeId;
  final String assetId;
  final Realtime3dSceneRole role;
}

final class Realtime3dCameraPreset {
  const Realtime3dCameraPreset({
    required this.fieldOfViewDegrees,
    required this.orbitDistance,
    required this.minPitchDegrees,
    required this.maxPitchDegrees,
  });

  final double fieldOfViewDegrees;
  final double orbitDistance;
  final double minPitchDegrees;
  final double maxPitchDegrees;

  bool get isValid =>
      fieldOfViewDegrees >= 25 &&
      fieldOfViewDegrees <= 75 &&
      orbitDistance > 0 &&
      minPitchDegrees < maxPitchDegrees &&
      minPitchDegrees >= -89 &&
      maxPitchDegrees <= 89;
}

final class Realtime3dLightingPreset {
  const Realtime3dLightingPreset({
    required this.keyLightIntensity,
    required this.ambientIntensity,
    required this.shadowsEnabled,
  });

  final double keyLightIntensity;
  final double ambientIntensity;
  final bool shadowsEnabled;

  bool get isValid =>
      keyLightIntensity > 0 &&
      ambientIntensity >= 0 &&
      ambientIntensity <= keyLightIntensity &&
      shadowsEnabled;
}

final class Realtime3dMobileRenderBudget {
  const Realtime3dMobileRenderBudget({
    required this.maxTriangles,
    required this.maxDrawCalls,
    required this.maxTextureMegabytes,
  });

  static const productionCeiling = Realtime3dMobileRenderBudget(
    maxTriangles: 250000,
    maxDrawCalls: 120,
    maxTextureMegabytes: 96,
  );

  final int maxTriangles;
  final int maxDrawCalls;
  final int maxTextureMegabytes;

  bool get isPositive =>
      maxTriangles > 0 && maxDrawCalls > 0 && maxTextureMegabytes > 0;

  bool fitsWithin(Realtime3dMobileRenderBudget ceiling) =>
      maxTriangles <= ceiling.maxTriangles &&
      maxDrawCalls <= ceiling.maxDrawCalls &&
      maxTextureMegabytes <= ceiling.maxTextureMegabytes;
}

final class Realtime3dSceneValidationResult {
  Realtime3dSceneValidationResult(Iterable<String> errors)
    : errors = List<String>.unmodifiable(errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

final class Realtime3dProductionSceneSlice {
  Realtime3dProductionSceneSlice({
    required Iterable<Realtime3dModelAsset> assets,
    required Iterable<Realtime3dSceneNode> nodes,
    required this.camera,
    required this.lighting,
    required this.budget,
  }) : assets = List<Realtime3dModelAsset>.unmodifiable(assets),
       nodes = List<Realtime3dSceneNode>.unmodifiable(nodes);

  final List<Realtime3dModelAsset> assets;
  final List<Realtime3dSceneNode> nodes;
  final Realtime3dCameraPreset camera;
  final Realtime3dLightingPreset lighting;
  final Realtime3dMobileRenderBudget budget;

  Realtime3dSceneValidationResult validate() {
    final errors = <String>[];
    final assetsById = <String, Realtime3dModelAsset>{};
    final nodeIds = <String>{};

    for (final asset in assets) {
      if (asset.assetId.trim().isEmpty) {
        errors.add('asset id must not be blank');
        continue;
      }
      if (assetsById.containsKey(asset.assetId)) {
        errors.add('duplicate asset id: ${asset.assetId}');
      } else {
        assetsById[asset.assetId] = asset;
      }
      if (!asset.usesLocalRuntimePath) {
        errors.add('asset must use the governed local runtime path: ${asset.assetId}');
      }
      if (!asset.extensionMatchesFormat) {
        errors.add('asset format/path mismatch: ${asset.assetId}');
      }
      if (!asset.hasProvenance) {
        errors.add('asset provenance is required: ${asset.assetId}');
      }
    }

    for (final node in nodes) {
      if (node.nodeId.trim().isEmpty) {
        errors.add('scene node id must not be blank');
      } else if (!nodeIds.add(node.nodeId)) {
        errors.add('duplicate scene node id: ${node.nodeId}');
      }
      if (!assetsById.containsKey(node.assetId)) {
        errors.add('scene node references unknown asset: ${node.nodeId}');
      }
    }

    const requiredRoles = <Realtime3dSceneRole>{
      Realtime3dSceneRole.vehicle,
      Realtime3dSceneRole.environment,
      Realtime3dSceneRole.deliveryTarget,
      Realtime3dSceneRole.ground,
      Realtime3dSceneRole.road,
    };
    final presentRoles = nodes.map((node) => node.role).toSet();
    for (final role in requiredRoles.difference(presentRoles)) {
      errors.add('missing required scene role: ${role.name}');
    }

    final cargoCount = nodes
        .where((node) => node.role == Realtime3dSceneRole.cargo)
        .length;
    if (cargoCount < 2) {
      errors.add('production slice requires at least two cargo nodes');
    }
    if (!camera.isValid) {
      errors.add('camera preset is outside the production bounds');
    }
    if (!lighting.isValid) {
      errors.add('lighting preset must include bounded key/ambient light and shadows');
    }
    if (!budget.isPositive ||
        !budget.fitsWithin(Realtime3dMobileRenderBudget.productionCeiling)) {
      errors.add('mobile render budget exceeds the production ceiling');
    }

    return Realtime3dSceneValidationResult(errors);
  }
}
