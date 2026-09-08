#!/usr/bin/env python3
"""Fail closed when CARGO V2 QA probes drift from the live deploy runtime type."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPLOY = ROOT / "Assets/_Project/UI/SCR_WorldMapMissionDeploy.cs"
PROBE = ROOT / "Assets/_Project/QA/SCR_CargoV2RuntimeContractProbe.cs"
READINESS = ROOT / "Assets/_Project/QA/Editor/SCR_CargoV2IntegrationPreviewReadiness.cs"

CORRECT = "CargoV2.UI.SCR_WorldMapMissionDeploy"
STALE = "CargoV2.UI.SCR_WorldMapMissionDeployGateway"


def fail(message: str) -> None:
    raise SystemExit(f"CARGO V2 RUNTIME CONTRACT NAME GUARD FAIL: {message}")


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    deploy = read(DEPLOY)
    probe = read(PROBE)
    readiness = read(READINESS)

    if "namespace CargoV2.UI" not in deploy or "public sealed class SCR_WorldMapMissionDeploy" not in deploy:
        fail("deploy implementation no longer exposes CargoV2.UI.SCR_WorldMapMissionDeploy")

    for label, source in (("runtime probe", probe), ("integration readiness", readiness)):
        if CORRECT not in source:
            fail(f"{label} does not require the live deploy type {CORRECT}")
        if STALE in source:
            fail(f"{label} still references stale deploy type {STALE}")

    print(
        "CARGO V2 RUNTIME CONTRACT NAME GUARD PASS: "
        "runtime/readiness probes resolve the integrated SCR_WorldMapMissionDeploy type and reject the stale Gateway name."
    )


if __name__ == "__main__":
    main()
