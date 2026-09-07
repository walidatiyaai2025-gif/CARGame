#!/usr/bin/env python3
"""Fail-closed source verifier for CARGO V2 delivery resume identity safety.

This is deliberately a structural regression guard, not Unity/runtime evidence.
It protects the invariant that a persisted delivery checkpoint may only resume
with the exact durable delivery-run identity that created it.
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
DIRECTOR = ROOT / "Assets/_Project/UI/SCR_MissionRuntimeDirector.cs"
BRIDGE = ROOT / "Assets/_Project/Scripts/Logic/SCR_MissionCompletionHandoffBridge.cs"


def fail(message: str) -> None:
    print(f"[CARGO V2][DELIVERY RECOVERY][FAIL] {message}")
    raise SystemExit(1)


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


def main() -> int:
    if not DIRECTOR.is_file():
        fail(f"missing director: {DIRECTOR.relative_to(ROOT)}")
    if not BRIDGE.is_file():
        fail(f"missing completion bridge: {BRIDGE.relative_to(ROOT)}")

    director = DIRECTOR.read_text(encoding="utf-8")
    bridge = BRIDGE.read_text(encoding="utf-8")
    method = extract_method(director, "private static string ResolveDeliveryRunId(bool hasResume)")

    required = (
        "if (hasResume)",
        "PlayerPrefs.HasKey(ActiveDeliveryRunKey)",
        'Guid.TryParseExact(existing, "N", out _)',
        "SCR_ActiveDeliveryStore.Clear();",
        "return string.Empty;",
        'Guid.NewGuid().ToString("N")',
    )
    for token in required:
        if token not in method:
            fail(f"ResolveDeliveryRunId missing required recovery token: {token}")

    if "if (hasResume && PlayerPrefs.HasKey(ActiveDeliveryRunKey))" in method:
        fail("legacy resume fallback is present; it can mint a fresh run id for an orphaned checkpoint")

    resume_start = method.find("if (hasResume)")
    fresh_id = method.find('Guid.NewGuid().ToString("N")')
    quarantine = method.find("SCR_ActiveDeliveryStore.Clear();", resume_start)
    reject = method.find("return string.Empty;", quarantine)
    if not (0 <= resume_start < quarantine < reject < fresh_id):
        fail("orphaned resume is not rejected before fresh run-id creation")

    warning_pattern = re.compile(
        r"Active delivery checkpoint has no valid delivery run id.*duplicate settlement",
        re.IGNORECASE | re.DOTALL,
    )
    if not warning_pattern.search(method):
        fail("orphaned-resume duplicate-settlement warning is missing")

    # The completion bridge intentionally removes the active run identity after
    # successful/idempotent settlement. Therefore stale checkpoints must never be
    # allowed to synthesize a replacement identity on resume.
    if "PlayerPrefs.DeleteKey(ActiveDeliveryRunKey);" not in bridge:
        fail("completion bridge no longer exposes the settlement identity lifecycle expected by this guard")
    if "TrySettleDelivery(" not in bridge:
        fail("delivery-run-id settlement contract is missing")

    print("[CARGO V2][DELIVERY RECOVERY][PASS] orphaned checkpoints cannot mint a replacement payable delivery run id")
    print("[CARGO V2][DELIVERY RECOVERY] structural source evidence only; Unity Play Mode/device execution is not claimed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
