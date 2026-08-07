# CARGame 3D Asset Root

This directory is governed by `docs/ASSET_CATALOG.md`.

No binary art is accepted here until the typed manifest (`AST-002`), safe fallback
path (`AST-003`), and provenance schema (`AST-011`) exist. This policy prevents
unregistered, unlicensed, oversized, or visually incompatible assets from entering
the Flutter runtime bundle.

Runtime files will live below `runtime/`; commercial-use records below
`provenance/`; reproducible authoring masters below `source/`. Do not declare the
directory in `pubspec.yaml` as a broad recursive bundle.
