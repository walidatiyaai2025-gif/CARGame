#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "docs/privacy/data_inventory.json"
PUBSPEC = ROOT / "pubspec.yaml"
STORAGE_KEY_PATTERN = re.compile(
    r"static const\s+([A-Za-z_][A-Za-z0-9_]*(?:Key|Prefix))\s*=\s*'([^']+)'\s*;"
)


def fail(message: str) -> None:
    print(f"PRIVACY INVENTORY VALIDATION FAILED: {message}", file=sys.stderr)
    raise SystemExit(1)


def dependency_present(pubspec: str, name: str) -> bool:
    return re.search(rf"^  {re.escape(name)}:", pubspec, re.MULTILINE) is not None


def string_list(value: object, label: str) -> list[str]:
    if not isinstance(value, list):
        fail(f"{label} must be an array")
    result: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            fail(f"{label} must contain non-empty strings")
        result.append(item)
    return result


def declared_storage_keys(flows: list[dict[str, object]]) -> set[str]:
    keys: set[str] = set()
    for flow in flows:
        flow_id = str(flow["id"])
        for key in string_list(flow.get("storageKeys", []), f"{flow_id}.storageKeys"):
            if key in keys:
                fail(f"storage key is inventoried more than once: {key}")
            keys.add(key)
    return keys


def source_storage_keys(paths: list[str]) -> set[str]:
    keys: set[str] = set()
    for relative_path in paths:
        source = ROOT / relative_path
        if not source.is_file():
            fail(f"local persistence source does not exist: {relative_path}")
        text = source.read_text(encoding="utf-8")
        matches = STORAGE_KEY_PATTERN.findall(text)
        if not matches:
            fail(f"local persistence source exposes no tracked keys: {relative_path}")
        for _, key in matches:
            if key in keys:
                fail(f"storage key is declared by multiple persistence sources: {key}")
            keys.add(key)
    return keys


