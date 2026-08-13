#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import importlib.util
import json
import re
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATOR = ROOT / 'tool/generate_rt3d_native_slice_glb.py'
VERIFIER = ROOT / 'tool/verify_rt3d_native_slice.py'
GLB = ROOT / 'assets/3d/runtime/models/cargame_native_slice_v1.glb'
PROVENANCE = ROOT / 'assets/3d/provenance/cargame_native_slice_v1.json'
WORKDOC = ROOT / 'docs/work/RT3D-002-VISUAL-EXPANSION-30.md'
WORKFLOW = ROOT / '.github/workflows/rt3d_visual_expansion_30_once.yml'

REQUIRED_NODES = {
    'vehicle.player', 'cargo.demo.electronics', 'cargo.demo.food',
    'environment.warehouse', 'delivery.electronics', 'delivery.food',
    'ground.main', 'road.main', 'road.cross', 'environment.warehouse.door',
    'vehicle.player.windshield', 'environment.tree.0.crown',
    'environment.lamp.0.head', 'environment.depot', 'environment.depot.roof',
    'environment.depot.door', 'environment.depot.sign', 'environment.office',
    'environment.office.roof', 'environment.office.window.0',
    'environment.sidewalk.west', 'environment.sidewalk.east',
    'environment.sidewalk.north', 'road.crosswalk.north.0',
    'road.crosswalk.south.0', 'environment.parking',
    'environment.parking.stripe.0', 'environment.cone.0',
    'environment.bollard.0', 'environment.trafficLight.pole',
    'environment.trafficLight.head', 'environment.checkpoint.left',
    'environment.checkpoint.right', 'environment.checkpoint.beam',
    'environment.tree.3.crown', 'environment.hedge.0', 'environment.bench',
    'environment.bin', 'environment.lamp.2.head',
    'vehicle.player.headlight.left', 'vehicle.player.taillight.left',
    'vehicle.player.beacon', 'vehicle.player.rearBumper',
    'vehicle.player.cargoRack', 'delivery.electronics.marker.nw',
    'delivery.food.marker.se',
}

TASKS = [
    ('RT3D2-T081', 'Add a second sorting-depot building to expand the delivery district.'),
    ('RT3D2-T082', 'Add a separate depot roof cap for stronger silhouette/readability.'),
    ('RT3D2-T083', 'Add a dark depot loading door.'),
    ('RT3D2-T084', 'Add a bright depot sign panel.'),
    ('RT3D2-T085', 'Add a separate office building on the opposite side of the yard.'),
    ('RT3D2-T086', 'Add an office roof cap.'),
    ('RT3D2-T087', 'Add four visible office window panels.'),
    ('RT3D2-T088', 'Add a west sidewalk ribbon.'),
    ('RT3D2-T089', 'Add an east sidewalk ribbon.'),
    ('RT3D2-T090', 'Add a north sidewalk ribbon.'),
    ('RT3D2-T091', 'Add a six-bar north zebra crossing.'),
    ('RT3D2-T092', 'Add a six-bar south zebra crossing.'),
    ('RT3D2-T093', 'Add a dedicated parking slab.'),
    ('RT3D2-T094', 'Add five parking-bay divider stripes.'),
    ('RT3D2-T095', 'Add four orange hazard-cone blocks at the loading edge.'),
    ('RT3D2-T096', 'Add four protective bollards around the delivery lane.'),
    ('RT3D2-T097', 'Add a traffic-light pole.'),
    ('RT3D2-T098', 'Add a high-contrast traffic-light head.'),
    ('RT3D2-T099', 'Add the left checkpoint-arch post.'),
    ('RT3D2-T100', 'Add the right checkpoint-arch post.'),
    ('RT3D2-T101', 'Add the checkpoint-arch top beam.'),
    ('RT3D2-T102', 'Add three more toy trees around the expanded district.'),
    ('RT3D2-T103', 'Add four hedge blocks around the office.'),
    ('RT3D2-T104', 'Add a visible street bench.'),
    ('RT3D2-T105', 'Add a visible trash bin.'),
    ('RT3D2-T106', 'Add two more street lamps in the expanded area.'),
    ('RT3D2-T107', 'Add two visible vehicle headlights.'),
    ('RT3D2-T108', 'Add two visible vehicle taillights.'),
    ('RT3D2-T109', 'Add vehicle roof beacon, rear bumper, and cargo rack details.'),
    ('RT3D2-T110', 'Add four corner markers to each delivery target for instant target readability.'),
]

MATERIAL_INSERT = """    ('sidewalk', [0.72, 0.74, 0.76, 1], 0.90, 0.0),
    ('office', [0.76, 0.62, 0.42, 1], 0.78, 0.0),
    ('sign', [0.93, 0.96, 1.00, 1], 0.35, 0.02),
    ('hazard', [1.00, 0.28, 0.03, 1], 0.55, 0.0),
    ('hedge', [0.05, 0.38, 0.16, 1], 0.95, 0.0),
    ('bench', [0.42, 0.20, 0.08, 1], 0.82, 0.0),
    ('bin', [0.03, 0.18, 0.13, 1], 0.88, 0.0),
    ('beacon', [0.95, 0.04, 0.05, 1], 0.18, 0.08),
    ('whiteLight', [1.00, 0.94, 0.72, 1], 0.16, 0.08),
"""

