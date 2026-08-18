#!/usr/bin/env python3
from __future__ import annotations

import tempfile
from pathlib import Path

import verify_rt3d_003 as contract


def expect_marker_failure(text: str, marker: str, source: str) -> None:
    mutated = text.replace(marker, 'RT3D003_MUTATED', 1)
    try:
        contract.require_markers(mutated, (marker,), source)
    except AssertionError as error:
        if marker not in str(error):
            raise AssertionError(f'expected missing marker {marker!r}; got {error!r}') from error
        return
    raise AssertionError(f'validator accepted missing marker: {marker}')


def main() -> None:
    native = contract.NATIVE_VIEW.read_text(encoding='utf-8')
    adapter = contract.DART_ADAPTER.read_text(encoding='utf-8')
    screen = contract.SCREEN.read_text(encoding='utf-8')

    expect_marker_failure(
        native,
        'bloomOptions.apply { enabled = true }',
        'NativeFilamentSceneView',
    )
    expect_marker_failure(native, '"setCameraPreset"', 'NativeFilamentSceneView')
    expect_marker_failure(native, '"fpsEstimate" to fpsEstimate', 'NativeFilamentSceneView')
    expect_marker_failure(adapter, 'Future<void> setCameraPreset', 'Dart Filament adapter')
    expect_marker_failure(screen, "key: const Key('rt3d-camera-presets')", 'RT3D preview HUD')
    expect_marker_failure(screen, 'selected: selected', 'RT3D preview HUD')

    with tempfile.TemporaryDirectory() as directory:
        bad_glb = Path(directory) / 'bad.glb'
        bad_glb.write_bytes(contract.GLB.read_bytes() + b'\x00')
        assert contract.hashlib.sha256(bad_glb.read_bytes()).hexdigest() != contract.EXPECTED_SHA256

    print('RT3D-003 CINEMATIC VALIDATOR MUTATION TESTS PASSED')


if __name__ == '__main__':
    main()
