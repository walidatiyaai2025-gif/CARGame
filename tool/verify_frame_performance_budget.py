#!/usr/bin/env python3
"""PERF-001 source-ownership and frame-budget drift validator."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "lib/core/performance/frame_performance_budget.dart",
    "lib/core/performance/frame_performance_scope.dart",
    "lib/core/motion/game_motion.dart",
    "lib/core/motion/ambient_motion_background.dart",
    "lib/bootstrap/cargo_sort_app.dart",
    "test/core/performance/frame_performance_budget_test.dart",
    "test/core/performance/frame_performance_scope_test.dart",
    "docs/PERFORMANCE_BUDGET.md",
    "docs/work/PERF-001.md",
    "docs/FEATURE_CATALOG.md",
    "docs/STATUS.md",
    ".github/workflows/flutter_ci.yml",
)


class ValidationError(RuntimeError):
    pass


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise ValidationError(f"missing required PERF-001 file: {relative}")
    return path.read_text(encoding="utf-8")


def _require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise ValidationError(f"missing {label}: {needle}")


def validate(root: Path = ROOT) -> None:
    for relative in REQUIRED_FILES:
        _read(root, relative)

    budget = _read(root, REQUIRED_FILES[0])
    for needle, label in (
        ("enum GameVisualQuality { full, constrained, reduced }", "quality ladder"),
        ("static const FramePerformancePolicy mobile60Hz", "60 Hz policy"),
        ("this.targetFps = 60", "60 Hz target"),
        ("this.jankFrameBudget = const Duration(milliseconds: 24)", "jank budget"),
        ("this.severeFrameBudget = const Duration(milliseconds: 34)", "severe-jank budget"),
        ("this.windowSize = 60", "bounded default window"),
        ("while (_samples.length > policy.windowSize)", "bounded rolling eviction"),
        ("current.jankRatio >= policy.degradeJankRatio", "degradation ratio"),
        ("_healthyWindows < policy.healthyWindowsToRecover", "recovery hysteresis"),
        ("notifyListeners();", "quality-change notification"),
    ):
        _require(budget, needle, label)

    scope = _read(root, REQUIRED_FILES[1])
    for needle, label in (
        ("SchedulerBinding.instance.addTimingsCallback", "scheduler timing observer"),
        ("SchedulerBinding.instance.removeTimingsCallback", "scheduler observer cleanup"),
        ("_controller.recordFrameTiming(timing)", "FrameTiming ingestion"),
        ("observeScheduler", "deterministic scheduler-off test hook"),
    ):
        _require(scope, needle, label)

    motion = _read(root, REQUIRED_FILES[2])
    for needle, label in (
        ("FramePerformanceScope.qualityOf(context)", "shared motion quality lookup"),
        ("bool get allowAmbientMotion", "ambient fallback decision"),
        ("if (reducedMotion) return 0;", "reduced-motion precedence"),
        ("GameVisualQuality.constrained => .65", "constrained effect scale"),
        ("GameVisualQuality.reduced => .35", "reduced effect scale"),
    ):
        _require(motion, needle, label)

    ambient = _read(root, REQUIRED_FILES[3])
    _require(
        ambient,
        "!GameMotion.of(context).allowAmbientMotion",
        "ambient ticker degradation",
    )

    app = _read(root, REQUIRED_FILES[4])
    _require(app, "return FramePerformanceScope(", "app-wide performance scope")
    _require(app, "child: MaterialApp(", "scope above MaterialApp")

    unit_tests = _read(root, REQUIRED_FILES[5])
    for needle in (
        "keeps rolling history strictly bounded",
        "one isolated bad frame does not degrade visual quality",
        "sustained pressure degrades one level per evaluation window",
        "recovery is conservative and occurs one level at a time",
    ):
        _require(unit_tests, needle, "PERF-001 unit regression")

    widget_tests = _read(root, REQUIRED_FILES[6])
    for needle in (
        "scope propagates adaptive quality changes to shared motion",
        "system reduced motion wins over adaptive quality",
        "shared motion defaults to full quality without a scope",
    ):
        _require(widget_tests, needle, "PERF-001 widget regression")

    docs = _read(root, REQUIRED_FILES[7])
    for needle in ("60 Hz", "16.67 ms", "bounded rolling window", "device-tier"):
        _require(docs, needle, "performance-budget documentation")

    work = _read(root, REQUIRED_FILES[8])
    _require(work, "# PERF-001", "work log identity")
    _require(work, "T50", "50-task execution contract")

    catalog = _read(root, REQUIRED_FILES[9])
    perf_rows = [line for line in catalog.splitlines() if line.startswith("| PERF-001 |")]
    if len(perf_rows) != 1:
        raise ValidationError(f"expected one PERF-001 catalog row, found {len(perf_rows)}")
    if "| IN PROGRESS |" not in perf_rows[0] and "| IMPLEMENTED |" not in perf_rows[0] and "| VERIFIED |" not in perf_rows[0]:
        raise ValidationError("PERF-001 catalog row is not active/completed")

    status = _read(root, REQUIRED_FILES[10])
    _require(status, "PERF-001", "live status tracking")

    ci = _read(root, REQUIRED_FILES[11])
    _require(ci, "Verify PERF-001 frame performance budget", "PERF-001 CI validator")
    _require(ci, "Test PERF-001 frame performance validator", "PERF-001 validator regressions")
    _require(ci, "Test PERF-001 frame performance budget", "PERF-001 Flutter regressions")
    for preserved in (
        "Verify TEST-007 critical-path contract",
        "Verify TEST-008 quality policy",
        "Verify TEST-010 dashboard catalog parity",
        "Verify AST-004 asset cache policy",
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
        print(f"PERF-001 VALIDATION FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
    print("PERF-001 FRAME PERFORMANCE BUDGET VALIDATION PASSED")
