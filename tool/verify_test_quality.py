#!/usr/bin/env python3
"""Validate CARGame's TEST-008 coverage and flaky-test policy."""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1] if Path(__file__).parent.name == 'tool' else Path.cwd()
DEFAULT_POLICY = ROOT / 'tool' / 'test_quality_policy.json'
WORKFLOW = ROOT / '.github' / 'workflows' / 'flutter_ci.yml'


class PolicyError(ValueError):
    pass


@dataclass(frozen=True)
class CoverageResult:
    hit_lines: int
    found_lines: int

    @property
    def percent(self) -> float:
        if self.found_lines <= 0:
            return 0.0
        return self.hit_lines * 100.0 / self.found_lines


def _load_json(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding='utf-8'))
    except FileNotFoundError as exc:
        raise PolicyError(f'missing policy file: {path}') from exc
    except json.JSONDecodeError as exc:
        raise PolicyError(f'invalid JSON in {path}: {exc}') from exc
    if not isinstance(data, dict):
        raise PolicyError('policy root must be an object')
    return data


def validate_policy(policy: dict, *, today: date | None = None) -> list[str]:
    today = today or date.today()
    if policy.get('schema_version') != 1:
        raise PolicyError('schema_version must be 1')

    coverage = policy.get('coverage')
    if not isinstance(coverage, dict):
        raise PolicyError('coverage must be an object')
    floor = coverage.get('minimum_line_percent')
    target = coverage.get('target_line_percent')
    if not isinstance(floor, (int, float)) or not 0 < float(floor) <= 100:
        raise PolicyError('coverage.minimum_line_percent must be in (0, 100]')
    if not isinstance(target, (int, float)) or not float(floor) <= float(target) <= 100:
        raise PolicyError('coverage.target_line_percent must be >= minimum and <= 100')
    excludes = coverage.get('exclude_path_prefixes', [])
    if not isinstance(excludes, list) or any(not isinstance(v, str) or not v for v in excludes):
        raise PolicyError('coverage.exclude_path_prefixes must be a string list')

    flaky = policy.get('flaky_tests')
    if not isinstance(flaky, dict):
        raise PolicyError('flaky_tests must be an object')
    if flaky.get('default_retry_count') != 0:
        raise PolicyError('blanket/default retries are forbidden; default_retry_count must be 0')
    max_retry = flaky.get('max_quarantine_retry_count')
    max_days = flaky.get('max_quarantine_days')
    if not isinstance(max_retry, int) or not 0 <= max_retry <= 1:
        raise PolicyError('max_quarantine_retry_count must be 0 or 1')
    if not isinstance(max_days, int) or not 1 <= max_days <= 30:
        raise PolicyError('max_quarantine_days must be between 1 and 30')
    quarantines = flaky.get('quarantines')
    if not isinstance(quarantines, list):
        raise PolicyError('flaky_tests.quarantines must be a list')

    seen: set[str] = set()
    notices: list[str] = []
    for idx, item in enumerate(quarantines):
        if not isinstance(item, dict):
            raise PolicyError(f'quarantine[{idx}] must be an object')
        required = {'test', 'owner', 'issue', 'reason', 'expires_on', 'retry_count'}
        missing = sorted(required - set(item))
        if missing:
            raise PolicyError(f'quarantine[{idx}] missing fields: {", ".join(missing)}')
        test_name = item['test']
        if not isinstance(test_name, str) or not test_name.strip():
            raise PolicyError(f'quarantine[{idx}].test must be non-empty')
        if test_name in seen:
            raise PolicyError(f'duplicate quarantine test: {test_name}')
        seen.add(test_name)
        owner = item['owner']
        if not isinstance(owner, str) or not re.fullmatch(r'@[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})', owner):
            raise PolicyError(f'quarantine[{idx}].owner must be a GitHub @handle')
        issue = item['issue']
        if not isinstance(issue, str) or not re.fullmatch(r'#\d+', issue):
            raise PolicyError(f'quarantine[{idx}].issue must be a local issue reference like #190')
        if not isinstance(item['reason'], str) or len(item['reason'].strip()) < 12:
            raise PolicyError(f'quarantine[{idx}].reason must be specific')
        retry = item['retry_count']
        if not isinstance(retry, int) or retry < 0 or retry > max_retry:
            raise PolicyError(f'quarantine[{idx}].retry_count exceeds policy maximum')
        try:
            expiry = datetime.strptime(item['expires_on'], '%Y-%m-%d').date()
        except (TypeError, ValueError) as exc:
            raise PolicyError(f'quarantine[{idx}].expires_on must be YYYY-MM-DD') from exc
        if expiry < today:
            raise PolicyError(f'quarantine expired: {test_name} on {expiry.isoformat()}')
        if (expiry - today).days > max_days:
            raise PolicyError(f'quarantine[{idx}] exceeds max_quarantine_days')
        notices.append(f'quarantine active: {test_name} owner={owner} issue={issue} until={expiry}')
    return notices


