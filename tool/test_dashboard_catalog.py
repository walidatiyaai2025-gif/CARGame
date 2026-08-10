#!/usr/bin/env python3
from __future__ import annotations

import unittest

from verify_ci_integrity import ContractError, REQUIRED_PHASES
from verify_dashboard_catalog import (
    dashboard_equivalent_identity,
    validate_contract,
)

STATUSES = (
    "VERIFIED",
    "IMPLEMENTED",
    "IN PROGRESS",
    "BLOCKED",
    "READY",
    "PLANNED",
    "DEFERRED",
)


def valid_catalog() -> str:
    chunks: list[str] = []
    for index, code in enumerate(REQUIRED_PHASES):
        status = "IN PROGRESS" if index == 0 else "PLANNED"
        dependency = "None" if index == 0 else f"F{REQUIRED_PHASES[index - 1]}-001"
        chunks.extend(
            [
                f"# {code}. Phase {code}",
                "",
                "| ID | Function | Priority | Status | Dependencies | Acceptance / evidence |",
                "|---|---|---:|---|---|---|",
                f"| F{code}-001 | Feature {code} | P1 | {status} | {dependency} | Evidence {code}. |",
                "",
            ]
        )
    return "\n".join(chunks)


def valid_dashboard() -> str:
    labels = ",".join(f"'{status}':'x'" for status in STATUSES)
    return rf"""
<div>Source of truth: docs/FEATURE_CATALOG.md</div>
<script>
const LABELS={{{labels}}},STATUSES=Object.keys(LABELS),REQ='ABCDEFGHIJKLMNOPQRS'.split('');
function parse(md){{
  let h=l.match(/^#\s+([A-Z])\.\s+(.+)$/);
  if(c.length!==6||c[0]==='ID'||/^[-:]+$/.test(c[0]))continue;
  let f={{id:c[0],priority:c[2],status:c[3].toUpperCase()}};
  if(!/^[A-Z][A-Z0-9]*-\d{{3}}$/.test(f.id)||!STATUSES.includes(f.status)||!/^P[0-3]$/.test(f.priority))continue;
}}
let missingDeps=model.features.flatMap(x=>x);
let active=count('IN PROGRESS');
fetch('../FEATURE_CATALOG.md?ts='+Date.now());
renderAudit();
</script>
"""


class DashboardCatalogParityTests(unittest.TestCase):
    def test_valid_contract_passes(self) -> None:
        model = validate_contract(valid_catalog(), valid_dashboard())
        self.assertEqual(19, len(model.features))

    def test_dashboard_equivalent_identity_matches_valid_catalog(self) -> None:
        phases, features = dashboard_equivalent_identity(valid_catalog())
        self.assertEqual(REQUIRED_PHASES, phases)
        self.assertEqual(tuple((code, f"F{code}-001") for code in REQUIRED_PHASES), features)

    def test_dependency_cycle_is_rejected(self) -> None:
        text = valid_catalog().replace(
            "| FA-001 | Feature A | P1 | IN PROGRESS | None |",
            "| FA-001 | Feature A | P1 | IN PROGRESS | FB-001 |",
            1,
        )
        with self.assertRaisesRegex(ContractError, "Dependency cycle detected"):
            validate_contract(text, valid_dashboard())

    def test_missing_status_vocabulary_is_rejected(self) -> None:
        dashboard = valid_dashboard().replace("'DEFERRED':'x',", "")
        if dashboard == valid_dashboard():
            dashboard = valid_dashboard().replace(",'DEFERRED':'x'", "")
        with self.assertRaisesRegex(ContractError, "status vocabulary drift"):
            validate_contract(valid_catalog(), dashboard)

    def test_non_strict_six_column_dashboard_parser_is_rejected(self) -> None:
        dashboard = valid_dashboard().replace("c.length!==6", "c.length<6", 1)
        with self.assertRaisesRegex(ContractError, "six-column parser guard"):
            validate_contract(valid_catalog(), dashboard)

    def test_non_strict_feature_id_guard_is_rejected(self) -> None:
        dashboard = valid_dashboard().replace(
            "/^[A-Z][A-Z0-9]*-\\d{3}$/.test(f.id)",
            "/^[A-Z0-9]+-\\d+/.test(f.id)",
            1,
        )
        with self.assertRaisesRegex(ContractError, "exact feature-id parser guard"):
            validate_contract(valid_catalog(), dashboard)

    def test_hard_coded_aggregate_is_rejected(self) -> None:
        dashboard = valid_dashboard() + "\n<script>const TOTAL_FEATURES=123;</script>\n"
        with self.assertRaisesRegex(ContractError, "hard-coded aggregate"):
            validate_contract(valid_catalog(), dashboard)

    def test_missing_dependency_is_rejected_by_authoritative_parser(self) -> None:
        text = valid_catalog().replace("| FB-001 |", "| FB-001 |", 1).replace(
            "| FC-001 | Feature C | P1 | PLANNED | FB-001 |",
            "| FC-001 | Feature C | P1 | PLANNED | ZZ-999 |",
            1,
        )
        with self.assertRaisesRegex(ContractError, "missing dependency ZZ-999"):
            validate_contract(text, valid_dashboard())

    def test_malformed_six_column_row_is_rejected(self) -> None:
        text = valid_catalog().replace(
            "| FB-001 | Feature B | P1 | PLANNED | FA-001 | Evidence B. |",
            "| FB-001 | Feature B | P1 | PLANNED | FA-001 | Evidence B. | Extra |",
            1,
        )
        with self.assertRaisesRegex(ContractError, "exactly 6 cells"):
            validate_contract(text, valid_dashboard())


if __name__ == "__main__":
    unittest.main(verbosity=2)
