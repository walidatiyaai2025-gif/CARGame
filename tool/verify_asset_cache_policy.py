#!/usr/bin/env python3
"""Validate AST-004 bounded asset-cache ownership and CI contracts."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = Path('lib/core/assets/game_asset_cache_policy.dart')
TEST_PATH = Path('test/core/assets/game_asset_cache_policy_test.dart')
WORKFLOW_PATH = Path('.github/workflows/flutter_ci.yml')


class PolicyError(ValueError):
    pass


def _read(root: Path, path: Path) -> str:
    full = root / path
    if not full.is_file():
        raise PolicyError(f'missing required AST-004 file: {path.as_posix()}')
    return full.read_text(encoding='utf-8')


def validate_policy_source(text: str) -> None:
    required = [
        'LinkedHashMap<String, Future<bool>> _inFlight',
        'Map<String, int> _assetGenerations',
        'int _generation = 0',
        'bool retryFailed = false',
        'void resetStatistics()',
        'staleCompletionCount',
        'evictionFailureCount',
        'Future<void> _evictSafely',
        'return joined;',
    ]
    missing = [token for token in required if token not in text]
    if missing:
        raise PolicyError('cache policy missing required contracts: ' + ', '.join(missing))
    if text.count('precacheImage(') != 1:
        raise PolicyError('cache policy must own exactly one Flutter precacheImage adapter call')


def validate_test_contract(text: str) -> None:
    required = [
        'concurrent same-ID callers share one load result',
        'clear during load prevents late cache resurrection',
        'forget during load prevents late cache resurrection',
        'retry starts safely after an invalidated operation settles',
        'cache hits promote LRU order without reloading',
        'automatic batches skip known failures unless retry is explicit',
        'evictor failures never escape cache operations',
        'statistics reset does not mutate cache state',
        'snapshot collections are immutable',
    ]
    missing = [token for token in required if token not in text]
    if missing:
        raise PolicyError('AST-004 focused tests missing required regressions: ' + ', '.join(missing))


def validate_workflow(text: str) -> None:
    required = [
        'Verify AST-004 asset cache policy',
        'Test AST-004 cache policy validator',
        'Test AST-004 asset cache policy',
        'Verify TEST-007 critical-path contract',
        'Verify TEST-008 quality policy',
        'Verify TEST-008 coverage threshold',
        'Verify TEST-010 dashboard catalog parity',
        'Restore packages',
        'Analyze',
        'Run full test suite',
        'Build debug APK',
    ]
    missing = [token for token in required if token not in text]
    if missing:
        raise PolicyError('Flutter CI missing AST-004/preserved gates: ' + ', '.join(missing))

    def pos(token: str) -> int:
        return text.index(token)

    if not (
        pos('Verify AST-004 asset cache policy')
        < pos('Test AST-004 cache policy validator')
        < pos('Restore packages')
    ):
        raise PolicyError('AST-004 machine gates must run before package restore')
    if not (
        pos('Analyze')
        < pos('Test AST-004 asset cache policy')
        < pos('Run full test suite')
        < pos('Verify TEST-008 coverage threshold')
        < pos('Build debug APK')
    ):
        raise PolicyError('AST-004 focused test/full-suite/coverage/APK gate order drifted')


def validate_precache_ownership(root: Path) -> None:
    offenders: list[str] = []
    lib = root / 'lib'
    if not lib.is_dir():
        raise PolicyError('missing lib directory')
    for path in sorted(lib.rglob('*.dart')):
        rel = path.relative_to(root)
        if rel == POLICY_PATH:
            continue
        if 'precacheImage(' in path.read_text(encoding='utf-8'):
            offenders.append(rel.as_posix())
    if offenders:
        raise PolicyError(
            'raw precacheImage calls must route through GameAssetCachePolicy: '
            + ', '.join(offenders)
        )


def validate_repository(root: Path = ROOT) -> None:
    policy = _read(root, POLICY_PATH)
    tests = _read(root, TEST_PATH)
    workflow = _read(root, WORKFLOW_PATH)
    validate_policy_source(policy)
    validate_test_contract(tests)
    validate_workflow(workflow)
    validate_precache_ownership(root)


def main() -> int:
    try:
        validate_repository()
    except (PolicyError, OSError) as exc:
        print(f'AST-004 VALIDATION FAILED: {exc}', file=sys.stderr)
        return 1
    print('AST-004 asset cache policy validation PASSED')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