def _is_excluded(path: str, prefixes: Iterable[str]) -> bool:
    normalized = path.replace('\\', '/').lstrip('./')
    return any(normalized.startswith(prefix.replace('\\', '/').lstrip('./')) for prefix in prefixes)


def parse_lcov(text: str, *, exclude_prefixes: Iterable[str] = ()) -> CoverageResult:
    if not text.strip():
        raise PolicyError('coverage file is empty')
    hit = found = 0
    current_file: str | None = None
    record_lf: int | None = None
    record_lh: int | None = None
    saw_record = False

    def flush() -> None:
        nonlocal hit, found, record_lf, record_lh, saw_record
        if current_file is None:
            record_lf = record_lh = None
            return
        if record_lf is None or record_lh is None:
            raise PolicyError(f'LCOV record missing LF/LH for {current_file}')
        if record_lf < 0 or record_lh < 0 or record_lh > record_lf:
            raise PolicyError(f'invalid LF/LH values for {current_file}')
        saw_record = True
        if not _is_excluded(current_file, exclude_prefixes):
            found += record_lf
            hit += record_lh
        record_lf = record_lh = None

    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith('SF:'):
            if current_file is not None:
                flush()
            current_file = line[3:]
            if not current_file:
                raise PolicyError('LCOV SF path is empty')
        elif line.startswith('LF:'):
            try:
                record_lf = int(line[3:])
            except ValueError as exc:
                raise PolicyError('LCOV LF must be an integer') from exc
        elif line.startswith('LH:'):
            try:
                record_lh = int(line[3:])
            except ValueError as exc:
                raise PolicyError('LCOV LH must be an integer') from exc
        elif line == 'end_of_record':
            flush()
            current_file = None
    if current_file is not None:
        flush()
    if not saw_record:
        raise PolicyError('coverage file contains no LCOV records')
    if found <= 0:
        raise PolicyError('coverage has zero measurable lines after exclusions')
    return CoverageResult(hit_lines=hit, found_lines=found)


def validate_workflow(workflow_text: str) -> None:
    required = [
        'Verify TEST-008 quality policy',
        'Test TEST-008 quality validator',
        'flutter test --coverage',
        'Verify TEST-008 coverage threshold',
        'Verify TEST-007 critical-path contract',
        'Verify TEST-010 dashboard catalog parity',
    ]
    missing = [item for item in required if item not in workflow_text]
    if missing:
        raise PolicyError('workflow missing TEST-008/preserved gates: ' + ', '.join(missing))
    if re.search(r'flutter\s+test[^\n]*--retry\b', workflow_text):
        raise PolicyError('blanket flutter test retries are forbidden')


def run(policy_path: Path, coverage_path: Path | None, workflow_path: Path = WORKFLOW) -> CoverageResult | None:
    policy = _load_json(policy_path)
    notices = validate_policy(policy)
    workflow = workflow_path.read_text(encoding='utf-8')
    validate_workflow(workflow)
    for notice in notices:
        print(notice)
    if coverage_path is None:
        print('TEST-008 POLICY VALIDATION PASSED')
        return None
    if not coverage_path.is_file():
        raise PolicyError(f'missing coverage file: {coverage_path}')
    result = parse_lcov(
        coverage_path.read_text(encoding='utf-8'),
        exclude_prefixes=policy['coverage'].get('exclude_path_prefixes', []),
    )
    floor = float(policy['coverage']['minimum_line_percent'])
    target = float(policy['coverage']['target_line_percent'])
    print(f'coverage: {result.hit_lines}/{result.found_lines} = {result.percent:.2f}%')
    print(f'enforced floor: {floor:.2f}% | target: {target:.2f}%')
    if result.percent + 1e-9 < floor:
        raise PolicyError(f'line coverage {result.percent:.2f}% is below enforced floor {floor:.2f}%')
    print('TEST-008 COVERAGE VALIDATION PASSED')
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--policy', type=Path, default=DEFAULT_POLICY)
    parser.add_argument('--coverage', type=Path)
    parser.add_argument('--workflow', type=Path, default=WORKFLOW)
    args = parser.parse_args(argv)
    try:
        run(args.policy, args.coverage, args.workflow)
    except (PolicyError, OSError) as exc:
        print(f'TEST-008 VALIDATION FAILED: {exc}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
