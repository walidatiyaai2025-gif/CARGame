#!/usr/bin/env python3
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_asset_cache_policy as mod  # noqa: E402


POLICY = '''
final class GameAssetCachePolicy {
  final LinkedHashMap<String, Future<bool>> _inFlight = LinkedHashMap<String, Future<bool>>();
  final Map<String, int> _assetGenerations = <String, int>{};
  int _generation = 0;
  int staleCompletionCount = 0;
  int evictionFailureCount = 0;
  Future<void> precacheNearFuture({bool retryFailed = false}) async {}
  void resetStatistics() {}
  Future<void> _evictSafely(dynamic provider) async {}
  Future<bool> join(Future<bool> joined) async { return joined; }
  void adapter() { precacheImage(null, null); }
}
'''

TESTS = '''
concurrent same-ID callers share one load result
clear during load prevents late cache resurrection
forget during load prevents late cache resurrection
retry starts safely after an invalidated operation settles
cache hits promote LRU order without reloading
automatic batches skip known failures unless retry is explicit
evictor failures never escape cache operations
statistics reset does not mutate cache state
snapshot collections are immutable
'''

WORKFLOW = '''
Verify TEST-007 critical-path contract
Verify TEST-010 dashboard catalog parity
Verify TEST-008 quality policy
Verify AST-004 asset cache policy
Test AST-004 cache policy validator
Restore packages
Analyze
Test AST-004 asset cache policy
Run full test suite
Verify TEST-008 coverage threshold
Build debug APK
'''


class AssetCachePolicyContractTests(unittest.TestCase):
    def _repo(
        self,
        root: Path,
        *,
        policy: str = POLICY,
        tests: str = TESTS,
        workflow: str = WORKFLOW,
        other_source: str = 'void main() {}',
    ) -> None:
        files = {
            mod.POLICY_PATH: policy,
            mod.TEST_PATH: tests,
            mod.WORKFLOW_PATH: workflow,
            Path('lib/features/example.dart'): other_source,
        }
        for rel, text in files.items():
            path = root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding='utf-8')

    def test_valid_repository_contract_passes(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self._repo(root)
            mod.validate_repository(root)

    def test_raw_precache_outside_policy_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self._repo(root, other_source='void x() { precacheImage(foo, bar); }')
            with self.assertRaises(mod.PolicyError):
                mod.validate_repository(root)

    def test_missing_ast004_ci_step_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self._repo(
                root,
                workflow=WORKFLOW.replace('Test AST-004 asset cache policy\n', ''),
            )
            with self.assertRaises(mod.PolicyError):
                mod.validate_repository(root)

    def test_machine_gate_after_restore_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            workflow = WORKFLOW.replace(
                'Verify AST-004 asset cache policy\nTest AST-004 cache policy validator\nRestore packages',
                'Restore packages\nVerify AST-004 asset cache policy\nTest AST-004 cache policy validator',
            )
            self._repo(root, workflow=workflow)
            with self.assertRaises(mod.PolicyError):
                mod.validate_repository(root)

    def test_missing_race_regression_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self._repo(
                root,
                tests=TESTS.replace(
                    'clear during load prevents late cache resurrection\n',
                    '',
                ),
            )
            with self.assertRaises(mod.PolicyError):
                mod.validate_repository(root)

    def test_missing_policy_source_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self._repo(root)
            (root / mod.POLICY_PATH).unlink()
            with self.assertRaises(mod.PolicyError):
                mod.validate_repository(root)


if __name__ == '__main__':
    unittest.main(verbosity=2)
