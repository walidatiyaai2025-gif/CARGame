#!/usr/bin/env python3
"""Verify CARGame dashboard/catalog and protected CI workflow contracts."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "FEATURE_CATALOG.md"
DASHBOARD = ROOT / "docs" / "dashboard" / "index.html"
FLUTTER_CI = ROOT / ".github" / "workflows" / "flutter_ci.yml"
RELEASE_SMOKE = ROOT / ".github" / "workflows" / "release_smoke.yml"

REQUIRED_PHASES = tuple("ABCDEFGHIJKLMNOPQRS")
ALLOWED_STATUSES = {
    "VERIFIED",
    "IMPLEMENTED",
    "IN PROGRESS",
    "BLOCKED",
    "READY",
    "PLANNED",
    "DEFERRED",
}
ALLOWED_PRIORITIES = {"P0", "P1", "P2", "P3"}
FEATURE_ID = re.compile(r"^[A-Z][A-Z0-9]*-\d{3}$")
DEPENDENCY_ID = re.compile(r"[A-Z][A-Z0-9]*-\d{3}")
PHASE_HEADING = re.compile(r"^#\s+([A-Z])\.\s+(.+?)\s*$")
TABLE_HEADER = (
    "ID",
    "Function",
    "Priority",
    "Status",
    "Dependencies",
    "Acceptance / evidence",
)


class ContractError(RuntimeError):
    pass


@dataclass(frozen=True)
class Feature:
    phase: str
    feature_id: str
    name: str
    priority: str
    status: str
    dependencies: str
    evidence: str


@dataclass(frozen=True)
class CatalogModel:
    phases: tuple[str, ...]
    features: tuple[Feature, ...]


def _cells(line: str) -> tuple[str, ...]:
    if not line.startswith("|") or not line.endswith("|"):
        return ()
    return tuple(cell.replace("`", "").strip() for cell in line.split("|")[1:-1])


def _fail(messages: Iterable[str]) -> None:
    issues = tuple(messages)
    if issues:
        raise ContractError("\n".join(f"- {issue}" for issue in issues))


def parse_catalog(text: str) -> CatalogModel:
    phases: list[str] = []
    features: list[Feature] = []
    current_phase: str | None = None
    current_has_header = False
    current_feature_count = 0
    errors: list[str] = []

    def finish_phase() -> None:
        nonlocal current_feature_count, current_has_header
        if current_phase is None:
            return
        if not current_has_header:
            errors.append(f"Phase {current_phase} is missing the feature table header")
        if current_feature_count == 0:
            errors.append(f"Phase {current_phase} has no feature rows")
        current_has_header = False
        current_feature_count = 0

    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.rstrip()
        heading = PHASE_HEADING.match(line)
        if heading:
            finish_phase()
            code = heading.group(1)
            if code in phases:
                errors.append(f"Duplicate phase heading {code} at line {line_number}")
            phases.append(code)
            current_phase = code
            continue

        if current_phase is None or not line.startswith("|"):
            continue

        cells = _cells(line)
        if not cells:
            errors.append(f"Malformed Markdown table row at line {line_number}")
            continue
        if cells == TABLE_HEADER:
            current_has_header = True
            continue
        if all(re.fullmatch(r"[-:]+", cell or "-") for cell in cells):
            continue

        if len(cells) != 6:
            errors.append(
                f"Phase {current_phase} row at line {line_number} must have exactly 6 cells; found {len(cells)}"
            )
            continue

        feature_id, name, priority, status, dependencies, evidence = cells
        status = status.upper()
        if not FEATURE_ID.fullmatch(feature_id):
            errors.append(f"Invalid feature ID {feature_id!r} at line {line_number}")
            continue
        if not name:
            errors.append(f"Feature {feature_id} has an empty function name")
        if priority not in ALLOWED_PRIORITIES:
            errors.append(f"Feature {feature_id} has invalid priority {priority!r}")
        if status not in ALLOWED_STATUSES:
            errors.append(f"Feature {feature_id} has invalid status {status!r}")
        if not dependencies:
            errors.append(f"Feature {feature_id} has an empty dependency field")
        if not evidence:
            errors.append(f"Feature {feature_id} has empty acceptance/evidence")

        features.append(
            Feature(
                phase=current_phase,
                feature_id=feature_id,
                name=name,
                priority=priority,
                status=status,
                dependencies=dependencies,
                evidence=evidence,
            )
        )
        current_feature_count += 1

    finish_phase()

    if tuple(phases) != REQUIRED_PHASES:
        errors.append(
            "Catalog phases must be exactly A-S in order; "
            f"found {''.join(phases) or '<none>'}"
        )

    ids = [feature.feature_id for feature in features]
    duplicates = sorted({feature_id for feature_id in ids if ids.count(feature_id) > 1})
    if duplicates:
        errors.append(f"Duplicate feature IDs: {', '.join(duplicates)}")

    known = set(ids)
    for feature in features:
        for dependency in DEPENDENCY_ID.findall(feature.dependencies):
            if dependency == feature.feature_id:
                errors.append(f"Feature {feature.feature_id} depends on itself")
            elif dependency not in known:
                errors.append(
                    f"Feature {feature.feature_id} references missing dependency {dependency}"
                )

    active = [feature.feature_id for feature in features if feature.status == "IN PROGRESS"]
    if len(active) > 1:
        errors.append(
            "Only one primary feature may be IN PROGRESS; found " + ", ".join(active)
        )

    _fail(errors)
    return CatalogModel(phases=tuple(phases), features=tuple(features))


def validate_dashboard_html(text: str) -> None:
    required_tokens = {
        "catalog source label": "Source of truth: docs/FEATURE_CATALOG.md",
        "status vocabulary": "const LABELS={'VERIFIED'",
        "required phase vocabulary": "REQ='ABCDEFGHIJKLMNOPQRS'.split('')",
        "runtime Markdown parser": "function parse(md)",
        "phase heading parser": "l.match(/^#\\s+([A-Z])\\.\\s+(.+)$/)",
        "six-column parser guard": "if(c.length!==6||c[0]==='ID'",
        "dependency audit": "missingDeps=model.features.flatMap",
        "single active feature audit": "active=count('IN PROGRESS')",
        "catalog runtime fetch": "fetch('../FEATURE_CATALOG.md?ts='",
        "runtime audit render": "renderAudit()",
    }
    errors = [
        f"Dashboard lost {label} contract"
        for label, token in required_tokens.items()
        if token not in text
    ]
    _fail(errors)


def validate_release_workflow(text: str) -> None:
    required_tokens = {
        "read-only permissions": "contents: read",
        "release preflight regression": "Test release input preflight contract",
        "release preflight executable": "./tool/test_release_input_preflight.ps1",
        "ephemeral signing": "Prepare ephemeral release signing",
        "ephemeral key generation": "keytool -genkeypair",
        "synthetic AdMob application ID": "ca-app-pub-0000000000000000~0000000000",
        "release input verification": "Verify release smoke inputs",
        "release APK build": "flutter build apk --release --no-pub",
        "release AAB build": "flutter build appbundle --release --no-pub",
        "output verification": "Verify release outputs",
        "non-distributable marker": "NON-DISTRIBUTABLE RELEASE PACKAGING SMOKE",
        "checksum evidence": "sha256sum",
        "artifact upload": "actions/upload-artifact@v4",
        "evidence artifact name": "cargame-release-smoke-evidence",
        "enforced release lockfile": "--enforce-lockfile",
        "dependency advisory security": "Verify dependency security advisories",
        "release artifact security": "Verify release artifact security",
        "release artifact scanner": "tool/verify_build_artifact_security.py",
    }
    errors = [
        f"Release smoke lost {label} contract"
        for label, token in required_tokens.items()
        if token not in text
    ]
    if text.count("--dart-define=ENABLE_ADS=false") < 2:
        errors.append("Release APK and AAB smoke builds must both disable runtime ads")
    if "${{ secrets." in text:
        errors.append("Release packaging smoke must not depend on production repository secrets")
    _fail(errors)


def validate_flutter_ci(text: str) -> None:
    required_steps = (
        "Verify dynamic Android targets",
        "Verify secret hygiene",
        "Verify privacy data inventory",
        "Verify security baseline",
        "Verify TEST-010 dashboard catalog parity",
        "Test TEST-010 dashboard catalog validator",
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
    errors: list[str] = []
    positions: list[int] = []
    for step in required_steps:
        token = f"- name: {step}"
        position = text.find(token)
        if position < 0:
            errors.append(f"Flutter CI is missing required step {step!r}")
        positions.append(position)
    valid_positions = [position for position in positions if position >= 0]
    if valid_positions and valid_positions != sorted(valid_positions):
        errors.append("Flutter CI required verification steps are out of contract order")
    _fail(errors)


def verify_repository(root: Path = ROOT) -> CatalogModel:
    model = parse_catalog((root / "docs" / "FEATURE_CATALOG.md").read_text(encoding="utf-8"))
    validate_dashboard_html(
        (root / "docs" / "dashboard" / "index.html").read_text(encoding="utf-8")
    )
    validate_release_workflow(
        (root / ".github" / "workflows" / "release_smoke.yml").read_text(
            encoding="utf-8"
        )
    )
    validate_flutter_ci(
        (root / ".github" / "workflows" / "flutter_ci.yml").read_text(
            encoding="utf-8"
        )
    )
    return model


def main() -> int:
    try:
        model = verify_repository()
    except (ContractError, OSError) as error:
        print("CI integrity verification FAILED", file=sys.stderr)
        print(error, file=sys.stderr)
        return 1

    statuses: dict[str, int] = {}
    for feature in model.features:
        statuses[feature.status] = statuses.get(feature.status, 0) + 1
    summary = ", ".join(f"{status}={count}" for status, count in sorted(statuses.items()))
    print(
        "CI integrity verification passed: "
        f"{len(model.phases)} phases, {len(model.features)} features; {summary}."
    )
    print("Dashboard runtime parser contract: PASSED")
    print("Protected release workflow contract: PASSED")
    print("Flutter CI gate-order contract: PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
