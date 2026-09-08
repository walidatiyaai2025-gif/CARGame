#!/usr/bin/env python3
"""Fail closed when the CARGO V2 WorldMap deploy CTA regresses structurally."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPLOY = ROOT / "Assets/_Project/UI/SCR_WorldMapMissionDeploy.cs"
TOUCH = ROOT / "Assets/_Project/UI/SCR_WorldMapTouchInputBridge.cs"
LOCK = ROOT / "Assets/_Project/UI/LOCK_UI_TEAM.txt"


def fail(message: str) -> None:
    raise SystemExit(f"CARGO V2 WORLD MAP DEPLOY CTA GUARD FAIL: {message}")


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require(source: str, token: str, label: str) -> None:
    if token not in source:
        fail(f"{label} missing required contract: {token}")


def main() -> None:
    deploy = read(DEPLOY)
    touch = read(TOUCH)
    lock = read(LOCK)

    if 'GameObject button = GameObject.CreatePrimitive(PrimitiveType.Cube);' in deploy:
        fail("deploy root regressed to the legacy single visible primitive cube")
    if "Geometry remains owned by the production-visual branch" in deploy:
        fail("stale production-visual ownership comment returned")

    deploy_contracts = {
        'new GameObject("DeployMissionButton")': "stable deploy root name",
        "BoxCollider hitTarget = button.AddComponent<BoxCollider>();": "single root hit target",
        '"DeployFrame"': "layered frame",
        '"DeploySurface"': "layered surface",
        '"DeployAccent"': "layered accent",
        "Collider collider = layer.GetComponent<Collider>();": "child collider lookup",
        "Destroy(collider);": "child collider removal",
        "deployActiveMaterial": "active visual state",
        "deployLockedMaterial": "locked visual state",
        "deployBusyMaterial": "busy visual state",
        "bool deployable = !missionRunning && IsDeployable(missionId);": "existing deployability-driven state",
        "internal void TryDeploy()": "deploy behavior entry point",
    }
    for token, label in deploy_contracts.items():
        require(deploy, token, label)

    touch_contracts = {
        'private const string DeployButtonName = "DeployMissionButton";': "touch root name",
        "MatchesObjectOrParent(target, DeployButtonName)": "parent-aware touch routing",
        "ResolveDeployGateway()?.TryDeploy();": "touch deploy dispatch",
    }
    for token, label in touch_contracts.items():
        require(touch, token, label)

    require(lock, "Status: RELEASED", "historical UI lock reconciliation")
    require(lock, "no active exclusive UI_TEAM claim remains here", "released lock policy")

    print(
        "CARGO V2 WORLD MAP DEPLOY CTA GUARD PASS: "
        "layered stateful CTA preserves the stable root hit target and existing deploy/touch contract."
    )


if __name__ == "__main__":
    main()
