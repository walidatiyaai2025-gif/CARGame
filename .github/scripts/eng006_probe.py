from __future__ import annotations

import json
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path.cwd()


def direct_hosted_from_pubspec() -> list[tuple[str, str, str]]:
    lines = Path('pubspec.yaml').read_text(encoding='utf-8').splitlines()
    section = None
    result: list[tuple[str, str, str]] = []
    for line in lines:
        if line == 'dependencies:':
            section = 'main'
            continue
        if line == 'dev_dependencies:':
            section = 'dev'
            continue
        if section and line and not line.startswith(' '):
            section = None
        if section is None or not line.startswith('  ') or line.startswith('    '):
            continue
        stripped = line.strip()
        if not stripped or stripped.startswith('#') or ':' not in stripped:
            continue
        name, value = stripped.split(':', 1)
        value = value.strip().strip("'\"")
        if value:
            result.append((name, section, value))
    return result


def lock_versions() -> dict[str, str]:
    lines = Path('pubspec.lock').read_text(encoding='utf-8').splitlines()
    current = None
    result: dict[str, str] = {}
    for line in lines:
        if line.startswith('  ') and not line.startswith('    ') and line.rstrip().endswith(':'):
            current = line.strip()[:-1]
            continue
        if current and line.startswith('    version:'):
            result[current] = line.split(':', 1)[1].strip().strip('"')
    return result


def package_roots() -> dict[str, Path]:
    config_path = ROOT / '.dart_tool/package_config.json'
    data = json.loads(config_path.read_text(encoding='utf-8'))
    roots: dict[str, Path] = {}
    for package in data['packages']:
        uri = package['rootUri']
        parsed = urlparse(uri)
        if parsed.scheme == 'file':
            root = Path(unquote(parsed.path))
        else:
            root = (config_path.parent / unquote(uri)).resolve()
        roots[package['name']] = root
    return roots


def license_file(root: Path) -> Path | None:
    candidates = [
        'LICENSE',
        'LICENSE.txt',
        'LICENSE.md',
        'LICENCE',
        'LICENCE.txt',
        'COPYING',
        'COPYING.txt',
    ]
    for name in candidates:
        path = root / name
        if path.is_file() and path.stat().st_size > 0:
            return path
    return None


def main() -> None:
    direct = direct_hosted_from_pubspec()
    versions = lock_versions()
    roots = package_roots()

    print('ENG-006 direct hosted dependency/license audit')
    print('=' * 72)
    for name, kind, constraint in direct:
        root = roots.get(name)
        resolved = versions.get(name, '<missing>')
        license_path = license_file(root) if root else None
        print(f'{name} | {kind} | constraint={constraint} | resolved={resolved}')
        if root is None:
            print('  package root: MISSING')
            continue
        print(f'  package root: {root}')
        if license_path is None:
            print('  license: MISSING')
            continue
        text = license_path.read_text(encoding='utf-8', errors='replace')
        non_empty = [line.strip() for line in text.splitlines() if line.strip()]
        print(f'  license file: {license_path.name} ({license_path.stat().st_size} bytes)')
        for line in non_empty[:8]:
            print(f'    {line[:180]}')


if __name__ == '__main__':
    main()
