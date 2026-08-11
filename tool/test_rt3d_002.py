#!/usr/bin/env python3
from pathlib import Path
import shutil
import tempfile

from verify_rt3d_002 import REQUIRED_FILES, verify


ROOT = Path(__file__).resolve().parents[1]


def copy_fixture(destination: Path) -> None:
    for relative in REQUIRED_FILES:
        source = ROOT / relative
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def require_error(errors: list[str], needle: str) -> None:
    if not any(needle in error for error in errors):
        raise AssertionError(f'expected error containing {needle!r}; got {errors!r}')


def run_case(mutator, expected_error: str) -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        copy_fixture(root)
        mutator(root)
        require_error(verify(root), expected_error)


def main() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        copy_fixture(root)
        errors = verify(root)
        if errors:
            raise AssertionError(f'valid RT3D-002 fixture failed: {errors!r}')

    def remove_native_gate(root: Path) -> None:
        path = root / 'lib/core/domain/realtime_3d/renderer_admission.dart'
        text = path.read_text(encoding='utf-8')
        text = text.replace(
            'candidate.kind != Realtime3dRendererKind.nativeGpu',
            'candidate.kind == Realtime3dRendererKind.webView',
        )
        path.write_text(text, encoding='utf-8')

    run_case(remove_native_gate, 'renderer admission contract missing marker')

    def remove_task(root: Path) -> None:
        path = root / 'docs/work/RT3D-002.md'
        lines = path.read_text(encoding='utf-8').splitlines()
        lines = [line for line in lines if 'RT3D2-T030:' not in line]
        path.write_text('\n'.join(lines) + '\n', encoding='utf-8')

    run_case(remove_task, 'exactly 30 completed tasks')

    def drift_min_sdk(root: Path) -> None:
        path = root / 'android/app/build.gradle.kts'
        text = path.read_text(encoding='utf-8').replace('minSdk = 23', 'minSdk = 24')
        path.write_text(text, encoding='utf-8')

    run_case(drift_min_sdk, 'minSdk drifted')

    def remove_ci_gate(root: Path) -> None:
        path = root / '.github/workflows/flutter_ci.yml'
        text = path.read_text(encoding='utf-8').replace(
            'Verify RT3D-002 production 3D contract',
            'Verify production 3D contract',
        )
        path.write_text(text, encoding='utf-8')

    run_case(remove_ci_gate, 'Flutter CI missing RT3D-002 gate')
    print('RT3D-002 VALIDATOR MUTATION TESTS PASSED')


if __name__ == '__main__':
    main()
