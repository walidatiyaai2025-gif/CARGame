#!/usr/bin/env python3
"""TEST-010: verify dashboard/catalog parser parity and dependency integrity."""

from __future__ import annotations

import re
import sys
from pathlib import Path

from verify_ci_integrity import (
    ALLOWED_PRIORITIES,
    ALLOWED_STATUSES,
    DEPENDENCY_ID,
    FEATURE_ID,
    PHASE_HEADING,
    REQUIRED_PHASES,
    TABLE_HEADER,
    CatalogModel,
    ContractError,
    parse_catalog,
    validate_dashboard_html,
)

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "FEATURE_CATALOG.md"
DASHBOARD = ROOT / "docs" / "dashboard" / "index.html"

LABEL_OBJECT = re.compile(r"const\s+LABELS\s*=\s*\{(?P<body>[^}]*)\}")
LABEL_KEY = re.compile(r"'([A-Z ]+)'\s*:")
HARDCODED_AGGREGATES = (
    re.compile(
        r"\b(?:TOTAL_FEATURES|FEATURE_TOTAL|FEATURE_COUNT|COMPLETED_FEATURES|"
        r"COMPLETION_PERCENT|COMPLETION_PERCENTAGE)\b\s*[:=]\s*\d+",
        re.IGNORECASE,
    ),
    re.compile(r"data-(?:total-features|feature-count|completion-percent)\s*=\s*['\"]\d+", re.IGNORECASE),
)

STRICT_DASHBOARD_TOKENS = {
    "exact six-column parser guard": "if(c.length!==6||c[0]==='ID'",
    "exact feature-id parser guard": "/^[A-Z][A-Z0-9]*-\\d{3}$/.test(f.id)",
    "status parser guard": "STATUSES.includes(f.status)",
    "priority parser guard": "/^P[0-3]$/.test(f.priority)",
}


def _cells(line: str) -> tuple[str, ...]:
    if not line.startswith("|") or not line.endswith("|"):
        return ()
    return tuple(cell.replace("`", "").strip() for cell in line.split("|")[1:-1])


def dashboard_equivalent_identity(text: str) -> tuple[tuple[str, ...], tuple[tuple[str, str], ...]]:
    """Independently model the dashboard's strict Markdown identity parsing."""

    phases: list[str] = []
    features: list[tuple[str, str]] = []
    current_phase: str | None = None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        heading = PHASE_HEADING.match(line)
        if heading:
            current_phase = heading.group(1)
            phases.append(current_phase)
            continue

        if current_phase is None or not line.startswith("|"):
            continue

        cells = _cells(line)
        if not cells or cells == TABLE_HEADER:
            continue
        if all(re.fullmatch(r"[-:]+", cell or "-") for cell in cells):
            continue
        if len(cells) != 6:
            continue

        feature_id, _name, priority, status, _dependencies, _evidence = cells
        status = status.upper()
        if not FEATURE_ID.fullmatch(feature_id):
            continue
        if priority not in ALLOWED_PRIORITIES or status not in ALLOWED_STATUSES:
            continue
        features.append((current_phase, feature_id))

    return tuple(phases), tuple(features)


def validate_dependency_graph(model: CatalogModel) -> None:
    graph: dict[str, tuple[str, ...]] = {}
    for feature in model.features:
        graph[feature.feature_id] = tuple(DEPENDENCY_ID.findall(feature.dependencies))

    visiting: list[str] = []
    visited: set[str] = set()

    def visit(node: str) -> None:
        if node in visited:
            return
        if node in visiting:
            start = visiting.index(node)
            cycle = visiting[start:] + [node]
            raise ContractError("Dependency cycle detected: " + " -> ".join(cycle))
        visiting.append(node)
        for dependency in graph[node]:
            if dependency == node:
                raise ContractError(f"Feature {node} depends on itself")
            if dependency in graph:
                visit(dependency)
        visiting.pop()
        visited.add(node)

    for feature_id in graph:
        visit(feature_id)


def dashboard_status_vocabulary(text: str) -> set[str]:
    match = LABEL_OBJECT.search(text)
    if not match:
        raise ContractError("Dashboard LABELS status vocabulary was not found")
    statuses = set(LABEL_KEY.findall(match.group("body")))
    if statuses != ALLOWED_STATUSES:
        missing = sorted(ALLOWED_STATUSES - statuses)
        extra = sorted(statuses - ALLOWED_STATUSES)
        details = []
        if missing:
            details.append("missing=" + ",".join(missing))
        if extra:
            details.append("extra=" + ",".join(extra))
        raise ContractError("Dashboard status vocabulary drift: " + "; ".join(details))
    return statuses


def validate_dashboard_source(text: str) -> None:
    validate_dashboard_html(text)
    issues = [
        f"Dashboard lost TEST-010 {label}"
        for label, token in STRICT_DASHBOARD_TOKENS.items()
        if token not in text
    ]
    for pattern in HARDCODED_AGGREGATES:
        match = pattern.search(text)
        if match:
            issues.append(
                "Dashboard contains a hard-coded aggregate instead of deriving it from the catalog: "
                + match.group(0)
            )
    if issues:
        raise ContractError("\n".join(issues))
    dashboard_status_vocabulary(text)


def validate_contract(catalog_text: str, dashboard_text: str) -> CatalogModel:
    model = parse_catalog(catalog_text)
    validate_dependency_graph(model)
    validate_dashboard_source(dashboard_text)

    dashboard_phases, dashboard_features = dashboard_equivalent_identity(catalog_text)
    authoritative_features = tuple((feature.phase, feature.feature_id) for feature in model.features)
    if dashboard_phases != model.phases:
        raise ContractError(
            "Dashboard-equivalent phase parsing drifted from authoritative catalog parsing: "
            f"dashboard={dashboard_phases}, authoritative={model.phases}"
        )
    if dashboard_features != authoritative_features:
        raise ContractError(
            "Dashboard-equivalent feature identity drifted from authoritative catalog parsing"
        )
    if dashboard_phases != REQUIRED_PHASES:
        raise ContractError("Dashboard-equivalent parser must resolve exactly phases A-S")
    return model


def main() -> int:
    try:
        model = validate_contract(
            CATALOG.read_text(encoding="utf-8"),
            DASHBOARD.read_text(encoding="utf-8"),
        )
    except (ContractError, OSError) as error:
        print("TEST-010 dashboard/catalog parity FAILED", file=sys.stderr)
        print(error, file=sys.stderr)
        return 1

    print(
        "TEST-010 dashboard/catalog parity PASSED: "
        f"{len(model.phases)} phases, {len(model.features)} features, "
        f"{len(ALLOWED_STATUSES)} statuses, acyclic dependency graph."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
