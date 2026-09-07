#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

FILES = {
    "save": ROOT / "Assets/_Project/Scripts/Logic/SCR_SaveManager.cs",
    "persistence": ROOT / "Assets/_Project/Scripts/Logic/SCR_WorldMapPersistenceBridge.cs",
    "economy": ROOT / "Assets/_Project/Scripts/Logic/SCR_MissionRewardStore.cs",
    "company": ROOT / "Assets/_Project/Scripts/Logic/SCR_CompanyProgressStore.cs",
    "active": ROOT / "Assets/_Project/Scripts/Logic/SCR_ActiveDeliveryStore.cs",
    "completion": ROOT / "Assets/_Project/Scripts/Logic/SCR_MissionCompletionHandoffBridge.cs",
    "qa": ROOT / "Assets/_Project/QA/Editor/SCR_CargoV2HostileStateRegression.cs",
    "build": ROOT / "Assets/_Project/UI/Editor/SCR_CargoV2Build.cs",
}

errors = []
text = {}
for name, path in FILES.items():
    if not path.is_file():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        text[name] = ""
    else:
        text[name] = path.read_text(encoding="utf-8")


def require(name: str, needle: str, reason: str) -> None:
    if needle not in text.get(name, ""):
        errors.append(f"{name}: {reason} (missing {needle!r})")


# Progress must distinguish unsupported/corrupt input from fresh state and block writes.
require("save", "FutureSchemaBlocked", "future progress schema classification required")
require("save", "UnsupportedLegacyBlocked", "unregistered legacy schema must fail closed")
require("save", "CorruptBlocked", "malformed progress without LKG must not reset")
require("save", "ProgressBackupKey", "progress LKG required")
require("persistence", "!saveManager.CanPersistLoadedState", "WorldMap must refuse unsupported/corrupt write-back")

# Economy must preserve idempotency evidence and read receipts without creating a debit.
require("economy", "EconomyBackupKey", "economy LKG required")
require("economy", "TryReadSpendCommit", "company recovery needs read-only spend receipt probe")
require("economy", "payload.settledDeliveryIds.Count >= MaxSettledDeliveryIds", "delivery ledger must fail closed at defensive bound")
require("economy", "payload.spendReceipts.Count >= MaxSpendReceipts", "spend receipt ledger must fail closed at defensive bound")
if "RemoveAt(0)" in text.get("economy", "") or "RemoveRange(0" in text.get("economy", ""):
    errors.append("economy: idempotency evidence eviction is forbidden")

# Company profile must salvage valid fleet data and only use current catalog before payment.
require("company", "SalvageCurrentPayload", "current-schema fleet salvage required")
require("company", "TryReadSpendCommit", "transaction recovery must classify pre/post debit")
require("company", "if (!paymentCommitted)", "catalog/pre-state checks must be confined to unpaid journal")
require("company", "CompanyBackupKey", "company LKG required")
require("company", "UnsupportedTransactionBackupKey", "future transaction journal must be preserved")
if "upgrade < CargoV2TruckUpgrade.Engine" in text.get("company", ""):
    errors.append("company: enum relational comparison is not valid C#; compare integer values")

# Active run corruption is session-quarantined, never normalized into a payable state.
require("active", "UnsupportedBackupKey", "future active-run raw payload must be preserved")
require("active", "remainingSeconds < 0f", "negative remaining time must be rejected")
require("active", "damage < 0f", "negative damage must be rejected")
require("active", "!Finite(position.x)", "NaN/Infinity active positions must be rejected")

# A rejected completion must not orphan another valid active run; a settled one must clear stale resume state.
require("completion", "ClearCompletionKeysOnly", "invalid completion must not clear active run identity")
require("completion", "SCR_ActiveDeliveryStore.Clear();", "settled completion must retire stale active snapshot")
require("completion", "ClearSettledDeliveryKeys", "settled completion cleanup boundary required")

# Deterministic tests must be part of Unity project validation.
require("build", "SCR_CargoV2HostileStateRegression.ValidateOrThrow();", "hostile regression must gate Unity validation/build")
for test_name in (
    "TestFreshInstall",
    "TestProgressHostileSchemas",
    "TestEconomyIdempotencyAndCorruption",
    "TestCompanySalvageAndFutureSchema",
    "TestCommittedTransactionCatalogDrift",
    "TestUnpaidTransactionCatalogDrift",
    "TestActiveDeliveryValidationAndQuarantine",
    "TestCompletionCrashCleanupAndInvalidHandoffIsolation",
    "TestFiniteEconomyAndContractMath",
):
    require("qa", test_name, f"missing deterministic regression {test_name}")

# Production code must not expose destructive one-click reset/debug surfaces.
for path in (ROOT / "Assets/_Project").rglob("*.cs"):
    rel = path.relative_to(ROOT).as_posix()
    if "/QA/" in f"/{rel}" or "/Editor/" in f"/{rel}":
        continue
    body = path.read_text(encoding="utf-8")
    if "PlayerPrefs.DeleteAll(" in body:
        errors.append(f"{rel}: PlayerPrefs.DeleteAll is forbidden in production runtime")
    if re.search(r"\.ClearProgress\s*\(", body):
        errors.append(f"{rel}: production call to ClearProgress is forbidden")
    if "[MenuItem(" in body:
        errors.append(f"{rel}: Unity editor MenuItem must not exist in production runtime code")

if errors:
    print("CARGO V2 HOSTILE STATE GUARD: FAIL")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print("CARGO V2 HOSTILE STATE GUARD: PASS")
print("Static/source contracts only; this is not Unity PlayMode, process-recreation, APK, or device evidence.")
