#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GLB = ROOT / 'assets/3d/runtime/models/cargame_native_slice_v1.glb'
PROVENANCE = ROOT / 'assets/3d/provenance/cargame_native_slice_v1.json'
GRADLE = ROOT / 'android/app/build.gradle.kts'
MAIN_ACTIVITY = ROOT / 'android/app/src/main/kotlin/com/walka/cargosort/MainActivity.kt'
NATIVE_VIEW = ROOT / 'android/app/src/main/kotlin/com/walka/cargosort/NativeFilamentSceneView.kt'
FACTORY = ROOT / 'android/app/src/main/kotlin/com/walka/cargosort/NativeFilamentSceneFactory.kt'
DART_ADAPTER = ROOT / 'lib/features/realtime_3d/native_filament_realtime_3d_scene.dart'
SCREEN = ROOT / 'lib/features/realtime_3d/realtime_3d_preview_screen.dart'
PUBSPEC = ROOT / 'pubspec.yaml'
GENERATOR = ROOT / 'tool/generate_rt3d_native_slice_glb.py'

EXPECTED_SHA256 = '766e42dfc52314024771efe432c667e8a38e7d439c5182234d57e43dc4a5cd0b'
REQUIRED_NODES = {
    'vehicle.player',
    'cargo.demo.electronics',
    'cargo.demo.food',
    'environment.warehouse',
    'delivery.electronics',
    'delivery.food',
    'ground.main',
    'road.main',
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def parse_glb(data: bytes) -> dict[str, object]:
    require(len(data) >= 20, 'GLB is too small')
    magic, version, total_length = struct.unpack_from('<4sII', data, 0)
    require(magic == b'glTF', 'GLB magic must be glTF')
    require(version == 2, 'GLB version must be 2')
    require(total_length == len(data), 'GLB header length must match file length')

    json_length, json_type = struct.unpack_from('<I4s', data, 12)
    require(json_type == b'JSON', 'first GLB chunk must be JSON')
    json_start = 20
    json_end = json_start + json_length
    require(json_end <= len(data), 'GLB JSON chunk exceeds file length')
    document = json.loads(data[json_start:json_end].decode('utf-8').rstrip(' '))
    require(document.get('asset', {}).get('version') == '2.0', 'glTF asset version must be 2.0')
    return document


def main() -> int:
    for path in (
        GLB,
        PROVENANCE,
        GRADLE,
        MAIN_ACTIVITY,
        NATIVE_VIEW,
        FACTORY,
        DART_ADAPTER,
        SCREEN,
        PUBSPEC,
        GENERATOR,
    ):
        require(path.is_file(), f'missing required RT3D native-slice file: {path.relative_to(ROOT)}')

    data = GLB.read_bytes()
    require(len(data) <= 1_000_000, 'first native GLB must remain <= 1 MB')
    digest = hashlib.sha256(data).hexdigest()
    require(digest == EXPECTED_SHA256, f'GLB sha256 drift: {digest}')
    document = parse_glb(data)

    nodes = document.get('nodes')
    require(isinstance(nodes, list), 'GLB nodes must be a list')
    node_names = {node.get('name') for node in nodes if isinstance(node, dict)}
    require(REQUIRED_NODES <= node_names, f'missing required scene nodes: {sorted(REQUIRED_NODES - node_names)}')
    require(len([name for name in node_names if isinstance(name, str) and name.startswith('cargo.')]) >= 4,
            'native slice must contain multiple visible cargo nodes')

    meshes = document.get('meshes')
    materials = document.get('materials')
    require(isinstance(meshes, list) and len(meshes) >= 8, 'native GLB must contain real mesh primitives')
    require(isinstance(materials, list) and len(materials) >= 8, 'native GLB must contain PBR materials')
    for material in materials:
        require(isinstance(material, dict) and 'pbrMetallicRoughness' in material,
                'every first-slice material must use glTF PBR metallic-roughness')

    provenance = json.loads(PROVENANCE.read_text(encoding='utf-8'))
    require(provenance.get('runtimePath') == 'assets/3d/runtime/models/cargame_native_slice_v1.glb',
            'provenance runtimePath mismatch')
    require(provenance.get('sha256') == EXPECTED_SHA256, 'provenance sha256 mismatch')
    require(provenance.get('byteLength') == len(data), 'provenance byteLength mismatch')
    require(provenance.get('ownership') == 'project-generated', 'native GLB ownership must be explicit')
    require(provenance.get('source') == 'tool/generate_rt3d_native_slice_glb.py', 'generator provenance mismatch')
    require(set(provenance.get('requiredNodes', [])) == REQUIRED_NODES, 'provenance requiredNodes drift')

    pubspec = PUBSPEC.read_text(encoding='utf-8')
    require('assets/3d/runtime/models/cargame_native_slice_v1.glb' in pubspec,
            'native GLB must be bundled in Flutter assets')
    generator = GENERATOR.read_text(encoding='utf-8')
    require(EXPECTED_SHA256 in generator, 'generator must pin admitted GLB hash')

    gradle = GRADLE.read_text(encoding='utf-8')
    for artifact in ('filament-android', 'gltfio-android', 'filament-utils-android'):
        require(f'com.google.android.filament:{artifact}:1.74.0' in gradle,
                f'{artifact} must be pinned to Filament 1.74.0')
    require('minSdk = 23' in gradle, 'Filament admission must not raise project minSdk 23')

    main_activity = MAIN_ACTIVITY.read_text(encoding='utf-8')
    require('NativeFilamentSceneFactory' in main_activity and 'registerViewFactory' in main_activity,
            'MainActivity must register the native platform view')
    factory = FACTORY.read_text(encoding='utf-8')
    require('PlatformViewFactory' in factory and 'NativeFilamentSceneView' in factory,
            'native platform-view factory contract missing')
    native_view = NATIVE_VIEW.read_text(encoding='utf-8')
    for marker in (
        'ModelViewer',
        'loadModelGlb',
        'getFirstEntityByName',
        'transformManager',
        'Choreographer',
        'camera.lookAt',
        'Google Filament',
        '1.74.0',
    ):
        require(marker in native_view, f'native renderer missing marker: {marker}')

    adapter = DART_ADAPTER.read_text(encoding='utf-8')
    require('implements Realtime3dScenePort' in adapter, 'Dart native adapter must preserve Realtime3dScenePort')
    require("MethodChannel('$viewType/$viewId')" in adapter, 'Dart adapter must bind to per-view method channel')
    screen = SCREEN.read_text(encoding='utf-8')
    require('AndroidView(' in screen, 'Android visual lab must host a native platform view')
    require('NativeFilamentRealtime3dScene.viewType' in screen, 'AndroidView must use the admitted Filament view type')
    require('Realtime3dPreviewPainter(_scene.projectedFallback)' in screen,
            'non-Android projected fallback must remain explicit and isolated')

    print('RT3D NATIVE SLICE VALIDATION PASSED')
    print(f'GLB bytes: {len(data)}')
    print(f'GLB sha256: {digest}')
    print(f'Nodes: {len(nodes)} | Meshes: {len(meshes)} | Materials: {len(materials)}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
