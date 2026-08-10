#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_test_quality as mod  # noqa: E402


BASE = {
    'schema_version': 1,
    'coverage': {
        'minimum_line_percent': 35.0,
        'target_line_percent': 60.0,
        'exclude_path_prefixes': ['lib/l10n/'],
    },
    'flaky_tests': {
        'default_retry_count': 0,
        'max_quarantine_retry_count': 1,
        'max_quarantine_days': 14,
        'quarantines': [],
    },
}


class TestQualityPolicy(unittest.TestCase):
    def test_valid_policy(self):
        self.assertEqual(mod.validate_policy(copy.deepcopy(BASE), today=date(2026, 8, 10)), [])

    def test_rejects_blanket_retry(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['default_retry_count'] = 1
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_invalid_coverage_floor(self):
        policy = copy.deepcopy(BASE)
        policy['coverage']['minimum_line_percent'] = 0
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_quarantine_requires_fields(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [{'test': 'x'}]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_expired_quarantine(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [{
            'test': 'test/foo_test.dart',
            'owner': '@owner',
            'issue': '#190',
            'reason': 'Reproduces only on one hosted runner.',
            'expires_on': '2026-08-09',
            'retry_count': 1,
        }]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_long_quarantine(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [{
            'test': 'test/foo_test.dart',
            'owner': '@owner',
            'issue': '#190',
            'reason': 'Reproduces only on one hosted runner.',
            'expires_on': '2026-09-30',
            'retry_count': 1,
        }]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_parses_lcov_and_excludes_prefix(self):
        result = mod.parse_lcov(
            'SF:lib/a.dart\nLF:10\nLH:8\nend_of_record\n'
            'SF:lib/l10n/x.dart\nLF:10\nLH:0\nend_of_record\n',
            exclude_prefixes=['lib/l10n/'],
        )
        self.assertEqual((result.hit_lines, result.found_lines), (8, 10))
        self.assertAlmostEqual(result.percent, 80.0)

    def test_rejects_malformed_lcov(self):
        with self.assertRaises(mod.PolicyError):
            mod.parse_lcov('SF:lib/a.dart\nLH:8\nend_of_record\n')

    def test_workflow_requires_preserved_gates(self):
        valid = '\n'.join([
            'Verify TEST-008 quality policy',
            'Test TEST-008 quality validator',
            'flutter test --coverage',
            'Verify TEST-008 coverage threshold',
            'Verify TEST-007 critical-path contract',
            'Verify TEST-010 dashboard catalog parity',
        ])
        mod.validate_workflow(valid)
        with self.assertRaises(mod.PolicyError):
            mod.validate_workflow(valid.replace('Verify TEST-010 dashboard catalog parity', 'removed'))

    def test_end_to_end_threshold_failure(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            policy = root / 'policy.json'
            workflow = root / 'ci.yml'
            coverage = root / 'lcov.info'
            policy.write_text(json.dumps(BASE), encoding='utf-8')
            workflow.write_text(
                '\n'.join([
                    'Verify TEST-008 quality policy',
                    'Test TEST-008 quality validator',
                    'flutter test --coverage',
                    'Verify TEST-008 coverage threshold',
                    'Verify TEST-007 critical-path contract',
                    'Verify TEST-010 dashboard catalog parity',
                ]),
                encoding='utf-8',
            )
            coverage.write_text(
                'SF:lib/a.dart\nLF:100\nLH:34\nend_of_record\n',
                encoding='utf-8',
            )
            with self.assertRaises(mod.PolicyError):
                mod.run(policy, coverage, workflow)


if __name__ == '__main__':
    unittest.main(verbosity=2)
