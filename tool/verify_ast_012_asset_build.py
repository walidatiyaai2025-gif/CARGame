#!/usr/bin/env python3
"""Deterministic source/build validation for CARGame runtime assets (AST-012).

The WebP gameplay manifest may intentionally contain descriptor-only entries while
AST-007 waits for commercial-use provenance. Native GLB runtime assets use their
existing per-model provenance sidecar as the declaration authority. Every binary
physically present under assets/3d/runtime must be declared, safe, non-empty,
supported and within its runtime-class budget.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import sys

MANIFEST = PurePosixPath("assets/3d/manifest.json")
PROVENANCE_DIR = PurePosixPath("assets/3d/provenance")
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


def _load_json(path: Path, *, label: str) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        _fail(f"{label} is not valid UTF-8 JSON: {exc}")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_repo(root: Path) -> dict[str, int]:
    root = root.resolve()
    manifest_file = root / MANIFEST
    if not manifest_file.is_file():
        _fail(f"missing manifest: {MANIFEST}")
    document = _load_json(manifest_file, label="manifest")
    if not isinstance(document, dict):
        _fail("manifest root must be an object")
    if document.get("schemaVersion") != 1:
        _fail("manifest schemaVersion must be 1")
    assets = document.get("assets")
    if not isinstance(assets, list) or not assets:
        _fail("manifest assets must be a non-empty list")

    ids: set[str] = set()
    declared_paths: dict[PurePosixPath, str] = {}
    native_metadata: dict[PurePosixPath, tuple[int, str]] = {}
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
        if path.suffix.lower() != ".webp":
            _fail(f"{asset_id}: gameplay manifest entries must be WebP descriptors")
        if path in declared_paths:
            _fail(f"duplicate runtime path: {path} ({declared_paths[path]}, {asset_id})")
        declared_paths[path] = asset_id

    provenance_dir = root / PROVENANCE_DIR
    native_sidecars = 0
    if provenance_dir.is_dir():
        for sidecar in sorted(provenance_dir.glob("*.json")):
            if sidecar.name == "catalog.json":
                continue
            data = _load_json(sidecar, label=sidecar.relative_to(root).as_posix())
            if not isinstance(data, dict) or "runtimePath" not in data:
                continue
            asset_id = data.get("assetId")
            if not isinstance(asset_id, str) or not asset_id.strip():
                _fail(f"{sidecar.name}: assetId must be a non-empty string")
            path = _safe_runtime_path(data.get("runtimePath"), asset_id=asset_id)
            if path.suffix.lower() != ".glb":
                continue
            if data.get("schemaVersion") != 1 or data.get("format") != "glb":
                _fail(f"{sidecar.name}: GLB provenance must use schemaVersion 1 and format glb")
            if path in declared_paths:
                _fail(f"duplicate runtime path: {path} ({declared_paths[path]}, {asset_id})")
            byte_length = data.get("byteLength")
            checksum = data.get("sha256")
            if not isinstance(byte_length, int) or byte_length <= 0:
                _fail(f"{sidecar.name}: byteLength must be a positive integer")
            if not isinstance(checksum, str) or len(checksum) != 64:
                _fail(f"{sidecar.name}: sha256 must contain 64 hex characters")
            try:
                int(checksum, 16)
            except ValueError:
                _fail(f"{sidecar.name}: sha256 must contain 64 hex characters")
            declared_paths[path] = asset_id
            native_metadata[path] = (byte_length, checksum.lower())
            native_sidecars += 1

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
        if rel in native_metadata:
            expected_size, expected_sha = native_metadata[rel]
            if size != expected_size:
                _fail(f"native provenance byteLength mismatch ({size} != {expected_size}): {rel}")
            actual_sha = _sha256(binary)
            if actual_sha != expected_sha:
                _fail(f"native provenance sha256 mismatch: {rel}")

    return {
        "manifest_entries": len(assets),
        "native_sidecars": native_sidecars,
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
    print(f"Native sidecars        : {summary['native_sidecars']}")
    print(f"Declared runtime paths : {summary['declared_runtime_paths']}")
    print(f"Runtime binaries       : {summary['runtime_binaries']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