NODE_INSERT = r'''
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
'''

EXTRA_VERIFIER_CHECKS = r'''
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('environment.office.window.')]) >= 4,
        'visual-expansion office must retain four visible windows',
    )
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('road.crosswalk.')]) >= 12,
        'visual-expansion slice must retain two zebra crossings',
    )
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('environment.parking.stripe.')]) >= 5,
        'visual-expansion parking bay dividers must remain visible',
    )
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('environment.cone.')]) == 4,
        'visual-expansion loading edge must retain four hazard cones',
    )
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('environment.bollard.')]) == 4,
        'visual-expansion delivery lane must retain four bollards',
    )
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('environment.hedge.')]) >= 4,
        'visual-expansion office landscaping must retain hedge blocks',
    )
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('delivery.electronics.marker.')]) == 4,
        'electronics target must retain four visible corner markers',
    )
    require(
        len([name for name in node_names if isinstance(name, str) and name.startswith('delivery.food.marker.')]) == 4,
        'food target must retain four visible corner markers',
    )
'''


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f'expected exactly one anchor, got {text.count(old)}: {old[:80]!r}')
    return text.replace(old, new, 1)


def patch_generator() -> None:
    text = GENERATOR.read_text(encoding='utf-8')
    text = replace_once(
        text,
        "    ('lamp', [1.00, 0.76, 0.22, 1], 0.24, 0.10),\n]\n",
        "    ('lamp', [1.00, 0.76, 0.22, 1], 0.24, 0.10),\n" + MATERIAL_INSERT + "]\n",
    )
    text = replace_once(
        text,
        "    node('ground.main', 'ground', (0, -0.15, 0), (18, 0.25, 18))",
        "    node('ground.main', 'ground', (0, -0.15, 0), (24, 0.25, 24))",
    )
    text = replace_once(text, "\n    document = {", "\n" + textwrap.dedent(NODE_INSERT).rstrip() + "\n\n    document = {")
    text = replace_once(
        text,
        "'CARGame RT3D-002 native slice visual polish v2'",
        "'CARGame RT3D-002 native slice visual expansion v3'",
    )
    text = re.sub(
        r"EXPECTED_SHA256 = '[0-9a-f]+'",
        "EXPECTED_SHA256 = '__PENDING_RT3D2_T081_T110__'",
        text,
        count=1,
    )
    marker = '# Stable gameplay IDs are preserved; visible district expansion implements RT3D2-T081..T110.\n'
    text = replace_once(text, 'FACES = [\n', marker + 'FACES = [\n')
    GENERATOR.write_text(text, encoding='utf-8')


def generate_and_pin() -> tuple[str, int, int, int]:
    spec = importlib.util.spec_from_file_location('rt3d_generator_v3', GENERATOR)
    if spec is None or spec.loader is None:
        raise RuntimeError('could not load patched generator')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    payload = module.generate()
    digest = hashlib.sha256(payload).hexdigest()
    generator_text = GENERATOR.read_text(encoding='utf-8')
    generator_text = replace_once(generator_text, '__PENDING_RT3D2_T081_T110__', digest)
    GENERATOR.write_text(generator_text, encoding='utf-8')
    GLB.write_bytes(payload)

    json_length = int.from_bytes(payload[12:16], 'little')
    document = json.loads(payload[20:20 + json_length].decode('utf-8').rstrip(' '))
    return digest, len(payload), len(document['nodes']), len(document['materials'])


def patch_provenance(digest: str, byte_length: int) -> None:
    provenance = json.loads(PROVENANCE.read_text(encoding='utf-8'))
    provenance['generator'] = 'CARGame RT3D-002 native slice visual expansion v3'
    provenance['sha256'] = digest
    provenance['byteLength'] = byte_length
    provenance['requiredNodes'] = sorted(REQUIRED_NODES)
    provenance['notes'] = (
        'Third owner-visible Native Filament checkpoint. Adds a sorting depot, office block, sidewalks, '
        'zebra crossings, parking, hazard props, traffic/checkpoint structures, expanded landscaping, '
        'vehicle lighting/beacon detail, and target corner markers while preserving stable gameplay entity '
        'names and offline loading.'
    )
    PROVENANCE.write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')


