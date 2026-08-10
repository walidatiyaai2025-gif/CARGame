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
    source_files: int

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


def validate_policy(
    policy: dict,
    *,
    today: date | None = None,
    repo_root: Path | None = None,
) -> list[str]:
    today = today or date.today()
    if policy.get('schema_version') != 1:
        raise PolicyError('schema_version must be 1')

    coverage = policy.get('coverage')
    if not isinstance(coverage, dict):
        raise PolicyError('coverage must be an object')
    floor = coverage.get('minimum_line_percent')
    target = coverage.get('target_line_percent')
    if not isinstance(floor, (int, float)) or isinstance(floor, bool) or not 0 < float(floor) <= 100:
        raise PolicyError('coverage.minimum_line_percent must be in (0, 100]')
    if (
        not isinstance(target, (int, float))
        or isinstance(target, bool)
        or not float(floor) <= float(target) <= 100
    ):
        raise PolicyError('coverage.target_line_percent must be >= minimum and <= 100')

    includes = coverage.get('include_path_prefixes', ['lib/'])
    excludes = coverage.get('exclude_path_prefixes', [])
    for key, values in (
        ('coverage.include_path_prefixes', includes),
        ('coverage.exclude_path_prefixes', excludes),
    ):
        if not isinstance(values, list) or not values or any(not isinstance(v, str) or not v for v in values):
            raise PolicyError(f'{key} must be a non-empty string list')

    flaky = policy.get('flaky_tests')
    if not isinstance(flaky, dict):
        raise PolicyError('flaky_tests must be an object')
    if flaky.get('default_retry_count') != 0:
        raise PolicyError('blanket/default retries are forbidden; default_retry_count must be 0')
    max_retry = flaky.get('max_quarantine_retry_count')
    max_days = flaky.get('max_quarantine_days')
    if not isinstance(max_retry, int) or isinstance(max_retry, bool) or not 0 <= max_retry <= 1:
        raise PolicyError('max_quarantine_retry_count must be 0 or 1')
    if not isinstance(max_days, int) or isinstance(max_days, bool) or not 1 <= max_days <= 30:
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
        unknown = sorted(set(item) - required)
        if unknown:
            raise PolicyError(f'quarantine[{idx}] has unknown fields: {", ".join(unknown)}')

        test_name = item['test']
        if (
            not isinstance(test_name, str)
            or not re.fullmatch(r'test/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+_test\.dart', test_name)
        ):
            raise PolicyError(f'quarantine[{idx}].test must be an exact repository test/*_test.dart path')
        if test_name in seen:
            raise PolicyError(f'duplicate quarantine test: {test_name}')
        seen.add(test_name)
        if repo_root is not None and not (repo_root / test_name).is_file():
            raise PolicyError(f'orphan quarantine test path: {test_name}')

        owner = item['owner']
        if not isinstance(owner, str) or not re.fullmatch(r'@[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})', owner):
            raise PolicyError(f'quarantine[{idx}].owner must be a GitHub @handle')
        issue = item['issue']
        if not isinstance(issue, str) or not re.fullmatch(r'#\d+', issue):
            raise PolicyError(f'quarantine[{idx}].issue must be a local issue reference like #190')
        if not isinstance(item['reason'], str) or len(item['reason'].strip()) < 12:
            raise PolicyError(f'quarantine[{idx}].reason must be specific')

        retry = item['retry_count']
        if not isinstance(retry, int) or isinstance(retry, bool) or retry < 0 or retry > max_retry:
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


def _canonical_source_path(path: str) -> str:
    normalized = path.strip().replace('\\', '/')
    if normalized.startswith('file://'):
        normalized = normalized[7:]
    normalized = re.sub(r'/+', '/', normalized)
    if normalized.startswith('lib/'):
        return normalized
    marker = '/lib/'
    index = normalized.rfind(marker)
    if index >= 0:
        return normalized[index + 1 :]
    return normalized.lstrip('/')


def _matches_prefix(path: str, prefixes: Iterable[str]) -> bool:
    canonical = _canonical_source_path(path)
    return any(canonical.startswith(_canonical_source_path(prefix)) for prefix in prefixes)


