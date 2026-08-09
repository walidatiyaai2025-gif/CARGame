from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import dependency_governance as governance


MIT_LICENSE = """MIT License

Copyright (c) 2026 Example

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction.
"""


class DependencyGovernanceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / 'tool').mkdir(parents=True)
        (self.root / '.dart_tool').mkdir(parents=True)
        self.package_root = self.root / 'packages' / 'foo'
        self.package_root.mkdir(parents=True)
        (self.package_root / 'LICENSE').write_text(MIT_LICENSE, encoding='utf-8')
        self.write_pubspec()
        self.write_lock()
        self.write_package_config()
        self.write_policy()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_pubspec(self, dependency_block: str = '  foo: ^1.2.0\n') -> None:
        (self.root / 'pubspec.yaml').write_text(
            "name: fixture\n"
            "environment:\n"
            "  sdk: '>=3.10.0 <4.0.0'\n"
            "dependencies:\n"
            "  flutter:\n"
            "    sdk: flutter\n"
            f'{dependency_block}'
            "dev_dependencies:\n"
            "  flutter_test:\n"
            "    sdk: flutter\n",
            encoding='utf-8',
        )

    def write_lock(
        self,
        *,
        version: str = '1.2.3',
        source: str = 'hosted',
        url: str = 'https://pub.dev',
        dependency: str = 'direct main',
    ) -> None:
        (self.root / 'pubspec.lock').write_text(
            "packages:\n"
            "  foo:\n"
            f'    dependency: "{dependency}"\n'
            "    description:\n"
            "      name: foo\n"
            "      sha256: deadbeef\n"
            f'      url: "{url}"\n'
            f'    source: {source}\n'
            f'    version: "{version}"\n',
            encoding='utf-8',
        )

    def write_package_config(self) -> None:
        payload = {
            'configVersion': 2,
            'packages': [
                {
                    'name': 'foo',
                    'rootUri': self.package_root.as_uri(),
                    'packageUri': 'lib/',
                    'languageVersion': '3.10',
                }
            ],
        }
        (self.root / '.dart_tool/package_config.json').write_text(
            json.dumps(payload),
            encoding='utf-8',
        )

    def write_policy(
        self,
        *,
        version: str = '1.2.3',
        license_name: str = 'MIT',
        packages: dict[str, object] | None = None,
    ) -> None:
        payload = {
            'schema_version': 1,
            'allowed_licenses': ['MIT', 'BSD-3-Clause', 'Apache-2.0'],
            'packages': packages
            if packages is not None
            else {
                'foo': {
                    'kind': 'main',
                    'reviewed_version': version,
                    'license': license_name,
                }
            },
        }
        (self.root / 'tool/dependency_license_policy.json').write_text(
            json.dumps(payload),
            encoding='utf-8',
        )

    def violations(self) -> list[str]:
        violations, _ = governance.verify_project(self.root)
        return violations

    def test_valid_hosted_dependency_passes(self) -> None:
        violations, inventory = governance.verify_project(self.root)

        self.assertEqual([], violations)
        self.assertEqual('1.2.3', inventory[0]['resolved'])
        self.assertEqual('MIT', inventory[0]['license'])

    def test_git_dependency_is_rejected(self) -> None:
        self.write_pubspec(
            "  foo:\n"
            "    git: https://example.invalid/foo.git\n"
        )

        self.assertTrue(
            any(
                'unapproved direct dependency source `git`' in item
                for item in self.violations()
            )
        )

    def test_custom_host_is_rejected(self) -> None:
        self.write_lock(url='https://packages.example.invalid')

        self.assertTrue(
            any(
                'is not approved `https://pub.dev`' in item
                for item in self.violations()
            )
        )

    def test_lock_version_must_satisfy_constraint(self) -> None:
        self.write_lock(version='2.0.0')
        self.write_policy(version='2.0.0')

        self.assertTrue(any('outside ^1.2.0' in item for item in self.violations()))

    def test_upgrade_requires_license_review(self) -> None:
        self.write_lock(version='1.3.0')

        self.assertTrue(
            any('requires license review' in item for item in self.violations())
        )

    def test_missing_license_is_rejected(self) -> None:
        (self.package_root / 'LICENSE').unlink()

        self.assertTrue(
            any('no non-empty license file' in item for item in self.violations())
        )

    def test_license_family_must_match_review(self) -> None:
        self.write_policy(license_name='Apache-2.0')

        self.assertTrue(
            any('does not match reviewed' in item for item in self.violations())
        )

    def test_dependency_overrides_are_rejected(self) -> None:
        pubspec = (self.root / 'pubspec.yaml').read_text(encoding='utf-8')
        pubspec += (
            "dependency_overrides:\n"
            "  foo: 1.2.3\n"
        )
        (self.root / 'pubspec.yaml').write_text(pubspec, encoding='utf-8')

        self.assertTrue(
            any('dependency_overrides are prohibited' in item for item in self.violations())
        )


if __name__ == '__main__':
    unittest.main(verbosity=2)
