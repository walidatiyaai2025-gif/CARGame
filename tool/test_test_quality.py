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
        'include_path_prefixes': ['lib/'],
        'exclude_path_prefixes': ['lib/l10n/'],
    },
    'flaky_tests': {
        'default_retry_count': 0,
        'max_quarantine_retry_count': 1,
        'max_quarantine_days': 14,
        'quarantines': [],
    },
}

VALID_WORKFLOW = '\n'.join([
    'Verify TEST-007 critical-path contract',
    'Verify TEST-010 dashboard catalog parity',
    'Verify TEST-008 quality policy',
    'run: python3 tool/verify_test_quality.py',
    'Test TEST-008 quality validator',
    'run: python3 tool/test_test_quality.py',
    'Restore packages',
    'Run full test suite',
    'run: flutter test --coverage',
    'Verify TEST-008 coverage threshold',
    'run: python3 tool/verify_test_quality.py --coverage coverage/lcov.info',
    'Build debug APK',
    'Verify debug APK artifact security',
])


def quarantine(**overrides):
    item = {
        'test': 'test/foo_test.dart',
        'owner': '@owner',
        'issue': '#190',
        'reason': 'Hosted runner timing race under investigation.',
        'expires_on': '2026-08-20',
        'retry_count': 1,
    }
    item.update(overrides)
    return item


def lcov(path='lib/a.dart', hits=(1, 0, 2)):
    das = ''.join(f'DA:{i + 1},{count}\n' for i, count in enumerate(hits))
    lf = len(hits)
    lh = sum(1 for count in hits if count > 0)
    return f'SF:{path}\n{das}LF:{lf}\nLH:{lh}\nend_of_record\n'


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

    def test_rejects_target_below_floor(self):
        policy = copy.deepcopy(BASE)
        policy['coverage']['target_line_percent'] = 30
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_requires_nonempty_include_prefixes(self):
        policy = copy.deepcopy(BASE)
        policy['coverage']['include_path_prefixes'] = []
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_quarantine_requires_fields(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [{'test': 'test/foo_test.dart'}]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_quarantine_rejects_unknown_fields(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(extra='x')]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_quarantine_requires_exact_test_path(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(test='foo')]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_orphan_quarantine_test_path(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine()]
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaises(mod.PolicyError):
                mod.validate_policy(policy, today=date(2026, 8, 10), repo_root=Path(td))

    def test_accepts_existing_quarantine_test_path(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine()]
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / 'test').mkdir()
            (root / 'test/foo_test.dart').write_text('// test', encoding='utf-8')
            notices = mod.validate_policy(policy, today=date(2026, 8, 10), repo_root=root)
            self.assertEqual(len(notices), 1)

    def test_rejects_invalid_owner(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(owner='owner')]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_invalid_issue(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(issue='190')]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_expired_quarantine(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(expires_on='2026-08-09')]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_long_quarantine(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(expires_on='2026-09-30')]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_retry_over_maximum(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(retry_count=2)]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_rejects_duplicate_quarantine(self):
        policy = copy.deepcopy(BASE)
        policy['flaky_tests']['quarantines'] = [quarantine(), quarantine()]
        with self.assertRaises(mod.PolicyError):
            mod.validate_policy(policy, today=date(2026, 8, 10))

    def test_parses_lcov(self):
        result = mod.parse_lcov(lcov())
        self.assertEqual((result.hit_lines, result.found_lines, result.source_files), (2, 3, 1))
        self.assertAlmostEqual(result.percent, 66.6666666667)

    def test_absolute_lcov_path_excludes_generated_localization(self):
        text = (
            lcov('/home/runner/work/CARGame/CARGame/lib/a.dart', (1, 1))
            + lcov('/home/runner/work/CARGame/CARGame/lib/l10n/app_localizations.dart', (0, 0, 0))
        )
        result = mod.parse_lcov(text, exclude_prefixes=['lib/l10n/'])
        self.assertEqual((result.hit_lines, result.found_lines, result.source_files), (2, 2, 1))

    def test_ignores_non_lib_records(self):
        text = lcov('packages/third_party.dart', (0, 0)) + lcov('lib/a.dart', (1, 0))
        result = mod.parse_lcov(text, include_prefixes=['lib/'])
        self.assertEqual((result.hit_lines, result.found_lines, result.source_files), (1, 2, 1))

    def test_rejects_empty_lcov(self):
        with self.assertRaises(mod.PolicyError):
            mod.parse_lcov('')

    def test_rejects_malformed_da(self):
        with self.assertRaises(mod.PolicyError):
            mod.parse_lcov('SF:lib/a.dart\nDA:x,1\nLF:1\nLH:1\nend_of_record\n')

    def test_rejects_da_outside_record(self):
        with self.assertRaises(mod.PolicyError):
            mod.parse_lcov('DA:1,1\n')

    def test_rejects_lf_lh_mismatch(self):
        with self.assertRaises(mod.PolicyError):
            mod.parse_lcov('SF:lib/a.dart\nDA:1,1\nLF:2\nLH:1\nend_of_record\n')

    def test_rejects_missing_end_record(self):
        with self.assertRaises(mod.PolicyError):
            mod.parse_lcov('SF:lib/a.dart\nDA:1,1\nLF:1\nLH:1\n')

    def test_rejects_duplicate_source_record(self):
        with self.assertRaises(mod.PolicyError):
            mod.parse_lcov(lcov('lib/a.dart') + lcov('/tmp/project/lib/a.dart'))

    def test_workflow_requires_preserved_gates(self):
        mod.validate_workflow(VALID_WORKFLOW)
        with self.assertRaises(mod.PolicyError):
            mod.validate_workflow(VALID_WORKFLOW.replace('Verify TEST-010 dashboard catalog parity', 'removed'))

    def test_workflow_rejects_blanket_retry_flag(self):
        with self.assertRaises(mod.PolicyError):
            mod.validate_workflow(VALID_WORKFLOW + '\nrun: flutter test --retry 2\n')

    def test_workflow_requires_policy_before_restore(self):
        bad = VALID_WORKFLOW.replace('Verify TEST-008 quality policy', 'TEMP', 1)
        bad = bad.replace('Restore packages', 'Restore packages\nVerify TEST-008 quality policy', 1)
        with self.assertRaises(mod.PolicyError):
            mod.validate_workflow(bad)

    def test_workflow_requires_threshold_before_apk(self):
        bad = VALID_WORKFLOW.replace('Verify TEST-008 coverage threshold', 'TEMP', 1)
        bad += '\nVerify TEST-008 coverage threshold\n'
        with self.assertRaises(mod.PolicyError):
            mod.validate_workflow(bad)

    def test_end_to_end_threshold_failure(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            policy = root / 'policy.json'
            workflow = root / 'ci.yml'
            coverage = root / 'lcov.info'
            policy.write_text(json.dumps(BASE), encoding='utf-8')
            workflow.write_text(VALID_WORKFLOW, encoding='utf-8')
            coverage.write_text(lcov('lib/a.dart', tuple([1] * 34 + [0] * 66)), encoding='utf-8')
            original_root = mod.ROOT
            try:
                mod.ROOT = root
                with self.assertRaises(mod.PolicyError):
                    mod.run(policy, coverage, workflow)
            finally:
                mod.ROOT = original_root


if __name__ == '__main__':
    unittest.main(verbosity=2)