def main() -> None:
    if not INVENTORY.is_file():
        fail("docs/privacy/data_inventory.json is missing")

    try:
        data = json.loads(INVENTORY.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"inventory cannot be parsed: {exc}")

    if data.get("schemaVersion") != 1:
        fail("unsupported or missing schemaVersion")

    processors = data.get("processors")
    flows = data.get("dataFlows")
    policy = data.get("dependencyPolicy")
    if not isinstance(processors, list) or not isinstance(flows, list):
        fail("processors and dataFlows must be arrays")
    if not isinstance(policy, dict):
        fail("dependencyPolicy must be an object")

    processor_ids: set[str] = set()
    processor_network: dict[str, bool] = {}
    network_processor_dependencies: set[str] = set()
    for processor in processors:
        if not isinstance(processor, dict):
            fail("processor entries must be objects")
        processor_id = processor.get("id")
        if not isinstance(processor_id, str) or not processor_id.strip():
            fail("processor id is required")
        if processor_id in processor_ids:
            fail(f"duplicate processor id: {processor_id}")
        network = processor.get("network")
        if not isinstance(network, bool):
            fail(f"processor {processor_id} must declare network as a boolean")
        processor_ids.add(processor_id)
        processor_network[processor_id] = network
        if network:
            dependency = processor.get("dependency")
            if not isinstance(dependency, str) or not dependency.strip():
                fail(f"network processor {processor_id} must declare its dependency")
            network_processor_dependencies.add(dependency)

    required_flow_ids = {
        "game-progress",
        "persistence-integrity",
        "storage-recovery-backup",
        "app-settings",
        "diagnostic-logs",
        "ad-sdk-processing",
    }
    required_fields = {
        "category",
        "purpose",
        "processor",
        "storage",
        "consent",
        "retention",
        "deletion",
        "source",
    }
    typed_flows: list[dict[str, object]] = []
    flow_ids: set[str] = set()
    for flow in flows:
        if not isinstance(flow, dict):
            fail("data-flow entries must be objects")
        flow_id = flow.get("id")
        if not isinstance(flow_id, str) or not flow_id.strip():
            fail("data-flow id is required")
        if flow_id in flow_ids:
            fail(f"duplicate data-flow id: {flow_id}")
        flow_ids.add(flow_id)

        for field in required_fields:
            value = flow.get(field)
            if not isinstance(value, str) or not value.strip():
                fail(f"data flow {flow_id} is missing {field}")

        processor_id = str(flow["processor"])
        if processor_id not in processor_ids:
            fail(f"data flow {flow_id} references unknown processor")
        network = flow.get("network")
        if not isinstance(network, bool):
            fail(f"data flow {flow_id} must declare network as a boolean")
        if network != processor_network[processor_id]:
            fail(
                f"data flow {flow_id} network={network} disagrees with "
                f"processor {processor_id} network={processor_network[processor_id]}"
            )
        if not (ROOT / str(flow["source"])).is_file():
            fail(f"data flow {flow_id} source does not exist: {flow['source']}")
        typed_flows.append(flow)

    missing = required_flow_ids - flow_ids
    if missing:
        fail(f"required data flows are missing: {', '.join(sorted(missing))}")

    pubspec = PUBSPEC.read_text(encoding="utf-8")
    network_dependencies = set(
        string_list(
            policy.get("networkDataDependencies", []),
            "dependencyPolicy.networkDataDependencies",
        )
    )
    local_dependencies = set(
        string_list(
            policy.get("localStorageDependencies", []),
            "dependencyPolicy.localStorageDependencies",
        )
    )
    declared_dependencies = network_dependencies | local_dependencies
    for dependency in declared_dependencies:
        if not dependency_present(pubspec, dependency):
            fail(f"inventory declares dependency {dependency} but pubspec does not")

    missing_network_dependencies = network_processor_dependencies - network_dependencies
    if missing_network_dependencies:
        fail(
            "network processor dependencies are not inventoried: "
            + ", ".join(sorted(missing_network_dependencies))
        )

    for dependency in string_list(
        policy.get("forbiddenUnlessInventoryUpdated", []),
        "dependencyPolicy.forbiddenUnlessInventoryUpdated",
    ):
        if dependency_present(pubspec, dependency):
            fail(
                f"dependency {dependency} was added but is still marked "
                "forbidden-until-reviewed"
            )

    persistence_sources = string_list(
        policy.get("localPersistenceSources", []),
        "dependencyPolicy.localPersistenceSources",
    )
    if not persistence_sources:
        fail("at least one local persistence source must be declared")

    inventoried_keys = declared_storage_keys(typed_flows)
    actual_keys = source_storage_keys(persistence_sources)
    missing_keys = actual_keys - inventoried_keys
    stale_keys = inventoried_keys - actual_keys
    if missing_keys:
        fail(
            "persisted keys are missing from the privacy inventory: "
            + ", ".join(sorted(missing_keys))
        )
    if stale_keys:
        fail(
            "privacy inventory declares storage keys not found in current sources: "
            + ", ".join(sorted(stale_keys))
        )

    principles = data.get("principles", {})
    if principles.get("offlineFirst") is not True:
        fail("offlineFirst must remain true")
    if principles.get("analyticsEnabled") is not False:
        fail("analyticsEnabled changed without inventory review")
    if principles.get("cloudSyncEnabled") is not False:
        fail("cloudSyncEnabled changed without inventory review")
    for key in (
        "adsFailClosedByConfig",
        "adRequestsFailClosedByConfig",
        "adSdkInitializationConsentGated",
        "adRequestsConsentGated",
    ):
        if principles.get(key) is not True:
            fail(f"{key} must remain true after ADS-007")

    consent_source = (ROOT / "lib/core/ads/ad_consent_controller.dart").read_text(
        encoding="utf-8"
    )
    main_source = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
    ad_service_source = (ROOT / "lib/core/ads/ad_service.dart").read_text(
        encoding="utf-8"
    )
    banner_source = (ROOT / "lib/core/ads/banner_ad_footer.dart").read_text(
        encoding="utf-8"
    )
    settings_source = (ROOT / "lib/features/settings/settings_screen.dart").read_text(
        encoding="utf-8"
    )
    required_source_contracts = {
        "UMP launch refresh": (consent_source, "requestConsentInfoUpdate"),
        "UMP required form": (consent_source, "loadAndShowConsentFormIfRequired"),
        "UMP request eligibility": (consent_source, "canRequestAds"),
        "privacy options form": (consent_source, "showPrivacyOptionsForm"),
        "bootstrap consent refresh": (main_source, "_composition.adConsent.refresh()"),
        "bootstrap request gate": (main_source, "if (!_composition.adConsent.state.canRequestAds) return;"),
        "fullscreen ad gate": (ad_service_source, "_requestGate.canRequestAds"),
        "banner ad gate": (banner_source, "_consentState.canRequestAds"),
        "publisher privacy entry": (settings_source, "privacy-options-button"),
    }
    for label, (source, token) in required_source_contracts.items():
        if token not in source:
            fail(f"ADS-007 source contract missing {label}: {token}")

    print(
        "Privacy inventory validation PASSED: "
        f"{len(flows)} flows, {len(processors)} processors, "
        f"{len(actual_keys)} persisted key families."
    )


if __name__ == "__main__":
    main()
