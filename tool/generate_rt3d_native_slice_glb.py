#!/usr/bin/env python3
"""Generate the project-owned GLB used by the RT3D-002 native slice."""
from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path

OUTPUT = Path('assets/3d/runtime/models/cargame_native_slice_v1.glb')
EXPECTED_SHA256 = '5de93589908d375446567cd84aa84dcba496a705538cec37c098f82440b480b2'

# Stable gameplay IDs are preserved; visible district expansion implements RT3D2-T081..T110.
FACES = [
    ((1, 0, 0), [(0.5, -0.5, -0.5), (0.5, 0.5, -0.5), (0.5, 0.5, 0.5), (0.5, -0.5, 0.5)]),
    ((-1, 0, 0), [(-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (-0.5, 0.5, -0.5), (-0.5, -0.5, -0.5)]),
    ((0, 1, 0), [(-0.5, 0.5, -0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5), (0.5, 0.5, -0.5)]),
    ((0, -1, 0), [(-0.5, -0.5, 0.5), (-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, -0.5, 0.5)]),
    ((0, 0, 1), [(-0.5, -0.5, 0.5), (0.5, -0.5, 0.5), (0.5, 0.5, 0.5), (-0.5, 0.5, 0.5)]),
    ((0, 0, -1), [(0.5, -0.5, -0.5), (-0.5, -0.5, -0.5), (-0.5, 0.5, -0.5), (0.5, 0.5, -0.5)]),
]
MATERIALS = [
    ('ground', [0.10, 0.22, 0.15, 1], 0.92, 0.0),
    ('road', [0.055, 0.065, 0.08, 1], 0.82, 0.0),
    ('warehouse', [0.45, 0.52, 0.60, 1], 0.72, 0.05),
    ('vehicle', [0.02, 0.28, 0.72, 1], 0.28, 0.25),
    ('cargoA', [0.04, 0.48, 0.95, 1], 0.45, 0.05),
    ('cargoB', [0.95, 0.42, 0.08, 1], 0.55, 0.0),
    ('targetA', [0.02, 0.70, 0.92, 1], 0.40, 0.05),
    ('targetB', [0.94, 0.64, 0.06, 1], 0.45, 0.0),
    ('stripe', [0.96, 0.84, 0.18, 1], 0.48, 0.0),
    ('curb', [0.58, 0.64, 0.68, 1], 0.76, 0.0),
    ('glass', [0.10, 0.35, 0.52, 1], 0.20, 0.45),
    ('tire', [0.025, 0.03, 0.035, 1], 0.88, 0.0),
    ('door', [0.12, 0.16, 0.22, 1], 0.68, 0.12),
    ('foliage', [0.10, 0.52, 0.24, 1], 0.90, 0.0),
    ('trunk', [0.36, 0.20, 0.08, 1], 0.92, 0.0),
    ('lamp', [1.00, 0.76, 0.22, 1], 0.24, 0.10),
    ('sidewalk', [0.72, 0.74, 0.76, 1], 0.90, 0.0),
    ('office', [0.76, 0.62, 0.42, 1], 0.78, 0.0),
    ('sign', [0.93, 0.96, 1.00, 1], 0.35, 0.02),
    ('hazard', [1.00, 0.28, 0.03, 1], 0.55, 0.0),
    ('hedge', [0.05, 0.38, 0.16, 1], 0.95, 0.0),
    ('bench', [0.42, 0.20, 0.08, 1], 0.82, 0.0),
    ('bin', [0.03, 0.18, 0.13, 1], 0.88, 0.0),
    ('beacon', [0.95, 0.04, 0.05, 1], 0.18, 0.08),
    ('whiteLight', [1.00, 0.94, 0.72, 1], 0.16, 0.08),
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
            'name': f'm.{name}',
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

    # Main toy-city delivery yard.
    node('ground.main', 'ground', (0, -0.15, 0), (24, 0.25, 24))
    node('road.main', 'road', (0, 0, -1.2), (5.2, 0.08, 15.5))
    node('road.cross', 'road', (0, 0.01, 1.2), (15.5, 0.08, 4.3))

    # Readable road edge/center markings.
    node('road.curb.west', 'curb', (-2.9, 0.10, -1.2), (0.18, 0.24, 15.5))
    node('road.curb.east', 'curb', (2.9, 0.10, -1.2), (0.18, 0.24, 15.5))
    node('road.curb.north', 'curb', (0, 0.11, 3.65), (15.5, 0.24, 0.18))
    node('road.curb.south', 'curb', (0, 0.11, -1.25), (15.5, 0.24, 0.18))
    for index, z in enumerate((-6.7, -4.6, -2.5, -0.4, 1.7, 3.8, 5.9)):
        node(f'road.stripe.main.{index}', 'stripe', (0, 0.075, z), (0.16, 0.035, 0.9))
    for index, x in enumerate((-6.0, -3.8, 3.8, 6.0)):
        node(f'road.stripe.cross.{index}', 'stripe', (x, 0.08, 1.2), (0.9, 0.035, 0.16))

    # Warehouse with readable entrance.
    node('environment.warehouse', 'warehouse', (-6, 1.8, 2.7), (3.2, 3.6, 5.8))
    node('environment.warehouse.roof', 'road', (-6, 3.72, 2.7), (3.5, 0.18, 6.1))
    node('environment.warehouse.door', 'door', (-4.36, 1.35, 2.2), (0.12, 2.25, 2.35))
    node('environment.warehouse.awning', 'vehicle', (-4.08, 2.65, 2.2), (0.55, 0.18, 2.65))

    # Delivery pads with small edge pylons.
    node('delivery.electronics', 'targetA', (4.2, 0.18, 2.9), (2.8, 0.32, 2.5))
    node('delivery.food', 'targetB', (4.2, 0.18, -3.1), (2.8, 0.32, 2.5))
    node('delivery.electronics.pylon', 'targetA', (5.25, 0.72, 3.8), (0.22, 1.25, 0.22))
    node('delivery.food.pylon', 'targetB', (5.25, 0.72, -4.0), (0.22, 1.25, 0.22))

    # Stylized delivery vehicle with windshield and four wheel blocks.
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

    # Interactive and stacked cargo.
    node('cargo.demo.electronics', 'cargoA', (-4.6, 0.62, 1), (1.05, 1.05, 1.05))
    node('cargo.demo.food', 'cargoB', (-4.6, 0.62, 3.4), (1.05, 1.05, 1.05))
    node('cargo.stack.electronics', 'cargoA', (-6.2, 0.48, 1), (0.72, 0.72, 0.72))
    node('cargo.stack.food', 'cargoB', (-6.2, 0.48, 3.4), (0.72, 0.72, 0.72))
    node('cargo.stack.electronics.high', 'cargoA', (-6.2, 1.25, 1), (0.62, 0.62, 0.62))
    node('cargo.stack.food.high', 'cargoB', (-6.2, 1.25, 3.4), (0.62, 0.62, 0.62))

    # Low-cost environment dressing: three toy trees and two street lamps.
    for index, (x, z) in enumerate(((-8.2, -5.8), (7.7, 6.1), (8.0, -6.0))):
        node(f'environment.tree.{index}.trunk', 'trunk', (x, 0.75, z), (0.38, 1.5, 0.38))
        node(f'environment.tree.{index}.crown', 'foliage', (x, 2.0, z), (1.45, 1.45, 1.45))
    for index, (x, z) in enumerate(((-3.6, -5.6), (3.6, 6.0))):
        node(f'environment.lamp.{index}.pole', 'curb', (x, 1.55, z), (0.14, 3.1, 0.14))
        node(f'environment.lamp.{index}.head', 'lamp', (x, 3.10, z), (0.42, 0.20, 0.42))


    # RT3D2-T081..T084: sorting depot with roof, loading door, and sign.
    node('environment.depot', 'warehouse', (-8.4, 1.55, -5.1), (3.0, 3.1, 4.0))
    node('environment.depot.roof', 'road', (-8.4, 3.18, -5.1), (3.3, 0.18, 4.3))
    node('environment.depot.door', 'door', (-6.86, 1.18, -5.1), (0.12, 1.95, 1.65))
    node('environment.depot.sign', 'sign', (-6.70, 2.55, -5.1), (0.10, 0.55, 1.55))

    # RT3D2-T085..T087: office, roof cap, and four windows.
    node('environment.office', 'office', (8.2, 1.65, 4.9), (3.0, 3.3, 3.8))
    node('environment.office.roof', 'road', (8.2, 3.38, 4.9), (3.3, 0.18, 4.1))
    for index, z in enumerate((3.7, 4.5, 5.3, 6.1)):
        node(f'environment.office.window.{index}', 'glass', (6.66, 1.95, z), (0.10, 0.72, 0.48))

    # RT3D2-T088..T090: broad sidewalks.
    node('environment.sidewalk.west', 'sidewalk', (-4.15, 0.08, -1.2), (2.0, 0.14, 18.0))
    node('environment.sidewalk.east', 'sidewalk', (4.15, 0.08, -1.2), (2.0, 0.14, 18.0))
    node('environment.sidewalk.north', 'sidewalk', (0, 0.08, 4.75), (18.0, 0.14, 1.7))

    # RT3D2-T091..T092: two zebra crossings.
    for index, x in enumerate((-2.25, -1.35, -0.45, 0.45, 1.35, 2.25)):
        node(f'road.crosswalk.north.{index}', 'sign', (x, 0.095, 4.0), (0.54, 0.035, 0.22))
        node(f'road.crosswalk.south.{index}', 'sign', (x, 0.095, -2.0), (0.54, 0.035, 0.22))

    # RT3D2-T093..T094: parking slab and bay dividers.
    node('environment.parking', 'road', (8.0, 0.04, -5.6), (5.5, 0.08, 4.2))
    for index, x in enumerate((5.8, 6.9, 8.0, 9.1, 10.2)):
        node(f'environment.parking.stripe.{index}', 'sign', (x, 0.09, -5.6), (0.08, 0.035, 3.5))

    # RT3D2-T095: four hazard-cone blocks.
    for index, z in enumerate((-0.2, 0.7, 1.6, 2.5)):
        node(f'environment.cone.{index}', 'hazard', (-3.55, 0.32, z), (0.26, 0.62, 0.26))

    # RT3D2-T096: delivery-lane bollards.
    for index, z in enumerate((-4.5, -2.3, 2.2, 4.4)):
        node(f'environment.bollard.{index}', 'curb', (2.85, 0.48, z), (0.18, 0.92, 0.18))

    # RT3D2-T097..T098: traffic light.
    node('environment.trafficLight.pole', 'door', (-2.2, 1.65, 4.3), (0.14, 3.3, 0.14))
    node('environment.trafficLight.head', 'hazard', (-2.2, 3.35, 4.3), (0.38, 0.78, 0.34))

    # RT3D2-T099..T101: checkpoint arch.
    node('environment.checkpoint.left', 'vehicle', (-2.5, 1.55, -8.4), (0.28, 3.1, 0.28))
    node('environment.checkpoint.right', 'vehicle', (2.5, 1.55, -8.4), (0.28, 3.1, 0.28))
    node('environment.checkpoint.beam', 'sign', (0, 3.1, -8.4), (5.3, 0.34, 0.34))

    # RT3D2-T102: three more toy trees.
    for index, (x, z) in enumerate(((-10.2, 6.5), (10.4, 8.2), (-10.0, -9.0)), start=3):
        node(f'environment.tree.{index}.trunk', 'trunk', (x, 0.75, z), (0.38, 1.5, 0.38))
        node(f'environment.tree.{index}.crown', 'foliage', (x, 2.0, z), (1.45, 1.45, 1.45))

    # RT3D2-T103: office hedge cluster.
    for index, z in enumerate((2.6, 4.0, 5.4, 6.8)):
        node(f'environment.hedge.{index}', 'hedge', (10.3, 0.52, z), (0.65, 0.95, 1.0))

    # RT3D2-T104..T105: street furniture.
    node('environment.bench', 'bench', (6.0, 0.55, 7.0), (1.9, 0.28, 0.55))
    node('environment.bin', 'bin', (8.4, 0.55, 7.0), (0.62, 1.05, 0.62))

    # RT3D2-T106: two more street lamps.
    for index, (x, z) in enumerate(((-7.4, 7.4), (7.5, -8.1)), start=2):
        node(f'environment.lamp.{index}.pole', 'curb', (x, 1.55, z), (0.14, 3.1, 0.14))
        node(f'environment.lamp.{index}.head', 'lamp', (x, 3.10, z), (0.42, 0.20, 0.42))

    # RT3D2-T107..T109: vehicle lighting, beacon, bumper, and cargo rack.
    node('vehicle.player.headlight.left', 'whiteLight', (-0.62, 0.86, -1.92), (0.34, 0.22, 0.08))
    node('vehicle.player.headlight.right', 'whiteLight', (0.82, 0.86, -1.92), (0.34, 0.22, 0.08))
    node('vehicle.player.taillight.left', 'beacon', (-0.62, 0.82, 1.34), (0.32, 0.20, 0.08))
    node('vehicle.player.taillight.right', 'beacon', (0.82, 0.82, 1.34), (0.32, 0.20, 0.08))
    node('vehicle.player.beacon', 'beacon', (0.1, 1.98, -0.82), (0.34, 0.22, 0.34))
    node('vehicle.player.rearBumper', 'curb', (0.1, 0.52, 1.42), (1.82, 0.18, 0.18))
    node('vehicle.player.cargoRack', 'door', (0.1, 1.55, 0.55), (1.42, 0.18, 1.55))

    # RT3D2-T110: target corner markers.
    for target, material, center_x, center_z in (
        ('electronics', 'targetA', 4.2, 2.9),
        ('food', 'targetB', 4.2, -3.1),
    ):
        for corner, dx, dz in (
            ('nw', -1.15, 0.95), ('ne', 1.15, 0.95),
            ('sw', -1.15, -0.95), ('se', 1.15, -0.95),
        ):
            node(
                f'delivery.{target}.marker.{corner}',
                material,
                (center_x + dx, 0.52, center_z + dz),
                (0.18, 0.74, 0.18),
            )

    document = {
        'asset': {'version': '2.0', 'generator': 'CARGame RT3D-002 native slice visual expansion v3'},
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
