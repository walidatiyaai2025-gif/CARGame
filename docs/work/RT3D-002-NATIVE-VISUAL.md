# RT3D-002 Native Visual Checkpoint

## Scope

This checkpoint turns the renderer-admission contract into an owner-visible native GPU scene while preserving the RT3D-001 pure-Dart interaction contracts and projected fallback.

## Visible path

Home -> `3D` -> `3D VISUAL LAB` -> `GPU` -> `NATIVE 3D`.

The native checkpoint contains real runtime 3D geometry for ground, roads, warehouse/delivery buildings, a stylized vehicle, multiple cargo objects, delivery pads, perspective camera, upper-left key light, ambient light, shadows, orbit inspection, cargo selection, drag-plane movement, compatible/wrong target resolution, snap/return, Reset, Reduced Motion handling, loading state, and an explicit renderer-failure fallback.

## Renderer admission

- Candidate: `three_js 0.3.0`.
- Direct package license review: MIT.
- Dependency lock resolved on Flutter 3.44.8 without weakening repository gates.
- The native renderer stays in the feature/infrastructure boundary. `core/domain` and `core/application` remain renderer-independent.

## Truth boundary

This is the first native visual checkpoint, not final RT3D-002 completion. Production GLB model admission/provenance and physical-device visual/performance evidence remain separate acceptance work. No third-party model licensing evidence is fabricated in this checkpoint.

## APK rule

This checkpoint is not owner-complete until its exact successful `main` source commit is promoted by the governed workflow into `Last verified APK/CARGame-latest-verified.apk`.
