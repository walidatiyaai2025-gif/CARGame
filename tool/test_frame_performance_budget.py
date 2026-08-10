#!/usr/bin/env python3
"""Focused regressions for the PERF-001 repository validator."""

from __future__ import annotations

import shutil
import tempfile
from pathlib import Path

import verify_frame_performance_budget as verifier

ROOT = Path(__file__).resolve().parents[1]


def _fixture() -> Path:
    temp = Path(tempfile.mkdtemp(prefix="perf001-validator-"))
    for relative in verifier.REQUIRED_FILES:
        source = ROOT / relative
        target = temp / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return temp


def _expect_failure(root: Path, expected: str) -> None:
    try:
        verifier.validate(root)
    except verifier.ValidationError as error:
        assert expected in str(error), (expected, str(error))
    else:
        raise AssertionError(f"expected validation failure containing {expected!r}")


def _replace(root: Path, relative: str, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text(encoding="utf-8")
    assert old in text, (relative, old)
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def _replace_all(root: Path, relative: str, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    assert count > 0, (relative, old)
    path.write_text(text.replace(old, new), encoding="utf-8")


def test_valid_repository_contract() -> None:
    root = _fixture()
    try:
        verifier.validate(root)
    finally:
        shutil.rmtree(root)


def test_rejects_target_fps_drift() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/performance/frame_performance_budget.dart",
            "this.targetFps = 60",
            "this.targetFps = 30",
        )
        _expect_failure(root, "60 Hz target")
    finally:
        shutil.rmtree(root)


def test_rejects_unbounded_history_drift() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/performance/frame_performance_budget.dart",
            "while (_samples.length > policy.windowSize)",
            "while (false)",
        )
        _expect_failure(root, "bounded rolling eviction")
    finally:
        shutil.rmtree(root)


def test_rejects_scheduler_cleanup_drift() -> None:
    root = _fixture()
    try:
        _replace_all(
            root,
            "lib/core/performance/frame_performance_scope.dart",
            "SchedulerBinding.instance.removeTimingsCallback",
            "SchedulerBinding.instance.addTimingsCallback",
        )
        _expect_failure(root, "scheduler observer cleanup")
    finally:
        shutil.rmtree(root)


def test_rejects_app_scope_drift() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/bootstrap/cargo_sort_app.dart",
            "return FramePerformanceScope(",
            "return Builder(",
        )
        _expect_failure(root, "app-wide performance scope")
    finally:
        shutil.rmtree(root)


def test_rejects_motion_fallback_drift() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            "lib/core/motion/ambient_motion_background.dart",
            "!GameMotion.of(context).allowAmbientMotion",
            "false",
        )
        _expect_failure(root, "ambient ticker degradation")
    finally:
        shutil.rmtree(root)


def test_rejects_catalog_tracking_drift() -> None:
    root = _fixture()
    try:
        path = root / "docs/FEATURE_CATALOG.md"
        text = path.read_text(encoding="utf-8")
        text = text.replace("| PERF-001 |", "| PERF-X01 |", 1)
        path.write_text(text, encoding="utf-8")
        _expect_failure(root, "expected one PERF-001 catalog row")
    finally:
        shutil.rmtree(root)


def test_rejects_ci_gate_drift() -> None:
    root = _fixture()
    try:
        _replace(
            root,
            ".github/workflows/flutter_ci.yml",
            "Verify PERF-001 frame performance budget",
            "Verify removed frame performance budget",
        )
        _expect_failure(root, "PERF-001 CI validator")
    finally:
        shutil.rmtree(root)


def main() -> None:
    tests = [
        test_valid_repository_contract,
        test_rejects_target_fps_drift,
        test_rejects_unbounded_history_drift,
        test_rejects_scheduler_cleanup_drift,
        test_rejects_app_scope_drift,
        test_rejects_motion_fallback_drift,
        test_rejects_catalog_tracking_drift,
        test_rejects_ci_gate_drift,
    ]
    for test in tests:
        test()
        print(f"PASS: {test.__name__}")
    print(f"PERF-001 validator regressions: {len(tests)}/{len(tests)} PASS")


if __name__ == "__main__":
    main()
