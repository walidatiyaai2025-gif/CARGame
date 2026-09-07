#!/usr/bin/env python3
"""Fail-closed source contract checks for the CARGO V2 Android ADB smoke harness.

This verifier proves only that the automation contract is present and keeps its
truth boundaries. It never substitutes for a real APK install/launch run.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SMOKE = ROOT / "SMOKE_CARGO_V2_ANDROID.ps1"
BUILD = ROOT / "BUILD_CARGO_V2_UNITY.ps1"


def fail(message: str) -> None:
    raise AssertionError(message)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")


def main() -> int:
    if not SMOKE.is_file():
        fail("SMOKE_CARGO_V2_ANDROID.ps1 is missing")
    if not BUILD.is_file():
        fail("BUILD_CARGO_V2_UNITY.ps1 is missing")

    smoke = SMOKE.read_text(encoding="utf-8")
    build = BUILD.read_text(encoding="utf-8")

    required_smoke = {
        "package identity": '[string]$PackageId = "com.walka.cargov2"',
        "dynamic adb discovery": "Get-Command adb",
        "dynamic device listing": '@("devices", "-l")',
        "zero-device failure": "No authorized Android device/emulator is connected to ADB.",
        "multi-device fail closed": "Multiple authorized Android devices are connected. Pass -Serial explicitly.",
        "explicit serial validation": "is not an authorized connected device",
        "archive verifier reuse": "-VerifyApkOnly",
        "upgrade-safe install": '@("-s", $script:SelectedSerial, "install", "-r", $resolvedApk)',
        "installed package confirmation": '"shell", "pm", "path", $PackageId',
        "bounded launcher": '"shell", "monkey", "-p", $PackageId',
        "launcher category": '"android.intent.category.LAUNCHER"',
        "process observation": '"shell", "pidof", $PackageId',
        "foreground observation": '"shell", "dumpsys", "activity", "activities"',
        "log reset": '"logcat", "-c"',
        "log collection": '"logcat", "-d", "-v", "brief"',
        "crash marker": "FATAL EXCEPTION",
        "ANR marker": "ANR in",
        "evidence mode": 'verificationMode = "adb-install-launch-smoke"',
        "install execution truth": "installExecuted = $false",
        "launch execution truth": "launchExecuted = $false",
        "process truth": "processObserved = $false",
        "foreground truth": "foregroundObserved = $false",
        "smoke truth": "smokePassed = $false",
        "evidence on failure": "Write-SmokeEvidence -Record $record",
        "truth boundary": "gameplay completion, controls, visual quality, sustained FPS",
    }
    for label, needle in required_smoke.items():
        require(smoke, needle, label)

    required_build = {
        "build package identity": '$ExpectedPackageId = "com.walka.cargov2"',
        "archive install false": "runtimeInstallExecuted = $false",
        "archive launch false": "runtimeLaunchExecuted = $false",
    }
    for label, needle in required_build.items():
        require(build, needle, label)

    forbidden = {
        "hard-coded emulator serial": r"\bemulator-\d+\b",
        "destructive uninstall": r'(?i)"uninstall"',
        "fabricated gameplay pass": r'(?i)gameplay\s+pass',
        "fabricated fps pass": r'(?i)fps\s+pass',
    }
    for label, pattern in forbidden.items():
        if re.search(pattern, smoke):
            fail(f"forbidden {label}: {pattern}")

    # The PASS line must remain scoped to ADB install/launch smoke, never generic QA.
    pass_lines = [line.strip() for line in smoke.splitlines() if " PASS" in line]
    if pass_lines != ['Write-Host "[CARGO V2] ANDROID ADB INSTALL/LAUNCH SMOKE PASS"']:
        fail(f"unexpected PASS claims in smoke harness: {pass_lines}")

    print("CARGO V2 Android smoke source contract PASS (no device/runtime claim).")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"CARGO V2 Android smoke source contract FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
