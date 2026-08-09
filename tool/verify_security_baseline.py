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


def require_bool(mapping: dict, key: str, label: str) -> bool:
    value = mapping.get(key)
    if not isinstance(value, bool):
        fail(f"{label}.{key} must be a boolean")
    return value


def main() -> None:
    model = load_json(THREAT_MODEL)
    privacy = load_json(PRIVACY_INVENTORY)
    if not SECRET_POLICY.is_file():
        fail("docs/SECRET_HANDLING.md is missing")

    if model.get("schemaVersion") != 1:
        fail("unsupported or missing threat-model schemaVersion")

    principles = model.get("securityPrinciples")
    if not isinstance(principles, dict):
        fail("securityPrinciples must be an object")

    required_principles = {
        "clientIsUntrusted": True,
        "privilegedSecretsInClient": False,
        "offlineCoreAvailable": True,
        "cleartextNetworkPermitted": False,
    }
    for key, expected in required_principles.items():
        if principles.get(key) is not expected:
            fail(f"security principle {key} must remain {expected}")

    privacy_principles = privacy.get("principles")
    if not isinstance(privacy_principles, dict):
        fail("privacy principles must be an object")

    runtime_parity = {
        "diagnosticsRedactedBeforePersistence": "diagnosticsRedacted",
        "diagnosticsBuildGateEffective": "diagnosticsBuildGateEffective",
        "adRequestsFailClosedByConfig": "adRequestsRespectEnableAds",
        "adSdkInitializationConsentGated": "adSdkInitializationConsentGated",
    }
    for privacy_key, security_key in runtime_parity.items():
        privacy_value = require_bool(
            privacy_principles,
            privacy_key,
            "privacy.principles",
        )
        security_value = require_bool(
            principles,
            security_key,
            "securityPrinciples",
        )
        if privacy_value != security_value:
            fail(
                "privacy/security runtime-control drift: "
                f"{privacy_key}={privacy_value}, "
                f"{security_key}={security_value}"
            )

    remote_diagnostics_enabled = require_bool(
        principles,
        "remoteDiagnosticsEnabled",
        "securityPrinciples",
    )
    explicitly_absent = privacy.get("explicitlyAbsent")
    if not isinstance(explicitly_absent, list) or not all(
        isinstance(item, str) for item in explicitly_absent
    ):
        fail("privacy explicitlyAbsent must be an array of strings")
    if "remote diagnostic upload" in explicitly_absent and remote_diagnostics_enabled:
        fail(
            "security model enables remote diagnostics while PRIV-001 declares "
            "remote diagnostic upload absent"
        )

    boundaries = model.get("trustBoundaries")
    if not isinstance(boundaries, list):
        fail("trustBoundaries must be an array")
    boundary_ids: set[str] = set()
    for boundary in boundaries:
        if not isinstance(boundary, dict):
            fail("trust-boundary entries must be objects")
        boundary_id = boundary.get("id")
        if not isinstance(boundary_id, str) or not boundary_id.strip():
            fail("every trust boundary requires an id")
        if boundary_id in boundary_ids:
            fail(f"duplicate trust boundary id: {boundary_id}")
        boundary_ids.add(boundary_id)
        if not isinstance(boundary.get("description"), str) or not boundary[
            "description"
        ].strip():
            fail(f"trust boundary {boundary_id} requires a description")
        if not isinstance(boundary.get("trusted"), bool):
            fail(f"trust boundary {boundary_id} must declare trusted as a boolean")

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
    if not all(isinstance(item, str) for item in privacy_network_processors):
        fail("privacy network processors require string ids")

    declared_processors = network.get("declaredNetworkProcessors")
    if not isinstance(declared_processors, list) or not all(
        isinstance(item, str) and item.strip() for item in declared_processors
    ):
        fail("networkPolicy.declaredNetworkProcessors must contain string ids")
    declared_network_processors = set(declared_processors)
    if len(declared_network_processors) != len(declared_processors):
        fail("networkPolicy.declaredNetworkProcessors contains duplicates")
    if declared_network_processors != privacy_network_processors:
        fail(
            "security network processors must exactly match the privacy inventory: "
            f"security={sorted(declared_network_processors)}, "
            f"privacy={sorted(privacy_network_processors)}"
        )
    missing_processor_boundaries = declared_network_processors - boundary_ids
    if missing_processor_boundaries:
        fail(
            "network processors are missing trust boundaries: "
            + ", ".join(sorted(missing_processor_boundaries))
        )

    protected_assets = model.get("protectedAssets")
    if not isinstance(protected_assets, list) or not protected_assets:
        fail("protectedAssets must be a non-empty array")
    protected_asset_ids: set[str] = set()
    for asset in protected_assets:
        if not isinstance(asset, dict):
            fail("protected-asset entries must be objects")
        asset_id = asset.get("id")
        if not isinstance(asset_id, str) or not asset_id.strip():
            fail("every protected asset requires an id")
        if asset_id in protected_asset_ids:
            fail(f"duplicate protected asset id: {asset_id}")
        protected_asset_ids.add(asset_id)
        classification = asset.get("classification")
        if not isinstance(classification, str) or not classification.strip():
            fail(f"protected asset {asset_id} requires a classification")
        location = asset.get("location")
        if location not in boundary_ids:
            fail(
                f"protected asset {asset_id} references unknown trust boundary: "
                f"{location}"
            )
        repository_allowed = asset.get("repositoryAllowed")
        if not isinstance(repository_allowed, bool):
            fail(f"protected asset {asset_id} must declare repositoryAllowed")
        if classification == "secret" and repository_allowed is not False:
            fail(f"secret asset {asset_id} cannot be repositoryAllowed")

    required_assets = {
        "release-signing-material",
        "game-progress",
        "transaction-recovery-state",
        "storage-recovery-snapshot",
        "diagnostic-logs",
        "ad-unit-ids",
    }
    missing_assets = required_assets - protected_asset_ids
    if missing_assets:
        fail(f"missing protected assets: {', '.join(sorted(missing_assets))}")

    privacy_gaps = privacy.get("knownGaps")
    security_gaps = model.get("knownGaps")
    if not isinstance(privacy_gaps, list):
        fail("privacy knownGaps must be an array")
    if not isinstance(security_gaps, list):
        fail("security knownGaps must be an array")

    privacy_gap_by_id: dict[str, dict] = {}
    for gap in privacy_gaps:
        if not isinstance(gap, dict):
            fail("privacy known-gap entries must be objects")
        gap_id = gap.get("id")
        if not isinstance(gap_id, str) or not gap_id.strip():
            fail("privacy known gaps require ids")
        if gap_id in privacy_gap_by_id:
            fail(f"duplicate privacy known gap id: {gap_id}")
        privacy_gap_by_id[gap_id] = gap

    security_gap_by_id: dict[str, dict] = {}
    for gap in security_gaps:
        if not isinstance(gap, dict):
            fail("security known-gap entries must be objects")
        gap_id = gap.get("id")
        if not isinstance(gap_id, str) or not gap_id.strip():
            fail("security known gaps require ids")
        if gap_id in security_gap_by_id:
            fail(f"duplicate security known gap id: {gap_id}")
        owner = gap.get("owner")
        impact = gap.get("securityImpact")
        if not isinstance(owner, str) or not owner.strip():
            fail(f"security known gap {gap_id} requires an owner")
        if not isinstance(impact, str) or not impact.strip():
            fail(f"security known gap {gap_id} requires securityImpact")
        security_gap_by_id[gap_id] = gap

    required_security_gap_ids = {"diagnostics-build-gate"}
    for gap_id in required_security_gap_ids:
        privacy_gap = privacy_gap_by_id.get(gap_id)
        security_gap = security_gap_by_id.get(gap_id)
        if privacy_gap is None:
            fail(f"PRIV-001 no longer declares required security-relevant gap: {gap_id}")
        if security_gap is None:
            fail(f"security model is missing PRIV-001 gap: {gap_id}")
        if security_gap.get("owner") != privacy_gap.get("owner"):
            fail(
                f"privacy/security gap owner drift for {gap_id}: "
                f"security={security_gap.get('owner')}, "
                f"privacy={privacy_gap.get('owner')}"
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
    allowed_severities = {"low", "medium", "high", "critical"}
    threat_ids: set[str] = set()
    categories: set[str] = set()
    threats_by_category: dict[str, dict] = {}
    for threat in threats:
        if not isinstance(threat, dict):
            fail("threat entries must be objects")
        threat_id = threat.get("id")
        if not isinstance(threat_id, str) or not threat_id.strip():
            fail("every threat requires an id")
        if threat_id in threat_ids:
            fail(f"duplicate threat id: {threat_id}")
        threat_ids.add(threat_id)
        category = threat.get("category")
        if not isinstance(category, str) or not category.strip():
            fail(f"threat {threat_id} requires a category")
        if category in threats_by_category:
            fail(f"duplicate threat category: {category}")
        categories.add(category)
        threats_by_category[category] = threat
        for field in ("scenario", "residualRisk", "owner", "followUp"):
            value = threat.get(field)
            if not isinstance(value, str) or not value.strip():
                fail(f"threat {threat_id} is missing {field}")
        severity = threat.get("severity")
        if severity not in allowed_severities:
            fail(f"threat {threat_id} has invalid severity: {severity}")
        mitigations = threat.get("mitigations")
        if not isinstance(mitigations, list) or not mitigations:
            fail(f"threat {threat_id} requires at least one mitigation")
        if not all(isinstance(item, str) and item.strip() for item in mitigations):
            fail(f"threat {threat_id} has an invalid mitigation")

    missing_categories = required_categories - categories
    if missing_categories:
        fail(f"missing threat categories: {', '.join(sorted(missing_categories))}")

    advertising_threat = threats_by_category["advertising-boundary"]
    if advertising_threat.get("owner") != "ADS-007":
        fail("advertising threat must remain owned by ADS-007 after consent integration")
    if principles.get("adSdkInitializationConsentGated") is not True:
        fail("advertising boundary requires consent-gated Mobile Ads initialization")
    diagnostics_threat = threats_by_category["diagnostic-privacy"]
    if diagnostics_threat.get("followUp") != security_gap_by_id[
        "diagnostics-build-gate"
    ].get("owner"):
        fail("diagnostic threat followUp must match the diagnostics gate owner")

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
        f"{len(threats)} threats, {len(boundaries)} trust boundaries, "
        f"{len(protected_assets)} protected assets, "
        f"{len(security_gaps)} mirrored security gaps."
    )


if __name__ == "__main__":
    main()
