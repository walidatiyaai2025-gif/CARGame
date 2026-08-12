#!/usr/bin/env python3
"""Generate the tiny project-owned GLB used by the RT3D-002 native visual slice."""
from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path

OUTPUT = Path('assets/3d/runtime/models/cargame_native_slice_v1.glb')
EXPECTED_SHA256 = '38dbfa968fc5da7a539d09acb66d6b91f1dab95f3332fab073ee94dc693137a1'

FACES = [
    ((1, 0, 0), [(0.5, -0.5, -0.5), (0.5, 0.5, -0.5), (0.5, 0.5, 0.5), (0.5, -0.5, 0.5)]),
    ((-1, 0, 0), [(-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (-0.5, 0.5, -0.5), (-0.5, -0.5, -0.5)]),
    ((0, 1, 0), [(-0.5, 0.5, -0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5), (0.5, 0.5, -0.5)]),
    ((0, -1, 0), [(-0.5, -0.5, 0.5), (-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, -0.5, 0.5)]),
    ((0, 0, 1), [(-0.5, -0.5, 0.5), (0.5, -0.5, 0.5), (0.5, 0.5, 0.5), (-0.5, 0.5, 0.5)]),
    ((0, 0, -1), [(0.5, -0.5, -0.5), (-0.5, -0.5, -0.5), (-0.5, 0.5, -0.5), (0.5, 0.5, -0.5)]),
]

MATERIALS = [
    ('ground', [0.12, 0.18, 0.16, 1], 0.95, 0.0),
    ('road', [0.08, 0.09, 0.11, 1], 0.85, 0.0),
    ('warehouse', [0.48, 0.55, 0.62, 1], 0.72, 0.05),
    ('roof', [0.16, 0.22, 0.28, 1], 0.82, 0.0),
    ('vehicle_blue', [0.02, 0.28, 0.72, 1], 0.28, 0.25),
    ('wheel', [0.015, 0.018, 0.022, 1], 0.70, 0.0),
    ('glass', [0.05, 0.25, 0.38, 1], 0.15, 0.15),
    ('cargo_electronics', [0.04, 0.48, 0.95, 1], 0.45, 0.05),
    ('cargo_food', [0.95, 0.42, 0.08, 1], 0.55, 0.0),
    ('target_electronics', [0.02, 0.70, 0.92, 1], 0.40, 0.05),
    ('target_food', [0.94, 0.64, 0.06, 1], 0.45, 0.0),
    ('accent', [0.95, 0.96, 1.0, 1], 0.35, 0.20),
]


def generate() -> bytes:
    positions: list[tuple[float, float, float]] = []
    normals: list[tuple[int, int, int]] = []
    indices: list[int] = []
    for normal, vertices in FACES:
        base = len(positions)
        positions.extend(vertices)
        normals.extend([normal] * 4)
        indices.extend([base, base + 1, base + 2, base, base + 2, base + 3])

    binary = bytearray()

    def align() -> None:
        while len(binary) % 4:
            binary.append(0)

    def add_vec3(values: list[tuple[float, float, float]]) -> tuple[int, int]:
        align()
        offset = len(binary)
        for value in values:
            binary.extend(struct.pack('<3f', *value))
        return offset, len(values) * 12

    def add_indices(values: list[int]) -> tuple[int, int]:
        align()
        offset = len(binary)
        for value in values:
            binary.extend(struct.pack('<H', value))
        return offset, len(values) * 2

    position_offset, position_length = add_vec3(positions)
    normal_offset, normal_length = add_vec3(normals)
    index_offset, index_length = add_indices(indices)
    align()

    material_index = {item[0]: index for index, item in enumerate(MATERIALS)}
    materials = [
        {
            'name': name,
            'pbrMetallicRoughness': {
                'baseColorFactor': color,
                'roughnessFactor': roughness,
                'metallicFactor': metallic,
            },
        }
        for name, color, roughness, metallic in MATERIALS
    ]
    meshes = [
        {
            'name': f'mesh.{name}',
            'primitives': [{
                'attributes': {'POSITION': 0, 'NORMAL': 1},
                'indices': 2,
                'material': index,
            }],
        }
        for index, (name, *_rest) in enumerate(MATERIALS)
    ]

    nodes: list[dict[str, object]] = []

    def node(name: str, material: str, translation: tuple[float, float, float], scale: tuple[float, float, float]) -> None:
        nodes.append({
            'name': name,
            'mesh': material_index[material],
            'translation': list(translation),
            'scale': list(scale),
        })

    node('ground.main', 'ground', (0, -0.15, 0), (18, 0.25, 18))
    node('road.main', 'road', (0, 0, -1.2), (5.2, 0.08, 15.5))
    node('environment.warehouse.floor', 'warehouse', (-4.5, 0.05, 2.8), (6.5, 0.12, 6))
    node('environment.warehouse', 'warehouse', (-7.5, 1.8, 2.8), (0.22, 3.6, 6))
    node('environment.warehouse.back', 'warehouse', (-4.5, 1.8, 5.7), (6.5, 3.6, 0.22))
    node('environment.warehouse.roof', 'roof', (-4.5, 3.68, 2.8), (6.8, 0.18, 6.3))
    for z in (0.7, 2.4, 4.1):
        node(f'environment.shelf.{z}', 'roof', (-5, 1.15, z), (3.8, 0.12, 0.75))
        node(f'environment.shelfpost.{z}.a', 'roof', (-6.7, 1.2, z), (0.1, 2.4, 0.1))
        node(f'environment.shelfpost.{z}.b', 'roof', (-3.3, 1.2, z), (0.1, 2.4, 0.1))
    node('delivery.electronics', 'target_electronics', (4.2, 0.18, 2.9), (2.8, 0.32, 2.5))
    node('delivery.electronics.sign', 'target_electronics', (4.2, 1.3, 4), (2.5, 2, 0.15))
    node('delivery.food', 'target_food', (4.2, 0.18, -3.1), (2.8, 0.32, 2.5))
    node('delivery.food.sign', 'target_food', (4.2, 1.3, -4.2), (2.5, 2, 0.15))
    node('vehicle.player', 'vehicle_blue', (0.1, 0.72, -0.3), (1.75, 0.70, 3.2))
    node('vehicle.player.cabin', 'vehicle_blue', (0.1, 1.35, -1), (1.65, 0.75, 1.45))
    node('vehicle.player.windshield', 'glass', (0.1, 1.45, -1.76), (1.35, 0.48, 0.08))
    node('vehicle.player.bumper', 'accent', (0.1, 0.52, -1.95), (1.82, 0.18, 0.18))
    for x in (-0.92, 1.12):
        for z in (-1.25, 0.72):
            node(f'vehicle.player.wheel.{x}.{z}', 'wheel', (x, 0.40, z), (0.34, 0.58, 0.72))
    node('cargo.demo.electronics', 'cargo_electronics', (-4.6, 0.62, 1), (1.05, 1.05, 1.05))
    node('cargo.demo.food', 'cargo_food', (-4.6, 0.62, 3.4), (1.05, 1.05, 1.05))
    node('cargo.stack.electronics', 'cargo_electronics', (-6, 0.48, 1), (0.72, 0.72, 0.72))
    node('cargo.stack.food', 'cargo_food', (-6, 0.48, 3.4), (0.72, 0.72, 0.72))
    for z in (-6, -3, 0, 3, 6):
        node(f'road.marking.{z}', 'accent', (0, 0.06, z), (0.12, 0.025, 1))

    document = {
        'asset': {'version': '2.0', 'generator': 'CARGame RT3D-002 deterministic native slice generator v1'},
        'scene': 0,
        'scenes': [{'name': 'CARGame Native Delivery Slice', 'nodes': list(range(len(nodes)))}],
        'nodes': nodes,
        'meshes': meshes,
        'materials': materials,
        'buffers': [{'byteLength': len(binary)}],
        'bufferViews': [
            {'buffer': 0, 'byteOffset': position_offset, 'byteLength': position_length, 'target': 34962},
            {'buffer': 0, 'byteOffset': normal_offset, 'byteLength': normal_length, 'target': 34962},
            {'buffer': 0, 'byteOffset': index_offset, 'byteLength': index_length, 'target': 34963},
        ],
        'accessors': [
            {'bufferView': 0, 'componentType': 5126, 'count': len(positions), 'type': 'VEC3', 'min': [-0.5, -0.5, -0.5], 'max': [0.5, 0.5, 0.5]},
            {'bufferView': 1, 'componentType': 5126, 'count': len(normals), 'type': 'VEC3'},
            {'bufferView': 2, 'componentType': 5123, 'count': len(indices), 'type': 'SCALAR', 'min': [0], 'max': [max(indices)]},
        ],
    }
    json_chunk = json.dumps(document, separators=(',', ':')).encode('utf-8')
    while len(json_chunk) % 4:
        json_chunk += b' '
    binary_chunk = bytes(binary)
    while len(binary_chunk) % 4:
        binary_chunk += b'\x00'
    total_length = 12 + 8 + len(json_chunk) + 8 + len(binary_chunk)
    return (
        struct.pack('<4sII', b'glTF', 2, total_length)
        + struct.pack('<I4s', len(json_chunk), b'JSON')
        + json_chunk
        + struct.pack('<I4s', len(binary_chunk), b'BIN\x00')
        + binary_chunk
    )


def main() -> int:
    payload = generate()
    digest = hashlib.sha256(payload).hexdigest()
    if digest != EXPECTED_SHA256:
        raise SystemExit(f'generator drift: expected {EXPECTED_SHA256}, got {digest}')
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(payload)
    print(f'Wrote {OUTPUT} ({len(payload)} bytes, sha256={digest})')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
