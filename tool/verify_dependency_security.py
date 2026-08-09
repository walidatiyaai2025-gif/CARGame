#!/usr/bin/env python3
"""Fail closed when the locked Dart/Flutter dependency graph has active advisories."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_POLICY = ROOT / "tool" / "security_advisory_exceptions.json"
PUBSPEC = ROOT / "pubspec.yaml"

_ADVISORY_URL_RE = re.compile(
    r"\[(?P<ref>\^?\d+)\]:\s*https://github\.com/advisories/(?P<id>GHSA-[0-9A-Za-z-]+)",
    re.IGNORECASE,
)
_AFFECTED_PACKAGE_RE = re.compile(
    r"^\s*(?P<package>[A-Za-z0-9_]+)\s+\S+\s+\(affected by advisory:\s*(?P<refs>[^)]+)\)",
    re.IGNORECASE,
)
_REF_RE = re.compile(r"\[(\^?\d+)\]")
_GHSA_RE = re.compile(r"\bGHSA-[0-9A-Za-z-]+\b", re.IGNORECASE)


@dataclass(frozen=True)
class Advisory:
    advisory_id: str
    package: str | None = None


@dataclass(frozen=True)
class ExceptionEntry:
    advisory_id: str
    package: str
    reason: str
    owner: str
    expires_at: dt.date


def _today() -> dt.date:
    return dt.datetime.now(dt.timezone.utc).date()


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def pubspec_has_ignored_advisories(text: str) -> bool:
    """Reject pubspec-level suppression so every exception remains independently audited."""
    return re.search(r"(?m)^\s*ignored_advisories\s*:", text) is not None


def parse_advisories(output: str) -> list[Advisory]:
    ref_to_id: dict[str, str] = {}
    for match in _ADVISORY_URL_RE.finditer(output):
        ref_to_id[match.group("ref").lstrip("^")] = match.group("id").upper()

    package_by_ref: dict[str, str] = {}
    for line in output.splitlines():
        match = _AFFECTED_PACKAGE_RE.search(line)
        if match is None:
            continue
        package = match.group("package")
        for ref in _REF_RE.findall(match.group("refs")):
            package_by_ref[ref.lstrip("^")] = package

    advisories: dict[str, Advisory] = {}
    for ref, advisory_id in ref_to_id.items():
        advisories[advisory_id] = Advisory(advisory_id, package_by_ref.get(ref))

    # Future pub output might expose GHSA IDs without reference footnotes. Fail closed
    # on those as well, preserving package=None when the package cannot be inferred.
    for advisory_id in _GHSA_RE.findall(output):
        normalized = advisory_id.upper()
        advisories.setdefault(normalized, Advisory(normalized, None))

    return sorted(advisories.values(), key=lambda item: item.advisory_id)


def load_exceptions(path: Path, *, today: dt.date | None = None) -> list[ExceptionEntry]:
    today = today or _today()
    try:
        raw = json.loads(_read_text(path))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"Unable to load advisory exception policy: {exc}") from exc

    if raw.get("schemaVersion") != 1:
        raise ValueError("security_advisory_exceptions.json schemaVersion must be 1")
    entries = raw.get("exceptions")
    if not isinstance(entries, list):
        raise ValueError("security advisory exceptions must be a list")

    seen: set[str] = set()
    parsed: list[ExceptionEntry] = []
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise ValueError(f"exception #{index + 1} must be an object")
        advisory_id = str(entry.get("id", "")).upper().strip()
        package = str(entry.get("package", "")).strip()
        reason = str(entry.get("reason", "")).strip()
        owner = str(entry.get("owner", "")).strip()
        expires_raw = str(entry.get("expiresAt", "")).strip()

        if not _GHSA_RE.fullmatch(advisory_id):
            raise ValueError(f"exception #{index + 1} has invalid GHSA id")
        if advisory_id in seen:
            raise ValueError(f"duplicate advisory exception: {advisory_id}")
        if not package or not re.fullmatch(r"[A-Za-z0-9_]+", package):
            raise ValueError(f"{advisory_id} must name one Dart package")
        if len(reason) < 12:
            raise ValueError(f"{advisory_id} requires a concrete review reason")
        if not owner:
            raise ValueError(f"{advisory_id} requires an accountable owner")
        try:
            expires_at = dt.date.fromisoformat(expires_raw)
        except ValueError as exc:
            raise ValueError(f"{advisory_id} expiresAt must be YYYY-MM-DD") from exc
        if expires_at < today:
            raise ValueError(f"{advisory_id} exception expired on {expires_at.isoformat()}")

        seen.add(advisory_id)
        parsed.append(ExceptionEntry(advisory_id, package, reason, owner, expires_at))

    return parsed


def evaluate_advisories(
    advisories: Iterable[Advisory],
    exceptions: Iterable[ExceptionEntry],
) -> tuple[list[str], list[str]]:
    active = {item.advisory_id: item for item in advisories}
    approved = {item.advisory_id: item for item in exceptions}
    violations: list[str] = []

    for advisory_id, advisory in active.items():
        exception = approved.get(advisory_id)
        if exception is None:
            package = advisory.package or "unknown package"
            violations.append(f"{advisory_id} affects {package} and has no reviewed exception")
            continue
        if advisory.package is not None and advisory.package != exception.package:
            violations.append(
                f"{advisory_id} affects {advisory.package}, but exception is scoped to {exception.package}"
            )

    stale = sorted(set(approved) - set(active))
    return violations, stale


def run_locked_pub_get(flutter: str) -> tuple[int, str]:
    process = subprocess.run(
        [flutter, "pub", "get", "--enforce-lockfile"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return process.returncode, process.stdout


def verify(output: str, policy_path: Path = DEFAULT_POLICY) -> list[str]:
    violations: list[str] = []
    if pubspec_has_ignored_advisories(_read_text(PUBSPEC)):
        violations.append(
            "pubspec.yaml must not use ignored_advisories; use the reviewed security exception policy"
        )

    try:
        exceptions = load_exceptions(policy_path)
    except ValueError as exc:
        return [str(exc)] + violations

    advisories = parse_advisories(output)
    advisory_violations, stale = evaluate_advisories(advisories, exceptions)
    violations.extend(advisory_violations)
    if stale:
        violations.append(
            "stale advisory exceptions must be removed after they stop appearing: " + ", ".join(stale)
        )
    return violations


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--input-log", type=Path)
    parser.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    args = parser.parse_args(argv)

    if args.input_log is not None:
        try:
            output = _read_text(args.input_log)
        except OSError as exc:
            print(f"Dependency security verification failed: {exc}", file=sys.stderr)
            return 2
        exit_code = 0
    else:
        exit_code, output = run_locked_pub_get(args.flutter)
        print(output, end="" if output.endswith("\n") else "\n")

    if exit_code != 0:
        print("Dependency security verification failed: enforced lockfile restore failed.", file=sys.stderr)
        return exit_code

    violations = verify(output, args.policy)
    if violations:
        print("Dependency security verification failed:", file=sys.stderr)
        for violation in violations:
            print(f" - {violation}", file=sys.stderr)
        return 1

    advisories = parse_advisories(output)
    print(
        f"Dependency security verification passed: enforced lockfile; {len(advisories)} active advisories; 0 stale exceptions."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
