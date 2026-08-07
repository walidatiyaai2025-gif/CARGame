#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "docs/privacy/data_inventory.json"
PUBSPEC = ROOT / "pubspec.yaml"


def fail(message: str) -> None:
    print(f"PRIVACY INVENTORY VALIDATION FAILED: {message}", file=sys.stderr)
    raise SystemExit(1)


def dependency_present(pubspec: str, name: str) -> bool:
    return re.search(rf"^  {re.escape(name)}:", pubspec, re.MULTILINE) is not None


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
    for processor in processors:
        if not isinstance(processor, dict):
            fail("processor entries must be objects")
        processor_id = processor.get("id")
        if not isinstance(processor_id, str) or not processor_id.strip():
            fail("processor id is required")
        if processor_id in processor_ids:
            fail(f"duplicate processor id: {processor_id}")
        processor_ids.add(processor_id)

    required_flow_ids = {
        "game-progress",
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

        if flow["processor"] not in processor_ids:
            fail(f"data flow {flow_id} references unknown processor")
        if not (ROOT / flow["source"]).is_file():
            fail(f"data flow {flow_id} source does not exist: {flow['source']}")

    missing = required_flow_ids - flow_ids
    if missing:
        fail(f"required data flows are missing: {', '.join(sorted(missing))}")

    pubspec = PUBSPEC.read_text(encoding="utf-8")
    declared = set(policy.get("networkDataDependencies", []))
    declared.update(policy.get("localStorageDependencies", []))
    for dependency in declared:
        if not dependency_present(pubspec, dependency):
            fail(f"inventory declares dependency {dependency} but pubspec does not")

    for dependency in policy.get("forbiddenUnlessInventoryUpdated", []):
        if dependency_present(pubspec, dependency):
            fail(
                f"dependency {dependency} was added but is still marked "
                "forbidden-until-reviewed"
            )

    principles = data.get("principles", {})
    if principles.get("offlineFirst") is not True:
        fail("offlineFirst must remain true")
    if principles.get("analyticsEnabled") is not False:
        fail("analyticsEnabled changed without inventory review")
    if principles.get("cloudSyncEnabled") is not False:
        fail("cloudSyncEnabled changed without inventory review")

    print(
        "Privacy inventory validation PASSED: "
        f"{len(flows)} flows, {len(processors)} processors."
    )


if __name__ == "__main__":
    main()
