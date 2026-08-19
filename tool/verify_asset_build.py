#!/usr/bin/env python3
"""Fail-closed build validation for governed runtime game assets.

Descriptor-only manifest records are intentionally allowed: they preserve the
fallback-safe AST-007 intake contract. Any runtime binary that is actually
checked in must be declared, non-empty, supported, and within its build budget.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

RUNTIME_ROOT = Path("assets/3d/runtime")
MANIFEST_PATH = Path("assets/3d/manifest.json")
SUPPORTED_SUFFIXES = {".webp", ".glb"}
MAX_BYTES = {
    ".webp": 2 * 1024 * 1024,
    ".glb": 32 * 1024 * 1024,
}


@dataclass(frozen=True)
class ValidationResult:
    errors: tuple[str, ...]
    descriptor_count: int
    runtime_file_count: int

    @property
    def ok(self) -> bool:
        return not self.errors


def _runtime_files(repo_root: Path) -> Iterable[Path]:
    root = repo_root / RUNTIME_ROOT
    if not root.exists():
        return ()
    return (path for path in root.rglob("*") if path.is_file())


def validate_asset_build(repo_root: Path) -> ValidationResult:
    errors: list[str] = []
    manifest_file = repo_root / MANIFEST_PATH
    if not manifest_file.is_file():
        return ValidationResult((f"missing manifest: {MANIFEST_PATH.as_posix()}",), 0, 0)

    try:
        payload = json.loads(manifest_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return ValidationResult((f"invalid manifest: {exc}",), 0, 0)

    if payload.get("schemaVersion") != 1:
        errors.append("manifest schemaVersion must equal 1")
    assets = payload.get("assets")
    if not isinstance(assets, list):
        return ValidationResult(tuple(errors + ["manifest assets must be a list"]), 0, 0)

    ids: set[str] = set()
    paths: set[str] = set()
    for index, asset in enumerate(assets):
        if not isinstance(asset, dict):
            errors.append(f"asset[{index}] must be an object")
            continue
        asset_id = asset.get("id")
        runtime_path = asset.get("path")
        if not isinstance(asset_id, str) or not asset_id.strip():
            errors.append(f"asset[{index}] has invalid id")
        elif asset_id in ids:
            errors.append(f"duplicate asset id: {asset_id}")
        else:
            ids.add(asset_id)

        if not isinstance(runtime_path, str) or not runtime_path.strip():
            errors.append(f"asset[{index}] has invalid path")
            continue
        normalized = Path(runtime_path).as_posix()
        if normalized in paths:
            errors.append(f"duplicate asset path: {normalized}")
        else:
            paths.add(normalized)
        if not normalized.startswith(f"{RUNTIME_ROOT.as_posix()}/"):
            errors.append(f"asset path escapes governed runtime root: {normalized}")
        if ".." in Path(normalized).parts:
            errors.append(f"asset path contains traversal: {normalized}")
        suffix = Path(normalized).suffix.lower()
        if suffix not in SUPPORTED_SUFFIXES:
            errors.append(f"unsupported manifest runtime format: {normalized}")

    runtime_files = list(_runtime_files(repo_root))
    declared_paths = paths
    for file_path in runtime_files:
        relative = file_path.relative_to(repo_root).as_posix()
        suffix = file_path.suffix.lower()
        if suffix not in SUPPORTED_SUFFIXES:
            errors.append(f"unsupported runtime file format: {relative}")
            continue
        if relative not in declared_paths:
            errors.append(f"undeclared runtime binary: {relative}")
        size = file_path.stat().st_size
        if size <= 0:
            errors.append(f"zero-byte runtime binary: {relative}")
        budget = MAX_BYTES[suffix]
        if size > budget:
            errors.append(
                f"runtime binary exceeds {budget} byte budget: {relative} ({size} bytes)"
            )

    return ValidationResult(tuple(sorted(set(errors))), len(assets), len(runtime_files))


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    result = validate_asset_build(repo_root)
    if result.errors:
        print("AST-012 asset build validation FAILED", file=sys.stderr)
        for error in result.errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        "AST-012 asset build validation passed: "
        f"{result.descriptor_count} descriptors, {result.runtime_file_count} runtime binaries"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
