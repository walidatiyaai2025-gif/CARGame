# CARGame Real-Time 3D Architecture

## Product decision

CARGame is migrating from a Flutter game that presents pre-rendered 3D-looking assets to a real-time interactive 3D game. The old flat/card gameplay direction is frozen for new feature work.

Flutter/Dart remains the application shell and owns startup, persistence, economy, ads, privacy, localization, accessibility, navigation, and composition. Real-time rendering is an outward adapter behind pure-Dart application ports. The selected renderer direction is Thermion/Filament for the Flutter runtime; package admission and the concrete adapter are isolated to RT3D-002 so the core game rules do not depend on a renderer package.

Existing save keys, 150-level truth, rewards, hearts, boosters, and anti-duplication rules remain authoritative unless a later migration explicitly changes them.

## Target architecture

```text
Flutter App Shell
  -> Realtime3dHost (presentation)
     -> SceneSessionController (application)
        -> World/City/Game domain state
        -> Realtime3dScenePort
           -> ThermionSceneAdapter (RT3D-002)
              -> Filament renderer / GPU
```

The renderer is replaceable. Domain/application code never imports Flutter, Thermion, Filament, Unity, OpenGL, Vulkan, Metal, or platform SDK types.

## Scene topology

Every runtime scene uses stable semantic roots rather than arbitrary renderer nodes:

```text
SceneRoot
  EnvironmentRoot
    Ground / Globe / Roads / Water
    StaticProps
  BuildingRoot
    DeliveryBuildings
    DecorativeBuildings
  CargoRoot
    SpawnedCargo
    VehicleCargo
  InteractionRoot
    PickProxies
    DeliveryVolumes
  FxRoot
    CorrectFx
    WrongFx
    ComboFx
  LightingRoot
    KeyLight
    Fill/Ambient
  CameraRig
```

Renderer entity IDs are adapter details. Gameplay refers to stable IDs such as `cargo.electronics.01` and `building.electronics`.

## Scene flow

### 1. World Globe

- Low-poly stylized Earth with country selection proxies.
- Orbit camera focused on planet origin.
- Tap performs renderer picking against country/marker entities.
- Pinch controls bounded zoom; one-finger drag controls orbit.
- Selecting a country focuses the camera before transition to its capital/city cluster.
- Countries/cities stream by metadata; the complete world does not require every city mesh resident at once.

### 2. Country / City Diorama

- Toy-like low-poly city island/diorama.
- Bounded isometric-perspective camera, not a flat UI map.
- Buildings, roads, delivery hubs, homes, warehouse and level markers are actual 3D entities.
- City selection transitions by camera flight and asset streaming, not card replacement.

### 3. Gameplay Delivery Scene

- Fixed/bounded isometric-perspective camera to protect touch accuracy.
- Cargo spawns in a warehouse/loading area.
- Delivery buildings expose explicit 3D delivery volumes independent of visible mesh complexity.
- Player drags cargo through a horizontal world drag plane.
- Correct target snaps cargo to a delivery socket; wrong/missed target returns to exact pickup origin.
- Camera orbit is disabled while cargo is actively dragged.

## Camera system

### GlobeCameraRig

- Perspective camera.
- Focus: globe center or selected country anchor.
- Controls: orbit + bounded pinch zoom.
- Pitch is clamped to avoid pole flips.
- Country focus uses a short eased spherical interpolation.

### CityCameraRig

- Perspective with a narrow field of view to retain a toy/isometric feel while preserving real parallax.
- Default yaw approximately 45 degrees and elevated pitch approximately 50-60 degrees.
- Bounded pan and zoom only; no free-flight camera.
- Camera collision is unnecessary because the rig stays above the diorama.

### GameplayCameraRig

- Same visual family as CityCameraRig for continuity.
- Framing is derived from board bounds and safe-area aspect ratio.
- Camera input is locked during cargo drag and resolution.
- Renderer must expose `screenRay(screenPoint)` so interaction math stays renderer-independent.

## First core mechanic: 3D cargo drag and delivery

RT3D-001 implements the renderer-independent state machine:

```text
idle
  -> selecting (GPU/entity pick pending)
  -> dragging (ray projected to horizontal drag plane)
  -> resolving (snap or return animation)
  -> idle
```

Rules:

1. A second pickup is rejected while selecting, dragging or resolving.
2. Renderer pick returns a stable cargo entity ID, cargo type ID and world position.
3. The controller creates a horizontal plane through the pickup position.
4. Each pointer update converts the screen point to a world ray.
5. Ray/plane intersection becomes the logical drop point; a small Y lift is render-only feedback.
6. Delivery targets use explicit AABBs and accepted cargo type IDs.
7. Compatible target -> snap to target socket.
8. Incompatible target -> wrong-target result + return to origin.
9. No target -> miss result + return to origin.
10. Cancel/back/interruption -> return to origin before releasing input when the renderer is available.

