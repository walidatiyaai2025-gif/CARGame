# CARGame 3D Asset Root

This directory is governed by `docs/ASSET_CATALOG.md`.

`manifest.json` is the versioned text manifest implemented by `AST-002`. Its Dart
contract lives under `lib/core/assets/` and validates stable IDs, taxonomy paths,
semantics, fallback metadata, dimensions, rarity, world identity, and render profile.
An empty manifest is intentionally valid while the binary-art admission gate remains
closed.

No binary art is accepted into the Flutter runtime bundle until the safe missing-asset
path (`AST-003`) and provenance schema (`AST-011`) exist. This prevents unregistered,
unlicensed, oversized, corrupt, or visually incompatible assets from becoming a
runtime dependency.

Runtime files will live below `runtime/`; commercial-use records below `provenance/`;
reproducible authoring masters below `source/`. Do not declare this directory in
`pubspec.yaml` as a broad recursive bundle. Runtime admission must be explicit and
registry-backed.