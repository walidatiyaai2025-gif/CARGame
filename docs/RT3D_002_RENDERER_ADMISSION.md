# RT3D-002 renderer admission boundary

RT3D-002 does not select a renderer by package popularity or by the ability to display a model in isolation. A production gameplay renderer must pass the source-controlled `Realtime3dRendererAdmissionPolicy` before it can replace the projected RT3D-001 adapter.

## Required production capabilities

The selected renderer must be native-GPU backed and support a real-time scene, local GLB loading, PBR materials, dynamic lighting, shadows, object picking, mutable entity transforms, camera control, Android, and the repository's stable Flutter release channel. A candidate that raises the current Android minSdk above 23 is rejected by this checkpoint.

WebView/model-viewer wrappers remain useful for product/model preview use cases but are not accepted as the CARGame production gameplay renderer. The existing projected scene remains an explicit transitional fallback only.

## First visual slice admission

The first production scene must contain a vehicle, at least two cargo nodes, an environment/warehouse node, a delivery target, ground and road geometry. Production model descriptors must use GLB or GLTF, live below `assets/3d/runtime/models/`, and carry a non-empty provenance reference before validation can succeed.

The first mobile scene budget is bounded to 250,000 triangles, 120 draw calls and 96 MB of texture data. These are source-level admission ceilings, not measured physical-device performance claims. Device profiling can lower these ceilings later.

## Architecture boundary

Renderer code stays behind `Realtime3dScenePort`. Save/progression/economy truth, navigation, localization, settings, privacy, ads and accessibility remain Flutter/application-owned. Cargo picking, dragging, snap/return and target compatibility remain driven by the RT3D pure-Dart contracts rather than renderer-specific business rules.

## Evidence boundary

No renderer package and no production GLB/GLTF binary is admitted by this document. Package selection, dependency governance, actual model licensing/provenance, runtime integration, physical-device profiling and root-APK promotion remain subsequent RT3D-002 checkpoints.