The controller does not spend moves, award coins, mutate save data, or complete a level. Those effects remain higher-level gameplay orchestration and will consume the deterministic outcome later.

## Renderer adapter contract (RT3D-002)

The concrete Thermion adapter must implement:

- `pickCargo(screenPoint)` using renderer picking.
- `screenRay(screenPoint)` from active camera/view matrices.
- `setCargoWorldPosition(entityId, position)`.
- `setCargoSelected(entityId, selected)` for outline/emissive selection feedback.
- `setTargetHover(targetId, active, compatible)` for green/red delivery feedback.
- `animateCargo(... snapToTarget/returnToOrigin)` with bounded durations and reduced-motion handling.

No gameplay rule may be moved into the adapter.

## Lighting and visual language

- Stylized low-poly / toy-like geometry.
- Key light from upper-left to retain the established brand direction.
- Soft ambient/IBL fill, restrained shadows, saturated materials and readable silhouettes.
- Avoid photoreal materials, dense textures, tiny geometry and screen-space UI pretending to be world geometry.
- Selection uses emissive/rim/outline cues plus non-color feedback.

## Mobile performance targets

These are engineering budgets to validate on physical Android devices, not claimed measurements:

- Prefer one main directional shadow caster.
- LOD or cull distant city props.
- Merge static decorative meshes/materials where practical.
- Use delivery/pick proxy volumes instead of mesh-accurate physics for touch interaction.
- Pool cargo, particles and common props.
- Keep expensive post-processing optional under the existing performance/reduced-effects policy.
- Stream city/world assets and release the previous scene after transition settles.

## 3D asset pipeline

Runtime format target: GLB/glTF with stable semantic node names and separate low-cost interaction proxies where required.

Asset families:

- `world/globe`
- `world/country_markers`
- `city/buildings`
- `city/roads_props`
- `game/cargo`
- `game/delivery_buildings`
- `game/vehicles`
- `fx/meshes`

Every production asset needs provenance, generation/source prompt, license/commercial-use approval, checksum, scale convention, pivot convention, LOD information and target material count.

### Generation prompt: first cargo crate

`Stylized low-poly 3D cargo crate for a mobile delivery sorting game, toy-like proportions, rounded bevels, chunky readable silhouette, warm saturated materials, subtle metal corner brackets, no text, no logos, centered origin, pivot at bottom center, real-world scale approximately 0.6m wide, clean topology, low material count, optimized for mobile, UVs clean, game-ready GLB, neutral pose, soft upper-left studio lighting for preview only.`

### Generation prompt: delivery house

`Stylized low-poly 3D suburban delivery house for a mobile isometric game, toy-like architecture, bright readable roof and door, slightly exaggerated proportions, simple windows, small porch, clean front delivery socket area, no text, no logos, optimized mobile geometry, low material count, pivot at ground center, game-ready GLB, coherent with colorful logistics city diorama.`

### Generation prompt: warehouse hub

`Stylized low-poly 3D logistics warehouse hub for a mobile cargo game, isometric toy-like proportions, loading bays, simple roller doors, roof vents, small signs without text, clear cargo spawn platform, modular clean geometry, low material count, optimized for mobile, pivot at ground center, game-ready GLB.`

### Generation prompt: globe

`Stylized low-poly 3D planet Earth for a mobile world-map game, clean faceted continents, simplified coastline geometry, saturated blue oceans and distinct land masses, toy-like premium look, no labels, no borders baked into texture, separate selectable country/region proxy strategy, optimized mobile topology, centered at world origin, radius 1 unit, game-ready GLB.`

## Migration phases

1. **RT3D-001 — Foundation:** pure-Dart geometry, interaction state machine, renderer port, architecture and tests.
2. **RT3D-002 — Runtime bridge:** governed Thermion dependency, host widget, entity registry, renderer picking/transforms, first procedural/primitive scene.
3. **RT3D-003 — Gameplay vertical slice:** one warehouse, three cargo objects, three delivery buildings, camera lock, correct/wrong/combo feedback.
4. **RT3D-004 — Globe navigation:** Earth, country selection, camera focus and country-to-city transition.
5. **RT3D-005 — City streaming:** city diorama kits, level nodes, asset lifetime/LOD/culling.
6. **RT3D-006 — Production asset pipeline:** GLB provenance, validation, budgets, generated asset intake and fallback policy.
7. **RT3D-007 — Full gameplay migration:** move current 150-level gameplay presentation to the real-time scene while preserving progression truth.
8. **RT3D-008 — Performance/device certification:** frame-time, memory, thermal, low-end-device and accessibility/reduced-motion evidence.

## Superseded direction

The existing WebP-only `AST-007` cargo visual intake remains valuable reference/provenance work but is no longer the destination for primary gameplay rendering. Do not spend new production art effort generating flat cargo WebP as the final gameplay asset format. Preserve the merged data and fallbacks until the real-time replacement is proven and migration-safe.
