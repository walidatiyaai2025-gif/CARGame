#!/usr/bin/env python3
from pathlib import Path
import re
import sys


REQUIRED_FILES = (
    'lib/core/domain/realtime_3d/renderer_admission.dart',
    'lib/core/domain/realtime_3d/production_scene_slice.dart',
    'test/core/domain/realtime_3d_renderer_admission_test.dart',
    'test/core/domain/realtime_3d_production_scene_slice_test.dart',
    'docs/work/RT3D-002.md',
    '.github/workflows/flutter_ci.yml',
    'android/app/build.gradle.kts',
)


def _read(root: Path, relative: str) -> str:
    return (root / relative).read_text(encoding='utf-8')


def verify(root: Path) -> list[str]:
    errors: list[str] = []
    for relative in REQUIRED_FILES:
        if not (root / relative).is_file():
            errors.append(f'missing required RT3D-002 file: {relative}')
    if errors:
        return errors

    renderer = _read(
        root,
        'lib/core/domain/realtime_3d/renderer_admission.dart',
    )
    for marker in (
        'enum Realtime3dRendererKind { nativeGpu, webView, projectedFallback }',
        'Realtime3dRendererCapability.localGlb',
        'Realtime3dRendererCapability.pbrMaterials',
        'Realtime3dRendererCapability.shadows',
        'Realtime3dRendererCapability.objectPicking',
        'Realtime3dRendererCapability.mutableTransforms',
        'Realtime3dRendererCapability.cameraControl',
        'Realtime3dRendererCapability.stableFlutterCompatible',
        'candidate.kind != Realtime3dRendererKind.nativeGpu',
        'requiredAndroidMinSdk > projectAndroidMinSdk',
    ):
        if marker not in renderer:
            errors.append(f'renderer admission contract missing marker: {marker}')

    scene = _read(
        root,
        'lib/core/domain/realtime_3d/production_scene_slice.dart',
    )
    for marker in (
        "path.startsWith('assets/3d/runtime/models/')",
        'Realtime3dModelFormat.glb',
        'Realtime3dModelFormat.gltf',
        'Realtime3dSceneRole.vehicle',
        'Realtime3dSceneRole.cargo',
        'Realtime3dSceneRole.environment',
        'Realtime3dSceneRole.deliveryTarget',
        'Realtime3dSceneRole.ground',
        'Realtime3dSceneRole.road',
        'production slice requires at least two cargo nodes',
        'asset provenance is required',
        'maxTriangles: 250000',
        'maxDrawCalls: 120',
        'maxTextureMegabytes: 96',
    ):
        if marker not in scene:
            errors.append(f'production scene contract missing marker: {marker}')

    gradle = _read(root, 'android/app/build.gradle.kts')
    if 'minSdk = 23' not in gradle:
        errors.append('Android project minSdk drifted from RT3D-002 admission baseline')

    workflow = _read(root, '.github/workflows/flutter_ci.yml')
    for marker in (
        'Verify RT3D-002 production 3D contract',
        'python3 tool/verify_rt3d_002.py',
        'Test RT3D-002 contract validator',
        'python3 tool/test_rt3d_002.py',
        'Test RT3D-002 domain contracts',
        'test/core/domain/realtime_3d_renderer_admission_test.dart',
        'test/core/domain/realtime_3d_production_scene_slice_test.dart',
    ):
        if marker not in workflow:
            errors.append(f'Flutter CI missing RT3D-002 gate: {marker}')

    work = _read(root, 'docs/work/RT3D-002.md')
    task_ids = re.findall(r'^- \[x\] (RT3D2-T\d{3}):', work, re.MULTILINE)
    if len(task_ids) != 30:
        errors.append(
            f'RT3D-002 work ledger must contain exactly 30 completed tasks; found {len(task_ids)}',
        )
    if len(set(task_ids)) != len(task_ids):
        errors.append('RT3D-002 work ledger contains duplicate task IDs')
    expected = [f'RT3D2-T{index:03d}' for index in range(1, 31)]
    if task_ids != expected:
        errors.append('RT3D-002 work ledger task IDs must be contiguous T001..T030')

    for marker in (
        'No native renderer package is claimed as admitted in this checkpoint.',
        'No production GLB/GLTF binary is claimed as admitted in this checkpoint.',
        'RT3D-002 remains IN PROGRESS after this 30-task checkpoint.',
    ):
        if marker not in work:
            errors.append(f'RT3D-002 truth boundary missing from work ledger: {marker}')

    return errors


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    errors = verify(root)
    if errors:
        for error in errors:
            print(f'RT3D-002 ERROR: {error}')
        return 1
    print('RT3D-002 PRODUCTION 3D CONTRACT PASSED')
    return 0


if __name__ == '__main__':
    sys.exit(main())
