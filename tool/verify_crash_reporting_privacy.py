#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def fail(errors: list[str]) -> None:
    print("ENG-013 crash reporting privacy contract FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)


def main() -> None:
    errors: list[str] = []

    pubspec = read("pubspec.yaml")
    build_config = read("lib/core/config/app_build_config.dart")
    contract = read("lib/core/application/crash_reporting_port.dart")
    adapter = read("lib/core/diagnostics/privacy_gated_crash_reporting.dart")
    logger = read("lib/core/logging/app_logger.dart")
    inventory = json.loads(read("docs/privacy/data_inventory.json"))

    forbidden_sdks = (
        "firebase_crashlytics",
        "sentry_flutter",
        "bugsnag_flutter",
        "datadog_flutter_plugin",
        "newrelic_mobile",
        "instabug_flutter",
    )
    for sdk in forbidden_sdks:
        if re.search(rf"^\s*{re.escape(sdk)}\s*:", pubspec, flags=re.MULTILINE):
            errors.append(f"remote crash SDK dependency is not allowed in ENG-013: {sdk}")

    required_build_fragments = (
        "ENABLE_REMOTE_DIAGNOSTICS",
        "defaultValue: false",
        "enableRemoteDiagnostics",
    )
    for fragment in required_build_fragments:
        if fragment not in build_config:
            errors.append(f"build config is missing required fragment: {fragment}")

    required_contract_fragments = (
        "static const int schemaVersion = 1",
        "CrashReportSeverity",
        "CrashReportSource",
        "CrashReportContext.fromEnvironment",
        "APP_VERSION",
        "APP_BUILD_NUMBER",
        "CrashReportingPrivacyPort",
    )
    for fragment in required_contract_fragments:
        if fragment not in contract:
            errors.append(f"crash reporting contract is missing: {fragment}")

    required_adapter_fragments = (
        "SecretRedactor.redact",
        "maxMessageLength = 512",
        "maxStackTraceLength = 8192",
        "DenyAllCrashReportingPrivacy",
        "_configEnabled && _privacy.canReportDiagnostics && _emitter != null",
        "schema_version",
        "app_version",
        "build_number",
        "timestamp_utc",
    )
    for fragment in required_adapter_fragments:
        if fragment not in adapter:
            errors.append(f"privacy-gated adapter is missing: {fragment}")

    forbidden_adapter_fragments = (
        "dart:io",
        "dart:http",
        "package:http/",
        "google_mobile_ads",
        "shared_preferences",
        "path_provider",
    )
    for fragment in forbidden_adapter_fragments:
        if fragment in adapter:
            errors.append(f"crash adapter must not own network/storage/ads coupling: {fragment}")

    required_logger_fragments = (
        "initialize(enabled: AppBuildConfig.current.enableDiagnostics)",
        "configEnabled: AppBuildConfig.current.enableRemoteDiagnostics",
        "privacy: const DenyAllCrashReportingPrivacy()",
        "CrashReportSource.flutter",
        "CrashReportSource.platform",
        "CrashReportSource.isolate",
        "reportNonFatal",
    )
    for fragment in required_logger_fragments:
        if fragment not in logger:
            errors.append(f"error boundary/local logger integration is missing: {fragment}")

    if "emitter:" in logger:
        errors.append("production error boundary must not install a remote crash emitter")

    principles = inventory.get("principles", {})
    if principles.get("diagnosticsBuildGateEffective") is not True:
        errors.append("privacy inventory must declare diagnosticsBuildGateEffective=true")
    if principles.get("remoteDiagnosticsEnabled") is not False:
        errors.append("privacy inventory must declare remoteDiagnosticsEnabled=false")

    processors = inventory.get("processors", [])
    network_processors = [item for item in processors if item.get("network") is True]
    unexpected = [
        item.get("id")
        for item in network_processors
        if item.get("id") != "google-mobile-ads"
    ]
    if unexpected:
        errors.append(f"unexpected network processor(s): {unexpected}")

    known_gaps = inventory.get("knownGaps", [])
    if any(item.get("id") == "diagnostics-build-gate" for item in known_gaps):
        errors.append("completed diagnostics-build-gate gap must be removed from inventory")

    absent = set(inventory.get("explicitlyAbsent", []))
    if "remote diagnostic upload" not in absent:
        errors.append("inventory must keep remote diagnostic upload explicitly absent")

    version_match = re.search(r"^version:\s*([^+\s]+)\+([^\s]+)", pubspec, re.MULTILINE)
    if not version_match:
        errors.append("pubspec version/build could not be parsed")
    else:
        version, build = version_match.groups()
        if f"defaultValue: '{version}'" not in contract:
            errors.append("crash APP_VERSION default must match pubspec version")
        if f"defaultValue: '{build}'" not in contract:
            errors.append("crash APP_BUILD_NUMBER default must match pubspec build number")

    if errors:
        fail(errors)

    print("ENG-013 crash reporting privacy contract: OK")


if __name__ == "__main__":
    main()
