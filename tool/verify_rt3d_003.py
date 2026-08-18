#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NATIVE_VIEW = ROOT / 'android/app/src/main/kotlin/com/walka/cargosort/NativeFilamentSceneView.kt'
DART_ADAPTER = ROOT / 'lib/features/realtime_3d/native_filament_realtime_3d_scene.dart'
SCREEN = ROOT / 'lib/features/realtime_3d/realtime_3d_preview_screen.dart'
GENERATOR = ROOT / 'tool/generate_rt3d_native_slice_glb.py'
GLB = ROOT / 'assets/3d/runtime/models/cargame_native_slice_v1.glb'
PROVENANCE = ROOT / 'assets/3d/provenance/cargame_native_slice_v1.json'
WORK_RECORD = ROOT / 'docs/work/RT3D-003-refresh.md'

EXPECTED_SHA256 = 'b727b594612452a9a3723aa64423ee5d18a9b90567aba191d9a035bf888de157'
EXPECTED_GENERATOR = 'CARGame RT3D-003 cinematic native slice v3'
CAMERA_PRESETS = ('overview', 'warehouse', 'docks')
EMISSIVE_MATERIALS = (
    'headlight',
    'rearLight',
    'beacon',
    'signalRed',
    'signalAmber',
    'signalGreen',
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_markers(text: str, markers: tuple[str, ...], source: str) -> None:
    for marker in markers:
        require(marker in text, f'{source} missing RT3D-003 marker: {marker}')


def main() -> int:
    for path in (NATIVE_VIEW, DART_ADAPTER, SCREEN, GENERATOR, GLB, PROVENANCE, WORK_RECORD):
        require(path.is_file(), f'missing RT3D-003 file: {path.relative_to(ROOT)}')

    digest = hashlib.sha256(GLB.read_bytes()).hexdigest()
    require(digest == EXPECTED_SHA256, f'RT3D-003 GLB hash drift: {digest}')

    provenance = json.loads(PROVENANCE.read_text(encoding='utf-8'))
    require(provenance.get('sha256') == EXPECTED_SHA256, 'RT3D-003 provenance hash drift')
    require(provenance.get('generator') == EXPECTED_GENERATOR, 'RT3D-003 provenance generator drift')

    generator = GENERATOR.read_text(encoding='utf-8')
    require_markers(
        generator,
        (
            EXPECTED_SHA256,
            EXPECTED_GENERATOR,
            'emissiveFactor',
            'road.arrow.main.shaft',
            'environment.signal.0.red',
            'environment.skyline.0',
            'delivery.electronics.rim.north',
        ),
        'GLB generator',
    )
    for material in EMISSIVE_MATERIALS:
        require(f"('{material}'," in generator, f'generator missing emissive material: {material}')

    native = NATIVE_VIEW.read_text(encoding='utf-8')
    require_markers(
        native,
        (
            'bloomOptions.apply { enabled = true }',
            'activeCameraPreset = "overview"',
            'private fun applyCameraPreset',
            'private fun updateOrbitCamera',
            '"setCameraPreset"',
            '"resetCamera"',
            '"cameraPreset" to activeCameraPreset',
            '"frameCount" to frameCount',
            '"fpsEstimate" to fpsEstimate',
            'lastFrameTimeNanos = 0L',
        ),
        'NativeFilamentSceneView',
    )
    for preset in CAMERA_PRESETS:
        require(f'"{preset}" -> doubleArrayOf' in native, f'native camera preset missing: {preset}')

    adapter = DART_ADAPTER.read_text(encoding='utf-8')
    require_markers(
        adapter,
        (
            'enum NativeFilamentCameraPreset',
            "overview('overview', 'Overview')",
            "warehouse('warehouse', 'Warehouse')",
            "docks('docks', 'Docks')",
            'Future<void> setCameraPreset',
            'Future<void> resetCamera()',
            "_invoke('setCameraPreset'",
            "String get cameraLabel => _cameraPreset?.label ?? 'Custom'",
        ),
        'Dart Filament adapter',
    )

    screen = SCREEN.read_text(encoding='utf-8')
    require_markers(
        screen,
        (
            "Key('rt3d-camera-${preset.wireName}')",
            "key: const Key('rt3d-camera-presets')",
            'Semantics(',
            'selected: selected',
            'Show ${preset.label.toLowerCase()} camera view',
            'Native Filament • GLB • PBR • bloom • ${_scene.cameraLabel}',
        ),
        'RT3D preview HUD',
    )

    work = WORK_RECORD.read_text(encoding='utf-8')
    require(EXPECTED_SHA256 in work, 'RT3D-003 work record must pin the admitted GLB hash')

    print('RT3D-003 CINEMATIC RUNTIME CONTRACT PASSED')
    print(f'GLB sha256: {digest}')
    print('Camera presets: overview, warehouse, docks + custom orbit')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
