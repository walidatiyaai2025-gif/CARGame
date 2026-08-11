#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

import verify_ast_007_batch_01 as batch_01_verifier

EXPECTED_CARGO_COUNT = 124
REQUIRED_FILES = [
    'assets/3d/manifest.json',
    'assets/3d/provenance/catalog.json',
    'assets/3d/source/cargo/batch_01/spec.json',
    'lib/core/assets/game_asset_intake_plan.dart',
    'lib/features/game/cargo_visual_catalog.dart',
    'lib/features/game/cargo_visual_asset.dart',
    'lib/features/game/gameplay_operations_deck.dart',
    'lib/features/game/game_screen.dart',
    'lib/features/game/level_data.dart',
    'test/core/assets/game_asset_intake_plan_test.dart',
    'test/features/game/cargo_visual_catalog_test.dart',
    'test/features/game/cargo_visual_asset_test.dart',
    'tool/plan_ast_007_asset_intake.dart',
    'tool/verify_ast_007_batch_01.py',
    'tool/test_ast_007_batch_01.py',
    'docs/ASSET_INTAKE_RUNBOOK.md',
    'docs/FEATURE_CATALOG.md',
    'docs/work/AST-007.md',
    'docs/work/AST-007-BATCH-01.md',
    'docs/work/AST-007-INTAKE-HARDENING-100.md',
    '.github/workflows/flutter_ci.yml',
]


class ValidationError(RuntimeError):
    pass


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise ValidationError(f'missing AST-007 file: {relative}')
    return path.read_text(encoding='utf-8')


