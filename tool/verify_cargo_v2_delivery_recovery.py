#!/usr/bin/env python3
"""Fail-closed source verifier for CARGO V2 crash/restart delivery safety.

This is structural/unit-level source evidence, not Unity runtime evidence. It protects
both durable run identity and the commit-before-pay ordering between WorldMap
progression persistence and delivery settlement.
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
DIRECTOR = ROOT / "Assets/_Project/UI/SCR_MissionRuntimeDirector.cs"
BRIDGE = ROOT / "Assets/_Project/Scripts/Logic/SCR_MissionCompletionHandoffBridge.cs"
PERSISTENCE = ROOT / "Assets/_Project/Scripts/Logic/SCR_WorldMapPersistenceBridge.cs"
EDITMODE = ROOT / "Assets/_Project/QA/Editor/SCR_CargoV2CompletionRecoveryRegression.cs"
PLAYMODE = ROOT / "Assets/_Project/QA/SCR_CargoV2CompletionRecoveryPlayModeProbe.cs"
BUILD = ROOT / "Assets/_Project/UI/Editor/SCR_CargoV2Build.cs"


def fail(message: str) -> None:
    print(f"[CARGO V2][DELIVERY RECOVERY][FAIL] {message}")
    raise SystemExit(1)


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def extract_method(source: str, signature: str) -> str:
    start = source.find(signature)
    if start < 0:
        fail(f"missing method signature: {signature}")
    brace = source.find("{", start)
    if brace < 0:
        fail(f"missing method body: {signature}")

    depth = 0
    for index in range(brace, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start : index + 1]
    fail(f"unterminated method body: {signature}")
    return ""


def require_tokens(label: str, source: str, tokens: tuple[str, ...]) -> None:
    for token in tokens:
        if token not in source:
            fail(f"{label} missing required recovery token: {token}")


def main() -> int:
    director = read(DIRECTOR)
    bridge = read(BRIDGE)
    persistence = read(PERSISTENCE)
    editmode = read(EDITMODE)
    playmode = read(PLAYMODE)
    build = read(BUILD)

    # Existing durable-run identity invariant: a checkpoint without its original
    # run id is quarantined; it must never mint a fresh payable identity.
    run_id_method = extract_method(director, "private static string ResolveDeliveryRunId(bool hasResume)")
    require_tokens(
        "ResolveDeliveryRunId",
        run_id_method,
        (
            "if (hasResume)",
            "PlayerPrefs.HasKey(ActiveDeliveryRunKey)",
            'Guid.TryParseExact(existing, "N", out _)',
            "SCR_ActiveDeliveryStore.Clear();",
            "return string.Empty;",
            'Guid.NewGuid().ToString("N")',
        ),
    )
    if "if (hasResume && PlayerPrefs.HasKey(ActiveDeliveryRunKey))" in run_id_method:
        fail("legacy resume fallback is present; it can mint a fresh run id for an orphaned checkpoint")

    resume_start = run_id_method.find("if (hasResume)")
    fresh_id = run_id_method.find('Guid.NewGuid().ToString("N")')
    quarantine = run_id_method.find("SCR_ActiveDeliveryStore.Clear();", resume_start)
    reject = run_id_method.find("return string.Empty;", quarantine)
    if not (0 <= resume_start < quarantine < reject < fresh_id):
        fail("orphaned resume is not rejected before fresh run-id creation")

    if not re.search(r"Active delivery checkpoint has no valid delivery run id.*duplicate settlement", run_id_method, re.I | re.S):
        fail("orphaned-resume duplicate-settlement warning is missing")

    # Commit-before-pay invariant.
    ensure = extract_method(bridge, "private bool EnsurePersistenceReady()")
    consume = extract_method(bridge, "internal bool ConsumePendingHandoff()")
    initialize = extract_method(persistence, "public bool Initialize()")
    persist = extract_method(persistence, "public bool PersistCurrentState()")

    require_tokens(
        "EnsurePersistenceReady",
        ensure,
        (
            "GetComponent<SCR_WorldMapPersistenceBridge>()",
            "AddComponent<SCR_WorldMapPersistenceBridge>()",
            "persistenceBridge.Initialize()",
            "persistenceBridge.IsInitialized",
            "return false;",
        ),
    )
    require_tokens(
        "WorldMap persistence Initialize",
        initialize,
        (
            "saveManager.LoadProgress(routeController.MissionCount)",
            "saveManager.CanPersistLoadedState",
            "routeController.SetProgress(payload.highestCompletedMissionId)",
            "initialized = true;",
            "Subscribe();",
            "if (PersistCurrentState()) return true;",
            "initialized = false;",
            "Unsubscribe();",
            "return false;",
        ),
    )
    require_tokens(
        "PersistCurrentState",
        persist,
        (
            "return saveManager.SaveProgress(",
            "routeController.HighestCompletedMissionId",
            "routeController.SelectedMissionId",
        ),
    )
    if not re.search(
        r"if\s*\(\s*!initialized\s*\|\|\s*routeController\s*==\s*null\s*\|\|\s*saveManager\s*==\s*null\s*\|\|\s*!saveManager\.CanPersistLoadedState\s*\)\s*return\s+false\s*;",
        persist,
    ):
        fail("PersistCurrentState must fail closed unless initialized, wired, and allowed to persist the loaded save state")

    ensure_pos = consume.find("EnsurePersistenceReady()")
    complete_pos = consume.find("routeController.TryCompleteMission(missionId)")
    durable_pos = consume.find("persistenceBridge.PersistCurrentState()")
    settle_delivery_pos = consume.find("SCR_MissionRewardStore.TrySettleDelivery(")
    settle_legacy_pos = consume.find("SCR_MissionRewardStore.TrySettleMission(")
    clear_pos = consume.find("ClearHandoff();", durable_pos)
    if not (0 <= ensure_pos < complete_pos < durable_pos < settle_delivery_pos):
        fail("completion ordering is not persistence-ready -> progress -> durable save -> delivery settlement")
    if settle_legacy_pos < durable_pos:
        fail("legacy settlement can execute before durable progression save")
    if clear_pos >= 0 and clear_pos < settle_delivery_pos:
        fail("handoff can be cleared before settlement is durably attempted")

    durable_guard = consume[complete_pos:settle_delivery_pos]
    require_tokens(
        "durable progression guard",
        durable_guard,
        (
            "if (persistenceBridge == null || !persistenceBridge.PersistCurrentState())",
            "settlement deferred and handoff retained",
            "return false;",
        ),
    )

    # Regression coverage must exercise the exact reversed ordering and duplicate
    # handoff/run identity in EditMode, plus a real next-frame PlayMode Start path.
    require_tokens(
        "EditMode regression",
        editmode,
        (
            "Run Completion Recovery Ordering Regression",
            "SaveProgress(0, 1, route.MissionCount)",
            "root.AddComponent<SCR_MissionCompletionHandoffBridge>()",
            "progress.highestCompletedMissionId != 1",
            "progress.selectedMissionId != 2",
            "secondEconomy.Coins != firstEconomy.Coins",
            "secondEconomy.Xp != firstEconomy.Xp",
        ),
    )
    require_tokens(
        "PlayMode probe",
        playmode,
        (
            "CARGO_V2_RUN_COMPLETION_RECOVERY_PROBE",
            "root.AddComponent<SCR_MissionCompletionHandoffBridge>()",
            "yield return null;",
            "progress.highestCompletedMissionId != 1",
            "progress.selectedMissionId != 2",
            "[CARGO V2][QA][PLAYMODE][PASS]",
        ),
    )
    if "root.AddComponent<SCR_WorldMapPersistenceBridge>()" in playmode:
        fail("PlayMode probe manually pre-installs persistence and no longer reproduces reversed bridge ordering")

    if "SCR_CargoV2CompletionRecoveryRegression.ValidateOrThrow();" not in build:
        fail("Unity build validation does not execute the EditMode completion recovery regression")

    if "PlayerPrefs.DeleteKey(ActiveDeliveryRunKey);" not in bridge or "TrySettleDelivery(" not in bridge:
        fail("delivery settlement identity lifecycle is missing")

    print("[CARGO V2][DELIVERY RECOVERY][PASS] run identity, save-state persistability, and commit-before-pay ordering are structurally guarded")
    print("[CARGO V2][DELIVERY RECOVERY] unit/source evidence only; EditMode/PlayMode execution still requires Unity")
    return 0


if __name__ == "__main__":
    sys.exit(main())
