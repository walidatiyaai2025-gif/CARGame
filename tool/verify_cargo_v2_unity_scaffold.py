#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_VERSION = "2022.3.75f1"
EXPECTED_REVISION = "6500b2dcc9f3"
SCENES = [
    ("Assets/_Project/Scenes/01_Splash.unity", "70e8e61f984d4f92aa1c2e1fb230ef01"),
    ("Assets/_Project/Scenes/02_Loading.unity", "70e8e61f984d4f92aa1c2e1fb230ef02"),
    ("Assets/_Project/Scenes/04_WorldMap.unity", "70e8e61f984d4f92aa1c2e1fb230ef04"),
]
REQUIRED_FILES = [
    ".gitignore",
    "ProjectSettings/ProjectVersion.txt",
    "ProjectSettings/EditorBuildSettings.asset",
    "Packages/manifest.json",
    "BUILD_CARGO_V2_UNITY.ps1",
    "BUILD_CARGO_V2_UNITY.bat",
    "Assets/_Project/UI/SCR_WorldMapSceneBootstrap.cs",
    "Assets/_Project/UI/Editor/SCR_CargoV2Build.cs",
    "Assets/_Project/UI/SCR_MissionRuntimeDirector.cs",
    "Assets/_Project/UI/SCR_MissionRuntimeDirector.Driving.cs",
    "Assets/_Project/UI/SCR_MissionRuntimeDirector.World.cs",
    "Assets/_Project/UI/SCR_MissionRuntimeDirector.Hud.cs",
    "Assets/_Project/Scripts/Logic/SCR_WorldMapRouteController.cs",
    "Assets/_Project/Scripts/Logic/SCR_WorldMapPersistenceBridge.cs",
    "Assets/_Project/Scripts/Logic/SCR_MissionCompletionHandoffBridge.cs",
    "Assets/_Project/Scripts/Logic/SCR_MissionRewardStore.cs",
    "Assets/_Project/Scripts/Logic/SCR_ActiveDeliveryStore.cs",
    "Assets/_Project/Scripts/Logic/SCR_CompanyProgressStore.cs",
    "Assets/Resources/CargoV2/Mission/MOD_Mission_CargoDepot.obj",
    "Assets/Resources/CargoV2/WorldMap/MOD_WorldMap_MarkerPack.obj",
    "Assets/Resources/CargoV2/Truck/MOD_Truck_Premium.obj",
]


def fail(message: str) -> None:
    raise SystemExit(f"CARGO V2 UNITY SCAFFOLD FAIL: {message}")


