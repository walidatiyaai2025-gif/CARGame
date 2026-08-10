#!/usr/bin/env python3
"""Mutation regressions for the TEST-011 repository validator."""

from __future__ import annotations

import shutil
import tempfile
from pathlib import Path

import verify_test_011_privacy_security as verifier

ROOT = Path(__file__).resolve().parents[1]


def _fixture() -> Path:
    temp = Path(tempfile.mkdtemp(prefix="test011-validator-"))
    for relative in verifier.REQUIRED_FILES:
        source = ROOT / relative
        target = temp / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return temp


def _replace(root: Path, relative: str, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text(encoding="utf-8")
    assert old in text, (relative, old)
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def _expect_failure(root: Path, expected: str) -> None:
    try:
        verifier.validate(root)
    except verifier.ValidationError as error:
        assert expected in str(error), (expected, str(error))
    else:
        raise AssertionError(f"expected validation failure containing {expected!r}")


def _mutated_failure(relative: str, old: str, new: str, expected: str) -> None:
    root = _fixture()
    try:
        _replace(root, relative, old, new)
        _expect_failure(root, expected)
    finally:
        shutil.rmtree(root)


def test_valid_repository_contract() -> None:
    root = _fixture()
    try:
        verifier.validate(root)
    finally:
        shutil.rmtree(root)


def test_rejects_missing_ump_refresh() -> None:
    _mutated_failure(
        "lib/core/ads/ad_consent_controller.dart",
        "requestConsentInfoUpdate",
        "removedConsentInfoUpdate",
        "UMP consent-info refresh",
    )


def test_rejects_persisted_duplicate_consent() -> None:
    _mutated_failure(
        "lib/core/ads/ad_consent_controller.dart",
        "import 'dart:async';",
        "import 'dart:async';\n// SharedPreferences duplicate consent storage",
        "must not persist a duplicate consent decision",
    )


def test_rejects_rewarded_interstitial_gate_drift() -> None:
    _mutated_failure(
        "lib/core/ads/ad_service.dart",
        "AppBuildConfig.current.enableAds && _requestGate.canRequestAds",
        "AppBuildConfig.current.enableAds",
        "rewarded/interstitial request gate",
    )


def test_rejects_banner_gate_drift() -> None:
    _mutated_failure(
        "lib/core/ads/banner_ad_footer.dart",
        "_consentState.canRequestAds",
        "true",
        "banner request consent gate",
    )


def test_rejects_offline_startup_order_drift() -> None:
    root = _fixture()
    try:
        path = root / "lib/main.dart"
        text = path.read_text(encoding="utf-8")
        ready = "setState(() => _ready = true);"
        consent = "unawaited(_refreshConsentAndInitializeAds());"
        assert ready in text and consent in text
        text = text.replace(ready, "// offline-ready marker removed", 1)
        path.write_text(text, encoding="utf-8")
        _expect_failure(root, "offline core readiness boundary")
    finally:
        shutil.rmtree(root)


def test_rejects_missing_fail_closed_regression() -> None:
    _mutated_failure(
        "test/core/ads/ad_consent_controller_test.dart",
        "unexpected UMP failure is fail closed",
        "unexpected UMP failure is ignored",
        "consent regression",
    )


def test_rejects_missing_settings_privacy_regression() -> None:
    _mutated_failure(
        "test/features/settings/settings_privacy_consent_test.dart",
        "privacy entry re-opens required UMP options and updates eligibility",
        "privacy entry regression removed",
        "Settings UMP regression",
    )


def test_rejects_missing_local_delete_regression() -> None:
    _mutated_failure(
        "test/core/privacy/local_data_controller_test.dart",
        "delete clears all SharedPreferences and local diagnostics",
        "delete regression removed",
        "local data control regression",
    )


def test_rejects_missing_settings_delete_confirmation_regression() -> None:
    _mutated_failure(
        "test/features/settings/settings_local_data_test.dart",
        "privacy-delete-confirm-button",
        "privacy-delete-confirmation-removed",
        "Settings delete confirmation regression",
    )


def test_rejects_missing_external_pending_boundary() -> None:
    _mutated_failure(
        "docs/TEST_011_PRIVACY_SECURITY.md",
        "External UMP regulated-device verification: PENDING",
        "External UMP regulated-device verification: COMPLETE",
        "external verification boundary",
    )


def test_rejects_false_verified_catalog_claim() -> None:
    root = _fixture()
    try:
        path = root / "docs/FEATURE_CATALOG.md"
        text = path.read_text(encoding="utf-8")
        rows = [line for line in text.splitlines() if line.startswith("| TEST-011 |")]
        assert len(rows) == 1
        old = rows[0]
        if "| IN PROGRESS |" in old:
            new = old.replace("| IN PROGRESS |", "| VERIFIED |", 1)
        elif "| IMPLEMENTED |" in old:
            new = old.replace("| IMPLEMENTED |", "| VERIFIED |", 1)
        else:
            raise AssertionError(f"unexpected TEST-011 row: {old}")
        path.write_text(text.replace(old, new, 1), encoding="utf-8")
        _expect_failure(root, "cannot be VERIFIED while external UMP/device evidence is pending")
    finally:
        shutil.rmtree(root)


def test_rejects_missing_test011_ci_validator() -> None:
    _mutated_failure(
        ".github/workflows/flutter_ci.yml",
        "Verify TEST-011 privacy consent and security contract",
        "Verify removed privacy contract",
        "TEST-011 CI validator",
    )


def test_rejects_missing_test011_focused_matrix() -> None:
    _mutated_failure(
        ".github/workflows/flutter_ci.yml",
        "Test TEST-011 privacy consent and security matrix",
        "Test removed privacy matrix",
        "TEST-011 focused Flutter matrix",
    )


def test_rejects_missing_secret_gate() -> None:
    _mutated_failure(
        ".github/workflows/flutter_ci.yml",
        "Verify secret hygiene",
        "Verify removed secret hygiene",
        "preserved CI gate Verify secret hygiene",
    )


def test_rejects_missing_dependency_security_gate() -> None:
    _mutated_failure(
        ".github/workflows/flutter_ci.yml",
        "Verify dependency security advisories",
        "Verify removed dependency advisories",
        "preserved CI gate Verify dependency security advisories",
    )


def test_rejects_missing_artifact_security_gate() -> None:
    _mutated_failure(
        ".github/workflows/flutter_ci.yml",
        "Verify debug APK artifact security",
        "Verify removed APK security",
        "preserved CI gate Verify debug APK artifact security",
    )


def main() -> None:
    tests = [
        test_valid_repository_contract,
        test_rejects_missing_ump_refresh,
        test_rejects_persisted_duplicate_consent,
        test_rejects_rewarded_interstitial_gate_drift,
        test_rejects_banner_gate_drift,
        test_rejects_offline_startup_order_drift,
        test_rejects_missing_fail_closed_regression,
        test_rejects_missing_settings_privacy_regression,
        test_rejects_missing_local_delete_regression,
        test_rejects_missing_settings_delete_confirmation_regression,
        test_rejects_missing_external_pending_boundary,
        test_rejects_false_verified_catalog_claim,
        test_rejects_missing_test011_ci_validator,
        test_rejects_missing_test011_focused_matrix,
        test_rejects_missing_secret_gate,
        test_rejects_missing_dependency_security_gate,
        test_rejects_missing_artifact_security_gate,
    ]
    for test in tests:
        test()
        print(f"PASS: {test.__name__}")
    print(f"TEST-011 validator regressions: {len(tests)}/{len(tests)} PASS")


if __name__ == "__main__":
    main()
