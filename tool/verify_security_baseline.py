#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THREAT_MODEL = ROOT / "docs/security/threat_model.json"
PRIVACY_INVENTORY = ROOT / "docs/privacy/data_inventory.json"
SECRET_POLICY = ROOT / "docs/SECRET_HANDLING.md"


def fail(message: str) -> None:
    print(f"SECURITY BASELINE VALIDATION FAILED: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot parse {path.relative_to(ROOT)}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path.relative_to(ROOT)} root must be an object")
    return value


def main() -> None:
    model = load_json(THREAT_MODEL)
    privacy = load_json(PRIVACY_INVENTORY)
    if not SECRET_POLICY.is_file():
        fail("docs/SECRET_HANDLING.md is missing")

    if model.get("schemaVersion") != 1:
        fail("unsupported or missing threat-model schemaVersion")

    principles = model.get("securityPrinciples")
    required_principles = {
        "clientIsUntrusted": True,
        "privilegedSecretsInClient": False,
        "offlineCoreAvailable": True,
        "diagnosticsRedacted": True,
        "cleartextNetworkPermitted": False,
    }
    if not isinstance(principles, dict):
        fail("securityPrinciples must be an object")
    for key, expected in required_principles.items():
        if principles.get(key) is not expected:
            fail(f"security principle {key} must remain {expected}")

    boundaries = model.get("trustBoundaries")
    if not isinstance(boundaries, list):
        fail("trustBoundaries must be an array")
    boundary_ids = {
        item.get("id")
        for item in boundaries
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    required_boundaries = {
        "mobile-client",
        "local-storage",
        "google-mobile-ads",
        "ci-secret-store",
        "future-backend",
    }
    missing_boundaries = required_boundaries - boundary_ids
    if missing_boundaries:
        fail(f"missing trust boundaries: {', '.join(sorted(missing_boundaries))}")

    network = model.get("networkPolicy")
    if not isinstance(network, dict):
        fail("networkPolicy must be an object")
    if network.get("requireTls") is not True:
        fail("networkPolicy.requireTls must remain true")
    if network.get("allowCleartext") is not False:
        fail("networkPolicy.allowCleartext must remain false")

    privacy_processors = privacy.get("processors")
    if not isinstance(privacy_processors, list):
        fail("privacy processors must be an array")
    privacy_network_processors = {
        item.get("id")
        for item in privacy_processors
        if isinstance(item, dict) and item.get("network") is True
    }
    declared_network_processors = set(network.get("declaredNetworkProcessors", []))
    if declared_network_processors != privacy_network_processors:
        fail(
            "security network processors must exactly match the privacy inventory: "
            f"security={sorted(declared_network_processors)}, "
            f"privacy={sorted(privacy_network_processors)}"
        )

    threats = model.get("threats")
    if not isinstance(threats, list):
        fail("threats must be an array")
    required_categories = {
        "client-extraction",
        "local-tampering",
        "repackaging-tamper",
        "network-interception",
        "secret-leakage",
        "diagnostic-privacy",
        "dependency-supply-chain",
        "malicious-input-state",
        "advertising-boundary",
    }
    threat_ids: set[str] = set()
    categories: set[str] = set()
    for threat in threats:
        if not isinstance(threat, dict):
            fail("threat entries must be objects")
        threat_id = threat.get("id")
        if not isinstance(threat_id, str) or not threat_id:
            fail("every threat requires an id")
        if threat_id in threat_ids:
            fail(f"duplicate threat id: {threat_id}")
        threat_ids.add(threat_id)
        category = threat.get("category")
        if isinstance(category, str):
            categories.add(category)
        for field in (
            "scenario",
            "severity",
            "residualRisk",
            "owner",
            "followUp",
        ):
            value = threat.get(field)
            if not isinstance(value, str) or not value.strip():
                fail(f"threat {threat_id} is missing {field}")
        mitigations = threat.get("mitigations")
        if not isinstance(mitigations, list) or not mitigations:
            fail(f"threat {threat_id} requires at least one mitigation")
        if not all(isinstance(item, str) and item.strip() for item in mitigations):
            fail(f"threat {threat_id} has an invalid mitigation")

    missing_categories = required_categories - categories
    if missing_categories:
        fail(f"missing threat categories: {', '.join(sorted(missing_categories))}")

    protected_assets = model.get("protectedAssets")
    if not isinstance(protected_assets, list) or not protected_assets:
        fail("protectedAssets must be a non-empty array")
    for asset in protected_assets:
        if not isinstance(asset, dict):
            fail("protected-asset entries must be objects")
        if asset.get("classification") == "secret" and asset.get("repositoryAllowed") is not False:
            fail(f"secret asset {asset.get('id')} cannot be repositoryAllowed")

    secret_policy = SECRET_POLICY.read_text(encoding="utf-8")
    for phrase in (
        "No reusable secret belongs in Dart source",
        "GitHub Actions Secrets",
        "Rotation procedure",
    ):
        if phrase not in secret_policy:
            fail(f"secret-handling policy lost required control: {phrase}")

    print(
        "Security baseline validation PASSED: "
        f"{len(threats)} threats, {len(boundaries)} trust boundaries."
    )


if __name__ == "__main__":
    main()
