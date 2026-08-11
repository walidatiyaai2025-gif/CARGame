import 'package:cargo_sort_game/core/domain/realtime_3d/production_scene_slice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Realtime3dProductionSceneSlice validSlice() {
    const assets = <Realtime3dModelAsset>[
      Realtime3dModelAsset(
        assetId: 'vehicle.delivery_van',
        path: 'assets/3d/runtime/models/vehicle/delivery_van.glb',
        format: Realtime3dModelFormat.glb,
        provenanceRef: 'provenance/vehicle.delivery_van',
      ),
      Realtime3dModelAsset(
        assetId: 'cargo.crate',
        path: 'assets/3d/runtime/models/cargo/crate.glb',
        format: Realtime3dModelFormat.glb,
        provenanceRef: 'provenance/cargo.crate',
      ),
      Realtime3dModelAsset(
        assetId: 'environment.warehouse',
        path: 'assets/3d/runtime/models/environment/warehouse.glb',
        format: Realtime3dModelFormat.glb,
        provenanceRef: 'provenance/environment.warehouse',
      ),
      Realtime3dModelAsset(
        assetId: 'environment.delivery_target',
        path: 'assets/3d/runtime/models/environment/delivery_target.glb',
        format: Realtime3dModelFormat.glb,
        provenanceRef: 'provenance/environment.delivery_target',
      ),
      Realtime3dModelAsset(
        assetId: 'environment.ground',
        path: 'assets/3d/runtime/models/environment/ground.glb',
        format: Realtime3dModelFormat.glb,
        provenanceRef: 'provenance/environment.ground',
      ),
      Realtime3dModelAsset(
        assetId: 'environment.road',
        path: 'assets/3d/runtime/models/environment/road.glb',
        format: Realtime3dModelFormat.glb,
        provenanceRef: 'provenance/environment.road',
      ),
    ];
    const nodes = <Realtime3dSceneNode>[
      Realtime3dSceneNode(
        nodeId: 'vehicle-1',
        assetId: 'vehicle.delivery_van',
        role: Realtime3dSceneRole.vehicle,
      ),
      Realtime3dSceneNode(
        nodeId: 'cargo-1',
        assetId: 'cargo.crate',
        role: Realtime3dSceneRole.cargo,
      ),
      Realtime3dSceneNode(
        nodeId: 'cargo-2',
        assetId: 'cargo.crate',
        role: Realtime3dSceneRole.cargo,
      ),
      Realtime3dSceneNode(
        nodeId: 'warehouse-1',
        assetId: 'environment.warehouse',
        role: Realtime3dSceneRole.environment,
      ),
      Realtime3dSceneNode(
        nodeId: 'target-1',
        assetId: 'environment.delivery_target',
        role: Realtime3dSceneRole.deliveryTarget,
      ),
      Realtime3dSceneNode(
        nodeId: 'ground-1',
        assetId: 'environment.ground',
        role: Realtime3dSceneRole.ground,
      ),
      Realtime3dSceneNode(
        nodeId: 'road-1',
        assetId: 'environment.road',
        role: Realtime3dSceneRole.road,
      ),
    ];

    return Realtime3dProductionSceneSlice(
      assets: assets,
      nodes: nodes,
      camera: const Realtime3dCameraPreset(
        fieldOfViewDegrees: 50,
        orbitDistance: 11,
        minPitchDegrees: -20,
        maxPitchDegrees: 55,
      ),
      lighting: const Realtime3dLightingPreset(
        keyLightIntensity: 1,
        ambientIntensity: 0.35,
        shadowsEnabled: true,
      ),
      budget: const Realtime3dMobileRenderBudget(
        maxTriangles: 180000,
        maxDrawCalls: 90,
        maxTextureMegabytes: 72,
      ),
    );
  }

  test('accepts a complete first production visual slice', () {
    expect(validSlice().validate().isValid, isTrue);
  });

  test('requires multiple cargo nodes', () {
    final source = validSlice();
    final slice = Realtime3dProductionSceneSlice(
      assets: source.assets,
      nodes: source.nodes.where((node) => node.nodeId != 'cargo-2'),
      camera: source.camera,
      lighting: source.lighting,
      budget: source.budget,
    );

    expect(
      slice.validate().errors,
      contains('production slice requires at least two cargo nodes'),
    );
  });

  test('rejects missing provenance and non-governed asset paths', () {
    final source = validSlice();
    final invalidAsset = Realtime3dModelAsset(
      assetId: 'vehicle.delivery_van',
      path: 'assets/random/delivery_van.glb',
      format: Realtime3dModelFormat.glb,
      provenanceRef: '',
    );
    final slice = Realtime3dProductionSceneSlice(
      assets: <Realtime3dModelAsset>[
        invalidAsset,
        ...source.assets.skip(1),
      ],
      nodes: source.nodes,
      camera: source.camera,
      lighting: source.lighting,
      budget: source.budget,
    );

    final errors = slice.validate().errors;
    expect(
      errors,
      contains(
        'asset must use the governed local runtime path: vehicle.delivery_van',
      ),
    );
    expect(
      errors,
      contains('asset provenance is required: vehicle.delivery_van'),
    );
  });

  test('rejects format mismatches and unknown scene assets', () {
    final source = validSlice();
    final badRoad = const Realtime3dModelAsset(
      assetId: 'environment.road',
      path: 'assets/3d/runtime/models/environment/road.gltf',
      format: Realtime3dModelFormat.glb,
      provenanceRef: 'provenance/environment.road',
    );
    final slice = Realtime3dProductionSceneSlice(
      assets: <Realtime3dModelAsset>[
        ...source.assets.take(source.assets.length - 1),
        badRoad,
      ],
      nodes: <Realtime3dSceneNode>[
        ...source.nodes,
        const Realtime3dSceneNode(
          nodeId: 'ghost',
          assetId: 'missing.asset',
          role: Realtime3dSceneRole.cargo,
        ),
      ],
      camera: source.camera,
      lighting: source.lighting,
      budget: source.budget,
    );

    final errors = slice.validate().errors;
    expect(
      errors,
      contains('asset format/path mismatch: environment.road'),
    );
    expect(errors, contains('scene node references unknown asset: ghost'));
  });

  test('rejects camera, lighting and render budgets outside production bounds', () {
    final source = validSlice();
    final slice = Realtime3dProductionSceneSlice(
      assets: source.assets,
      nodes: source.nodes,
      camera: const Realtime3dCameraPreset(
        fieldOfViewDegrees: 90,
        orbitDistance: 0,
        minPitchDegrees: 50,
        maxPitchDegrees: 20,
      ),
      lighting: const Realtime3dLightingPreset(
        keyLightIntensity: 0,
        ambientIntensity: 2,
        shadowsEnabled: false,
      ),
      budget: const Realtime3dMobileRenderBudget(
        maxTriangles: 300000,
        maxDrawCalls: 150,
        maxTextureMegabytes: 128,
      ),
    );

    final errors = slice.validate().errors;
    expect(errors, contains('camera preset is outside the production bounds'));
    expect(
      errors,
      contains(
        'lighting preset must include bounded key/ambient light and shadows',
      ),
    );
    expect(
      errors,
      contains('mobile render budget exceeds the production ceiling'),
    );
  });
}
