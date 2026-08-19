# AST-007 — Cargo Batch 01

Issue: #210
Branch: `agent/ast-007-batch01-procedural-art`
Parent feature: `AST-007` — IN PROGRESS

## Purpose

Record and enforce the first admitted production-art batch for the 12 deterministic cargo assets selected by the AST-007 intake planner. The runtime artwork is project-original procedural WebP generated from source-controlled geometry instructions, and each admitted file has matching provenance and a verified export checksum.

Runtime binary status: `READY`
Provenance status: `READY`

## Batch boundary

Batch 01 contains exactly 12 deterministic cargo assets:

| Asset ID | Concept | Runtime path |
|---|---|---|
| `cargo.accessory_box` | Accessory Box | `assets/3d/runtime/cargo/fashion/cg_cargo_accessory_box_pcargo_v01.webp` |
| `cargo.accessory_carton` | Accessory Carton | `assets/3d/runtime/cargo/special/cg_cargo_accessory_carton_pcargo_v01.webp` |
| `cargo.action_figure_box` | Action Figure Box | `assets/3d/runtime/cargo/toys/cg_cargo_action_figure_box_pcargo_v01.webp` |
| `cargo.apparel_box` | Apparel Box | `assets/3d/runtime/cargo/fashion/cg_cargo_apparel_box_pcargo_v01.webp` |
| `cargo.apple_crate` | Apple Crate | `assets/3d/runtime/cargo/food/cg_cargo_apple_crate_pcargo_v01.webp` |
| `cargo.archive_box` | Archive Box | `assets/3d/runtime/cargo/office/cg_cargo_archive_box_pcargo_v01.webp` |
| `cargo.auto_part_crate` | Auto Part Crate | `assets/3d/runtime/cargo/special/cg_cargo_auto_part_crate_pcargo_v01.webp` |
| `cargo.bakery_box` | Bakery Box | `assets/3d/runtime/cargo/food/cg_cargo_bakery_box_pcargo_v01.webp` |
| `cargo.basketball_bag` | Basketball Bag | `assets/3d/runtime/cargo/sports/cg_cargo_basketball_bag_pcargo_v01.webp` |
| `cargo.battery_pack` | Battery Pack | `assets/3d/runtime/cargo/special/cg_cargo_battery_pack_pcargo_v01.webp` |
| `cargo.board_game_box` | Board Game Box | `assets/3d/runtime/cargo/toys/cg_cargo_board_game_box_pcargo_v01.webp` |
| `cargo.boot_carton` | Boot Carton | `assets/3d/runtime/cargo/fashion/cg_cargo_boot_carton_pcargo_v01.webp` |

`assets/3d/source/cargo/batch_01/spec.json` is the machine-readable source of truth for this handoff. The validator cross-checks every ID, concept and runtime path against `assets/3d/manifest.json`; the table above is documentation only.

## Locked pcargo render contract

- Output: 384×384 WebP, 8-bit sRGB, alpha required.
- Encoded size ceiling: 122,880 bytes (120 KiB) per runtime asset.
- Camera: 50 mm equivalent perspective, yaw -30°, elevation 18°, roll 0°.
- Pivot: bottom-center.
- Subject occupancy: 78–86% of the canvas.
- Transparent safety padding: 7% on every side.
- Lighting: soft upper-left key, cool lower-right fill, restrained rim, soft neutral contact shadow inside the safety padding.
- Material language: clean premium stylized mobile-game 3D; saturated rounded materials; no grime or photoreal brand treatment.
- Background: transparent with clean alpha and no halo.
- No logos, trademarks, readable text, numbers, currency, team marks, manufacturer branding, locale-specific marks, baked UI panels, or baked screen blur.

## Machine enforcement

`tool/verify_ast_007_batch_01.py` fails closed when:

- the batch is not the exact deterministic 12-ID set;
- an ID/path/concept/profile/dimension drifts from the main manifest;
- the pcargo export/camera/composition contract drifts;
- a prompt is missing the explicit no-brand/no-readable-copy boundary;
- an item claims `READY` without the corresponding WebP/provenance existing;
- an item still claims `NOT_CREATED` after the corresponding WebP/provenance appears.

`tool/test_ast_007_batch_01.py` mutation-tests those failure modes and is invoked by the existing AST-007 validator regression entrypoint, so normal Flutter CI owns this batch without a parallel CI workflow.

## Admission sequence

For each asset in this batch the source-controlled admission sequence is now complete through the repository gate:

1. render the original deterministic project-owned asset from the checked-in generator;
2. export the runtime WebP to its exact manifest path under the 120 KiB pcargo budget;
3. record AST-011 provenance with commercial-use evidence and real source/export checksums;
4. mark the spec READY only because the corresponding binary and provenance record exist;
5. verify WebP container, byte budget and SHA-256 equality against provenance;
6. keep device/profile visual and memory observation as separate evidence and keep fallbacks for all still-unadmitted cargo identities.

## Non-claims

- This checkpoint admits exactly 12 runtime cargo WebP files and 12 matching source-controlled provenance records; it does not claim the remaining 112 cargo identities are complete.
- Commercial-use status comes from the project-original source-controlled procedural artwork record, not from prompt text alone.
- No production signing or physical-device visual/performance evidence is claimed.
- `AST-007` remains IN PROGRESS and `GAME-012` remains blocked until the full production pack and required device evidence are complete.