def parse_lcov(
    text: str,
    *,
    include_prefixes: Iterable[str] = ('lib/',),
    exclude_prefixes: Iterable[str] = (),
) -> CoverageResult:
    if not text.strip():
        raise PolicyError('coverage file is empty')

    hit = 0
    found = 0
    source_files = 0
    current_file: str | None = None
    record_lf: int | None = None
    record_lh: int | None = None
    line_hits: dict[int, int] = {}
    saw_record = False
    seen_files: set[str] = set()

    include_prefixes = tuple(include_prefixes)
    exclude_prefixes = tuple(exclude_prefixes)
    if not include_prefixes:
        raise PolicyError('coverage include prefixes cannot be empty')

    def flush() -> None:
        nonlocal hit, found, source_files, current_file, record_lf, record_lh, line_hits, saw_record
        if current_file is None:
            raise PolicyError('LCOV end_of_record without SF')
        canonical = _canonical_source_path(current_file)
        if canonical in seen_files:
            raise PolicyError(f'duplicate LCOV source record: {canonical}')
        seen_files.add(canonical)
        if record_lf is None or record_lh is None:
            raise PolicyError(f'LCOV record missing LF/LH for {current_file}')
        if not line_hits:
            raise PolicyError(f'LCOV record has no DA lines for {current_file}')
        calculated_found = len(line_hits)
        calculated_hit = sum(1 for count in line_hits.values() if count > 0)
        if record_lf != calculated_found or record_lh != calculated_hit:
            raise PolicyError(
                f'LCOV LF/LH mismatch for {current_file}: '
                f'LF={record_lf} LH={record_lh} DA={calculated_found}/{calculated_hit}'
            )
        saw_record = True
        included = _matches_prefix(canonical, include_prefixes)
        excluded = _matches_prefix(canonical, exclude_prefixes) if exclude_prefixes else False
        if included and not excluded:
            found += calculated_found
            hit += calculated_hit
            source_files += 1
        current_file = None
        record_lf = None
        record_lh = None
        line_hits = {}

    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith('SF:'):
            if current_file is not None:
                raise PolicyError(f'LCOV record for {current_file} is missing end_of_record')
            current_file = line[3:]
            if not current_file:
                raise PolicyError('LCOV SF path is empty')
        elif line.startswith('DA:'):
            if current_file is None:
                raise PolicyError('LCOV DA appears outside an SF record')
            parts = line[3:].split(',')
            if len(parts) < 2:
                raise PolicyError(f'malformed LCOV DA entry: {line}')
            try:
                line_number = int(parts[0])
                count = int(parts[1])
            except ValueError as exc:
                raise PolicyError(f'malformed LCOV DA entry: {line}') from exc
            if line_number <= 0 or count < 0:
                raise PolicyError(f'invalid LCOV DA values: {line}')
            if line_number in line_hits:
                raise PolicyError(f'duplicate LCOV DA line {line_number} for {current_file}')
            line_hits[line_number] = count
        elif line.startswith('LF:'):
            if current_file is None:
                raise PolicyError('LCOV LF appears outside an SF record')
            try:
                record_lf = int(line[3:])
            except ValueError as exc:
                raise PolicyError('LCOV LF must be an integer') from exc
        elif line.startswith('LH:'):
            if current_file is None:
                raise PolicyError('LCOV LH appears outside an SF record')
            try:
                record_lh = int(line[3:])
            except ValueError as exc:
                raise PolicyError('LCOV LH must be an integer') from exc
        elif line == 'end_of_record':
            flush()
        elif line.startswith(('TN:', 'FN:', 'FNDA:', 'FNF:', 'FNH:', 'BRDA:', 'BRF:', 'BRH:')):
            continue
        else:
            raise PolicyError(f'unrecognized LCOV line: {line}')

    if current_file is not None:
        raise PolicyError(f'LCOV record for {current_file} is missing end_of_record')
    if not saw_record:
        raise PolicyError('coverage file contains no LCOV records')
    if found <= 0 or source_files <= 0:
        raise PolicyError('coverage has zero measurable authored lib lines after exclusions')
    return CoverageResult(hit_lines=hit, found_lines=found, source_files=source_files)


def validate_workflow(workflow_text: str) -> None:
    required = [
        'Verify TEST-008 quality policy',
        'python3 tool/verify_test_quality.py',
        'Test TEST-008 quality validator',
        'python3 tool/test_test_quality.py',
        'flutter test --coverage',
        'Verify TEST-008 coverage threshold',
        'python3 tool/verify_test_quality.py --coverage coverage/lcov.info',
        'Verify TEST-007 critical-path contract',
        'Verify TEST-010 dashboard catalog parity',
        'Build debug APK',
        'Verify debug APK artifact security',
    ]
    missing = [item for item in required if item not in workflow_text]
    if missing:
        raise PolicyError('workflow missing TEST-008/preserved gates: ' + ', '.join(missing))
    if '--retry' in workflow_text:
        raise PolicyError('blanket test retries are forbidden in normal Flutter CI')

    policy_index = workflow_text.index('Verify TEST-008 quality policy')
    restore_index = workflow_text.index('Restore packages')
    full_test_index = workflow_text.index('Run full test suite')
    threshold_index = workflow_text.index('Verify TEST-008 coverage threshold')
    apk_index = workflow_text.index('Build debug APK')
    if policy_index > restore_index:
        raise PolicyError('TEST-008 policy validation must run before package restore')
    if not full_test_index < threshold_index < apk_index:
        raise PolicyError('TEST-008 coverage gate must run after the full suite and before APK packaging')


def run(policy_path: Path, coverage_path: Path | None, workflow_path: Path = WORKFLOW) -> CoverageResult | None:
    policy = _load_json(policy_path)
    notices = validate_policy(policy, repo_root=ROOT)
    try:
        workflow = workflow_path.read_text(encoding='utf-8')
    except FileNotFoundError as exc:
        raise PolicyError(f'missing workflow file: {workflow_path}') from exc
    validate_workflow(workflow)
    for notice in notices:
        print(notice)
    if coverage_path is None:
        print('TEST-008 POLICY VALIDATION PASSED')
        return None
    if not coverage_path.is_file():
        raise PolicyError(f'missing coverage file: {coverage_path}')
    coverage = policy['coverage']
    result = parse_lcov(
        coverage_path.read_text(encoding='utf-8'),
        include_prefixes=coverage.get('include_path_prefixes', ['lib/']),
        exclude_prefixes=coverage.get('exclude_path_prefixes', []),
    )
    floor = float(coverage['minimum_line_percent'])
    target = float(coverage['target_line_percent'])
    print(
        f'coverage: {result.hit_lines}/{result.found_lines} = {result.percent:.2f}% '
        f'across {result.source_files} authored source file(s)'
    )
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
