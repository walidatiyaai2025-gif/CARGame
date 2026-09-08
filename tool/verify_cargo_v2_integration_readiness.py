#!/usr/bin/env python3
"""Fail closed if CARGO V2 Unity build validation stops enforcing integration readiness."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
READINESS = ROOT / "Assets/_Project/QA/Editor/SCR_CargoV2IntegrationPreviewReadiness.cs"
BUILD = ROOT / "Assets/_Project/UI/Editor/SCR_CargoV2Build.cs"


def fail(message: str) -> None:
    raise SystemExit(f"CARGO V2 INTEGRATION READINESS GUARD FAIL: {message}")


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require(source: str, fragment: str, label: str) -> None:
    if fragment not in source:
        fail(f"{label} missing required fragment: {fragment}")


def main() -> None:
    readiness = read(READINESS)
    build = read(BUILD)

    require(readiness, "public static void ValidateOrThrow()", "readiness validator")
    require(readiness, "Evaluate(out int pass, out int hold);", "readiness validator")
    require(readiness, "if (hold > 0)", "readiness validator")
    require(readiness, "throw new InvalidOperationException(message);", "readiness validator")
    require(readiness, "STRUCTURAL READY", "readiness validator")

    scene_setup = "EditorBuildSettings.scenes = new[]"
    readiness_call = "CargoV2.QA.Editor.SCR_CargoV2IntegrationPreviewReadiness.ValidateOrThrow();"
    require(build, scene_setup, "Unity build validator")
    require(build, readiness_call, "Unity build validator")

    if build.find(scene_setup) > build.find(readiness_call):
        fail("Unity build validator calls integration readiness before configuring authoritative build scenes")

    if build.count(readiness_call) != 1:
        fail("Unity build validator must invoke fail-closed integration readiness exactly once")

    print(
        "CARGO V2 INTEGRATION READINESS GUARD PASS: "
        "Unity build validation configures authoritative scenes then executes fail-closed structural readiness."
    )


if __name__ == "__main__":
    main()
