#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "FEATURE_CATALOG.md"
STATUS = ROOT / "docs" / "STATUS.md"


def replace_status_field(text: str, field: str, value: str) -> str:
    lines = text.splitlines()
    prefix = f"| {field} |"
    matches = [i for i, line in enumerate(lines) if line.startswith(prefix)]
    if len(matches) != 1:
        raise SystemExit(f"Expected one STATUS field {field!r}, found {len(matches)}")
    lines[matches[0]] = f"| {field} | {value} |"
    return "\n".join(lines) + "\n"


def replace_section_item(text: str, heading: str, next_heading: str, item: str) -> str:
    start_token = f"## {heading}"
    end_token = f"## {next_heading}"
    start = text.find(start_token)
    end = text.find(end_token, start + len(start_token))
    if start < 0 or end < 0:
        raise SystemExit(f"Missing queue section {heading!r}")
    replacement = f"{start_token}\n\n- {item}\n\n"
    return text[:start] + replacement + text[end:]


catalog = CATALOG.read_text(encoding="utf-8")
lines = catalog.splitlines()
row_matches = [i for i, line in enumerate(lines) if line.startswith("| TEST-010 |")]
if len(row_matches) != 1:
    raise SystemExit(f"Expected exactly one TEST-010 row, found {len(row_matches)}")
index = row_matches[0]
cells = [cell.strip() for cell in lines[index].split("|")[1:-1]]
if len(cells) != 6:
    raise SystemExit("TEST-010 row does not have six cells")
if cells[3] not in {"PLANNED", "IN PROGRESS"}:
    raise SystemExit(f"Unexpected TEST-010 state {cells[3]!r}")
cells[3] = "IN PROGRESS"
cells[5] = (
    "Issue #187 / branch `agent/test-010-dashboard-catalog-parity` are active. "
    "Dedicated parser-parity, dependency-cycle, full-status-vocabulary, and no-hard-coded-aggregate "
    "CI contracts are being added on top of the VERIFIED ENG-007 integrity baseline."
)
lines[index] = "| " + " | ".join(cells) + " |"
catalog = "\n".join(lines) + "\n"
catalog = replace_section_item(
    catalog,
    "IN PROGRESS",
    "NEXT READY",
    "`TEST-010` Dashboard/catalog parser validation — issue #187; dedicated parity/regression gate is the sole primary workstream.",
)
catalog = replace_section_item(
    catalog,
    "NEXT READY",
    "BLOCKED",
    "None while TEST-010 is IN PROGRESS; preserve TEST-007 and latest-verified-APK gates.",
)
CATALOG.write_text(catalog, encoding="utf-8")

status = STATUS.read_text(encoding="utf-8")
status = replace_status_field(
    status,
    "Primary feature",
    "`TEST-010` Dashboard/catalog parser validation — IN PROGRESS on issue #187 / `agent/test-010-dashboard-catalog-parity`.",
)
status = replace_status_field(
    status,
    "Status",
    "Dependency-ready scan selected TEST-010 as the next source-contained P1 gate; implementation is adding parser parity, dependency-cycle rejection, complete status-vocabulary coverage, and dashboard aggregate-drift protection without touching runtime behavior.",
)
status = replace_status_field(
    status,
    "Next recommended feature",
    "Finish TEST-010 focused validator/regressions, run normal Flutter CI, reconcile evidence, then select the next single dependency-ready workstream.",
)
STATUS.write_text(status, encoding="utf-8")

print("TEST-010 marked IN PROGRESS in catalog and STATUS")