def patch_verifier(digest: str) -> None:
    text = VERIFIER.read_text(encoding='utf-8')
    required_literal = '{\n' + ''.join(f"    {name!r},\n" for name in sorted(REQUIRED_NODES)) + '}'
    text, count = re.subn(
        r"EXPECTED_SHA256 = '[0-9a-f]+'\nREQUIRED_NODES = \{.*?\}\n\n\n",
        f"EXPECTED_SHA256 = '{digest}'\nREQUIRED_NODES = {required_literal}\n\n\n",
        text,
        count=1,
        flags=re.S,
    )
    if count != 1:
        raise RuntimeError('failed to replace verifier digest/required-node block')
    text = replace_once(
        text,
        "require(len(nodes) >= 45, 'visual-polish slice must retain at least 45 visible scene nodes')",
        "require(len(nodes) >= 120, 'visual-expansion slice must retain at least 120 visible scene nodes')",
    )
    text = replace_once(
        text,
        "'visual-polish slice must contain toy environment trees',",
        "'visual-expansion slice must contain toy environment trees',",
    )
    text = replace_once(
        text,
        "\n    meshes = document.get('meshes')",
        "\n" + textwrap.dedent(EXTRA_VERIFIER_CHECKS).rstrip() + "\n\n    meshes = document.get('meshes')",
    )
    text = replace_once(
        text,
        "len(meshes) >= 16, 'visual-polish GLB must contain at least 16 mesh/material variants'",
        "len(meshes) >= 25, 'visual-expansion GLB must contain at least 25 mesh/material variants'",
    )
    text = replace_once(
        text,
        "len(materials) >= 16, 'visual-polish GLB must contain at least 16 PBR materials'",
        "len(materials) >= 25, 'visual-expansion GLB must contain at least 25 PBR materials'",
    )
    text = replace_once(
        text,
        "provenance.get('generator') == 'CARGame RT3D-002 native slice visual polish v2'",
        "provenance.get('generator') == 'CARGame RT3D-002 native slice visual expansion v3'",
    )
    text = replace_once(text, "require('visual polish v2' in generator, 'generator must identify the visible polish revision')",
                        "require('visual expansion v3' in generator, 'generator must identify the visible expansion revision')\n    require('RT3D2-T081..T110' in generator, 'generator must identify the 30-task visual checkpoint')")
    text = replace_once(text, "print('RT3D NATIVE SLICE VALIDATION PASSED')",
                        "print('RT3D NATIVE VISUAL EXPANSION VALIDATION PASSED')")
    VERIFIER.write_text(text, encoding='utf-8')


def write_workdoc(digest: str, byte_length: int, node_count: int, material_count: int) -> None:
    lines = [
        '# RT3D-002 — Native Filament visual expansion 30', '', 'Issue: #222  ',
        'Priority: P0 VISUAL DELIVERY  ', 'Checkpoint: RT3D2-T081 through RT3D2-T110  ',
        'Branch: `agent/rt3d-002-visual-expansion-30`', '', '## Goal', '',
        'Deliver 30 owner-visible improvements in the actual Native Filament scene. No numbered task is documentation-only; every task adds geometry/material detail that must be visible through `Home -> 3D -> 3D VISUAL LAB` in the retained root APK before handoff is complete.', '',
        '## 30 visual tasks', '',
    ]
    lines.extend(f'- [x] {task_id}: {description}' for task_id, description in TASKS)
    lines.extend([
        '', '## Asset/result contract', '',
        '- Project-owned deterministic GLB revision: `visual expansion v3`.',
        f'- Expected GLB SHA-256: `{digest}`.',
        f'- Expected GLB byte length: `{byte_length}`.',
        f'- Generator output: {node_count} visible nodes and {material_count} PBR material/mesh variants.',
        '- Stable gameplay entity IDs remain unchanged (`cargo.demo.*`, `delivery.*`, `vehicle.player`).',
        '- Google Filament 1.74.0 and the current Android PlatformView bridge remain unchanged.',
        '- No third-party model content is introduced.', '',
        '## Owner-visible result', '',
        'The scene should read as a small toy delivery district rather than a sparse yard: two work buildings, sidewalks, zebra crossings, parking, safety props, a checkpoint, street furniture/landscaping, more vehicle detail, and clearer target zones.', '',
        '## Handoff boundary', '',
        'Source/PR CI is not enough. Completion requires: PR gates -> merge -> exact-main Flutter CI -> governed `Last verified APK` promotion -> `LATEST.txt` source SHA matches the merged visual-expansion commit. Physical-device FPS remains separate evidence and is not invented here.',
    ])
    WORKDOC.parent.mkdir(parents=True, exist_ok=True)
    WORKDOC.write_text('\n'.join(lines) + '\n', encoding='utf-8')


def main() -> int:
    patch_generator()
    digest, byte_length, node_count, material_count = generate_and_pin()
    if node_count < 120 or material_count < 25:
        raise RuntimeError(f'visual expansion below contract: nodes={node_count}, materials={material_count}')
    patch_provenance(digest, byte_length)
    patch_verifier(digest)
    write_workdoc(digest, byte_length, node_count, material_count)
    Path(__file__).unlink()
    if WORKFLOW.exists():
        WORKFLOW.unlink()
    print(f'RT3D2-T081..T110 generated: {node_count} nodes, {material_count} materials, {byte_length} bytes, sha256={digest}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
