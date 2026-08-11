#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

BATCH_PATH = 'assets/3d/source/cargo/batch_01/spec.json'
MANIFEST_PATH = 'assets/3d/manifest.json'
PROVENANCE_PATH = 'assets/3d/provenance/catalog.json'

EXPECTED_ASSET_IDS = {
    'cargo.accessory_box',
    'cargo.accessory_carton',
    'cargo.action_figure_box',
    'cargo.apparel_box',
    'cargo.apple_crate',
    'cargo.archive_box',
    'cargo.auto_part_crate',
    'cargo.bakery_box',
    'cargo.basketball_bag',
    'cargo.battery_pack',
    'cargo.board_game_box',
    'cargo.boot_carton',
}

ALLOWED_BINARY_STATES = {'NOT_CREATED', 'READY'}
ALLOWED_PROVENANCE_STATES = {'NOT_CREATED', 'READY'}


class ValidationError(RuntimeError):
    pass


def _load_json(root: Path, relative: str) -> dict:
    path = root / relative
    if not path.is_file():
        raise ValidationError(f'missing required file: {relative}')
    try:
        value = json.loads(path.read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError) as error:
        raise ValidationError(f'invalid JSON in {relative}: {error}') from error
    if not isinstance(value, dict):
        raise ValidationError(f'{relative} must contain a JSON object')
    return value


def _manifest_by_id(manifest: dict) -> dict[str, dict]:
    assets = manifest.get('assets')
    if not isinstance(assets, list):
        raise ValidationError('manifest assets must be a list')
    result: dict[str, dict] = {}
    for asset in assets:
        if not isinstance(asset, dict) or not isinstance(asset.get('id'), str):
            raise ValidationError('manifest contains an invalid asset descriptor')
        if asset['id'] in result:
            raise ValidationError(f"duplicate manifest asset ID: {asset['id']}")
        result[asset['id']] = asset
    return result


def _provenance_ids(catalog: dict) -> set[str]:
    records = catalog.get('records')
    if not isinstance(records, list):
        raise ValidationError('provenance records must be a list')
    result: set[str] = set()
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get('assetId'), str):
            raise ValidationError('provenance catalog contains an invalid record')
        result.add(record['assetId'])
    return result


