#!/usr/bin/env python3
from __future__ import annotations

import unittest

from verify_ci_integrity import (
    ContractError,
    REQUIRED_PHASES,
    parse_catalog,
    validate_dashboard_html,
    validate_release_workflow,
    validate_flutter_ci,
)


def valid_catalog(*, active: str | None = "A") -> str:
    chunks = []
    for code in REQUIRED_PHASES:
        status = "IN PROGRESS" if code == active else "PLANNED"
        chunks.extend(
            [
                f"# {code}. Phase {code}",
                "",
                "| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |",
                "|---|---|---:|---|---|---|",
                f"| F{code}-001 | Feature {code} | P1 | {status} | None | Evidence {code}. |",
                "",
            ]
        )
    return "\n".join(chunks)


VALID_DASHBOARD = r"""
<div>Source of truth: docs/FEATURE_CATALOG.md</div>
<script>
const LABELS={'VERIFIED':'x'};
const REQ='ABCDEFGHIJKLMNOPQRS'.split('');
function parse(md){
  let h=l.match(/^#\s+([A-Z])\.\s+(.+)$/);
  if(c.length<6||c[0]==='ID')continue;
}
let missingDeps=model.features.flatMap(x=>x);
let active=count('IN PROGRESS');
fetch('../FEATURE_CATALOG.md?ts='+Date.now());
renderAudit();
</script>
"""

VALID_RELEASE = r"""
permissions:
  contents: read
steps:
  - name: Restore packages
    run: flutter pub get --enforce-lockfile
  - name: Verify dependency security advisories
    run: python3 tool/verify_dependency_security.py
  - name: Test release input preflight contract
    run: ./tool/test_release_input_preflight.ps1
  - name: Prepare ephemeral release signing
    run: keytool -genkeypair
  - name: Synthetic app id
    run: echo ca-app-pub-0000000000000000~0000000000
  - name: Verify release smoke inputs
    run: echo ok
  - name: Build release APK smoke
    run: flutter build apk --release --no-pub --dart-define=ENABLE_ADS=false
  - name: Build release AAB smoke
    run: flutter build appbundle --release --no-pub --dart-define=ENABLE_ADS=false
  - name: Verify release artifact security
    run: python3 tool/verify_build_artifact_security.py app-release.apk app-release.aab
  - name: Verify release outputs
    run: |
      echo NON-DISTRIBUTABLE RELEASE PACKAGING SMOKE
      sha256sum output
  - name: Upload release smoke evidence
    uses: actions/upload-artifact@v4
    with:
      name: cargame-release-smoke-evidence
"""


VALID_FLUTTER_CI = "\n".join(
    f"- name: {step}"
    for step in (
        "Verify dynamic Android targets",
        "Verify secret hygiene",
        "Verify privacy data inventory",
        "Verify security baseline",
        "Restore packages",
        "Verify dependency security advisories",
        "Test security scan policy",
        "Verify dependency governance",
        "Test dependency governance policy",
        "Verify dashboard and release CI contracts",
        "Test dashboard and release CI contracts",
        "Validate 3D asset registry and provenance",
        "Verify changed Dart formatting",
        "Verify whitespace integrity",
        "Analyze",
        "Run full test suite",
        "Build debug APK",
        "Verify debug APK artifact security",
        "Upload debug APK",
    )
)


class CatalogContractTests(unittest.TestCase):
    def test_valid_catalog_passes(self) -> None:
        model = parse_catalog(valid_catalog())
        self.assertEqual(REQUIRED_PHASES, model.phases)
        self.assertEqual(19, len(model.features))

    def test_duplicate_feature_id_is_rejected(self) -> None:
        text = valid_catalog().replace("FB-001", "FA-001", 1)
        with self.assertRaisesRegex(ContractError, "Duplicate feature IDs"):
            parse_catalog(text)

    def test_missing_dependency_is_rejected(self) -> None:
        text = valid_catalog().replace(
            "| FA-001 | Feature A | P1 | IN PROGRESS | None |",
            "| FA-001 | Feature A | P1 | IN PROGRESS | ZZ-999 |",
            1,
        )
        with self.assertRaisesRegex(ContractError, "missing dependency ZZ-999"):
            parse_catalog(text)

    def test_invalid_status_is_rejected(self) -> None:
        text = valid_catalog().replace("IN PROGRESS", "DONE", 1)
        with self.assertRaisesRegex(ContractError, "invalid status"):
            parse_catalog(text)

    def test_invalid_priority_is_rejected(self) -> None:
        text = valid_catalog().replace("| P1 | IN PROGRESS |", "| P9 | IN PROGRESS |", 1)
        with self.assertRaisesRegex(ContractError, "invalid priority"):
            parse_catalog(text)

    def test_multiple_active_features_are_rejected(self) -> None:
        text = valid_catalog().replace("| FB-001 | Feature B | P1 | PLANNED |", "| FB-001 | Feature B | P1 | IN PROGRESS |", 1)
        with self.assertRaisesRegex(ContractError, "Only one primary feature"):
            parse_catalog(text)

    def test_missing_phase_is_rejected(self) -> None:
        section = "\n".join(
            [
                "# S. Phase S",
                "",
                "| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |",
                "|---|---|---:|---|---|---|",
                "| FS-001 | Feature S | P1 | PLANNED | None | Evidence S. |",
                "",
            ]
        )
        text = valid_catalog().replace(section, "")
        with self.assertRaisesRegex(ContractError, "exactly A-S"):
            parse_catalog(text)


class DashboardContractTests(unittest.TestCase):
    def test_valid_dashboard_contract_passes(self) -> None:
        validate_dashboard_html(VALID_DASHBOARD)

    def test_catalog_runtime_fetch_is_required(self) -> None:
        with self.assertRaisesRegex(ContractError, "catalog runtime fetch"):
            validate_dashboard_html(VALID_DASHBOARD.replace("fetch('../FEATURE_CATALOG.md?ts='", "fetch('./snapshot.json?ts='"))


class ReleaseWorkflowContractTests(unittest.TestCase):
    def test_valid_release_contract_passes(self) -> None:
        validate_release_workflow(VALID_RELEASE)

    def test_both_release_outputs_must_disable_ads(self) -> None:
        text = VALID_RELEASE.replace("--dart-define=ENABLE_ADS=false", "", 1)
        with self.assertRaisesRegex(ContractError, "both disable runtime ads"):
            validate_release_workflow(text)

    def test_production_secret_reference_is_rejected(self) -> None:
        text = VALID_RELEASE + "\nenv:\n  STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}\n"
        with self.assertRaisesRegex(ContractError, "must not depend on production repository secrets"):
            validate_release_workflow(text)


class FlutterCiContractTests(unittest.TestCase):
    def test_valid_flutter_ci_contract_passes(self) -> None:
        validate_flutter_ci(VALID_FLUTTER_CI)

    def test_dependency_security_gate_is_required(self) -> None:
        text = VALID_FLUTTER_CI.replace(
            "- name: Verify dependency security advisories\n", "", 1
        )
        with self.assertRaisesRegex(ContractError, "dependency security advisories"):
            validate_flutter_ci(text)

    def test_artifact_security_gate_is_required(self) -> None:
        text = VALID_FLUTTER_CI.replace(
            "- name: Verify debug APK artifact security\n", "", 1
        )
        with self.assertRaisesRegex(ContractError, "debug APK artifact security"):
            validate_flutter_ci(text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
