#!/usr/bin/env python3
"""Deterministic source/build validation for CARGame runtime assets (AST-012).

Descriptor-only manifest entries are intentionally allowed: AST-007 may declare a
future runtime WebP while retaining the production fallback until commercial-use
provenance and the binary are admitted. Any binary that *is* present under the
runtime root must be declared, non-empty, supported, and within its class budget.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import sys

MANIFEST = PurePosixPath("assets/3d/manifest.json")
RUNTIME_ROOT = PurePosixPath("assets/3d/runtime")
SUPPORTED_EXTENSIONS = {".webp", ".glb"}
MAX_BYTES_BY_CLASS = {
    "ui": 1 * 1024 * 1024,
    "boosters": 2 * 1024 * 1024,
    "rewards": 2 * 1024 * 1024,
    "boss": 4 * 1024 * 1024,
    "cargo": 2 * 1024 * 1024,
    "models": 16 * 1024 * 1024,
}


class AssetBuildValidationError(RuntimeError):
    pass


def _fail(message: str) -> None:
    raise AssetBuildValidationError(message)


def _safe_runtime_path(value: object, *, asset_id: str) -> PurePosixPath:
    if not isinstance(value, str) or not value.strip():
        _fail(f"{asset_id}: path must be a non-empty string")
    if "\\" in value:
        _fail(f"{asset_id}: runtime path must use forward slashes: {value}")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "." in path.parts:
        _fail(f"{asset_id}: unsafe runtime path: {value}")
    root_parts = RUNTIME_ROOT.parts
    if path.parts[: len(root_parts)] != root_parts:
        _fail(f"{asset_id}: runtime path must stay under {RUNTIME_ROOT}: {value}")
    if path.suffix.lower() not in SUPPORTED_EXTENSIONS:
        _fail(f"{asset_id}: unsupported runtime format {path.suffix or '<none>'}: {value}")
    if len(path.parts) <= len(root_parts):
        _fail(f"{asset_id}: runtime path has no class: {value}")
    runtime_class = path.parts[len(root_parts)]
    if runtime_class not in MAX_BYTES_BY_CLASS:
        _fail(f"{asset_id}: unsupported runtime class '{runtime_class}': {value}")
    if path.suffix.lower() == ".glb" and runtime_class != "models":
        _fail(f"{asset_id}: GLB assets must live in runtime/models: {value}")
    if path.suffix.lower() == ".webp" and runtime_class == "models":
        _fail(f"{asset_id}: WebP assets cannot use runtime/models: {value}")
    return path


def validate_repo(root: Path) -> dict[str, int]:
    root = root.resolve()
    manifest_file = root / MANIFEST
    if not manifest_file.is_file():
        _fail(f"missing manifest: {MANIFEST}")
    try:
        document = json.loads(manifest_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        _fail(f"manifest is not valid UTF-8 JSON: {exc}")

    if not isinstance(document, dict):
        _fail("manifest root must be an object")
    if document.get("schemaVersion") != 1:
        _fail("manifest schemaVersion must be 1")
    assets = document.get("assets")
    if not isinstance(assets, list) or not assets:
        _fail("manifest assets must be a non-empty list")

    ids: set[str] = set()
    declared_paths: dict[PurePosixPath, str] = {}
    for index, item in enumerate(assets):
        if not isinstance(item, dict):
            _fail(f"assets[{index}] must be an object")
        asset_id = item.get("id")
        if not isinstance(asset_id, str) or not asset_id.strip():
            _fail(f"assets[{index}].id must be a non-empty string")
        if asset_id in ids:
            _fail(f"duplicate asset id: {asset_id}")
        ids.add(asset_id)
        path = _safe_runtime_path(item.get("path"), asset_id=asset_id)
        if path in declared_paths:
            _fail(f"duplicate runtime path: {path} ({declared_paths[path]}, {asset_id})")
        declared_paths[path] = asset_id

    runtime_dir = root / RUNTIME_ROOT
    binaries: list[Path] = []
    if runtime_dir.exists():
        if not runtime_dir.is_dir():
            _fail(f"runtime root is not a directory: {RUNTIME_ROOT}")
        for path in sorted(runtime_dir.rglob("*")):
            if path.is_symlink():
                _fail(f"runtime symlinks are not allowed: {path.relative_to(root).as_posix()}")
            if path.is_file():
                binaries.append(path)

    for binary in binaries:
        rel = PurePosixPath(binary.relative_to(root).as_posix())
        if rel.suffix.lower() not in SUPPORTED_EXTENSIONS:
            _fail(f"unsupported runtime binary format: {rel}")
        if rel not in declared_paths:
            _fail(f"undeclared runtime binary: {rel}")
        size = binary.stat().st_size
        if size <= 0:
            _fail(f"zero-byte runtime binary: {rel}")
        runtime_class = rel.parts[len(RUNTIME_ROOT.parts)]
        budget = MAX_BYTES_BY_CLASS[runtime_class]
        if size > budget:
            _fail(f"runtime binary exceeds {runtime_class} budget ({size} > {budget} bytes): {rel}")

    return {
        "manifest_entries": len(assets),
        "declared_runtime_paths": len(declared_paths),
        "runtime_binaries": len(binaries),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="repository root (default: cwd)")
    args = parser.parse_args(argv)
    try:
        summary = validate_repo(Path(args.root))
    except AssetBuildValidationError as exc:
        print(f"AST-012 ASSET BUILD VALIDATION FAILED: {exc}", file=sys.stderr)
        return 1
    print("AST-012 ASSET BUILD VALIDATION PASSED")
    print(f"Manifest entries       : {summary['manifest_entries']}")
    print(f"Declared runtime paths : {summary['declared_runtime_paths']}")
    print(f"Runtime binaries       : {summary['runtime_binaries']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
