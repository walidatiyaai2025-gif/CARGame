#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
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
SHA256_RE = re.compile(r'^[0-9a-f]{64}$')


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


def _provenance_by_id(catalog: dict) -> dict[str, dict]:
    records = catalog.get('records')
    if not isinstance(records, list):
        raise ValidationError('provenance records must be a list')
    result: dict[str, dict] = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get('assetId'), str):
            raise ValidationError('provenance catalog contains an invalid record')
        asset_id = record['assetId']
        if asset_id in result:
            raise ValidationError(f'duplicate provenance asset ID: {asset_id}')
        result[asset_id] = record
    return result


def _verify_webp(path: Path, max_bytes: int, asset_id: str) -> str:
    if not path.is_file():
        raise ValidationError(f'{asset_id} claims READY but runtime WebP is missing')
    data = path.read_bytes()
    if len(data) > max_bytes:
        raise ValidationError(f'{asset_id} exceeds pcargo encoded-byte budget')
    if len(data) < 12 or data[:4] != b'RIFF' or data[8:12] != b'WEBP':
        raise ValidationError(f'{asset_id} runtime binary is not a WebP container')
    return hashlib.sha256(data).hexdigest()


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
        'runtimeBinaryStatus': 'READY',
        'provenanceStatus': 'READY',
    }
    for key, expected in expected_contract.items():
        if contract.get(key) != expected:
            raise ValidationError(f'globalContract {key} drifted from admitted pcargo contract')

    if contract.get('camera') != {
        'projection': 'perspective',
        'focalLengthEquivalentMm': 50,
        'yawDegrees': -30,
        'elevationDegrees': 18,
        'rollDegrees': 0,
    }:
        raise ValidationError('pcargo camera contract drifted')
    if contract.get('composition') != {
        'pivot': 'bottom-center',
        'subjectOccupancyPercentMin': 78,
        'subjectOccupancyPercentMax': 86,
        'transparentSafetyPaddingPercent': 7,
    }:
        raise ValidationError('pcargo composition contract drifted')

    required_prohibitions = {
        'logos', 'trademarks', 'readable text', 'numbers', 'currency',
        'locale-specific marks', 'team marks', 'manufacturer branding',
        'baked UI panels', 'baked screen blur',
    }
    prohibited = contract.get('prohibitedVisualContent')
    if not isinstance(prohibited, list) or not required_prohibitions.issubset(set(prohibited)):
        raise ValidationError('batch must preserve no-brand/no-text visual restrictions')

    items = spec.get('assets')
    if not isinstance(items, list) or len(items) != 12:
        raise ValidationError('batch 01 must contain exactly 12 assets')
    ids = [item.get('assetId') for item in items if isinstance(item, dict)]
    if len(ids) != 12 or set(ids) != EXPECTED_ASSET_IDS or len(set(ids)) != len(ids):
        raise ValidationError('batch 01 asset IDs must match the deterministic first 12 exactly')

    descriptors = _manifest_by_id(manifest)
    provenance_by_id = _provenance_by_id(provenance)
    max_bytes = contract['maxEncodedBytes']

    for item in items:
        if not isinstance(item, dict):
            raise ValidationError('batch asset entries must be objects')
        asset_id = item['assetId']
        descriptor = descriptors.get(asset_id)
        if descriptor is None:
            raise ValidationError(f'{asset_id} missing from manifest')
        if descriptor.get('category') != 'cargo' or descriptor.get('profile') != 'pcargo':
            raise ValidationError(f'{asset_id} must remain a pcargo cargo descriptor')
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
        if item.get('runtimeBinaryStatus') != 'READY':
            raise ValidationError(f'{asset_id} must truthfully claim runtime READY')
        if item.get('provenanceStatus') != 'READY':
            raise ValidationError(f'{asset_id} must truthfully claim provenance READY')

        record = provenance_by_id.get(asset_id)
        if record is None:
            raise ValidationError(f'{asset_id} claims provenance READY but record is missing')
        if record.get('runtimePath') != descriptor['path']:
            raise ValidationError(f'{asset_id} provenance runtimePath drifted')
        if record.get('profile') != 'pcargo' or record.get('dimensions') != {'width': 384, 'height': 384}:
            raise ValidationError(f'{asset_id} provenance pcargo contract drifted')
        if record.get('revision') != 1 or not descriptor['path'].endswith('_v01.webp'):
            raise ValidationError(f'{asset_id} provenance revision drifted')
        source_sha = record.get('sourceSha256')
        export_sha = record.get('exportSha256')
        if not isinstance(source_sha, str) or not SHA256_RE.fullmatch(source_sha):
            raise ValidationError(f'{asset_id} source SHA-256 is invalid')
        if not isinstance(export_sha, str) or not SHA256_RE.fullmatch(export_sha):
            raise ValidationError(f'{asset_id} export SHA-256 is invalid')

        actual_sha = _verify_webp(root / descriptor['path'], max_bytes, asset_id)
        if actual_sha != export_sha:
            raise ValidationError(f'{asset_id} runtime WebP SHA-256 does not match provenance')


if __name__ == '__main__':
    validate()
    print('AST-007 BATCH 01 CONTRACT PASSED (12 admitted cargo WebP assets + provenance hashes)')
