#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

import verify_ast_007_cargo_visuals as verifier

ROOT = Path(__file__).resolve().parents[1]


def fixture() -> Path:
    root = Path(tempfile.mkdtemp(prefix='ast007-validator-'))
    for relative in verifier.REQUIRED_FILES:
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


def replace(root: Path, relative: str, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text(encoding='utf-8')
    assert old in text, (relative, old)
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


def test_valid() -> None:
    root = fixture()
    try:
        verifier.validate(root)
    finally:
        shutil.rmtree(root)


def test_rejects_missing_descriptor() -> None:
    root = fixture()
    try:
        path = root / 'assets/3d/manifest.json'
        data = json.loads(path.read_text(encoding='utf-8'))
        data['assets'] = [
            item
            for item in data['assets']
            if item.get('id') != 'cargo.premium_parcel'
        ]
        path.write_text(json.dumps(data), encoding='utf-8')
        expect_failure(root, 'expected 124 cargo descriptors')
    finally:
        shutil.rmtree(root)


def test_rejects_wrong_profile() -> None:
    root = fixture()
    try:
        replace(
            root,
            'assets/3d/manifest.json',
            '"profile": "pcargo"',
            '"profile": "pui"',
        )
        expect_failure(root, 'must use pcargo')
    finally:
        shutil.rmtree(root)


def test_rejects_catalog_manifest_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'lib/features/game/cargo_visual_catalog.dart',
            "'premium_parcel'",
            "'premium_parcel_changed'",
        )
        expect_failure(root, 'typed catalog and manifest cargo IDs')
    finally:
        shutil.rmtree(root)


def test_rejects_gameplay_id_drift() -> None:
    root = fixture()
    try:
        replace(root, 'lib/features/game/level_data.dart', 'id: 18,', 'id: 118,')
        expect_failure(root, 'CargoItem IDs must remain exactly 1..18')
    finally:
        shutil.rmtree(root)


def test_rejects_missing_ui_bridge() -> None:
    root = fixture()
    try:
        replace(
            root,
            'lib/features/game/gameplay_operations_deck.dart',
            'CargoVisualAsset(',
            'SizedBox(',
        )
        replace(
            root,
            'lib/features/game/gameplay_operations_deck.dart',
            'CargoVisualAsset(',
            'SizedBox(',
        )
        replace(
            root,
            'lib/features/game/gameplay_operations_deck.dart',
            'CargoVisualAsset(',
            'SizedBox(',
        )
        expect_failure(root, 'cargo bay, warehouse and flight')
    finally:
        shutil.rmtree(root)


def test_rejects_intake_provenance_validation_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'lib/core/assets/game_asset_intake_plan.dart',
            'provenanceRecord?.validateAgainst(descriptor);',
            '// provenance validation removed',
        )
        expect_failure(root, 'AST-007 intake planner missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_intake_summary_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'lib/core/assets/game_asset_intake_plan.dart',
            'final class GameAssetIntakeSummary',
            'final class RemovedIntakeSummary',
        )
        expect_failure(root, 'AST-007 intake planner missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_orphan_runtime_contract_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'lib/core/assets/game_asset_intake_plan.dart',
            'path.startsWith(runtimePrefix)',
            "path.startsWith('ignored/runtime/')",
        )
        expect_failure(root, 'AST-007 intake planner missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_offset_filter_contract_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'lib/core/assets/game_asset_intake_plan.dart',
            'int offset = 0',
            'int page = 0',
        )
        expect_failure(root, 'AST-007 intake planner missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_cli_format_contract_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'tool/plan_ast_007_asset_intake.dart',
            '_OutputFormat { human, json, csv }',
            '_OutputFormat { human, json }',
        )
        expect_failure(root, 'AST-007 intake CLI missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_cli_strict_contract_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'tool/plan_ast_007_asset_intake.dart',
            'options.strict && !plan.isComplete',
            'false',
        )
        expect_failure(root, 'AST-007 intake CLI missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_unknown_option_guard_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'tool/plan_ast_007_asset_intake.dart',
            "throw FormatException('Unknown option: $argument')",
            'continue',
        )
        expect_failure(root, 'AST-007 intake CLI missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_production_truth_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'docs/work/AST-007.md',
            'Approved provenance records: 0.',
            'Approved provenance records: 124.',
        )
        expect_failure(root, 'AST-007 work note missing production truth')
    finally:
        shutil.rmtree(root)


def test_rejects_hardening_tracking_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'docs/work/AST-007-INTAKE-HARDENING-100.md',
            'H100',
            'H099-END',
        )
        expect_failure(root, 'AST-007 hardening note missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_runbook_safety_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            'docs/ASSET_INTAKE_RUNBOOK.md',
            'Never synthesize',
            'Automatically synthesize',
        )
        expect_failure(root, 'AST-007 intake runbook missing contract')
    finally:
        shutil.rmtree(root)


def test_rejects_ci_smoke_drift() -> None:
    root = fixture()
    try:
        replace(
            root,
            '.github/workflows/flutter_ci.yml',
            'Smoke AST-007 intake handoff',
            'Removed AST-007 intake smoke',
        )
        expect_failure(root, 'normal Flutter CI missing AST-007 gate')
    finally:
        shutil.rmtree(root)


def main() -> None:
    tests = [
        test_valid,
        test_rejects_missing_descriptor,
        test_rejects_wrong_profile,
        test_rejects_catalog_manifest_drift,
        test_rejects_gameplay_id_drift,
        test_rejects_missing_ui_bridge,
        test_rejects_intake_provenance_validation_drift,
        test_rejects_intake_summary_drift,
        test_rejects_orphan_runtime_contract_drift,
        test_rejects_offset_filter_contract_drift,
        test_rejects_cli_format_contract_drift,
        test_rejects_cli_strict_contract_drift,
        test_rejects_unknown_option_guard_drift,
        test_rejects_production_truth_drift,
        test_rejects_hardening_tracking_drift,
        test_rejects_runbook_safety_drift,
        test_rejects_ci_smoke_drift,
    ]
    for test in tests:
        test()
        print(f'PASS: {test.__name__}')
    print(f'AST-007 validator regressions: {len(tests)}/{len(tests)} PASS')


if __name__ == '__main__':
    main()