def validate(root: Path = Path('.')) -> None:
    spec = _load_json(root, BATCH_PATH)
    manifest = _load_json(root, MANIFEST_PATH)
    provenance = _load_json(root, PROVENANCE_PATH)

    if spec.get('schemaVersion') != 1:
        raise ValidationError('batch schemaVersion must be 1')
    if spec.get('batchId') != 'AST-007-BATCH-01':
        raise ValidationError('batchId must be AST-007-BATCH-01')
    if spec.get('featureId') != 'AST-007' or spec.get('issue') != 210:
        raise ValidationError('batch must remain owned by AST-007 / issue #210')

    contract = spec.get('globalContract')
    if not isinstance(contract, dict):
        raise ValidationError('globalContract must be an object')
    expected_contract = {
        'profile': 'pcargo',
        'canvas': {'width': 384, 'height': 384},
        'maxEncodedBytes': 122880,
        'format': 'webp',
        'colorSpace': 'sRGB',
        'bitDepth': 8,
        'alphaRequired': True,
        'background': 'transparent',
        'runtimeBinaryStatus': 'NOT_CREATED',
        'provenanceStatus': 'NOT_CREATED',
    }
    for key, expected in expected_contract.items():
        if contract.get(key) != expected:
            raise ValidationError(f'globalContract {key} drifted from pcargo production contract')

    camera = contract.get('camera')
    if camera != {
        'projection': 'perspective',
        'focalLengthEquivalentMm': 50,
        'yawDegrees': -30,
        'elevationDegrees': 18,
        'rollDegrees': 0,
    }:
        raise ValidationError('pcargo camera contract drifted')

    composition = contract.get('composition')
    if composition != {
        'pivot': 'bottom-center',
        'subjectOccupancyPercentMin': 78,
        'subjectOccupancyPercentMax': 86,
        'transparentSafetyPaddingPercent': 7,
    }:
        raise ValidationError('pcargo composition contract drifted')

    prohibited = contract.get('prohibitedVisualContent')
    required_prohibitions = {
        'logos',
        'trademarks',
        'readable text',
        'numbers',
        'currency',
        'locale-specific marks',
        'team marks',
        'manufacturer branding',
        'baked UI panels',
        'baked screen blur',
    }
    if not isinstance(prohibited, list) or not required_prohibitions.issubset(set(prohibited)):
        raise ValidationError('batch must preserve no-brand/no-text visual restrictions')

    items = spec.get('assets')
    if not isinstance(items, list) or len(items) != 12:
        raise ValidationError('batch 01 must contain exactly 12 assets')
    ids = [item.get('assetId') for item in items if isinstance(item, dict)]
    if len(ids) != 12 or set(ids) != EXPECTED_ASSET_IDS:
        raise ValidationError('batch 01 asset IDs must match the deterministic first 12 exactly')
    if len(set(ids)) != len(ids):
        raise ValidationError('batch 01 asset IDs must be unique')

    descriptors = _manifest_by_id(manifest)
    provenance_ids = _provenance_ids(provenance)

    for item in items:
        if not isinstance(item, dict):
            raise ValidationError('batch asset entries must be objects')
        asset_id = item['assetId']
        descriptor = descriptors.get(asset_id)
        if descriptor is None:
            raise ValidationError(f'{asset_id} missing from manifest')
        if descriptor.get('category') != 'cargo':
            raise ValidationError(f'{asset_id} must remain a cargo descriptor')
        if descriptor.get('profile') != 'pcargo':
            raise ValidationError(f'{asset_id} must use pcargo')
        if descriptor.get('dimensions') != {'width': 384, 'height': 384}:
            raise ValidationError(f'{asset_id} must remain 384x384')
        if item.get('runtimePath') != descriptor.get('path'):
            raise ValidationError(f'{asset_id} runtimePath must exactly match manifest')
        concept = descriptor.get('semantics', {}).get('englishConcept')
        if item.get('concept') != concept:
            raise ValidationError(f'{asset_id} concept must exactly match manifest semantics')

        prompt = item.get('prompt')
        if not isinstance(prompt, str) or len(prompt.strip()) < 80:
            raise ValidationError(f'{asset_id} needs a concrete generation/render prompt')
        lower_prompt = prompt.lower()
        if 'no ' not in lower_prompt or 'text' not in lower_prompt:
            raise ValidationError(f'{asset_id} prompt must explicitly reject branded/readable copy')

        binary_state = item.get('runtimeBinaryStatus')
        provenance_state = item.get('provenanceStatus')
        if binary_state not in ALLOWED_BINARY_STATES:
            raise ValidationError(f'{asset_id} has invalid runtimeBinaryStatus')
        if provenance_state not in ALLOWED_PROVENANCE_STATES:
            raise ValidationError(f'{asset_id} has invalid provenanceStatus')

        runtime_exists = (root / descriptor['path']).is_file()
        provenance_exists = asset_id in provenance_ids
        if binary_state == 'NOT_CREATED' and runtime_exists:
            raise ValidationError(f'{asset_id} claims NOT_CREATED but runtime WebP exists')
        if binary_state == 'READY' and not runtime_exists:
            raise ValidationError(f'{asset_id} claims READY but runtime WebP is missing')
        if provenance_state == 'NOT_CREATED' and provenance_exists:
            raise ValidationError(f'{asset_id} claims no provenance but a record exists')
        if provenance_state == 'READY' and not provenance_exists:
            raise ValidationError(f'{asset_id} claims provenance READY but record is missing')


if __name__ == '__main__':
    validate()
    print('AST-007 BATCH 01 CONTRACT PASSED (12 deterministic cargo handoff assets)')
