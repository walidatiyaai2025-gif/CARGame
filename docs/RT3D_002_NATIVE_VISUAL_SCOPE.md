# RT3D-002 Native Visual Acceptance Boundary

This checkpoint is user-facing and therefore follows the repository visual-APK rule.

## Must be visible in-app

- Native GPU-rendered 3D ground and roads.
- Warehouse and two delivery buildings.
- One stylized 3D vehicle.
- Multiple cargo objects with one interactive cargo bound to `CargoDragController`.
- Perspective camera orbit.
- Key and ambient lighting with mobile shadows.
- Compatible/wrong target feedback plus snap/return behavior.
- Loading, renderer failure, Reset, Back/fallback, and Reduced Motion behavior.

## Handoff rule

PR/debug artifacts are verification evidence only. Owner-facing completion requires the exact successful merged `main` source to be promoted into `Last verified APK/CARGame-latest-verified.apk`.

## Deferred from this checkpoint

Production GLB model admission and provenance, richer vehicle controls, globe/city streaming, and physical-device performance certification remain follow-on work. They must not be claimed by this checkpoint.
