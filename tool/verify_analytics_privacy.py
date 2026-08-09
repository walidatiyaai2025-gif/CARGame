#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ANALYTICS PRIVACY VALIDATION FAILED: {message}", file=sys.stderr)
    raise SystemExit(1)


def read(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.is_file():
        fail(f"required source is missing: {relative_path}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    inventory = json.loads(read("docs/privacy/data_inventory.json"))
    principles = inventory.get("principles", {})
    if principles.get("analyticsEnabled") is not False:
        fail("privacy inventory must keep first-party analytics disabled")

    processors = inventory.get("processors", [])
    for processor in processors:
        if not isinstance(processor, dict):
            continue
        processor_id = str(processor.get("id", "")).lower()
        if "analytic" in processor_id:
            fail("ENG-012 must not add an analytics processor")

    pubspec = read("pubspec.yaml")
    forbidden_dependencies = (
        "firebase_analytics",
        "amplitude_flutter",
        "mixpanel_flutter",
        "posthog_flutter",
        "matomo_tracker",
    )
    for dependency in forbidden_dependencies:
        if re.search(rf"^  {re.escape(dependency)}:", pubspec, re.MULTILINE):
            fail(f"analytics SDK dependency is not allowed in ENG-012: {dependency}")

    config = read("lib/core/config/app_build_config.dart")
    if "'ENABLE_ANALYTICS'" not in config:
        fail("AppBuildConfig must expose ENABLE_ANALYTICS")
    if not re.search(
        r"'ENABLE_ANALYTICS'\s*,\s*defaultValue:\s*false",
        config,
        re.MULTILINE,
    ):
        fail("ENABLE_ANALYTICS must default to false")

    event_source = read("lib/core/domain/analytics_event.dart")
    if "static const int schemaVersion = 1;" not in event_source:
        fail("analytics event schema must expose explicit version 1")
    if "Map<String, dynamic>" in event_source or "dynamic properties" in event_source:
        fail("analytics event properties must not use an unbounded dynamic payload")

    port_source = read("lib/core/application/analytics_port.dart")
    for token in ("abstract interface class AnalyticsPort", "AnalyticsPrivacyPort"):
        if token not in port_source:
            fail(f"application analytics contract is missing: {token}")

    adapter = read("lib/core/analytics/privacy_gated_analytics.dart")
    forbidden_adapter_tokens = (
        "google_mobile_ads",
        "AdConsentController",
        "canRequestAds",
        "SharedPreferences",
        "path_provider",
        "dart:io",
        "dart:convert",
        "HttpClient",
    )
    for token in forbidden_adapter_tokens:
        if token in adapter:
            fail(f"analytics adapter must remain independent of ads/storage/network: {token}")
    for token in (
        "_configEnabled && _privacy.canCollectAnalytics && _emitter != null",
        "catch (_)",
    ):
        if token not in adapter:
            fail(f"fail-closed analytics adapter contract is missing: {token}")

    composition = read("lib/bootstrap/app_composition.dart")
    for token in (
        "AppBuildConfig.current.enableAnalytics",
        "DenyAllAnalyticsPrivacy()",
    ):
        if token not in composition:
            fail(f"production analytics composition is not fail-closed: {token}")
    if "emitter:" in composition:
        fail("production composition must not install an analytics emitter in ENG-012")

    print(
        "Analytics privacy validation PASSED: schema v1, no analytics SDK/processor, "
        "build gate defaults off, runtime privacy deny-all, and no production emitter."
    )


if __name__ == "__main__":
    main()
