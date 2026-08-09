#!/usr/bin/env python3
"""Validate CARGame privacy policy and Google Play Data Safety disclosure mapping."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "docs" / "privacy" / "data_inventory.json"
DISCLOSURE = ROOT / "docs" / "privacy" / "play_data_safety.json"
POLICY = ROOT / "docs" / "PRIVACY_POLICY.md"
LOCAL_DATA_CONTROLLER = ROOT / "lib" / "core" / "privacy" / "local_data_controller.dart"
SETTINGS_SCREEN = ROOT / "lib" / "features" / "settings" / "settings_screen.dart"

REQUIRED_GMA_DATA_TYPES = {
    "approximate_location",
    "app_interactions",
    "diagnostics",
    "device_or_other_ids",
}
REQUIRED_GMA_PURPOSES = {
    "advertising_or_marketing",
    "analytics",
    "fraud_prevention_security_compliance",
}


class DisclosureError(RuntimeError):
    """Raised when privacy/store disclosure contracts drift."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise DisclosureError(message)


def _objects(value: object, label: str) -> list[dict[str, object]]:
    _require(isinstance(value, list), f"{label} must be an array")
    result: list[dict[str, object]] = []
    for item in value:
        _require(isinstance(item, dict), f"{label} entries must be objects")
        result.append(item)
    return result


def _strings(value: object, label: str) -> list[str]:
    _require(isinstance(value, list), f"{label} must be an array")
    result: list[str] = []
    for item in value:
        _require(
            isinstance(item, str) and bool(item.strip()),
            f"{label} must contain non-empty strings",
        )
        result.append(item)
    return result


def _flow_map(
    flows: list[dict[str, object]], label: str
) -> dict[str, dict[str, object]]:
    result: dict[str, dict[str, object]] = {}
    for flow in flows:
        flow_id = flow.get("id") if label == "inventory" else flow.get("flowId")
        _require(
            isinstance(flow_id, str) and bool(flow_id.strip()),
            f"{label} flow id is required",
        )
        _require(flow_id not in result, f"duplicate {label} flow mapping: {flow_id}")
        result[flow_id] = flow
    return result


