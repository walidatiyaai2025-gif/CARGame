#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

import verify_ast_007_batch_01 as verifier

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    verifier.BATCH_PATH,
    verifier.MANIFEST_PATH,
    verifier.PROVENANCE_PATH,
]


def fixture() -> Path:
    root = Path(tempfile.mkdtemp(prefix='ast007-batch01-'))
    for relative in REQUIRED_FILES:
        source = ROOT / relative
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return root


def read_spec(root: Path) -> dict:
    return json.loads((root / verifier.BATCH_PATH).read_text(encoding='utf-8'))


def write_spec(root: Path, spec: dict) -> None:
    (root / verifier.BATCH_PATH).write_text(
        json.dumps(spec, indent=2) + '\n',
        encoding='utf-8',
    )


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
        spec = read_spec(root)
        spec['assets'][0]['assetId'] = 'cargo.premium_parcel'
        write_spec(root, spec)
        expect_failure(root, 'deterministic first 12')
    finally:
        shutil.rmtree(root)


def test_rejects_manifest_path_drift() -> None:
    root = fixture()
    try:
        spec = read_spec(root)
        spec['assets'][0]['runtimePath'] = 'assets/3d/runtime/cargo/special/wrong.webp'
        write_spec(root, spec)
        expect_failure(root, 'runtimePath must exactly match manifest')
    finally:
        shutil.rmtree(root)


def test_rejects_pcargo_budget_drift() -> None:
    root = fixture()
    try:
        spec = read_spec(root)
        spec['globalContract']['maxEncodedBytes'] = 200000
        write_spec(root, spec)
        expect_failure(root, 'maxEncodedBytes drifted')
    finally:
        shutil.rmtree(root)


def test_rejects_fake_binary_ready_claim() -> None:
    root = fixture()
    try:
        spec = read_spec(root)
        spec['assets'][0]['runtimeBinaryStatus'] = 'READY'
        write_spec(root, spec)
        expect_failure(root, 'claims READY but runtime WebP is missing')
    finally:
        shutil.rmtree(root)


def test_rejects_fake_provenance_ready_claim() -> None:
    root = fixture()
    try:
        spec = read_spec(root)
        spec['assets'][0]['provenanceStatus'] = 'READY'
        write_spec(root, spec)
        expect_failure(root, 'claims provenance READY but record is missing')
    finally:
        shutil.rmtree(root)


def test_rejects_existing_binary_with_not_created_claim() -> None:
    root = fixture()
    try:
        spec = read_spec(root)
        path = root / spec['assets'][0]['runtimePath']
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'not-a-real-webp')
        expect_failure(root, 'claims NOT_CREATED but runtime WebP exists')
    finally:
        shutil.rmtree(root)


def main() -> None:
    tests = [
        test_valid,
        test_rejects_wrong_batch_set,
        test_rejects_manifest_path_drift,
        test_rejects_pcargo_budget_drift,
        test_rejects_fake_binary_ready_claim,
        test_rejects_fake_provenance_ready_claim,
        test_rejects_existing_binary_with_not_created_claim,
    ]
    for test in tests:
        test()
        print(f'PASS: {test.__name__}')
    print(f'AST-007 batch 01 validator regressions: {len(tests)}/{len(tests)} PASS')


if __name__ == '__main__':
    main()
