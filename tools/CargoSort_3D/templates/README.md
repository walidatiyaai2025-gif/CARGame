# Cargo Sort 3D Design Package

Production-oriented Unity/URP architecture package for upgrading Cargo Sort into a premium 3D casual mobile experience.

## Contents

- **Design system:** mobile palette, glassmorphic surfaces, typography, touch targets and motion tokens.
- **Shaders/VFX:** URP cargo highlight shader, UI light sweep shader and particle/haptic/audio specifications.
- **Core logic:** isometric camera, spring-based 3D drag-and-drop, squash/stretch, drop probing and combo feedback.
- **Screens:** animated 3D world-map nodes and sequential 3-star level-clear flow.

## Engine baseline

Use Unity 2022.3 LTS or Unity 6 with Universal Render Pipeline, Linear color space, TextMesh Pro and an EventSystem. Target 60 FPS on mid-range Android/iOS; optionally expose 120 FPS on high-refresh devices.

## Scene setup

1. Add `CameraSetup` to the gameplay camera and assign the board root and directional key light.
2. Add `PhysicsRaycaster` to the gameplay camera and keep one active `EventSystem` in the scene.
3. Put draggable cargo on a `Cargo` layer; give each object a Collider, Rigidbody and a material using `CargoSort/ItemHighlight`.
4. Put the board interaction plane on `DragSurface`, destinations on `DropTarget`, then configure both masks in `DragAndDrop3D`.
5. Add one `ComboFXManager` and assign TMP floating-text, audio and particle prefabs.
6. Add `WorldMap3DNodes` to the map scene and assign locked/available/completed prefabs.
7. Add `LevelClearModal` under the UI canvas and wire the star graphics, counters and buttons.

## Drag feel

`DragAndDrop3D` combines raycasting with a spring-damper Rigidbody controller. The selected item is lifted from the board, velocity-limited, tilted from movement, stretched on pickup and squashed on release. MaterialPropertyBlock drives `_HighlightStrength`, so dragging does not clone materials.

Recommended Rigidbody mass: `0.7-1.2`. Start with Fixed Timestep `0.02`; use `0.0166667` only for device tiers where the CPU budget supports it.

## VFX and UI

`ItemHighlight.shader` is a URP forward-lit shader with shadow support, ambient SH lighting, specular response and animated Fresnel glow. `ButtonLightSweep.shader` supports Unity UI transparency and stencil clipping while adding a diagonal CTA sweep.

The JSON VFX contract caps simultaneous particles at 320 and defines escalating match/combo/level-complete bursts. In the production game, pool repeated particle and floating-text instances rather than relying on Instantiate/Destroy on every event.

For glass blur, prefer a controlled URP renderer feature on mid/high tiers and a translucent approximation on budget Android hardware.

## Performance budget

- 60 FPS gameplay target.
- About 80k-140k visible triangles per puzzle scene depending on device tier.
- Fewer than 120 active renderers in a normal level.
- 2x MSAA on low tier, 4x on mid/high tier.
- Soft-shadow distance around 22 on low tier and 30-40 on stronger devices.
- ASTC mobile textures where supported.
- SRP Batcher and GPU instancing enabled where applicable.

## Validation checklist

- URP is the active render pipeline.
- Main-light and soft shadows are enabled.
- TextMesh Pro references resolve.
- EventSystem and PhysicsRaycaster are active.
- Drag/drop layer masks are configured correctly.
- All draggable items have Rigidbody + Collider.
- UI CanvasScaler uses the 1080x1920 reference resolution and respects safe areas.
- Level clear animation remains readable at a 30 FPS fallback.
- Particle count stays within the selected device-tier budget.

## Rebuild the package

From the repository root:

```bash
node tools/CargoSort_3D/build_cargo_sort_3D.js
```

The script recreates `CargoSort_3D/` and outputs `CargoSort_3D_Design_Package.zip` in the current working directory. It uses Node.js built-in modules only; no npm installation is required.