def validate_models(
    inventory: dict[str, object],
    disclosure: dict[str, object],
    policy_text: str,
) -> None:
    _require(inventory.get("schemaVersion") == 1, "inventory schemaVersion must be 1")
    _require(
        disclosure.get("schemaVersion") == 1,
        "disclosure schemaVersion must be 1",
    )
    _require(
        disclosure.get("sourceInventory") == "docs/privacy/data_inventory.json",
        "disclosure must identify docs/privacy/data_inventory.json as its source",
    )
    _require(
        disclosure.get("policyDocument") == "docs/PRIVACY_POLICY.md",
        "disclosure must identify docs/PRIVACY_POLICY.md as its policy",
    )

    inventory_flows = _flow_map(
        _objects(inventory.get("dataFlows"), "inventory.dataFlows"), "inventory"
    )
    mappings = _flow_map(
        _objects(disclosure.get("flowMappings"), "disclosure.flowMappings"),
        "disclosure",
    )
    missing = set(inventory_flows) - set(mappings)
    stale = set(mappings) - set(inventory_flows)
    _require(
        not missing,
        "disclosure is missing inventory flows: " + ", ".join(sorted(missing)),
    )
    _require(
        not stale,
        "disclosure contains stale flows: " + ", ".join(sorted(stale)),
    )

    processors = {
        str(processor.get("id")): processor
        for processor in _objects(inventory.get("processors"), "inventory.processors")
    }
    network_processors = {
        processor_id
        for processor_id, processor in processors.items()
        if processor.get("network") is True
    }
    _require(
        network_processors == {"google-mobile-ads"},
        "current disclosure contract expects Google Mobile Ads as the only network processor",
    )

    network_flows: list[str] = []
    for flow_id, inventory_flow in inventory_flows.items():
        mapping = mappings[flow_id]
        processor = inventory_flow.get("processor")
        _require(
            mapping.get("processor") == processor,
            f"{flow_id} processor does not match privacy inventory",
        )
        network = inventory_flow.get("network")
        _require(
            isinstance(network, bool),
            f"{flow_id} inventory network flag must be boolean",
        )
        data_types = _objects(mapping.get("dataTypes"), f"{flow_id}.dataTypes")
        collected = mapping.get("collectedOffDevice")
        shared = mapping.get("sharedWithThirdParties")
        _require(
            isinstance(collected, bool),
            f"{flow_id}.collectedOffDevice must be boolean",
        )
        _require(
            isinstance(shared, bool),
            f"{flow_id}.sharedWithThirdParties must be boolean",
        )

        if not network:
            _require(
                not collected,
                f"{flow_id} is local-only and must not be declared off-device collection",
            )
            _require(
                not shared,
                f"{flow_id} is local-only and must not be declared third-party sharing",
            )
            _require(
                not data_types,
                f"{flow_id} is local-only and must not declare Play data types",
            )
            continue

        network_flows.append(flow_id)
        _require(
            collected,
            f"{flow_id} network processing must be declared as collected off device",
        )
        _require(
            shared,
            f"{flow_id} Google Mobile Ads processing must conservatively be declared shared",
        )

    _require(
        network_flows == ["ad-sdk-processing"],
        "ad-sdk-processing must be the only off-device flow in the current inventory",
    )

    ad_mapping = mappings["ad-sdk-processing"]
    typed_ad_data = _objects(
        ad_mapping.get("dataTypes"), "ad-sdk-processing.dataTypes"
    )
    observed_types: set[str] = set()
    for item in typed_ad_data:
        data_type = item.get("type")
        _require(
            isinstance(data_type, str) and bool(data_type),
            "Google Mobile Ads data type id is required",
        )
        _require(
            data_type not in observed_types,
            f"duplicate Google Mobile Ads data type: {data_type}",
        )
        observed_types.add(data_type)
        purposes = set(_strings(item.get("purposes"), f"{data_type}.purposes"))
        missing_purposes = REQUIRED_GMA_PURPOSES - purposes
        _require(
            not missing_purposes,
            f"{data_type} is missing required Google Mobile Ads purposes: "
            + ", ".join(sorted(missing_purposes)),
        )

    _require(
        observed_types == REQUIRED_GMA_DATA_TYPES,
        "Google Mobile Ads disclosure data types must be exactly: "
        + ", ".join(sorted(REQUIRED_GMA_DATA_TYPES)),
    )

    expected_absent = set(
        _strings(inventory.get("explicitlyAbsent"), "inventory.explicitlyAbsent")
    )
    disclosed_absent = set(
        _strings(disclosure.get("explicitlyAbsent"), "disclosure.explicitlyAbsent")
    )
    _require(
        disclosed_absent == expected_absent,
        "explicitlyAbsent must exactly match the privacy inventory",
    )

    safety = disclosure.get("playDataSafety")
    _require(isinstance(safety, dict), "playDataSafety must be an object")
    _require(
        safety.get("collectsUserData") is True,
        "Play Data Safety must disclose SDK off-device collection",
    )
    _require(
        safety.get("sharesUserData") is True,
        "Play Data Safety must disclose SDK third-party sharing",
    )
    _require(
        safety.get("accountCreationAvailable") is False,
        "CARGame currently has no account creation",
    )
    _require(
        safety.get("deletionRequestMechanismAvailable") is True,
        "local deletion mechanism must remain available after PRIV-003",
    )
    encryption = safety.get("encryptedInTransit")
    _require(isinstance(encryption, dict), "encryptedInTransit must be an object")
    _require(
        encryption.get("recommendedAnswer") is True,
        "Google Mobile Ads SDK disclosure supports an encrypted-in-transit recommendation",
    )
    _require(
        encryption.get("requiresProductionConfirmation") is True,
        "encryption answer must remain flagged for production confirmation",
    )

    gaps = {
        str(gap.get("id")): gap
        for gap in _objects(inventory.get("knownGaps"), "inventory.knownGaps")
    }
    _require(
        "in-app-data-controls" not in gaps,
        "completed PRIV-003 in-app data-controls gap must not remain in inventory",
    )

    publication = disclosure.get("publication")
    _require(isinstance(publication, dict), "publication must be an object")
    state = publication.get("state")
    _require(
        state in {"draft", "published"},
        "publication.state must be draft or published",
    )
    url = publication.get("privacyPolicyUrl")
    contact = publication.get("publisherContact")

    required_policy_tokens = (
        "# CARGame Privacy Policy",
        "## Data stored on your device",
        "## Advertising and Google Mobile Ads",
        "Google UMP",
        "canRequestAds",
        "IP address",
        "app interactions",
        "diagnostic information",
        "device and account identifiers",
        "## Data we do not collect in first-party code",
        "## Retention and deletion",
        "Settings > Privacy",
        "JSON export",
        "## Children and target audience",
        "## Contact",
    )
    for token in required_policy_tokens:
        _require(
            token in policy_text,
            f"privacy policy is missing required content: {token}",
        )

    if state == "draft":
        _require(
            "Publication status: DRAFT — NOT YET PUBLISHED" in policy_text,
            "draft policy marker is missing",
        )
        _require(url is None, "draft disclosure must not fabricate a privacy policy URL")
        _require(
            contact is None,
            "draft disclosure must not fabricate publisher contact",
        )
        _require(
            publication.get("targetAudienceConfirmed") is False,
            "draft target audience must remain unconfirmed",
        )
        _require(
            publication.get("playConsoleSubmitted") is False,
            "draft must not claim Play Console submission",
        )
        _require(
            publication.get("productionAdMobConfigurationReviewed") is False,
            "draft must not claim production AdMob configuration review",
        )
        _require(
            "PUBLISHER CONTACT EMAIL REQUIRED BEFORE PUBLICATION" in policy_text,
            "draft policy must retain the publisher-contact publication blocker",
        )
    else:
        _require(
            isinstance(url, str) and re.fullmatch(r"https://[^\s]+", url) is not None,
            "published privacy policy requires a stable HTTPS URL",
        )
        _require(
            isinstance(contact, str)
            and bool(contact.strip())
            and "REQUIRED" not in contact.upper()
            and "PLACEHOLDER" not in contact.upper(),
            "published privacy policy requires real publisher contact",
        )
        _require(
            publication.get("targetAudienceConfirmed") is True,
            "published target audience must be confirmed",
        )
        _require(
            publication.get("playConsoleSubmitted") is True,
            "published state requires Play Console submission",
        )
        _require(
            publication.get("productionAdMobConfigurationReviewed") is True,
            "published state requires production AdMob configuration review",
        )
        _require(
            "NOT YET PUBLISHED" not in policy_text,
            "published policy still carries a draft marker",
        )
        _require(
            "PUBLISHER CONTACT EMAIL REQUIRED BEFORE PUBLICATION" not in policy_text,
            "published policy still carries a contact placeholder",
        )


