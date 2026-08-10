#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, found {count}: {old[:80]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


dashboard = ROOT / "docs" / "dashboard" / "index.html"
replace_once(
    dashboard,
    "if(c.length<6||c[0]==='ID'||/^[-:]+$/.test(c[0]))continue;",
    "if(c.length!==6||c[0]==='ID'||/^[-:]+$/.test(c[0]))continue;",
)
replace_once(
    dashboard,
    "if(!/^[A-Z0-9]+-\\d+/.test(f.id))continue;",
    "if(!/^[A-Z][A-Z0-9]*-\\d{3}$/.test(f.id)||!STATUSES.includes(f.status)||!/^P[0-3]$/.test(f.priority))continue;",
)

verify_ci = ROOT / "tool" / "verify_ci_integrity.py"
replace_once(
    verify_ci,
    '"six-column parser guard": "if(c.length<6||c[0]===\'ID\'",',
    '"six-column parser guard": "if(c.length!==6||c[0]===\'ID\'",',
)
replace_once(
    verify_ci,
    '        "Test TEST-007 critical-path validator",\n        "Restore packages",',
    '        "Test TEST-007 critical-path validator",\n        "Verify TEST-010 dashboard catalog parity",\n        "Test TEST-010 dashboard catalog validator",\n        "Restore packages",',
)

test_ci = ROOT / "tool" / "test_ci_integrity.py"
replace_once(test_ci, "if(c.length<6||c[0]==='ID')continue;", "if(c.length!==6||c[0]==='ID')continue;")
replace_once(
    test_ci,
    '        "Verify security baseline",\n        "Restore packages",',
    '        "Verify security baseline",\n        "Verify TEST-010 dashboard catalog parity",\n        "Test TEST-010 dashboard catalog validator",\n        "Restore packages",',
)

flutter_ci = ROOT / ".github" / "workflows" / "flutter_ci.yml"
replace_once(
    flutter_ci,
    "      - name: Test TEST-007 critical-path validator\n        run: python3 tool/test_test_007_critical_path.py\n\n      - name: Restore packages",
    "      - name: Test TEST-007 critical-path validator\n        run: python3 tool/test_test_007_critical_path.py\n\n      - name: Verify TEST-010 dashboard catalog parity\n        run: python3 tool/verify_dashboard_catalog.py\n\n      - name: Test TEST-010 dashboard catalog validator\n        run: python3 tool/test_dashboard_catalog.py\n\n      - name: Restore packages",
)

catalog = ROOT / "docs" / "FEATURE_CATALOG.md"
replace_once(
    catalog,
    "| NAV-003 | Deep-link and notification route safety | P2 | PLANNED | NAV-001, RET-008 |",
    "| NAV-003 | Deep-link and notification route safety | P2 | PLANNED | NAV-001 |",
)

print("Applied TEST-010 parser parity implementation patches")
