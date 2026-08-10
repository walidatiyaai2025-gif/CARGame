#!/usr/bin/env python3
"""PERF-002 source-ownership and memory/image-budget drift validator."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "lib/core/assets/game_image_memory_policy.dart",
    "lib/core/assets/game_asset_view.dart",
    "lib/core/assets/game_asset_cache_policy.dart",
    "lib/main.dart",
    "test/core/assets/game_image_memory_policy_test.dart",
    "test/core/assets/game_asset_view_memory_test.dart",
    "test/core/assets/game_asset_cache_policy_test.dart",
    "docs/MEMORY_IMAGE_BUDGET.md",
    "docs/work/PERF-002.md",
    "docs/FEATURE_CATALOG.md",
    "docs/STATUS.md",
    ".github/workflows/flutter_ci.yml",
)


class ValidationError(RuntimeError):
    pass


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise ValidationError(f"missing required PERF-002 file: {relative}")
    return path.read_text(encoding="utf-8")


def _require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise ValidationError(f"missing {label}: {needle}")


def validate(root: Path = ROOT) -> None:
    for relative in REQUIRED_FILES:
        _read(root, relative)

    policy = _read(root, REQUIRED_FILES[0])
    for needle, label in (
        ("this.globalCacheEntries = 96", "global cache entry ceiling"),
        ("this.globalCacheBytes = 48 * 1024 * 1024", "global cache byte ceiling"),
        ("this.maxDecodedImageBytes = 6 * 1024 * 1024", "per-image byte ceiling"),
        ("this.maxDecodeDimension = 1536", "hard decode dimension"),
        ("this.defaultPrecachePhysicalExtent = 1024", "precache physical extent"),
        ("cache.maximumSize = globalCacheEntries", "ImageCache entry configuration"),
        ("cache.maximumSizeBytes = globalCacheBytes", "ImageCache byte configuration"),
        ("scale = math.min(scale, 1.0)", "native no-upsample guard"),
        ("math.sqrt(maxDecodedImageBytes / nativeBytes)", "decoded byte scaling"),
        ("ResizeImage.resizeIfNeeded", "resize provider boundary"),
    ):
        _require(policy, needle, label)

    view = _read(root, REQUIRED_FILES[1])
    for needle, label in (
        ("memoryPolicy.targetForDisplay", "display target calculation"),
        ("cacheWidth: decodeTarget.width", "Image.asset cacheWidth"),
        ("cacheHeight: decodeTarget.height", "Image.asset cacheHeight"),
        ("descriptor.dimensions", "descriptor dimension authority"),
    ):
        _require(view, needle, label)

    cache = _read(root, REQUIRED_FILES[2])
    for needle, label in (
        ("this.maxEntries = 24", "AST-004 application cache bound"),
        ("memoryPolicy.targetForPrecache", "bounded precache target"),
        ("memoryPolicy.resizeProvider", "production resize-aware precache"),
        ("_injectedPrecacheLoader", "legacy test precache compatibility"),
        ("_injectedEvictor", "legacy test eviction compatibility"),
        ("while (_cached.length > maxEntries)", "bounded LRU trim"),
    ):
        _require(cache, needle, label)

    main = _read(root, REQUIRED_FILES[3])
    _require(
        main,
        "GameImageMemoryPolicy.standard.configureImageCache(",
        "startup ImageCache configuration",
    )
    _require(
        main,
        "PaintingBinding.instance.imageCache",
        "global Flutter ImageCache ownership",
    )

    policy_tests = _read(root, REQUIRED_FILES[4])
    for needle in (
        "configures explicit global ImageCache entry and byte ceilings",
        "decodes a large image near its physical display size",
        "never upsamples beyond native dimensions",
        "decoded RGBA estimate never exceeds per-image byte budget",
        "precache without layout hints remains bounded",
    ):
        _require(policy_tests, needle, "PERF-002 policy regression")

    view_tests = _read(root, REQUIRED_FILES[5])
    _require(view_tests, "near-display decode target", "view decode regression")
    _require(view_tests, "bounded decode target", "unbounded-layout regression")

    ast004_tests = _read(root, REQUIRED_FILES[6])
    for needle in (
        "concurrent same-ID callers share one load result",
        "clear during load prevents late cache resurrection",
        "forget during load prevents late cache resurrection",
        "precache is bounded and evicts the least recently used entry",
    ):
        _require(ast004_tests, needle, "preserved AST-004 regression")

    docs = _read(root, REQUIRED_FILES[7])
    for needle in ("96", "48 MiB", "6 MiB", "1536 px", "1024 physical px", "device/profile"):
        _require(docs, needle, "memory budget documentation")

    work = _read(root, REQUIRED_FILES[8])
    _require(work, "# PERF-002", "work log identity")
    _require(work, "T50", "50-task execution contract")

    catalog = _read(root, REQUIRED_FILES[9])
    rows = [line for line in catalog.splitlines() if line.startswith("| PERF-002 |")]
    if len(rows) != 1:
        raise ValidationError(f"expected one PERF-002 catalog row, found {len(rows)}")
    if not any(f"| {status} |" in rows[0] for status in ("IN PROGRESS", "IMPLEMENTED", "VERIFIED")):
        raise ValidationError("PERF-002 catalog row is not active/completed")

    status = _read(root, REQUIRED_FILES[10])
    _require(status, "PERF-002", "live status tracking")

    ci = _read(root, REQUIRED_FILES[11])
    _require(ci, "Verify PERF-002 memory and image budget", "PERF-002 CI validator")
    _require(ci, "Test PERF-002 memory budget validator", "PERF-002 validator regressions")
    _require(ci, "Test PERF-002 memory and image budget", "PERF-002 Flutter regressions")
    for preserved in (
        "Verify TEST-007 critical-path contract",
        "Verify TEST-008 quality policy",
        "Verify TEST-010 dashboard catalog parity",
        "Verify AST-004 asset cache policy",
        "Verify PERF-001 frame performance budget",
        "Run full test suite",
        "Verify TEST-008 coverage threshold",
        "Build debug APK",
        "Verify debug APK artifact security",
    ):
        _require(ci, preserved, f"preserved CI gate {preserved}")


if __name__ == "__main__":
    try:
        validate()
    except ValidationError as error:
        print(f"PERF-002 VALIDATION FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
    print("PERF-002 MEMORY AND IMAGE BUDGET VALIDATION PASSED")