def validate(root: Path = Path('.')) -> None:
    for relative in REQUIRED_FILES:
        if not (root / relative).is_file():
            raise ValidationError(f'missing AST-007 file: {relative}')

    manifest = json.loads(_read(root, 'assets/3d/manifest.json'))
    assets = manifest.get('assets')
    if not isinstance(assets, list):
        raise ValidationError('manifest assets must be a list')
    cargo = [item for item in assets if item.get('category') == 'cargo']
    if len(cargo) != EXPECTED_CARGO_COUNT:
        raise ValidationError(
            f'expected {EXPECTED_CARGO_COUNT} cargo descriptors, found {len(cargo)}'
        )
    cargo_ids = [item.get('id') for item in cargo]
    if len(set(cargo_ids)) != EXPECTED_CARGO_COUNT:
        raise ValidationError('cargo descriptor IDs must be unique')

    path_pattern = re.compile(
        r'^assets/3d/runtime/cargo/[a-z0-9_]+/cg_cargo_[a-z0-9_]+_pcargo_v01\.webp$'
    )
    for item in cargo:
        if not isinstance(item.get('id'), str) or not item['id'].startswith('cargo.'):
            raise ValidationError('cargo descriptor ID must use cargo.* namespace')
        if item.get('profile') != 'pcargo':
            raise ValidationError(f"cargo descriptor {item.get('id')} must use pcargo")
        if item.get('dimensions') != {'width': 384, 'height': 384}:
            raise ValidationError(f"cargo descriptor {item.get('id')} must be 384x384")
        if not isinstance(item.get('path'), str) or not path_pattern.match(item['path']):
            raise ValidationError(f"cargo descriptor {item.get('id')} has invalid runtime path")

    catalog = _read(root, 'lib/features/game/cargo_visual_catalog.dart')
    families = re.findall(r'_CargoVisualFamily\(\s*archetypeId:\s*(\d+),', catalog)
    if sorted(map(int, families)) != list(range(1, 19)):
        raise ValidationError('typed catalog must define archetypes 1..18 exactly once')
    slugs = re.findall(r"^\s+'([a-z0-9_]+)',?$", catalog, flags=re.M)
    if len(slugs) != EXPECTED_CARGO_COUNT or len(set(slugs)) != EXPECTED_CARGO_COUNT:
        raise ValidationError('typed catalog must own 124 unique subject slugs')
    if {f'cargo.{slug}' for slug in slugs} != set(cargo_ids):
        raise ValidationError('typed catalog and manifest cargo IDs must match exactly')
    for token in [
        'expectedVariantCount = 124',
        'required int levelNumber',
        'required int archetypeId',
        "'assets/3d/runtime/cargo/",
        'GameAssetProfile.pcargo',
    ]:
        if token not in catalog:
            raise ValidationError(f'cargo visual catalog missing contract: {token}')

    level_data = _read(root, 'lib/features/game/level_data.dart')
    archetype_ids = [
        int(value)
        for value in re.findall(r'CargoItem\(\s*id:\s*(\d+),', level_data)
    ]
    if archetype_ids != list(range(1, 19)):
        raise ValidationError('gameplay CargoItem IDs must remain exactly 1..18')
    if 'Random(number * 7919 + 2026)' not in level_data:
        raise ValidationError('deterministic level generator seed changed')

    bridge = _read(root, 'lib/features/game/cargo_visual_asset.dart')
    for token in [
        'CargoVisualCatalog.resolve(',
        'GameManifestAssetView(',
        'errorFallback: fallback',
        "'cargo-visual-${visual.assetId}'",
    ]:
        if token not in bridge:
            raise ValidationError(f'cargo visual bridge missing contract: {token}')

    deck = _read(root, 'lib/features/game/gameplay_operations_deck.dart')
    if deck.count('CargoVisualAsset(') < 3:
        raise ValidationError('cargo bay, warehouse and flight must all use CargoVisualAsset')
    if "import 'cargo_visual_asset.dart';" not in deck:
        raise ValidationError('gameplay deck missing cargo visual bridge import')

    game = _read(root, 'lib/features/game/game_screen.dart')
    if game.count('levelNumber: widget.level.number') < 3:
        raise ValidationError('game screen must pass level identity to all cargo visual surfaces')

    intake = _read(root, 'lib/core/assets/game_asset_intake_plan.dart')
    for token in [
        'final class GameAssetIntakeSummary',
        'GameAssetIntakeState.missingBinaryAndProvenance',
        'provenanceRecord?.validateAgainst(descriptor)',
        'orphanRuntimeBinaryPaths',
        'orphanProvenanceAssetIds',
        'int offset = 0',
        'Set<GameAssetIntakeState>? states',
        '_normalizeRuntimePath',
        "path.startsWith(runtimePrefix)",
        "record.assetId.startsWith(assetIdPrefix)",
        "'completionPercent': completionPercent",
    ]:
        if token not in intake:
            raise ValidationError(f'AST-007 intake planner missing contract: {token}')

    intake_cli = _read(root, 'tool/plan_ast_007_asset_intake.dart')
    for token in [
        'GameAssetIntakePlan.build(',
        "argument == '--json'",
        "argument.startsWith('--limit=')",
        "argument.startsWith('--offset=')",
        "argument.startsWith('--state=')",
        "argument.startsWith('--format=')",
        "argument == '--summary-only'",
        "argument == '--strict'",
        '_OutputFormat { human, json, csv }',
        '_writeCsv(batch)',
        'options.strict && !plan.isComplete',
        "throw FormatException('Unknown option: $argument')",
    ]:
        if token not in intake_cli:
            raise ValidationError(f'AST-007 intake CLI missing contract: {token}')

    work_doc = _read(root, 'docs/work/AST-007.md')
    for token in [
        '133 descriptors: 9 non-cargo + 124 cargo',
        'Approved provenance records: 0.',
        'Runtime WebP binaries: 0.',
        'The planner does not invent or auto-approve provenance.',
    ]:
        if token not in work_doc:
            raise ValidationError(f'AST-007 work note missing production truth: {token}')

    batch_doc = _read(root, 'docs/work/AST-007-BATCH-01.md')
    for token in [
        'Runtime binary status: `NOT_CREATED`',
        'Provenance status: `NOT_CREATED`',
        '12 deterministic cargo assets',
    ]:
        if token not in batch_doc:
            raise ValidationError(f'AST-007 batch 01 work note missing truth boundary: {token}')

    hardening_doc = _read(root, 'docs/work/AST-007-INTAKE-HARDENING-100.md')
    for token in [
        'Production truth remains 124 cargo descriptors, 0 approved provenance records, and 0 runtime cargo WebP binaries.',
        'H001',
        'H100 Reconcile evidence while keeping AST-007 IN PROGRESS until real provenance-backed WebP admission occurs.',
        'does **not** complete the production art pack by itself',
    ]:
        if token not in hardening_doc:
            raise ValidationError(f'AST-007 hardening note missing contract: {token}')

    runbook = _read(root, 'docs/ASSET_INTAKE_RUNBOOK.md')
    for token in [
        'dart run tool/plan_ast_007_asset_intake.dart',
        '--strict',
        'commercial-use provenance',
        'Never synthesize',
        'orphan',
    ]:
        if token not in runbook:
            raise ValidationError(f'AST-007 intake runbook missing contract: {token}')

    catalog_doc = _read(root, 'docs/FEATURE_CATALOG.md')
    if '| AST-007 | 100+ 3D cargo product pack | P1 | IN PROGRESS |' not in catalog_doc and \
       '| AST-007 | 100+ 3D cargo product pack | P1 | IMPLEMENTED |' not in catalog_doc:
        raise ValidationError('AST-007 catalog tracking is not owned by this workstream')

    ci = _read(root, '.github/workflows/flutter_ci.yml')
    for token in [
        'Verify AST-007 cargo visual pack',
        'Test AST-007 cargo visual validator',
        'Smoke AST-007 intake handoff',
        'Test AST-007 cargo visual pack',
        'test/core/assets/game_asset_intake_plan_test.dart',
    ]:
        if token not in ci:
            raise ValidationError(f'normal Flutter CI missing AST-007 gate: {token}')

    try:
        batch_01_verifier.validate(root)
    except batch_01_verifier.ValidationError as error:
        raise ValidationError(f'AST-007 batch 01 contract failed: {error}') from error


if __name__ == '__main__':
    validate()
    print('AST-007 CARGO VISUAL CONTRACT PASSED (124 descriptors / batch 01 / hardened intake)')
