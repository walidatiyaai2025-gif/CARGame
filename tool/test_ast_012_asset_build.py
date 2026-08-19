#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

import verify_ast_012_asset_build as validator


class AssetBuildValidatorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "assets/3d/runtime/models").mkdir(parents=True)
        self.manifest = self.root / "assets/3d/manifest.json"
        self._write_manifest([
            {"id": "model.scene", "path": "assets/3d/runtime/models/scene.glb"},
            {"id": "cargo.future", "path": "assets/3d/runtime/cargo/special/future.webp"},
        ])
        (self.root / "assets/3d/runtime/models/scene.glb").write_bytes(b"glTF" + b"x" * 32)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_manifest(self, assets: list[dict[str, object]], schema: int = 1) -> None:
        self.manifest.write_text(
            json.dumps({"schemaVersion": schema, "assets": assets}),
            encoding="utf-8",
        )

    def _assets(self) -> list[dict[str, object]]:
        return json.loads(self.manifest.read_text(encoding="utf-8"))["assets"]

    def assertRejected(self, expected: str) -> None:
        with self.assertRaisesRegex(validator.AssetBuildValidationError, expected):
            validator.validate_repo(self.root)

    def test_current_shape_accepts_descriptor_only_entries(self) -> None:
        summary = validator.validate_repo(self.root)
        self.assertEqual(summary["manifest_entries"], 2)
        self.assertEqual(summary["runtime_binaries"], 1)

    def test_rejects_duplicate_ids(self) -> None:
        assets = self._assets()
        assets[1]["id"] = assets[0]["id"]
        self._write_manifest(assets)
        self.assertRejected("duplicate asset id")

    def test_rejects_duplicate_paths(self) -> None:
        assets = self._assets()
        assets[1]["path"] = assets[0]["path"]
        self._write_manifest(assets)
        self.assertRejected("duplicate runtime path")

    def test_rejects_path_traversal(self) -> None:
        assets = self._assets()
        assets[0]["path"] = "assets/3d/runtime/models/../escape.glb"
        self._write_manifest(assets)
        self.assertRejected("unsafe runtime path")

    def test_rejects_unsupported_declared_format(self) -> None:
        assets = self._assets()
        assets[1]["path"] = "assets/3d/runtime/cargo/special/future.png"
        self._write_manifest(assets)
        self.assertRejected("unsupported runtime format")

    def test_rejects_undeclared_runtime_binary(self) -> None:
        rogue = self.root / "assets/3d/runtime/models/rogue.glb"
        rogue.write_bytes(b"glTF")
        self.assertRejected("undeclared runtime binary")

    def test_rejects_zero_byte_runtime_binary(self) -> None:
        binary = self.root / "assets/3d/runtime/models/scene.glb"
        binary.write_bytes(b"")
        self.assertRejected("zero-byte runtime binary")

    def test_rejects_oversized_runtime_binary(self) -> None:
        binary = self.root / "assets/3d/runtime/models/scene.glb"
        with binary.open("wb") as handle:
            handle.truncate(validator.MAX_BYTES_BY_CLASS["models"] + 1)
        self.assertRejected("exceeds models budget")

    def test_rejects_unknown_runtime_class(self) -> None:
        assets = self._assets()
        assets[1]["path"] = "assets/3d/runtime/mystery/future.webp"
        self._write_manifest(assets)
        self.assertRejected("unsupported runtime class")

    def test_rejects_wrong_schema_version(self) -> None:
        self._write_manifest(self._assets(), schema=2)
        self.assertRejected("schemaVersion must be 1")


if __name__ == "__main__":
    unittest.main(verbosity=2)
