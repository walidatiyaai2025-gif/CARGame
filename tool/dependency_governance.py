from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlparse

APPROVED_HOST = 'https://pub.dev'
LICENSE_FILENAMES = (
    'LICENSE',
    'LICENSE.txt',
    'LICENSE.md',
    'LICENCE',
    'LICENCE.txt',
    'COPYING',
    'COPYING.txt',
)
CONSTRAINT_RE = re.compile(
    r'^(?:\^)?\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$'
)


@dataclass(frozen=True)
class DirectDependency:
    name: str
    kind: str
    source: str
    constraint: str | None = None


@dataclass(frozen=True)
class LockPackage:
    name: str
    dependency: str
    source: str
    version: str
    url: str | None


def _strip_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_pubspec(path: Path) -> tuple[list[DirectDependency], list[str]]:
    lines = path.read_text(encoding='utf-8').splitlines()
    section: str | None = None
    dependencies: list[DirectDependency] = []
    overrides: list[str] = []
    index = 0

    while index < len(lines):
        line = lines[index]
        if line == 'dependencies:':
            section = 'main'
            index += 1
            continue
        if line == 'dev_dependencies:':
            section = 'dev'
            index += 1
            continue
        if line == 'dependency_overrides:':
            section = 'override'
            index += 1
            continue
        if section and line and not line.startswith(' '):
            section = None
            continue

        if section and line.startswith('  ') and not line.startswith('    '):
            stripped = line.strip()
            if not stripped or stripped.startswith('#') or ':' not in stripped:
                index += 1
                continue
            name, raw_value = stripped.split(':', 1)
            raw_value = _strip_scalar(raw_value)

            if section == 'override':
                overrides.append(name)
                index += 1
                continue

            if raw_value:
                dependencies.append(
                    DirectDependency(
                        name=name,
                        kind=section,
                        source='hosted',
                        constraint=raw_value,
                    )
                )
                index += 1
                continue

            child_lines: list[str] = []
            probe = index + 1
            while probe < len(lines):
                child = lines[probe]
                if child and not child.startswith(' '):
                    break
                if child.startswith('  ') and not child.startswith('    '):
                    break
                if child.startswith('    '):
                    child_lines.append(child.strip())
                probe += 1

            child_keys = {
                child.split(':', 1)[0]: _strip_scalar(child.split(':', 1)[1])
                for child in child_lines
                if ':' in child
            }
            if 'sdk' in child_keys:
                source = 'sdk'
                constraint = child_keys['sdk']
            elif 'git' in child_keys:
                source = 'git'
                constraint = child_keys.get('version')
            elif 'path' in child_keys:
                source = 'path'
                constraint = child_keys.get('version')
            elif 'hosted' in child_keys:
                source = 'custom-hosted'
                constraint = child_keys.get('version')
            else:
                source = 'unknown-map'
                constraint = child_keys.get('version')

            dependencies.append(
                DirectDependency(
                    name=name,
                    kind=section,
                    source=source,
                    constraint=constraint,
                )
            )
            index = probe
            continue

        index += 1

    return dependencies, overrides


def parse_lockfile(path: Path) -> dict[str, LockPackage]:
    lines = path.read_text(encoding='utf-8').splitlines()
    packages: dict[str, LockPackage] = {}
    current: str | None = None
    dependency = ''
    source = ''
    version = ''
    url: str | None = None

    def flush() -> None:
        nonlocal current, dependency, source, version, url
        if current is not None:
            packages[current] = LockPackage(
                name=current,
                dependency=dependency,
                source=source,
                version=version,
                url=url,
            )
        current = None
        dependency = ''
        source = ''
        version = ''
        url = None

    for line in lines:
        if line.startswith('  ') and not line.startswith('    ') and line.rstrip().endswith(':'):
            flush()
            current = line.strip()[:-1]
            continue
        if current is None:
            continue
        stripped = line.strip()
        if line.startswith('    dependency:'):
            dependency = _strip_scalar(stripped.split(':', 1)[1])
        elif line.startswith('    source:'):
            source = _strip_scalar(stripped.split(':', 1)[1])
        elif line.startswith('    version:'):
            version = _strip_scalar(stripped.split(':', 1)[1])
        elif line.startswith('      url:'):
            url = _strip_scalar(stripped.split(':', 1)[1])
    flush()
    return packages


