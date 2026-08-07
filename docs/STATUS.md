# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | B — Shared 3D design system |
| Active checkpoint | `UI3D-006` Responsive screen shell and safe areas |
| Status | IN PROGRESS — owned by the existing team workstream; this reconciliation does not modify its implementation |
| Recently reconciled | `AST-002` Asset manifest and typed registry |
| Next recommended feature | Continue `UI3D-006`; after it closes, `AST-003` is the next P0 asset-pipeline dependency |
| Known blocker | Binary runtime assets remain gated until `AST-003` missing-asset fallback and `AST-011` provenance controls are complete. |

## AST-002 reconciliation evidence — 2026-08-07

- Existing team commits already introduced typed asset descriptors and registry parsing.
- Stable IDs, governed runtime paths, category/profile compatibility, world/rarity fields, semantics, fallback metadata, dimensions, and duplicate IDs are validated.
- `GameAssetManifest.load()` reads `assets/3d/manifest.json` from the Flutter bundle.
- `pubspec.yaml` bundles the versioned manifest and the current manifest is intentionally empty while binary asset admission remains gated.
- Focused registry tests cover valid parsing, duplicate IDs, invalid paths, category/profile mismatch, localization requirements, unsupported schema versions, and enum values.
- No production/runtime code was duplicated or rewritten during this reconciliation.
- Feature status is `IMPLEMENTED`, not `VERIFIED`, because no workflow run is associated with the final manifest-bundling commit and a fresh Flutter verification was not executed by this documentation-only branch.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | AST-002 implementation inspection | PASSED — typed descriptor, registry, bundle loader, manifest, pubspec entry, and focused tests are present on `main` |
| 2026-08-07 | AST-002 associated workflow evidence | BLOCKED — GitHub reports no workflow run associated with commit `89087de30f14e41608b7266849c75a9b23ee4ed0` |
| 2026-08-07 | Reconciliation branch runtime verification | NOT APPLICABLE — documentation/tracking only; production Dart and platform files are unchanged |

## Team coordination

- `UI3D-006` remains the only primary feature marked `IN PROGRESS` and must not be silently displaced by a parallel primary task.
- `AST-002` is reconciled to the code that already exists on `main`.
- This checkpoint deliberately avoids changing team-owned responsive-shell work.
