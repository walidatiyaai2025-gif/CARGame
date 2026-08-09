#!/usr/bin/env python3
"""Verify CARGame's canonical developer workflow documentation and entry points."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_PATHS = (
    "README.md",
    "docs/DEVELOPER_WORKFLOWS.md",
    "START_CARGAME_TOOL.bat",
    "START_CARGAME_TOOL.ps1",
    "SETUP_TOOL.ps1",
    "FIRST_TIME_SETUP_AND_RUN.ps1",
    "RUN_ON_EMULATOR.ps1",
    "REPAIR_ANDROID_BUILD.ps1",
    "REPAIR_KOTLIN_CACHE_AND_BUILD.ps1",
    "OPEN_DEVELOPMENT_DASHBOARD.ps1",
    "VERIFY_RELEASE_INPUTS.ps1",
    "BUILD_RC.ps1",
    "docs/ANDROID_SIGNING.md",
    "docs/BUILD_CONFIGURATION.md",
    "docs/SECRET_HANDLING.md",
    ".github/workflows/flutter_ci.yml",
)

README_REQUIRED_TOKENS = (
    "START_CARGAME_TOOL.bat",
    "FIRST_TIME_SETUP_AND_RUN.ps1",
    "docs/DEVELOPER_WORKFLOWS.md",
    "RUN_ON_EMULATOR.ps1",
    "REPAIR_ANDROID_BUILD.ps1",
    "OPEN_DEVELOPMENT_DASHBOARD.ps1",
    "VERIFY_RELEASE_INPUTS.ps1",
    "BUILD_RC.ps1",
    "outside source control",
    "Google UMP",
)

WORKFLOW_REQUIRED_TOKENS = (
    "START_CARGAME_TOOL.bat",
    "SETUP_TOOL.ps1",
    "FIRST_TIME_SETUP_AND_RUN.ps1",
    "RUN_ON_EMULATOR.ps1",
    "REPAIR_ANDROID_BUILD.ps1",
    "REPAIR_KOTLIN_CACHE_AND_BUILD.ps1",
    "OPEN_DEVELOPMENT_DASHBOARD.ps1",
    "VERIFY_RELEASE_INPUTS.ps1",
    "BUILD_RC.ps1",
    "flutter pub get --enforce-lockfile",
    "flutter analyze --no-fatal-infos --no-fatal-warnings",
    "flutter test",
    "flutter build apk --debug --no-pub",
    "docs/FEATURE_CATALOG.md",
    "docs/STATUS.md",
    "outside source control",
    "Google UMP",
)

FORBIDDEN_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    (
        "project-regeneration command",
        re.compile(r"\bflutter\s+create\b", re.IGNORECASE),
    ),
    (
        "obsolete bootstrap.sh workflow",
        re.compile(r"\bbootstrap\.sh\b", re.IGNORECASE),
    ),
    (
        "tracked AndroidManifest AdMob replacement instruction",
        re.compile(
            r"replace\s+(?:the\s+)?(?:test\s+)?app\s+ids?.{0,80}androidmanifest",
            re.IGNORECASE | re.DOTALL,
        ),
    ),
    (
        "tracked ad-service ID replacement instruction",
        re.compile(
            r"replace\s+(?:the\s+)?(?:test\s+)?(?:ad\s+)?unit\s+ids?.{0,80}lib/",
            re.IGNORECASE | re.DOTALL,
        ),
    ),
    (
        "manual UMP integration instruction",
        re.compile(r"\badd\s+(?:a\s+)?ump\s+consent", re.IGNORECASE),
    ),
    (
        "hard-coded emulator serial",
        re.compile(r"\bemulator-\d{3,}\b", re.IGNORECASE),
    ),
    (
        "direct unguarded release APK build",
        re.compile(r"flutter\s+build\s+apk\s+--release\b", re.IGNORECASE),
    ),
    (
        "direct unguarded release AAB build",
        re.compile(r"flutter\s+build\s+appbundle\s+--release\b", re.IGNORECASE),
    ),
)


class WorkflowError(RuntimeError):
    """Raised when the canonical developer workflow contract drifts."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise WorkflowError(message)


def validate_texts(readme: str, workflow: str) -> None:
    for token in README_REQUIRED_TOKENS:
        _require(token in readme, f"README is missing required workflow token: {token}")

    for token in WORKFLOW_REQUIRED_TOKENS:
        _require(
            token in workflow,
            f"developer workflow is missing required token: {token}",
        )

    combined = f"{readme}\n{workflow}"
    for label, pattern in FORBIDDEN_PATTERNS:
        _require(
            pattern.search(combined) is None,
            f"canonical developer docs contain forbidden {label}",
        )

    _require(
        "Production advertising and signing values are external inputs" in readme,
        "README must state that production advertising/signing values are external",
    )
    _require(
        "Production release values are external inputs" in workflow,
        "developer workflow must state that production release values are external",
    )
    _require(
        "platform projects are already tracked" in readme,
        "README must state that platform projects are already tracked",
    )
    _require(
        "platform projects are source-controlled" in workflow,
        "developer workflow must protect checked-in platform projects",
    )


def validate_repository(root: Path = ROOT) -> int:
    missing = [path for path in REQUIRED_PATHS if not (root / path).is_file()]
    _require(
        not missing,
        "required developer workflow entry points are missing: " + ", ".join(missing),
    )

    try:
        readme = (root / "README.md").read_text(encoding="utf-8")
        workflow = (root / "docs" / "DEVELOPER_WORKFLOWS.md").read_text(
            encoding="utf-8"
        )
    except OSError as exc:
        raise WorkflowError(f"developer workflow documentation cannot be read: {exc}") from exc

    validate_texts(readme, workflow)
    return len(REQUIRED_PATHS)


def main() -> int:
    try:
        path_count = validate_repository()
    except WorkflowError as exc:
        print(f"DEVELOPER WORKFLOW VALIDATION FAILED: {exc}", file=sys.stderr)
        return 1

    print(
        "Developer workflow validation PASSED: "
        f"{path_count} required entry points; canonical README/workflow guidance is current."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
