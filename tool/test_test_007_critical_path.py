#!/usr/bin/env python3
"""Regression tests for the TEST-007 contract validator."""

from __future__ import annotations

import unittest

from tool.verify_test_007_critical_path import (
    EXPECTED_IDS,
    REQUIRED_CI_TOKENS,
    REQUIRED_TEST_TOKENS,
    validate_contract,
)


def valid_doc() -> str:
    return "\n".join(f"- [ ] {checkpoint} release checkpoint" for checkpoint in EXPECTED_IDS)


def valid_test() -> str:
    calls = "\n".join(
        f"checkpoint('{checkpoint}', true, isTrue);" for checkpoint in EXPECTED_IDS
    )
    anchors = "\n".join(REQUIRED_TEST_TOKENS)
    return f"{anchors}\n{calls}\n"


def valid_ci() -> str:
    return "\n".join(REQUIRED_CI_TOKENS)


class TestTest007ContractValidator(unittest.TestCase):
    def test_accepts_complete_contract(self) -> None:
        self.assertEqual(validate_contract(valid_doc(), valid_test(), valid_ci()), [])

    def test_rejects_missing_documented_checkpoint(self) -> None:
        errors = validate_contract(
            valid_doc().replace("- [ ] T17 release checkpoint\n", ""),
            valid_test(),
            valid_ci(),
        )
        self.assertTrue(any("T01..T50" in error for error in errors))

    def test_rejects_duplicate_executable_checkpoint(self) -> None:
        errors = validate_contract(
            valid_doc(),
            valid_test() + "checkpoint('T09', true, isTrue);\n",
            valid_ci(),
        )
        self.assertTrue(any("duplicates=['T09']" in error for error in errors))

    def test_rejects_missing_production_anchor(self) -> None:
        errors = validate_contract(
            valid_doc(),
            valid_test().replace("CargoSortApp", ""),
            valid_ci(),
        )
        self.assertTrue(any("CargoSortApp" in error for error in errors))

    def test_rejects_network_dependency(self) -> None:
        errors = validate_contract(
            valid_doc(),
            valid_test() + "\nfinal endpoint = 'https://example.invalid';\n",
            valid_ci(),
        )
        self.assertTrue(any("offline" in error for error in errors))

    def test_rejects_missing_focused_ci_execution(self) -> None:
        errors = validate_contract(
            valid_doc(),
            valid_test(),
            valid_ci().replace(
                "flutter test test/integration/test_007_critical_path_test.dart", ""
            ),
        )
        self.assertTrue(any("blocking command" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
