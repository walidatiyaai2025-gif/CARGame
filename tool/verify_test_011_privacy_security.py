#!/usr/bin/env python3
"""TEST-011 privacy/consent/security release-contract validator."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "lib/core/ads/ad_consent_controller.dart",
    "lib/core/ads/ad_service.dart",
    "lib/core/ads/banner_ad_footer.dart",
    "lib/main.dart",
    "lib/core/analytics/privacy_gated_analytics.dart",
    "lib/core/diagnostics/privacy_gated_crash_reporting.dart",
    "lib/core/privacy/local_data_controller.dart",
    "test/core/ads/ad_consent_controller_test.dart",
    "test/core/ads/ad_request_gate_test.dart",
    "test/features/settings/settings_privacy_consent_test.dart",
    "test/core/privacy/local_data_controller_test.dart",
    "test/features/settings/settings_local_data_test.dart",
    "test/core/analytics/privacy_gated_analytics_test.dart",
    "test/core/diagnostics/privacy_gated_crash_reporting_test.dart",
    "test/core/logging/app_logger_gate_test.dart",
    "test/core/security/secret_redactor_test.dart",
    "docs/TEST_011_PRIVACY_SECURITY.md",
    "docs/PRIVACY_DATA_INVENTORY.md",
    "docs/privacy/data_inventory.json",
    "docs/privacy/play_data_safety.json",
    "docs/work/TEST-011.md",
    "docs/FEATURE_CATALOG.md",
    "docs/STATUS.md",
    ".github/workflows/flutter_ci.yml",
)


class ValidationError(RuntimeError):
    pass


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise ValidationError(f"missing required TEST-011 file: {relative}")
    return path.read_text(encoding="utf-8")


def _require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise ValidationError(f"missing {label}: {needle}")


def validate(root: Path = ROOT) -> None:
    for relative in REQUIRED_FILES:
        _read(root, relative)

    consent = _read(root, "lib/core/ads/ad_consent_controller.dart")
    for needle, label in (
        ("requestConsentInfoUpdate", "UMP consent-info refresh"),
        ("loadAndShowConsentFormIfRequired", "required UMP form handling"),
        ("ConsentInformation.instance.canRequestAds()", "live UMP ad eligibility"),
        ("ConsentForm.showPrivacyOptionsForm", "UMP privacy options form"),
        ("bool _canRequestAds = false", "fail-closed default consent state"),
        ("void failClosed(Object error)", "explicit fail-closed transition"),
        ("bool get firstPartyAnalyticsAllowed => false", "analytics consent separation"),
    ):
        _require(consent, needle, label)
    if "SharedPreferences" in consent:
        raise ValidationError("ad consent controller must not persist a duplicate consent decision")

    ads = _read(root, "lib/core/ads/ad_service.dart")
    for needle, label in (
        ("AppBuildConfig.current.enableAds && _requestGate.canRequestAds", "rewarded/interstitial request gate"),
        ("if (!_adsAllowed || _disposed) return", "preload/show fail-closed guards"),
        ("_disposeLoadedAds()", "runtime consent-revocation disposal"),
        ("RewardedAd.load(", "rewarded load ownership"),
        ("InterstitialAd.load(", "interstitial load ownership"),
    ):
        _require(ads, needle, label)

    banner = _read(root, "lib/core/ads/banner_ad_footer.dart")
    for needle, label in (
        ("_consentState.canRequestAds", "banner request consent gate"),
        ("if (!_requestAllowed || _banner != null) return", "banner fail-closed load guard"),
        ("_disposeBanner()", "banner revocation disposal"),
    ):
        _require(banner, needle, label)

    main = _read(root, "lib/main.dart")
    for needle, label in (
        ("setState(() => _ready = true)", "offline core readiness boundary"),
        ("unawaited(_refreshConsentAndInitializeAds())", "post-core consent startup"),
        ("final canRequestAds = await _composition.adConsent.refresh()", "consent refresh before ads"),
        ("if (!_composition.adConsent.state.canRequestAds) return", "Mobile Ads initialization gate"),
        ("await MobileAds.instance.initialize()", "Mobile Ads initialization ownership"),
        ("Privacy/ads are optional and must never block offline play", "offline consent failure posture"),
    ):
        _require(main, needle, label)
    if main.find("setState(() => _ready = true)") > main.find("unawaited(_refreshConsentAndInitializeAds())"):
        raise ValidationError("consent/ad startup moved before offline core readiness")

    consent_tests = _read(root, "test/core/ads/ad_consent_controller_test.dart")
    for needle in (
        "disabled ads skip UMP and fail closed",
        "unexpected UMP failure is fail closed",
        "privacy options refresh runtime request eligibility without restart",
        "concurrent refresh calls are deduplicated",
    ):
        _require(consent_tests, needle, "consent regression")

    request_tests = _read(root, "test/core/ads/ad_request_gate_test.dart")
    for needle in ("reward", "interstitial", "consent"):
        _require(request_tests.lower(), needle, "ad request-gate regression coverage")

    settings_consent = _read(root, "test/features/settings/settings_privacy_consent_test.dart")
    _require(settings_consent, "privacy entry re-opens required UMP options and updates eligibility", "Settings UMP regression")
    _require(settings_consent, "privacy options button stays hidden when UMP does not require it", "Settings conditional privacy entry")

    local_tests = _read(root, "test/core/privacy/local_data_controller_test.dart")
    for needle in (
        "export is versioned JSON with local preferences and diagnostics",
        "delete clears all SharedPreferences and local diagnostics",
        "concurrent delete callers share one safe completion boundary",
        "fresh stores rehydrate safe defaults after destructive reset",
    ):
        _require(local_tests, needle, "local data control regression")

    settings_local = _read(root, "test/features/settings/settings_local_data_test.dart")
    for needle in ("export", "delete", "reset"):
        _require(settings_local.lower(), needle, "Settings local-data regression coverage")

    analytics = _read(root, "lib/core/analytics/privacy_gated_analytics.dart")
    _require(analytics, "privacy", "analytics privacy boundary")
    analytics_tests = _read(root, "test/core/analytics/privacy_gated_analytics_test.dart")
    _require(analytics_tests, "privacy", "analytics privacy regression")

    crash = _read(root, "lib/core/diagnostics/privacy_gated_crash_reporting.dart")
    _require(crash, "privacy", "crash-reporting privacy boundary")
    crash_tests = _read(root, "test/core/diagnostics/privacy_gated_crash_reporting_test.dart")
    _require(crash_tests, "privacy", "crash-reporting privacy regression")

    logger_tests = _read(root, "test/core/logging/app_logger_gate_test.dart")
    _require(logger_tests, "diagnostic", "local diagnostics gate regression")
    redactor_tests = _read(root, "test/core/security/secret_redactor_test.dart")
    _require(redactor_tests, "redact", "secret redaction regression")

    inventory = _read(root, "docs/PRIVACY_DATA_INVENTORY.md")
    for needle, label in (
        ("Google Mobile Ads is the only intentional third-party network data processor", "single declared network processor"),
        ("ENABLE_ANALYTICS` defaults to `false`", "analytics disabled-by-default disclosure"),
        ("ENABLE_REMOTE_DIAGNOSTICS=false", "remote diagnostics disabled disclosure"),
        ("networkTransfer: false", "zero-network local export disclosure"),
        ("Google UMP must remain the source of truth", "UMP data-minimization rule"),
    ):
        _require(inventory, needle, label)

    evidence = _read(root, "docs/TEST_011_PRIVACY_SECURITY.md")
    for needle, label in (
        ("Repository status:", "repository evidence status"),
        ("External UMP regulated-device verification: PENDING", "external verification boundary"),
        ("TEST-011 MUST NOT be marked VERIFIED", "CI-only verification prohibition"),
        ("Google Mobile Ads is the only intentional off-device processor", "processor evidence"),
        ("schema-versioned first-party JSON export", "local export evidence"),
        ("packaged-artifact security scan", "APK security evidence"),
        ("External evidence still required for VERIFIED", "external evidence procedure"),
    ):
        _require(evidence, needle, label)

    work = _read(root, "docs/work/TEST-011.md")
    _require(work, "# TEST-011", "TEST-011 work log identity")
    _require(work, "T100", "100-checkpoint execution contract")

    catalog = _read(root, "docs/FEATURE_CATALOG.md")
    rows = [line for line in catalog.splitlines() if line.startswith("| TEST-011 |")]
    if len(rows) != 1:
        raise ValidationError(f"expected one TEST-011 catalog row, found {len(rows)}")
    row = rows[0]
    if "| VERIFIED |" in row and "External UMP regulated-device verification: PENDING" in evidence:
        raise ValidationError("TEST-011 cannot be VERIFIED while external UMP/device evidence is pending")
    if not any(f"| {status} |" in row for status in ("IN PROGRESS", "IMPLEMENTED", "VERIFIED")):
        raise ValidationError("TEST-011 catalog row is not active/completed")

    status = _read(root, "docs/STATUS.md")
    _require(status, "TEST-011", "live TEST-011 status tracking")

    ci = _read(root, ".github/workflows/flutter_ci.yml")
    for needle, label in (
        ("Verify TEST-011 privacy consent and security contract", "TEST-011 CI validator"),
        ("python3 tool/verify_test_011_privacy_security.py", "TEST-011 validator command"),
        ("Test TEST-011 privacy consent and security validator", "TEST-011 validator regressions"),
        ("python3 tool/test_test_011_privacy_security.py", "TEST-011 validator regression command"),
        ("Test TEST-011 privacy consent and security matrix", "TEST-011 focused Flutter matrix"),
        ("test/core/ads/ad_consent_controller_test.dart", "focused consent test"),
        ("test/core/ads/ad_request_gate_test.dart", "focused ad request-gate test"),
        ("test/features/settings/settings_privacy_consent_test.dart", "focused Settings consent test"),
        ("test/core/privacy/local_data_controller_test.dart", "focused local data test"),
        ("test/features/settings/settings_local_data_test.dart", "focused Settings local data test"),
        ("test/core/security/secret_redactor_test.dart", "focused redaction test"),
    ):
        _require(ci, needle, label)

    for preserved in (
        "Verify secret hygiene",
        "Test secret hygiene policy",
        "Verify privacy data inventory",
        "Verify analytics privacy contract",
        "Verify crash reporting privacy contract",
        "Verify Play Data Safety disclosures",
        "Test privacy disclosure policy",
        "Verify security baseline",
        "Verify TEST-007 critical-path contract",
        "Verify TEST-008 quality policy",
        "Verify TEST-010 dashboard catalog parity",
        "Verify AST-004 asset cache policy",
        "Verify PERF-001 frame performance budget",
        "Verify PERF-002 memory and image budget",
        "Verify dependency security advisories",
        "Test security scan policy",
        "Run full test suite",
        "Verify TEST-008 coverage threshold",
        "Build debug APK",
        "Verify debug APK artifact security",
        "Upload debug APK",
    ):
        _require(ci, preserved, f"preserved CI gate {preserved}")


if __name__ == "__main__":
    try:
        validate()
    except ValidationError as error:
        print(f"TEST-011 VALIDATION FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
    print("TEST-011 PRIVACY CONSENT AND SECURITY VALIDATION PASSED")
