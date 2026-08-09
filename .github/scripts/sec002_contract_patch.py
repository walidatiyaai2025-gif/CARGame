from pathlib import Path

verifier_path = Path('tool/verify_ci_integrity.py')
tests_path = Path('tool/test_ci_integrity.py')

text = verifier_path.read_text(encoding='utf-8')
text = text.replace(
    '        "evidence artifact name": "cargame-release-smoke-evidence",\n',
    '        "evidence artifact name": "cargame-release-smoke-evidence",\n'
    '        "enforced release lockfile": "--enforce-lockfile",\n'
    '        "dependency advisory security": "Verify dependency security advisories",\n'
    '        "release artifact security": "Verify release artifact security",\n'
    '        "release artifact scanner": "tool/verify_build_artifact_security.py",\n',
    1,
)
text = text.replace(
    '        "Restore packages",\n        "Verify dependency governance",\n',
    '        "Restore packages",\n'
    '        "Verify dependency security advisories",\n'
    '        "Test security scan policy",\n'
    '        "Verify dependency governance",\n',
    1,
)
text = text.replace(
    '        "Build debug APK",\n        "Upload debug APK",\n',
    '        "Build debug APK",\n'
    '        "Verify debug APK artifact security",\n'
    '        "Upload debug APK",\n',
    1,
)
verifier_path.write_text(text, encoding='utf-8')

tests = tests_path.read_text(encoding='utf-8')
tests = tests.replace(
    '    validate_release_workflow,\n)',
    '    validate_release_workflow,\n    validate_flutter_ci,\n)',
    1,
)
tests = tests.replace(
    'steps:\n  - name: Test release input preflight contract',
    'steps:\n  - name: Restore packages\n    run: flutter pub get --enforce-lockfile\n'
    '  - name: Verify dependency security advisories\n    run: python3 tool/verify_dependency_security.py\n'
    '  - name: Test release input preflight contract',
    1,
)
tests = tests.replace(
    '  - name: Verify release outputs\n',
    '  - name: Verify release artifact security\n'
    '    run: python3 tool/verify_build_artifact_security.py app-release.apk app-release.aab\n'
    '  - name: Verify release outputs\n',
    1,
)
insert = r'''

VALID_FLUTTER_CI = "\n".join(
    f"- name: {step}"
    for step in (
        "Verify dynamic Android targets",
        "Verify secret hygiene",
        "Verify privacy data inventory",
        "Verify security baseline",
        "Restore packages",
        "Verify dependency security advisories",
        "Test security scan policy",
        "Verify dependency governance",
        "Test dependency governance policy",
        "Verify dashboard and release CI contracts",
        "Test dashboard and release CI contracts",
        "Validate 3D asset registry and provenance",
        "Verify changed Dart formatting",
        "Verify whitespace integrity",
        "Analyze",
        "Run full test suite",
        "Build debug APK",
        "Verify debug APK artifact security",
        "Upload debug APK",
    )
)
'''
tests = tests.replace('\n\nclass CatalogContractTests', insert + '\n\nclass CatalogContractTests', 1)
append = r'''

class FlutterCiContractTests(unittest.TestCase):
    def test_valid_flutter_ci_contract_passes(self) -> None:
        validate_flutter_ci(VALID_FLUTTER_CI)

    def test_dependency_security_gate_is_required(self) -> None:
        text = VALID_FLUTTER_CI.replace(
            "- name: Verify dependency security advisories\n", "", 1
        )
        with self.assertRaisesRegex(ContractError, "dependency security advisories"):
            validate_flutter_ci(text)

    def test_artifact_security_gate_is_required(self) -> None:
        text = VALID_FLUTTER_CI.replace(
            "- name: Verify debug APK artifact security\n", "", 1
        )
        with self.assertRaisesRegex(ContractError, "debug APK artifact security"):
            validate_flutter_ci(text)
'''
tests = tests.replace('\n\nif __name__ == "__main__":', append + '\n\nif __name__ == "__main__":', 1)
tests_path.write_text(tests, encoding='utf-8')