def read(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        fail(f"missing required file: {path}")
    return target.read_text(encoding="utf-8")


def require_tokens(path: str, tokens: tuple[str, ...]) -> None:
    content = read(path)
    for token in tokens:
        if token not in content:
            fail(f"{path} contract missing: {token}")


def main() -> None:
    for path in REQUIRED_FILES:
        if not (ROOT / path).is_file():
            fail(f"missing required file: {path}")

    require_tokens(
        ".gitignore",
        (
            "[Ll]ibrary/",
            "[Tt]emp/",
            "[Oo]bj/",
            "[Ll]ogs/",
            "[Uu]ser[Ss]ettings/",
            "[Bb]uilds/",
            "BuildLogs/",
        ),
    )

    version = read("ProjectSettings/ProjectVersion.txt")
    if f"m_EditorVersion: {EXPECTED_VERSION}" not in version:
        fail(f"Unity editor is not pinned to {EXPECTED_VERSION}")
    if EXPECTED_REVISION not in version:
        fail(f"Unity revision is not pinned to {EXPECTED_REVISION}")

    manifest = json.loads(read("Packages/manifest.json"))
    dependencies = manifest.get("dependencies")
    if not isinstance(dependencies, dict):
        fail("Packages/manifest.json has no dependencies object")
    for package in (
        "com.unity.modules.androidjni",
        "com.unity.modules.audio",
        "com.unity.modules.jsonserialize",
        "com.unity.modules.physics",
        "com.unity.modules.ui",
    ):
        if dependencies.get(package) != "1.0.0":
            fail(f"required built-in module missing or unpinned: {package}")

    build_settings = read("ProjectSettings/EditorBuildSettings.asset")
    last_index = -1
    for path, guid in SCENES:
        if not (ROOT / path).is_file():
            fail(f"build scene missing: {path}")
        index = build_settings.find(f"path: {path}")
        if index <= last_index:
            fail(f"build scene missing or out of order: {path}")
        if guid not in build_settings[index:index + 220]:
            fail(f"build scene GUID mismatch: {path}")
        last_index = index

    world_meta = read("Assets/_Project/Scenes/04_WorldMap.unity.meta")
    if "guid: 70e8e61f984d4f92aa1c2e1fb230ef04" not in world_meta:
        fail("04_WorldMap scene GUID mismatch")

    require_tokens(
        "Assets/_Project/UI/SCR_WorldMapSceneBootstrap.cs",
        (
            "SCR_WorldMapRouteController",
            "SCR_WorldMapPersistenceBridge",
            "SCR_MissionCompletionHandoffBridge",
            'new GameObject("Main Camera")',
            'new GameObject("CARGO_V2_WorldMapKeyLight")',
            "Application.targetFrameRate = 60",
        ),
    )

    require_tokens(
        "Assets/_Project/UI/Editor/SCR_CargoV2Build.cs",
        (
            "BuildAndroidBatch",
            "ValidateBatch",
            'CargoV2/Mission/MOD_Mission_CargoDepot',
            'CargoV2/WorldMap/MOD_WorldMap_MarkerPack',
            'CargoV2/Truck/MOD_Truck_Premium',
            'com.walka.cargov2',
            "UIOrientation.LandscapeLeft",
            "AndroidArchitecture.ARM64",
            "ScriptingImplementation.IL2CPP",
            "EditorUserBuildSettings.buildAppBundle = false",
        ),
    )

    require_tokens(
        "BUILD_CARGO_V2_UNITY.ps1",
        (
            '2022.3.75f1',
            'SCR_CargoV2Build.ValidateBatch',
            'SCR_CargoV2Build.BuildAndroidBatch',
            'CARGO_V2_ANDROID_OUTPUT',
            'Get-FileHash',
            'SHA256',
        ),
    )
    require_tokens(
        "BUILD_CARGO_V2_UNITY.bat",
        (
            'BUILD_CARGO_V2_UNITY.ps1',
            'ExecutionPolicy Bypass',
            'exit /b %EXIT_CODE%',
        ),
    )

    mission_core = read("Assets/_Project/UI/SCR_MissionRuntimeDirector.cs")
    if "partial class SCR_MissionRuntimeDirector" not in mission_core:
        fail("Mission runtime is not the composed partial trucking runtime")
    for sibling in (
        "Assets/_Project/UI/SCR_MissionRuntimeDirector.Driving.cs",
        "Assets/_Project/UI/SCR_MissionRuntimeDirector.World.cs",
        "Assets/_Project/UI/SCR_MissionRuntimeDirector.Hud.cs",
    ):
        if "partial class SCR_MissionRuntimeDirector" not in read(sibling):
            fail(f"Mission runtime partial contract missing: {sibling}")

    require_tokens(
        "Assets/_Project/UI/SCR_MissionRuntimeDirector.cs",
        (
            "ActiveDeliveryRunKey",
            "CompletionDeliveryRunKey",
            "Guid.NewGuid().ToString(\"N\")",
            "Rigidbody",
            "FixedUpdate()",
        ),
    )
    require_tokens(
        "Assets/_Project/UI/SCR_MissionRuntimeDirector.Driving.cs",
        (
            "if (!cargoLoaded) return;",
            "int expectedCheckpoint = checkpointIndex + 1;",
            "checkpoint != expectedCheckpoint",
            "checkpointIndex < CheckpointPositions.Length - 1",
            "PlayerPrefs.SetString(CompletionDeliveryRunKey, deliveryRunId)",
        ),
    )
    require_tokens(
        "Assets/_Project/Scripts/Logic/SCR_ActiveDeliveryStore.cs",
        (
            "MaxCheckpointIndex = 3",
            "(!cargoLoaded && checkpointIndex != 0)",
            "payload.checkpointIndex > MaxCheckpointIndex",
        ),
    )
    require_tokens(
        "Assets/_Project/Scripts/Logic/SCR_MissionRewardStore.cs",
        (
            "TrySettleDelivery",
            "settledDeliveryIds",
            "MaxSettledDeliveryIds = 256",
            "Guid.TryParseExact(deliveryRunId, \"N\"",
            "payload.rewardedMissionIds.Add(mission.missionId)",
        ),
    )
    require_tokens(
        "Assets/_Project/Scripts/Logic/SCR_MissionCompletionHandoffBridge.cs",
        (
            "CompletionDeliveryRunKey",
            "TrySettleDelivery",
            "TrySettleMission",
            "ClearHandoff()",
        ),
    )

    guid_to_path: dict[str, Path] = {}
    duplicate_guids: list[str] = []
    for base in (ROOT / "Assets/_Project", ROOT / "Assets/Resources/CargoV2"):
        if not base.exists():
            continue
        for meta in base.rglob("*.meta"):
            match = re.search(r"(?m)^guid:\s*([0-9a-fA-F]{32})\s*$", meta.read_text(encoding="utf-8", errors="ignore"))
            if not match:
                continue
            guid = match.group(1).lower()
            if guid in guid_to_path and guid_to_path[guid] != meta:
                duplicate_guids.append(f"{guid}: {guid_to_path[guid]} <> {meta}")
            else:
                guid_to_path[guid] = meta
    if duplicate_guids:
        fail("duplicate Unity GUIDs: " + "; ".join(duplicate_guids))

    forbidden = [
        name for name in ("Library", "Temp", "Obj", "Logs", "UserSettings", "Builds", "BuildLogs")
        if (ROOT / name).exists()
    ]
    if forbidden:
        fail("generated Unity directories are tracked/present: " + ", ".join(forbidden))

    print(
        "CARGO V2 UNITY SCAFFOLD PASS: "
        f"Unity {EXPECTED_VERSION} ({EXPECTED_REVISION}), 3 build scenes, "
        f"{len(guid_to_path)} unique governed Unity GUIDs, ordered trucking runtime + "
        "repeatable idempotent delivery economy + ARM64 landscape Android closure build present."
    )


if __name__ == "__main__":
    main()
