# AST-007 Production Cargo Asset Intake Runbook

This runbook is the operational handoff for the 124 descriptor-backed cargo visuals. It does not create or approve artwork. Production truth must always come from real runtime files and real commercial-use provenance.

## 1. Inspect the current queue

Run the human view:

```bash
dart run tool/plan_ast_007_asset_intake.dart --limit=12
```

For automation or handoff systems, use deterministic JSON:

```bash
dart run tool/plan_ast_007_asset_intake.dart --format=json --limit=12
```

For spreadsheet/import workflows:

```bash
dart run tool/plan_ast_007_asset_intake.dart --format=csv --limit=12
```

Use `--offset=N` to page through the pending queue and `--state=missing_provenance`, `--state=missing_binary`, or `--state=missing_binary_and_provenance` to repair partial admissions before starting untouched assets.

## 2. Produce the exact runtime file

Each batch row gives the stable asset ID, concept, profile, dimensions, and exact runtime path. For AST-007 cargo assets the descriptor contract is `pcargo`, 384x384 WebP, under `assets/3d/runtime/cargo/...`.

Do not rename stable `cargo.*` IDs or change the 18 gameplay archetype IDs to fit artwork. The visual layer is intentionally separate from gameplay/save/matching identity.

## 3. Record commercial-use provenance

Every admitted WebP requires a matching record in `assets/3d/provenance/catalog.json` that satisfies AST-011. Required evidence includes the real source type, creator/vendor/tool, creation date, commercial-use reference, source/export hashes, profile, dimensions, encoder/quality data, reviewer, and approval date as applicable.

**Never synthesize** a license, creator, vendor, source URL, checksum, approval, attribution, or commercial-use statement. If evidence is missing, leave the asset pending.

## 4. Repair partial and orphan states

The planner prioritizes partial admissions first:

- `missing_provenance`: a runtime WebP exists but evidence is incomplete;
- `missing_binary`: provenance exists but the matching runtime WebP is absent;
- `missing_binary_and_provenance`: neither side exists.

It also reports orphan cargo runtime WebP paths and orphan cargo provenance IDs. An orphan must be investigated and either aligned to the exact descriptor or removed; do not silence the warning by inventing a descriptor or provenance record.

## 5. Validate before PR

Run the repository admission and AST-007 contracts:

```bash
dart run tool/validate_asset_pipeline.dart
python3 tool/verify_ast_007_cargo_visuals.py
python3 tool/test_ast_007_cargo_visuals.py
flutter test test/core/assets/game_asset_intake_plan_test.dart \
  test/features/game/cargo_visual_catalog_test.dart \
  test/features/game/cargo_visual_asset_test.dart
```

Use strict readiness when checking whether the complete cargo pack can be promoted:

```bash
dart run tool/plan_ast_007_asset_intake.dart --summary-only --strict
```

`--strict` exits non-zero while any descriptor is pending or while cargo orphan files/records remain. A non-zero result is expected until the real production pack is complete.

## 6. First deterministic batch

With the current truthful baseline of 0 runtime cargo WebP and 0 approved provenance records, the first default 12-item handoff remains:

1. `cargo.accessory_box`
2. `cargo.accessory_carton`
3. `cargo.action_figure_box`
4. `cargo.apparel_box`
5. `cargo.apple_crate`
6. `cargo.archive_box`
7. `cargo.auto_part_crate`
8. `cargo.bakery_box`
9. `cargo.basketball_bag`
10. `cargo.battery_pack`
11. `cargo.board_game_box`
12. `cargo.boot_carton`

These are production targets only. Their presence in this runbook is not evidence that binaries, licenses, provenance, or device verification exist.

## 7. Promotion boundary

AST-007 remains IN PROGRESS until real provenance-backed cargo WebP files are admitted and then exercised through the required build/device/profile validation. Source-only intake tooling, green CI, or descriptor coverage must never be used to claim the production art pack is VERIFIED.