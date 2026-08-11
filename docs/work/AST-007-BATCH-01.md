# AST-007 — Cargo Batch 01

Issue: #210
Branch: `agent/ast-007-cargo-batch-01`
Parent feature: `AST-007` — IN PROGRESS

## Purpose

Prepare a reproducible production-art handoff for the first 12 deterministic cargo assets selected by the merged AST-007 intake planner. This checkpoint defines what must be created and how it must be validated; it does not pretend that artwork, commercial-use approval, or runtime admission already exists.

Runtime binary status: `NOT_CREATED`
Provenance status: `NOT_CREATED`

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

For each asset, the next production step is:

1. create/render the original asset against `spec.json`;
2. export the runtime WebP to its exact manifest path under the 120 KiB pcargo budget;
3. record complete AST-011 provenance with commercial-use evidence and real checksums;
4. change the spec status only when the corresponding artifact/record actually exists;
5. run AST-007 validation, AST-011 asset admission, full Flutter CI, and device/profile visual/memory checks;
6. keep the existing Flutter fallback active for any item not successfully admitted.

## Non-claims

- No runtime cargo WebP is added by this handoff checkpoint.
- No provenance record is added or auto-approved.
- No commercial-use license is inferred from a prompt.
- No production signing or physical-device visual evidence is claimed.
- `AST-007` remains IN PROGRESS and `GAME-012` remains blocked.
