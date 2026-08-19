#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

import verify_ast_007_batch_01 as verifier

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_JSON = [
    verifier.BATCH_PATH,
    verifier.MANIFEST_PATH,
    verifier.PROVENANCE_PATH,
]


def read_json(root: Path, relative: str) -> dict:
    return json.loads((root / relative).read_text(encoding='utf-8'))


def write_json(root: Path, relative: str, value: dict) -> None:
    (root / relative).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def fixture() -> Path:
    root = Path(tempfile.mkdtemp(prefix='ast007-batch01-'))
    for relative in REQUIRED_JSON:
        source = ROOT / relative
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    spec = read_json(root, verifier.BATCH_PATH)
    for item in spec['assets']:
        relative = item['runtimePath']
        source = ROOT / relative
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return root


def expect_failure(root: Path, expected: str) -> None:
    try:
        verifier.validate(root)
    except verifier.ValidationError as error:
        assert expected in str(error), (expected, str(error))
    else:
        raise AssertionError(f'expected failure containing {expected!r}')


def test_valid() -> None:
    root = fixture()
    try:
        verifier.validate(root)
    finally:
        shutil.rmtree(root)


def test_rejects_wrong_batch_set() -> None:
    root = fixture()
    try:
        spec = read_json(root, verifier.BATCH_PATH)
        spec['assets'][0]['assetId'] = 'cargo.premium_parcel'
        write_json(root, verifier.BATCH_PATH, spec)
        expect_failure(root, 'deterministic first 12')
    finally:
        shutil.rmtree(root)


def test_rejects_manifest_path_drift() -> None:
    root = fixture()
    try:
        spec = read_json(root, verifier.BATCH_PATH)
        spec['assets'][0]['runtimePath'] = 'assets/3d/runtime/cargo/special/wrong.webp'
        write_json(root, verifier.BATCH_PATH, spec)
        expect_failure(root, 'runtimePath must exactly match manifest')
    finally:
        shutil.rmtree(root)


def test_rejects_pcargo_budget_drift() -> None:
    root = fixture()
    try:
        spec = read_json(root, verifier.BATCH_PATH)
        spec['globalContract']['maxEncodedBytes'] = 200000
        write_json(root, verifier.BATCH_PATH, spec)
        expect_failure(root, 'maxEncodedBytes drifted')
    finally:
        shutil.rmtree(root)


def test_rejects_missing_binary() -> None:
    root = fixture()
    try:
        spec = read_json(root, verifier.BATCH_PATH)
        (root / spec['assets'][0]['runtimePath']).unlink()
        expect_failure(root, 'claims READY but runtime WebP is missing')
    finally:
        shutil.rmtree(root)


def test_rejects_missing_provenance() -> None:
    root = fixture()
    try:
        catalog = read_json(root, verifier.PROVENANCE_PATH)
        catalog['records'] = catalog['records'][1:]
        write_json(root, verifier.PROVENANCE_PATH, catalog)
        expect_failure(root, 'claims provenance READY but record is missing')
    finally:
        shutil.rmtree(root)


def test_rejects_stale_not_created_claim() -> None:
    root = fixture()
    try:
        spec = read_json(root, verifier.BATCH_PATH)
        spec['assets'][0]['runtimeBinaryStatus'] = 'NOT_CREATED'
        write_json(root, verifier.BATCH_PATH, spec)
        expect_failure(root, 'must truthfully claim runtime READY')
    finally:
        shutil.rmtree(root)


def test_rejects_binary_checksum_drift() -> None:
    root = fixture()
    try:
        spec = read_json(root, verifier.BATCH_PATH)
        path = root / spec['assets'][0]['runtimePath']
        data = bytearray(path.read_bytes())
        data[-1] ^= 1
        path.write_bytes(data)
        expect_failure(root, 'SHA-256 does not match provenance')
    finally:
        shutil.rmtree(root)


def test_rejects_fake_export_sha() -> None:
    root = fixture()
    try:
        catalog = read_json(root, verifier.PROVENANCE_PATH)
        catalog['records'][0]['exportSha256'] = '0' * 64
        write_json(root, verifier.PROVENANCE_PATH, catalog)
        expect_failure(root, 'SHA-256 does not match provenance')
    finally:
        shutil.rmtree(root)


def main() -> None:
    tests = [
        test_valid,
        test_rejects_wrong_batch_set,
        test_rejects_manifest_path_drift,
        test_rejects_pcargo_budget_drift,
        test_rejects_missing_binary,
        test_rejects_missing_provenance,
        test_rejects_stale_not_created_claim,
        test_rejects_binary_checksum_drift,
        test_rejects_fake_export_sha,
    ]
    for test in tests:
        test()
        print(f'PASS: {test.__name__}')
    print(f'AST-007 batch 01 validator regressions: {len(tests)}/{len(tests)} PASS')


if __name__ == '__main__':
    main()
