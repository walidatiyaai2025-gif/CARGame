#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from verify_developer_workflows import (
    REQUIRED_PATHS,
    WorkflowError,
    validate_repository,
    validate_texts,
)


def valid_readme() -> str:
    return """# CARGame
START_CARGAME_TOOL.bat
FIRST_TIME_SETUP_AND_RUN.ps1
docs/DEVELOPER_WORKFLOWS.md
RUN_ON_EMULATOR.ps1
REPAIR_ANDROID_BUILD.ps1
OPEN_DEVELOPMENT_DASHBOARD.ps1
VERIFY_RELEASE_INPUTS.ps1
BUILD_RC.ps1
Production advertising and signing values are external inputs and remain outside source control.
The platform projects are already tracked and must be preserved.
Google UMP is already integrated.
"""


def valid_workflow() -> str:
    return """# Developer Workflows
START_CARGAME_TOOL.bat
SETUP_TOOL.ps1
FIRST_TIME_SETUP_AND_RUN.ps1
RUN_ON_EMULATOR.ps1
REPAIR_ANDROID_BUILD.ps1
REPAIR_KOTLIN_CACHE_AND_BUILD.ps1
OPEN_DEVELOPMENT_DASHBOARD.ps1
VERIFY_RELEASE_INPUTS.ps1
BUILD_RC.ps1
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug --no-pub
docs/FEATURE_CATALOG.md
docs/STATUS.md
Production release values are external inputs and remain outside source control.
The platform projects are source-controlled and must be preserved.
Google UMP already owns consent/privacy integration.
"""


class DeveloperWorkflowContractTests(unittest.TestCase):
    def test_valid_text_contract_passes(self) -> None:
        validate_texts(valid_readme(), valid_workflow())

    def test_project_regeneration_is_rejected(self) -> None:
        readme = valid_readme() + "\nflutter create --platforms=android .\n"
        with self.assertRaisesRegex(WorkflowError, "project-regeneration"):
            validate_texts(readme, valid_workflow())

    def test_obsolete_bootstrap_script_is_rejected(self) -> None:
        readme = valid_readme() + "\nRun ./bootstrap.sh first.\n"
        with self.assertRaisesRegex(WorkflowError, "bootstrap.sh"):
            validate_texts(readme, valid_workflow())

    def test_tracked_admob_replacement_is_rejected(self) -> None:
        readme = (
            valid_readme()
            + "\nReplace the test App IDs in AndroidManifest.xml before release.\n"
        )
        with self.assertRaisesRegex(WorkflowError, "AndroidManifest"):
            validate_texts(readme, valid_workflow())

    def test_manual_ump_integration_is_rejected(self) -> None:
        readme = valid_readme() + "\nAdd UMP consent before publishing.\n"
        with self.assertRaisesRegex(WorkflowError, "manual UMP"):
            validate_texts(readme, valid_workflow())

    def test_hardcoded_emulator_serial_is_rejected(self) -> None:
        workflow = valid_workflow() + "\nadb -s emulator-5554 shell getprop\n"
        with self.assertRaisesRegex(WorkflowError, "hard-coded emulator"):
            validate_texts(valid_readme(), workflow)

    def test_direct_release_build_is_rejected(self) -> None:
        workflow = valid_workflow() + "\nflutter build appbundle --release\n"
        with self.assertRaisesRegex(WorkflowError, "unguarded release AAB"):
            validate_texts(valid_readme(), workflow)

    def test_missing_required_release_token_is_rejected(self) -> None:
        workflow = valid_workflow().replace("BUILD_RC.ps1\n", "")
        with self.assertRaisesRegex(WorkflowError, "BUILD_RC.ps1"):
            validate_texts(valid_readme(), workflow)

    def test_repository_requires_all_supported_entry_points(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            for relative in REQUIRED_PATHS:
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("placeholder\n", encoding="utf-8")
            (root / "README.md").write_text(valid_readme(), encoding="utf-8")
            (root / "docs" / "DEVELOPER_WORKFLOWS.md").write_text(
                valid_workflow(), encoding="utf-8"
            )
            (root / "RUN_ON_EMULATOR.ps1").unlink()

            with self.assertRaisesRegex(WorkflowError, "RUN_ON_EMULATOR.ps1"):
                validate_repository(root)

    def test_repository_fixture_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            for relative in REQUIRED_PATHS:
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("placeholder\n", encoding="utf-8")
            (root / "README.md").write_text(valid_readme(), encoding="utf-8")
            (root / "docs" / "DEVELOPER_WORKFLOWS.md").write_text(
                valid_workflow(), encoding="utf-8"
            )

            self.assertEqual(validate_repository(root), len(REQUIRED_PATHS))


if __name__ == "__main__":
    unittest.main(verbosity=2)
