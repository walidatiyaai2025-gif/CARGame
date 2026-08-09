#!/usr/bin/env python3

from __future__ import annotations

import datetime as dt
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import verify_build_artifact_security as artifact
import verify_dependency_security as dependency


class DependencySecurityTests(unittest.TestCase):
    def test_no_advisories_parses_empty(self) -> None:
        self.assertEqual(dependency.parse_advisories("Got dependencies!\n"), [])

    def test_advisory_maps_to_affected_package(self) -> None:
        output = """Resolving dependencies...
http 0.13.0 (affected by advisory: [^0], 1.2.0 available)
Dependencies are affected by security advisories:
  [^0]: https://github.com/advisories/GHSA-4rgh-jx4f-qfcq
"""
        self.assertEqual(
            dependency.parse_advisories(output),
            [dependency.Advisory("GHSA-4RGH-JX4F-QFCQ", "http")],
        )

    def test_unreviewed_advisory_is_rejected(self) -> None:
        violations, stale = dependency.evaluate_advisories(
            [dependency.Advisory("GHSA-AAAA-BBBB-CCCC", "demo")],
            [],
        )
        self.assertEqual(stale, [])
        self.assertIn("no reviewed exception", violations[0])

    def test_scoped_exception_allows_matching_advisory(self) -> None:
        exception = dependency.ExceptionEntry(
            "GHSA-AAAA-BBBB-CCCC",
            "demo",
            "Reviewed and not reachable in this application path.",
            "security-owner",
            dt.date(2099, 1, 1),
        )
        violations, stale = dependency.evaluate_advisories(
            [dependency.Advisory("GHSA-AAAA-BBBB-CCCC", "demo")],
            [exception],
        )
        self.assertEqual(violations, [])
        self.assertEqual(stale, [])

    def test_stale_exception_is_reported(self) -> None:
        exception = dependency.ExceptionEntry(
            "GHSA-AAAA-BBBB-CCCC",
            "demo",
            "Temporary reviewed exception for regression coverage.",
            "security-owner",
            dt.date(2099, 1, 1),
        )
        violations, stale = dependency.evaluate_advisories([], [exception])
        self.assertEqual(violations, [])
        self.assertEqual(stale, ["GHSA-AAAA-BBBB-CCCC"])

    def test_expired_exception_policy_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "policy.json"
            path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "exceptions": [
                            {
                                "id": "GHSA-AAAA-BBBB-CCCC",
                                "package": "demo",
                                "reason": "Temporary reviewed exception for regression coverage.",
                                "owner": "security-owner",
                                "expiresAt": "2026-01-01",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "expired"):
                dependency.load_exceptions(path, today=dt.date(2026, 8, 9))

    def test_pubspec_level_advisory_suppression_is_rejected(self) -> None:
        self.assertTrue(
            dependency.pubspec_has_ignored_advisories(
                "name: demo\nignored_advisories:\n  - GHSA-AAAA-BBBB-CCCC\n"
            )
        )


class ArtifactSecurityTests(unittest.TestCase):
    def _zip(self, entries: dict[str, bytes | str]) -> tuple[tempfile.TemporaryDirectory, Path]:
        temp_dir = tempfile.TemporaryDirectory()
        path = Path(temp_dir.name) / "app-debug.apk"
        with zipfile.ZipFile(path, "w") as archive:
            for name, value in entries.items():
                archive.writestr(name, value)
        return temp_dir, path

    def test_safe_apk_entries_pass(self) -> None:
        temp_dir, path = self._zip(
            {
                "assets/flutter_assets/config.json": '{"mode":"debug"}',
                "META-INF/CERT.RSA": b"\x00\x01expected-signature-container",
            }
        )
        try:
            self.assertEqual(artifact.scan_zip(path), [])
        finally:
            temp_dir.cleanup()

    def test_keystore_entry_is_rejected(self) -> None:
        temp_dir, path = self._zip({"assets/release.jks": b"not-a-real-keystore"})
        try:
            violations = artifact.scan_zip(path)
            self.assertIn("signing/private-key", violations[0])
        finally:
            temp_dir.cleanup()

    def test_private_key_text_is_rejected(self) -> None:
        marker = "-----BEGIN" + " PRIVATE KEY-----"
        temp_dir, path = self._zip({"assets/config.txt": marker})
        try:
            violations = artifact.scan_zip(path)
            self.assertIn("private-key material", violations[0])
        finally:
            temp_dir.cleanup()

    def test_high_confidence_token_is_rejected(self) -> None:
        token = "AKIA" + ("A" * 16)
        temp_dir, path = self._zip({"assets/config.txt": token})
        try:
            violations = artifact.scan_zip(path)
            self.assertIn("credential/token", violations[0])
        finally:
            temp_dir.cleanup()

    def test_placeholder_assignment_is_allowed(self) -> None:
        temp_dir, path = self._zip(
            {"assets/config.properties": "api_key=your-example-placeholder-key"}
        )
        try:
            self.assertEqual(artifact.scan_zip(path), [])
        finally:
            temp_dir.cleanup()

    def test_missing_artifact_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            missing = Path(temp_dir) / "missing.apk"
            self.assertIn("does not exist", artifact.scan_path(missing)[0])


if __name__ == "__main__":
    unittest.main(verbosity=2)