def _validate_runtime_controls(root: Path) -> None:
    controller_path = root / "lib" / "core" / "privacy" / "local_data_controller.dart"
    settings_path = root / "lib" / "features" / "settings" / "settings_screen.dart"
    try:
        controller_text = controller_path.read_text(encoding="utf-8")
        settings_text = settings_path.read_text(encoding="utf-8")
    except OSError as exc:
        raise DisclosureError(f"local data control source cannot be read: {exc}") from exc

    for token in (
        "class LocalDataController",
        "Future<String> exportJson()",
        "Future<void> deleteAllLocalData()",
        "'networkTransfer': false",
    ):
        _require(
            token in controller_text,
            f"PRIV-003 local data controller is missing runtime contract: {token}",
        )

    for token in (
        "privacy-export-data-button",
        "privacy-delete-data-button",
        "privacy-delete-confirm-button",
    ):
        _require(
            token in settings_text,
            f"PRIV-003 Settings control is missing runtime contract: {token}",
        )


def validate_repository(root: Path = ROOT) -> tuple[int, int]:
    inventory_path = root / "docs" / "privacy" / "data_inventory.json"
    disclosure_path = root / "docs" / "privacy" / "play_data_safety.json"
    policy_path = root / "docs" / "PRIVACY_POLICY.md"
    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        disclosure = json.loads(disclosure_path.read_text(encoding="utf-8"))
        policy_text = policy_path.read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as exc:
        raise DisclosureError(
            f"privacy disclosure inputs cannot be read: {exc}"
        ) from exc

    validate_models(inventory, disclosure, policy_text)
    _validate_runtime_controls(root)
    mapping_count = len(
        _objects(disclosure.get("flowMappings"), "disclosure.flowMappings")
    )
    ad_types = next(
        mapping["dataTypes"]
        for mapping in disclosure["flowMappings"]
        if mapping["flowId"] == "ad-sdk-processing"
    )
    return mapping_count, len(ad_types)


def main() -> int:
    try:
        flow_count, ad_type_count = validate_repository()
    except DisclosureError as exc:
        print(f"PRIVACY DISCLOSURE VALIDATION FAILED: {exc}", file=sys.stderr)
        return 1
    print(
        "Privacy disclosure validation PASSED: "
        f"{flow_count} flows; 1 off-device SDK flow; "
        f"{ad_type_count} Google Mobile Ads data types; "
        "local export/delete controls=available; publication=draft."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
