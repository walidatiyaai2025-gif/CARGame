#!/usr/bin/env python3
"""Validate the TEST-007 50-checkpoint critical-path release contract."""

from __future__ import annotations

import re
import sys
from pathlib import Path

EXPECTED_IDS = [f"T{index:02d}" for index in range(1, 51)]
CHECKPOINT_PATTERN = re.compile(r"checkpoint\(\s*['\"](T\d{2})['\"]")
DOC_PATTERN = re.compile(r"^- \[[ xX]\] (T\d{2})\b", re.MULTILINE)

REQUIRED_TEST_TOKENS = (
    "CargoSortApp",
    "HomeScreen",
    "LevelSelectScreen",
    "CityBriefingScreen",
    "GameScreen",
    "GameplayResultDebrief",
    "ShopScreen",
    "EconomyConfig.current",
    "completeLevel(",
    "purchaseShopBooster('hint')",
    "pending_shop_purchase_v1",
    "ProgressStore()",
    "InMemorySharedPreferencesAsync",
    "TextDirection.ltr",
    "TextDirection.rtl",
)

FORBIDDEN_TEST_TOKENS = (
    "package:http/",
    "package:dio/",
    "HttpClient(",
    "https://",
    "http://",
)

REQUIRED_CI_TOKENS = (
    "python3 tool/verify_test_007_critical_path.py",
    "python3 tool/test_test_007_critical_path.py",
    "flutter test test/integration/test_007_critical_path_test.dart",
)


def _duplicates(values: list[str]) -> list[str]:
    return sorted({value for value in values if values.count(value) > 1})


def validate_contract(doc_text: str, test_text: str, ci_text: str) -> list[str]:
    errors: list[str] = []

    doc_ids = DOC_PATTERN.findall(doc_text)
    test_ids = CHECKPOINT_PATTERN.findall(test_text)

    if doc_ids != EXPECTED_IDS:
        missing = sorted(set(EXPECTED_IDS) - set(doc_ids))
        unexpected = sorted(set(doc_ids) - set(EXPECTED_IDS))
        duplicates = _duplicates(doc_ids)
        errors.append(
            "docs/work/TEST-007.md must declare T01..T50 exactly once in order; "
            f"missing={missing}, unexpected={unexpected}, duplicates={duplicates}"
        )

    if sorted(test_ids) != EXPECTED_IDS or len(test_ids) != 50:
        missing = sorted(set(EXPECTED_IDS) - set(test_ids))
        unexpected = sorted(set(test_ids) - set(EXPECTED_IDS))
        duplicates = _duplicates(test_ids)
        errors.append(
            "TEST-007 integration test must execute exactly one checkpoint call for "
            f"each T01..T50; missing={missing}, unexpected={unexpected}, "
            f"duplicates={duplicates}, total={len(test_ids)}"
        )

    for token in REQUIRED_TEST_TOKENS:
        if token not in test_text:
            errors.append(f"TEST-007 integration contract is missing required token: {token}")

    for token in FORBIDDEN_TEST_TOKENS:
        if token in test_text:
            errors.append(
                "TEST-007 must remain deterministic/offline; forbidden network token "
                f"found: {token}"
            )

    for token in REQUIRED_CI_TOKENS:
        if token not in ci_text:
            errors.append(f"Flutter CI is missing TEST-007 blocking command: {token}")

    return errors


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    doc_path = root / "docs" / "work" / "TEST-007.md"
    test_path = root / "test" / "integration" / "test_007_critical_path_test.dart"
    ci_path = root / ".github" / "workflows" / "flutter_ci.yml"

    missing_files = [
        str(path.relative_to(root))
        for path in (doc_path, test_path, ci_path)
        if not path.is_file()
    ]
    if missing_files:
        for path in missing_files:
            print(f"ERROR: missing TEST-007 contract file: {path}")
        return 1

    errors = validate_contract(
        doc_path.read_text(encoding="utf-8"),
        test_path.read_text(encoding="utf-8"),
        ci_path.read_text(encoding="utf-8"),
    )
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print(
        "TEST-007 critical-path contract verified: 50/50 checkpoints, production "
        "journey/state anchors present, offline boundary preserved, CI commands present."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