def _version_tuple(value: str) -> tuple[int, int, int]:
    core = value.split('+', 1)[0].split('-', 1)[0]
    parts = core.split('.')
    if len(parts) != 3 or any(not part.isdigit() for part in parts):
        raise ValueError(f'Unsupported semantic version: {value}')
    return tuple(int(part) for part in parts)  # type: ignore[return-value]


def constraint_allows(constraint: str, version: str) -> bool:
    if not CONSTRAINT_RE.fullmatch(constraint):
        return False
    if constraint.startswith('^'):
        lower = _version_tuple(constraint[1:])
        candidate = _version_tuple(version)
        major, minor, patch = lower
        if major > 0:
            upper = (major + 1, 0, 0)
        elif minor > 0:
            upper = (0, minor + 1, 0)
        else:
            upper = (0, 0, patch + 1)
        return lower <= candidate < upper
    return _version_tuple(constraint) == _version_tuple(version)


def load_license_policy(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text(encoding='utf-8'))
    if data.get('schema_version') != 1:
        raise ValueError('Unsupported dependency license policy schema')
    if not isinstance(data.get('packages'), dict):
        raise ValueError('Dependency license policy must define packages')
    return data


def load_package_roots(path: Path) -> dict[str, Path]:
    data = json.loads(path.read_text(encoding='utf-8'))
    roots: dict[str, Path] = {}
    for package in data.get('packages', []):
        name = package.get('name')
        root_uri = package.get('rootUri')
        if not isinstance(name, str) or not isinstance(root_uri, str):
            continue
        parsed = urlparse(root_uri)
        if parsed.scheme == 'file':
            root = Path(unquote(parsed.path))
        else:
            root = (path.parent / unquote(root_uri)).resolve()
        roots[name] = root
    return roots


def find_license_file(package_root: Path) -> Path | None:
    for filename in LICENSE_FILENAMES:
        candidate = package_root / filename
        if candidate.is_file() and candidate.stat().st_size > 0:
            return candidate
    return None


def detect_license(text: str) -> str | None:
    normalized = text.lower()
    if 'apache license' in normalized and 'version 2.0' in normalized:
        return 'Apache-2.0'
    if (
        ('mit license' in normalized or 'the mit license' in normalized)
        and 'permission is hereby granted' in normalized
    ):
        return 'MIT'
    if (
        'redistribution and use in source and binary forms' in normalized
        and 'neither the name' in normalized
    ):
        return 'BSD-3-Clause'
    return None


