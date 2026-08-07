# CARGame 3D Asset Catalog Standard

## Purpose

This document is the production contract for authored 3D-rendered assets. It
defines paths, names, render profiles, export limits, and handoff rules before any
binary art enters the Flutter bundle. `docs/FEATURE_CATALOG.md` remains the source
of truth for implementation status.

The game uses pre-rendered 3D visuals, not a real-time 3D engine. Runtime assets
must look like one coherent product family across Arabic/English, phones, tablets,
and reduced-performance modes.

## Repository taxonomy

```text
assets/3d/
  README.md
  runtime/
    ui/
      resources/
      navigation/
      status/
    boosters/
    cargo/
      food/
      beverage/
      household/
      electronics/
      fashion/
      sports/
      toys/
      travel/
      office/
      special/
    worlds/
      harbor/
      desert/
      forest/
      snow/
      neon/
      sky/
    cities/
      harbor/
      desert/
      forest/
      snow/
      neon/
      sky/
    bosses/
    rewards/
    environments/
    effects/
  provenance/
  source/
```

Rules:

- `runtime/` contains only optimized files loaded by Flutter.
- `provenance/` contains one commercial-use record per stable asset ID; it is not
  declared as a Flutter runtime bundle.
- `source/` is reserved for reproducible authoring masters and render settings. Raw
  multi-megabyte source files require the repository's future large-file policy.
- A category must not be added because one asset is convenient. Add it only when it
  represents a durable product or interface family.
- World slugs are stable content identifiers. Renaming a displayed world must not
  rename its asset folder or saved content identity.
- No binary runtime directory is declared in `pubspec.yaml` until `AST-002` adds the
  typed manifest and `AST-011` provides provenance coverage.

## Stable naming grammar

All paths and filenames use lowercase ASCII snake case. Runtime filenames follow:

```text
cg_<family>_<subject>[_<variant>][_<state>][_p<profile>]_v<revision>.<extension>
```

| Segment | Rule | Examples |
|---|---|---|
| `cg` | Fixed CARGame prefix | `cg` |
| `family` | One taxonomy family | `ui`, `cargo`, `city`, `world`, `boss`, `reward`, `booster`, `environment`, `effect` |
| `subject` | Stable semantic noun; never a translated label | `coin`, `orange_juice`, `cairo_gate` |
| `variant` | Material/content variant only when meaningful | `gold`, `blue`, `winter` |
| `state` | Persistent visual state, not animation frame order | `locked`, `open`, `completed`, `selected`, `disabled` |
| `profile` | Optional render profile code | `pui`, `pcargo`, `pcity`, `phero` |
| `revision` | Two-digit authored revision | `v01`, `v02` |
| `extension` | Runtime raster format | `webp` |

Valid examples:

- `cg_ui_coin_gold_pui_v01.webp`
- `cg_booster_combo_shield_selected_pui_v02.webp`
- `cg_cargo_orange_juice_closed_pcargo_v01.webp`
- `cg_city_cairo_gate_locked_pcity_v03.webp`
- `cg_world_desert_caravan_phero_v01.webp`

Invalid patterns:

- spaces, hyphens, uppercase letters, dates, artist initials, or localized words;
- screen-specific copies such as `home_coin` and `shop_coin` for the same asset;
- quality labels such as `final`, `new`, `best`, or `latest`;
- frame numbers in stable asset names;
- dimensions in names; the manifest owns exported size metadata.

The future typed registry ID omits the `cg_` prefix, profile, revision, and extension.
For example, `cg_cargo_orange_juice_closed_pcargo_v01.webp` maps to the stable ID
`cargo.orange_juice.closed`. Re-exporting a visual does not change its stable ID.

## Coordinate and composition contract

- Object up axis is positive Y in the authoring package.
- Object forward faces the camera at the render profile's standard yaw.
- Pivot is bottom-center for cargo, boosters, cities, bosses, and characters; it is
  geometric center for UI resources and effects.
- The subject occupies 78–86% of the canvas. Hero environments may occupy 90% when
  their bleed is intentional.
- Preserve 7% transparent safety padding on every side unless the profile explicitly
  permits full bleed.
- Contact shadows must not cross the safe padding or be clipped.
- Mirroring is not used to create Arabic variants. Directional symbols and text are
  separate localized UI concerns.
- Rendered assets contain no baked text, numbers, currency labels, or locale-specific
  direction unless the asset is explicitly decorative and non-semantic.

## Camera profiles

Camera profiles are locked per family so assets can be mixed without perspective
jumps.

| Code | Use | Projection and pose | Framing |
|---|---|---|---|
| `pui` | resources, rewards, boosters, status | Orthographic, three-quarter front, yaw -35°, elevation 24° | Centered with 10% padding |
| `pcargo` | sortable cargo products | 50 mm equivalent perspective, yaw -30°, elevation 18° | Bottom-center pivot, consistent perceived volume |
| `pcity` | city nodes, boss gates, landmarks | Orthographic isometric, yaw -45°, elevation 30° | Ground footprint visible; contact plane aligned |
| `phero` | world heroes and large environments | 35 mm equivalent perspective, yaw selected once per world, elevation 12–20° | Full-bleed-safe center with UI exclusion zones |

Camera roll is always 0°. Field of view, orthographic scale, target height, and
subject bounding box must be stored with the source render record so another artist
can reproduce the result.

