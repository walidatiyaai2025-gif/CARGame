#!/usr/bin/env python3
"""Generate the project-owned GLB used by the CARGame native Filament visual lab."""
from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path

OUTPUT = Path('assets/3d/runtime/models/cargame_native_slice_v1.glb')
EXPECTED_SHA256 = 'b727b594612452a9a3723aa64423ee5d18a9b90567aba191d9a035bf888de157'
GENERATOR_NAME = 'CARGame RT3D-003 cinematic native slice v3'

FACES = [
    ((1, 0, 0), [(0.5, -0.5, -0.5), (0.5, 0.5, -0.5), (0.5, 0.5, 0.5), (0.5, -0.5, 0.5)]),
    ((-1, 0, 0), [(-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (-0.5, 0.5, -0.5), (-0.5, -0.5, -0.5)]),
    ((0, 1, 0), [(-0.5, 0.5, -0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5), (0.5, 0.5, -0.5)]),
    ((0, -1, 0), [(-0.5, -0.5, 0.5), (-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, -0.5, 0.5)]),
    ((0, 0, 1), [(-0.5, -0.5, 0.5), (0.5, -0.5, 0.5), (0.5, 0.5, 0.5), (-0.5, 0.5, 0.5)]),
    ((0, 0, -1), [(0.5, -0.5, -0.5), (-0.5, -0.5, -0.5), (-0.5, 0.5, -0.5), (0.5, 0.5, -0.5)]),
]

MATERIALS = [
    ('ground', [0.10, 0.22, 0.15, 1], 0.92, 0.0, None),
    ('road', [0.055, 0.065, 0.08, 1], 0.82, 0.0, None),
    ('warehouse', [0.45, 0.52, 0.60, 1], 0.72, 0.05, None),
    ('vehicle', [0.02, 0.28, 0.72, 1], 0.28, 0.25, None),
    ('cargoA', [0.04, 0.48, 0.95, 1], 0.45, 0.05, None),
    ('cargoB', [0.95, 0.42, 0.08, 1], 0.55, 0.0, None),
    ('targetA', [0.02, 0.70, 0.92, 1], 0.40, 0.05, None),
    ('targetB', [0.94, 0.64, 0.06, 1], 0.45, 0.0, None),
    ('stripe', [0.96, 0.84, 0.18, 1], 0.48, 0.0, None),
    ('curb', [0.58, 0.64, 0.68, 1], 0.76, 0.0, None),
    ('glass', [0.10, 0.35, 0.52, 1], 0.20, 0.45, None),
    ('tire', [0.025, 0.03, 0.035, 1], 0.88, 0.0, None),
    ('door', [0.12, 0.16, 0.22, 1], 0.68, 0.12, None),
    ('foliage', [0.10, 0.52, 0.24, 1], 0.90, 0.0, None),
    ('trunk', [0.36, 0.20, 0.08, 1], 0.92, 0.0, None),
    ('lamp', [1.00, 0.76, 0.22, 1], 0.24, 0.10, [1.00, 0.52, 0.08]),
    ('headlight', [1.00, 0.94, 0.68, 1], 0.16, 0.05, [1.00, 0.88, 0.48]),
    ('rearLight', [0.92, 0.03, 0.02, 1], 0.22, 0.0, [1.00, 0.02, 0.01]),
    ('beacon', [1.00, 0.34, 0.02, 1], 0.20, 0.05, [1.00, 0.22, 0.01]),
    ('sign', [0.02, 0.52, 0.92, 1], 0.34, 0.08, [0.02, 0.42, 1.00]),
    ('signalRed', [0.70, 0.02, 0.02, 1], 0.24, 0.0, [1.00, 0.01, 0.01]),
    ('signalAmber', [0.92, 0.44, 0.02, 1], 0.24, 0.0, [1.00, 0.24, 0.01]),
    ('signalGreen', [0.02, 0.62, 0.20, 1], 0.24, 0.0, [0.01, 0.92, 0.12]),
    ('pallet', [0.47, 0.27, 0.10, 1], 0.90, 0.0, None),
    ('skyline', [0.10, 0.13, 0.20, 1], 0.78, 0.05, None),
    ('safety', [0.96, 0.30, 0.04, 1], 0.55, 0.05, None),
]


def generate() -> bytes:
    positions = []
    normals = []
    indices = []
    for normal, vertices in FACES:
        base = len(positions)
        positions.extend(vertices)
        normals.extend([normal] * 4)
        indices.extend([base, base + 1, base + 2, base, base + 2, base + 3])

    binary = bytearray()

    def align() -> None:
        while len(binary) % 4:
            binary.append(0)

    def add_vec3(values):
        align()
        offset = len(binary)
        for value in values:
            binary.extend(struct.pack('<3f', *value))
        return offset, len(values) * 12

    def add_indices(values):
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
    materials = []
    for name, color, roughness, metallic, emissive in MATERIALS:
        material = {
            'name': name,
            'pbrMetallicRoughness': {
                'baseColorFactor': color,
                'roughnessFactor': roughness,
                'metallicFactor': metallic,
            },
        }
        if emissive is not None:
            material['emissiveFactor'] = emissive
        materials.append(material)

    meshes = [
        {
            'name': f'm.{name}',
            'primitives': [{
                'attributes': {'POSITION': 0, 'NORMAL': 1},
                'indices': 2,
                'material': index,
            }],
        }
        for index, (name, *_rest) in enumerate(MATERIALS)
    ]

    nodes = []

    def node(name, material, translation, scale):
        nodes.append({
            'name': name,
            'mesh': material_index[material],
            'translation': list(translation),
            'scale': list(scale),
        })

    node('ground.main', 'ground', (0, -0.15, 0), (18, 0.25, 18))
    node('road.main', 'road', (0, 0, -1.2), (5.2, 0.08, 15.5))
    node('road.cross', 'road', (0, 0.01, 1.2), (15.5, 0.08, 4.3))

    node('road.curb.west', 'curb', (-2.9, 0.10, -1.2), (0.18, 0.24, 15.5))
    node('road.curb.east', 'curb', (2.9, 0.10, -1.2), (0.18, 0.24, 15.5))
    node('road.curb.north', 'curb', (0, 0.11, 3.65), (15.5, 0.24, 0.18))
    node('road.curb.south', 'curb', (0, 0.11, -1.25), (15.5, 0.24, 0.18))
    for index, z in enumerate((-6.7, -4.6, -2.5, -0.4, 1.7, 3.8, 5.9)):
        node(f'road.stripe.main.{index}', 'stripe', (0, 0.075, z), (0.16, 0.035, 0.9))
    for index, x in enumerate((-6.0, -3.8, 3.8, 6.0)):
        node(f'road.stripe.cross.{index}', 'stripe', (x, 0.08, 1.2), (0.9, 0.035, 0.16))
    node('road.stop.north', 'stripe', (0, 0.09, 3.05), (4.2, 0.03, 0.16))
    node('road.stop.south', 'stripe', (0, 0.09, -0.65), (4.2, 0.03, 0.16))
    node('road.arrow.main.shaft', 'stripe', (-1.1, 0.09, -5.0), (0.18, 0.03, 1.15))
    node('road.arrow.main.head.left', 'stripe', (-1.42, 0.09, -4.0), (0.48, 0.03, 0.18))
    node('road.arrow.main.head.right', 'stripe', (-0.78, 0.09, -4.0), (0.48, 0.03, 0.18))
    node('road.arrow.cross.shaft', 'stripe', (6.0, 0.09, 2.0), (1.05, 0.03, 0.18))
    node('road.arrow.cross.head.top', 'stripe', (6.85, 0.09, 2.32), (0.18, 0.03, 0.48))
    node('road.arrow.cross.head.bottom', 'stripe', (6.85, 0.09, 1.68), (0.18, 0.03, 0.48))

    node('environment.warehouse', 'warehouse', (-6, 1.8, 2.7), (3.2, 3.6, 5.8))
    node('environment.warehouse.roof', 'road', (-6, 3.72, 2.7), (3.5, 0.18, 6.1))
    node('environment.warehouse.door', 'door', (-4.36, 1.35, 2.2), (0.12, 2.25, 2.35))
    node('environment.warehouse.awning', 'vehicle', (-4.08, 2.65, 2.2), (0.55, 0.18, 2.65))
    node('environment.warehouse.sign.header', 'door', (-4.30, 3.25, 2.2), (0.18, 0.62, 2.85))
    node('environment.warehouse.sign.panel', 'sign', (-4.18, 3.25, 2.2), (0.08, 0.38, 2.35))
    for index, z in enumerate((0.3, 1.2, 3.2, 4.1)):
        node(f'environment.loading.safety.{index}', 'safety', (-3.85, 0.55, z), (0.18, 1.0, 0.18))
    node('environment.loading.barrier.low', 'safety', (-3.82, 0.52, -0.1), (0.18, 0.18, 1.4))
    node('environment.loading.barrier.high', 'safety', (-3.82, 0.52, 4.55), (0.18, 0.18, 1.4))

    node('delivery.electronics', 'targetA', (4.2, 0.18, 2.9), (2.8, 0.32, 2.5))
    node('delivery.food', 'targetB', (4.2, 0.18, -3.1), (2.8, 0.32, 2.5))
    node('delivery.electronics.pylon', 'targetA', (5.25, 0.72, 3.8), (0.22, 1.25, 0.22))
    node('delivery.food.pylon', 'targetB', (5.25, 0.72, -4.0), (0.22, 1.25, 0.22))
    for prefix, material, z in (
        ('delivery.electronics.rim', 'targetA', 2.9),
        ('delivery.food.rim', 'targetB', -3.1),
    ):
        node(f'{prefix}.north', material, (4.2, 0.38, z + 1.34), (3.05, 0.08, 0.12))
        node(f'{prefix}.south', material, (4.2, 0.38, z - 1.34), (3.05, 0.08, 0.12))
        node(f'{prefix}.east', material, (5.73, 0.38, z), (0.12, 0.08, 2.55))
        node(f'{prefix}.west', material, (2.67, 0.38, z), (0.12, 0.08, 2.55))

    node('vehicle.player', 'vehicle', (0.1, 0.72, -0.3), (1.75, 0.70, 3.2))
    node('vehicle.player.cabin', 'vehicle', (0.1, 1.35, -1), (1.65, 0.75, 1.45))
    node('vehicle.player.windshield', 'glass', (0.1, 1.48, -1.77), (1.35, 0.42, 0.08))
    for name, x, z in (
        ('fl', -0.72, -1.45),
        ('fr', 0.92, -1.45),
        ('rl', -0.72, 0.78),
        ('rr', 0.92, 0.78),
    ):
        node(f'vehicle.player.wheel.{name}', 'tire', (x, 0.42, z), (0.42, 0.42, 0.32))
    node('vehicle.player.headlight.left', 'headlight', (-0.55, 0.84, -1.93), (0.34, 0.22, 0.08))
    node('vehicle.player.headlight.right', 'headlight', (0.75, 0.84, -1.93), (0.34, 0.22, 0.08))
    node('vehicle.player.rearlight.left', 'rearLight', (-0.55, 0.76, 1.34), (0.30, 0.20, 0.08))
    node('vehicle.player.rearlight.right', 'rearLight', (0.75, 0.76, 1.34), (0.30, 0.20, 0.08))
    node('vehicle.player.bumper.front', 'curb', (0.1, 0.46, -1.98), (1.62, 0.18, 0.12))
    node('vehicle.player.bumper.rear', 'curb', (0.1, 0.46, 1.38), (1.62, 0.18, 0.12))
    node('vehicle.player.mirror.left', 'glass', (-1.00, 1.45, -1.2), (0.16, 0.20, 0.28))
    node('vehicle.player.mirror.right', 'glass', (1.20, 1.45, -1.2), (0.16, 0.20, 0.28))
    node('vehicle.player.beacon.base', 'door', (0.1, 1.92, -0.95), (0.34, 0.12, 0.34))
    node('vehicle.player.beacon.light', 'beacon', (0.1, 2.08, -0.95), (0.24, 0.20, 0.24))

    node('cargo.demo.electronics', 'cargoA', (-4.6, 0.62, 1), (1.05, 1.05, 1.05))
    node('cargo.demo.food', 'cargoB', (-4.6, 0.62, 3.4), (1.05, 1.05, 1.05))
    node('cargo.stack.electronics', 'cargoA', (-6.2, 0.48, 1), (0.72, 0.72, 0.72))
    node('cargo.stack.food', 'cargoB', (-6.2, 0.48, 3.4), (0.72, 0.72, 0.72))
    node('cargo.stack.electronics.high', 'cargoA', (-6.2, 1.25, 1), (0.62, 0.62, 0.62))
    node('cargo.stack.food.high', 'cargoB', (-6.2, 1.25, 3.4), (0.62, 0.62, 0.62))

    for index, (x, z, material) in enumerate((
        (-8.1, 0.3, 'cargoA'), (-8.1, 1.5, 'cargoB'), (-8.1, 4.8, 'cargoA'),
        (-7.0, -4.6, 'cargoB'), (7.5, -7.0, 'cargoA'), (7.5, 7.0, 'cargoB'),
    )):
        node(f'environment.pallet.{index}', 'pallet', (x, 0.22, z), (1.15, 0.18, 1.15))
        node(f'environment.pallet.{index}.crate', material, (x, 0.72, z), (0.82, 0.82, 0.82))

    for index, (x, z) in enumerate(((-8.2, -5.8), (7.7, 6.1), (8.0, -6.0))):
        node(f'environment.tree.{index}.trunk', 'trunk', (x, 0.75, z), (0.38, 1.5, 0.38))
        node(f'environment.tree.{index}.crown', 'foliage', (x, 2.0, z), (1.45, 1.45, 1.45))
    for index, (x, z) in enumerate(((-3.6, -5.6), (3.6, 6.0))):
        node(f'environment.lamp.{index}.pole', 'curb', (x, 1.55, z), (0.14, 3.1, 0.14))
        node(f'environment.lamp.{index}.head', 'lamp', (x, 3.10, z), (0.42, 0.20, 0.42))
    for index, (x, z) in enumerate(((-3.55, 3.95), (3.55, -1.55))):
        node(f'environment.signal.{index}.pole', 'door', (x, 1.45, z), (0.12, 2.9, 0.12))
        node(f'environment.signal.{index}.housing', 'door', (x, 2.72, z), (0.42, 0.92, 0.30))
        node(f'environment.signal.{index}.red', 'signalRed', (x, 3.02, z - 0.17), (0.22, 0.20, 0.08))
        node(f'environment.signal.{index}.amber', 'signalAmber', (x, 2.72, z - 0.17), (0.22, 0.20, 0.08))
        node(f'environment.signal.{index}.green', 'signalGreen', (x, 2.42, z - 0.17), (0.22, 0.20, 0.08))

    for index, (x, y, z, sx, sy, sz) in enumerate((
        (-10.8, 2.1, -7.8, 2.0, 4.2, 2.2),
        (-7.0, 2.7, -9.4, 2.4, 5.4, 1.8),
        (0.0, 1.8, -10.3, 3.2, 3.6, 1.5),
        (7.4, 2.4, -9.2, 2.1, 4.8, 1.8),
        (10.8, 3.0, 0.8, 1.8, 6.0, 2.4),
    )):
        node(f'environment.skyline.{index}', 'skyline', (x, y, z), (sx, sy, sz))

    document = {
        'asset': {'version': '2.0', 'generator': GENERATOR_NAME},
        'scene': 0,
        'scenes': [{'name': 'CARGame Cinematic Delivery Yard', 'nodes': list(range(len(nodes)))}],
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
    print(f'Wrote {OUTPUT} ({len(payload)} bytes) sha256={digest}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