def _git_tracks_lockfile(root: Path) -> bool:
    if not (root / '.git').exists():
        return True
    result = subprocess.run(
        ['git', 'ls-files', '--error-unmatch', 'pubspec.lock'],
        cwd=root,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def verify_project(root: Path) -> tuple[list[str], list[dict[str, str]]]:
    violations: list[str] = []
    inventory: list[dict[str, str]] = []

    pubspec = root / 'pubspec.yaml'
    lockfile = root / 'pubspec.lock'
    package_config = root / '.dart_tool/package_config.json'
    policy_path = root / 'tool/dependency_license_policy.json'

    for required in (pubspec, lockfile, package_config, policy_path):
        if not required.is_file():
            violations.append(
                f'Missing required dependency-governance input: {required.relative_to(root)}'
            )
    if violations:
        return violations, inventory

    dependencies, overrides = parse_pubspec(pubspec)
    if overrides:
        violations.append(
            'dependency_overrides are prohibited for production governance: '
            + ', '.join(sorted(overrides))
        )

    hosted = [dependency for dependency in dependencies if dependency.source == 'hosted']
    unsupported = [
        dependency
        for dependency in dependencies
        if dependency.source not in {'hosted', 'sdk'}
    ]
    for dependency in unsupported:
        violations.append(
            f'{dependency.name}: unapproved direct dependency source `{dependency.source}`'
        )

    lock_packages = parse_lockfile(lockfile)
    policy = load_license_policy(policy_path)
    package_policy = policy['packages']
    assert isinstance(package_policy, dict)
    allowed_licenses = set(policy.get('allowed_licenses', []))
    package_roots = load_package_roots(package_config)

    direct_names = {dependency.name for dependency in hosted}
    reviewed_names = set(package_policy.keys())
    missing_review = sorted(direct_names - reviewed_names)
    stale_review = sorted(reviewed_names - direct_names)
    if missing_review:
        violations.append(
            'Direct hosted dependencies missing license review: ' + ', '.join(missing_review)
        )
    if stale_review:
        violations.append(
            'License policy contains stale direct dependencies: ' + ', '.join(stale_review)
        )

    if not _git_tracks_lockfile(root):
        violations.append('pubspec.lock must remain committed for application builds')

    for dependency in hosted:
        constraint = dependency.constraint or ''
        if not CONSTRAINT_RE.fullmatch(constraint):
            violations.append(
                f'{dependency.name}: direct hosted constraint `{constraint}` must be a '
                'caret or exact semantic version'
            )

        locked = lock_packages.get(dependency.name)
        if locked is None:
            violations.append(f'{dependency.name}: missing from pubspec.lock')
            continue

        expected_kind = 'direct main' if dependency.kind == 'main' else 'direct dev'
        if locked.dependency != expected_kind:
            violations.append(
                f'{dependency.name}: lockfile dependency kind `{locked.dependency}` '
                f'does not match `{expected_kind}`'
            )
        if locked.source != 'hosted':
            violations.append(
                f'{dependency.name}: lockfile source `{locked.source}` is not hosted'
            )
        if locked.url != APPROVED_HOST:
            violations.append(
                f'{dependency.name}: hosted source `{locked.url}` is not approved `{APPROVED_HOST}`'
            )
        if constraint and locked.version and not constraint_allows(constraint, locked.version):
            violations.append(
                f'{dependency.name}: locked version {locked.version} is outside {constraint}'
            )

        review = package_policy.get(dependency.name)
        if not isinstance(review, dict):
            continue
        reviewed_kind = review.get('kind')
        reviewed_version = review.get('reviewed_version')
        expected_license = review.get('license')
        if reviewed_kind != dependency.kind:
            violations.append(
                f'{dependency.name}: reviewed kind `{reviewed_kind}` does not match '
                f'`{dependency.kind}`'
            )
        if reviewed_version != locked.version:
            violations.append(
                f'{dependency.name}: locked version {locked.version} requires license review; '
                f'policy currently reviews {reviewed_version}'
            )
        if expected_license not in allowed_licenses:
            violations.append(
                f'{dependency.name}: reviewed license `{expected_license}` is not allowlisted'
            )

        package_root = package_roots.get(dependency.name)
        if package_root is None:
            violations.append(
                f'{dependency.name}: package root missing from .dart_tool/package_config.json'
            )
            continue
        license_path = find_license_file(package_root)
        if license_path is None:
            violations.append(
                f'{dependency.name}: installed package has no non-empty license file'
            )
            continue
        license_text = license_path.read_text(encoding='utf-8', errors='replace')
        detected_license = detect_license(license_text)
        if detected_license is None:
            violations.append(
                f'{dependency.name}: installed license family is not recognized'
            )
        elif detected_license != expected_license:
            violations.append(
                f'{dependency.name}: installed license `{detected_license}` does not match '
                f'reviewed `{expected_license}`'
            )

        inventory.append(
            {
                'package': dependency.name,
                'kind': dependency.kind,
                'constraint': constraint,
                'resolved': locked.version,
                'license': detected_license or 'UNKNOWN',
            }
        )

    return violations, inventory


def print_inventory(inventory: list[dict[str, str]]) -> None:
    if not inventory:
        return
    print('Direct dependency governance inventory:')
    for item in sorted(inventory, key=lambda row: (row['kind'], row['package'])):
        print(
            ' - {package} [{kind}] {constraint} -> {resolved} | {license}'.format(
                **item
            )
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description='Verify CARGame dependency governance.'
    )
    parser.add_argument(
        'command',
        nargs='?',
        default='verify',
        choices=('verify',),
    )
    parser.add_argument('--root', default='.', help='Repository root.')
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    try:
        violations, inventory = verify_project(root)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(
            f'Dependency governance failed to read policy inputs: {error}',
            file=sys.stderr,
        )
        return 1

    print_inventory(inventory)
    if violations:
        print('\nDependency governance violations:', file=sys.stderr)
        for violation in violations:
            print(f' - {violation}', file=sys.stderr)
        return 1

    print('\nDependency governance verification passed.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
