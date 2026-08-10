#!/usr/bin/env python3
"""Focused regressions for the PERF-002 repository validator."""

from __future__ import annotations

import shutil
import tempfile
from pathlib import Path

import verify_memory_image_budget as verifier

ROOT = Path(__file__).resolve().parents[1]


def _fixture() -> Path:
    temp = Path(tempfile.mkdtemp(prefix="perf002-validator-"))
    for relative in verifier.REQUIRED_FILES:
        source = ROOT / relative
        target = temp / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return temp


def _replace(root: Path, relative: str, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text(encoding="utf-8")
    assert old in text, (relative, old)
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def _expect_failure(root: Path, expected: str) -> None:
    try:
        verifier.validate(root)
    except verifier.ValidationError as error:
        assert expected in str(error), (expected, str(error))
    else:
        raise AssertionError(f"expected validation failure containing {expected!r}")


def test_valid_repository_contract() -> None:
    root = _fixture()
    try:
        verifier.validate(root)
    finally:
        shutil.rmtree(root)


def test_rejects_unbounded_global_cache_entries() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/assets/game_image_memory_policy.dart",
            "this.globalCacheEntries = 96",
            "this.globalCacheEntries = 1000",
        )
        _expect_failure(root, "global cache entry ceiling")
    finally:
        shutil.rmtree(root)


def test_rejects_missing_global_byte_configuration() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/assets/game_image_memory_policy.dart",
            "cache.maximumSizeBytes = globalCacheBytes",
            "// byte limit removed",
        )
        _expect_failure(root, "ImageCache byte configuration")
    finally:
        shutil.rmtree(root)


def test_rejects_missing_no_upsample_guard() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/assets/game_image_memory_policy.dart",
            "scale = math.min(scale, 1.0)",
            "scale = scale",
        )
        _expect_failure(root, "native no-upsample guard")
    finally:
        shutil.rmtree(root)


def test_rejects_full_resolution_view_decode() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/assets/game_asset_view.dart",
            "cacheWidth: decodeTarget.width",
            "cacheWidth: null",
        )
        _expect_failure(root, "Image.asset cacheWidth")
    finally:
        shutil.rmtree(root)


def test_rejects_unbounded_precache_drift() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/assets/game_asset_cache_policy.dart",
            "memoryPolicy.targetForPrecache",
            "memoryPolicy.targetForDisplay",
        )
        _expect_failure(root, "bounded precache target")
    finally:
        shutil.rmtree(root)


def test_rejects_missing_startup_cache_configuration() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/main.dart",
            "GameImageMemoryPolicy.standard.configureImageCache(",
            "GameImageMemoryPolicy.standard.toString(); // ",
        )
        _expect_failure(root, "startup ImageCache configuration")
    finally:
        shutil.rmtree(root)


def test_rejects_catalog_tracking_drift() -> None:
    root = _fixture()
    try:
        path = root / "docs/FEATURE_CATALOG.md"
        text = path.read_text(encoding="utf-8")
        text = text.replace("| PERF-002 |", "| PERF-X02 |", 1)
        path.write_text(text, encoding="utf-8")
        _expect_failure(root, "expected one PERF-002 catalog row")
    finally:
        shutil.rmtree(root)


def test_rejects_ci_gate_drift() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            ".github/workflows/flutter_ci.yml",
            "Verify PERF-002 memory and image budget",
            "Verify removed memory and image budget",
        )
        _expect_failure(root, "PERF-002 CI validator")
    finally:
        shutil.rmtree(root)


def main() -> None:
    tests = [
        test_valid_repository_contract,
        test_rejects_unbounded_global_cache_entries,
        test_rejects_missing_global_byte_configuration,
        test_rejects_missing_no_upsample_guard,
        test_rejects_full_resolution_view_decode,
        test_rejects_unbounded_precache_drift,
        test_rejects_missing_startup_cache_configuration,
        test_rejects_catalog_tracking_drift,
        test_rejects_ci_gate_drift,
    ]
    for test in tests:
        test()
        print(f"PASS: {test.__name__}")
    print(f"PERF-002 validator regressions: {len(tests)}/{len(tests)} PASS")


if __name__ == "__main__":
    main()