## Lighting and material direction

- Key light originates upper-left from the viewer: horizontal angle 35–45° and
  downward angle 35–50°.
- Use one large soft key, a low-intensity cool fill from lower-right, and a restrained
  rim light separating the subject from both light and dark backgrounds.
- Key-to-fill intensity starts near 3:1. Do not crush shadow detail or clip white
  highlights.
- Ambient occlusion is soft and local. Avoid dirty creases or photoreal grime.
- Contact shadows are soft, neutral, and consistent with the upper-left key.
- Materials are stylized, clean, saturated, and rounded. Metals use broad highlights;
  plastics use softer response; glass remains readable at mobile size.
- Rare/reward assets may add a rim or controlled emission but must retain the same
  camera, key direction, and shadow density.
- World palettes can change hue and atmosphere, not the global material language.

## Background and alpha

- UI, cargo, booster, city, boss, reward, and effect assets export with transparency.
- Edge pixels must be color-matted to the subject, not black or white, to prevent
  halos after scaling.
- Transparent RGB data must be clean and alpha bounds tight enough for predictable
  layout.
- Environment/hero assets may be opaque when their catalog entry declares full bleed.
- Do not bake screen blur, glass panels, drop shadows, or localization into a subject
  asset when those effects belong to shared Flutter components.

## Runtime export profiles

All runtime raster assets use 8-bit sRGB WebP. Masters remain lossless in the source
workflow. These are initial hard budgets; `AST-010` may tighten them after device
profiling without changing stable IDs.

| Family/profile | Canvas | Maximum encoded size | Alpha | Notes |
|---|---:|---:|---|---|
| UI resource/status `pui` | 256×256 | 80 KB | Required | Must remain legible at 32 logical pixels |
| Booster/reward `pui` | 384×384 | 120 KB | Required | Room for controlled glow inside bounds |
| Cargo `pcargo` | 384×384 | 120 KB | Required | Consistent product scale across a level |
| City/boss `pcity` | 512×512 | 180 KB | Required | Preserve ground footprint and lock-state silhouette |
| World hero `phero` | 1024×1024 | 350 KB | Profile dependent | Hero subject; no baked interface text |
| Environment | 1600×900 | 500 KB | Optional | Crop-safe across phone/tablet aspect ratios |
| Effect | 256×256 | 60 KB | Required | Prefer reusable particles over long frame sequences |

Export rules:

1. Trim only to the profile's fixed canvas; never auto-trim each variant differently.
2. Preserve the documented pivot and optical center.
3. Remove metadata not required at runtime.
4. Inspect at 1× and at the smallest intended display size.
5. Verify transparency over light, dark, and saturated backgrounds.
6. Compare silhouette, camera, key direction, shadow softness, and scale with the
   profile reference sheet.
7. Record the encoder and quality settings in provenance before handoff.

## Animation and state assets

- Prefer Flutter transform/opacity/particle motion over pre-rendered frame sequences.
- Separate raster states are allowed only when geometry or material truly changes.
- State sets share canvas, pivot, camera, light rig, and scale exactly.
- Effects do not own reward, navigation, or gameplay truth; completion remains in the
  domain/application flow.
- Reduced-motion mode may use the same static asset with shorter opacity feedback.
- Sprite sheets require a measured memory advantage and are registered as one asset
  with explicit frame metadata under `AST-002`.

## Accessibility and localization handoff

Every meaningful asset handoff must provide an English semantic concept, Arabic
translation key, decorative/meaningful classification, and non-image fallback plan.
The image itself must not be the only carrier of locked, selected, success, failure,
rarity, or reward state. `AST-002`, `AST-003`, and `A11Y-001` implement these fields
and behaviors.

## Provenance handoff

Before a runtime binary is accepted, its record must identify:

- stable asset ID and runtime path;
- source type: original, commissioned, licensed, or generated;
- creator/vendor/tool and creation date;
- commercial-use license or contract reference;
- generation prompt and reference-file identifiers when applicable;
- source/master checksum and exported-file checksum;
- render profile, revision, dimensions, encoder, and quality;
- reviewer and approval date;
- prohibited-use or attribution conditions.

`AST-011` owns the formal provenance schema and completeness gate. Until then, no
binary art should be treated as release-approved.

## Review checklist

An asset batch is ready for manifest integration only when:

- every filename matches the grammar and lives in the correct taxonomy path;
- stable IDs are unique and do not encode screen, locale, size, or revision;
- camera/pivot/scale match the selected profile;
- key light is upper-left and shadows/material response match references;
- dimensions, encoded size, color space, alpha, and edge matte pass;
- variants share canvas and optical center;
- accessibility/fallback concepts are supplied;
- commercial-use provenance is complete;
- runtime assets contain no baked localized text;
- binary files are not declared in Flutter before typed registry validation exists.

## Dependency gates

- `AST-002` implements the typed registry and manifest for this taxonomy.
- `AST-003` implements safe missing/corrupt-asset fallbacks.
- `AST-004` owns bounded precache and memory behavior.
- `AST-005` through `AST-009` author production packs under these profiles.
- `AST-010` profiles and enforces performance budgets.
- `AST-011` implements provenance/licensing records.
- `AST-012` enforces naming, manifest, size, format, and provenance in CI.
