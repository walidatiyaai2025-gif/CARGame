#!/usr/bin/env python3
from __future__ import annotations

import hashlib
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
        (self.root / "assets/3d/provenance").mkdir(parents=True)
        self.manifest = self.root / "assets/3d/manifest.json"
        self.model = self.root / "assets/3d/runtime/models/scene.glb"
        self.model.write_bytes(b"glTF" + b"x" * 32)
        self._write_manifest([
            {"id": "cargo.future", "path": "assets/3d/runtime/cargo/special/future.webp"},
            {"id": "ui.future", "path": "assets/3d/runtime/ui/future.webp"},
        ])
        self._write_native_sidecar()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_manifest(self, assets: list[dict[str, object]], schema: int = 1) -> None:
        self.manifest.write_text(json.dumps({"schemaVersion": schema, "assets": assets}), encoding="utf-8")

    def _assets(self) -> list[dict[str, object]]:
        return json.loads(self.manifest.read_text(encoding="utf-8"))["assets"]

    def _write_native_sidecar(self, *, path: str = "assets/3d/runtime/models/scene.glb", size: int | None = None, sha: str | None = None) -> None:
        payload = self.model.read_bytes()
        sidecar = {
            "schemaVersion": 1,
            "assetId": "native.scene",
            "runtimePath": path,
            "format": "glb",
            "byteLength": len(payload) if size is None else size,
            "sha256": hashlib.sha256(payload).hexdigest() if sha is None else sha,
        }
        (self.root / "assets/3d/provenance/scene.json").write_text(json.dumps(sidecar), encoding="utf-8")

    def assertRejected(self, expected: str) -> None:
        with self.assertRaisesRegex(validator.AssetBuildValidationError, expected):
            validator.validate_repo(self.root)

    def test_current_shape_accepts_descriptor_only_entries(self) -> None:
        summary = validator.validate_repo(self.root)
        self.assertEqual(summary["manifest_entries"], 2)
        self.assertEqual(summary["native_sidecars"], 1)
        self.assertEqual(summary["runtime_binaries"], 1)

    def test_rejects_duplicate_ids(self) -> None:
        assets = self._assets(); assets[1]["id"] = assets[0]["id"]; self._write_manifest(assets)
        self.assertRejected("duplicate asset id")

    def test_rejects_duplicate_paths(self) -> None:
        assets = self._assets(); assets[1]["path"] = assets[0]["path"]; self._write_manifest(assets)
        self.assertRejected("duplicate runtime path")

    def test_rejects_path_traversal(self) -> None:
        assets = self._assets(); assets[0]["path"] = "assets/3d/runtime/cargo/../escape.webp"; self._write_manifest(assets)
        self.assertRejected("unsafe runtime path")

    def test_rejects_unsupported_declared_format(self) -> None:
        assets = self._assets(); assets[0]["path"] = "assets/3d/runtime/cargo/future.png"; self._write_manifest(assets)
        self.assertRejected("unsupported runtime format")

    def test_rejects_undeclared_runtime_binary(self) -> None:
        (self.root / "assets/3d/runtime/models/rogue.glb").write_bytes(b"glTF")
        self.assertRejected("undeclared runtime binary")

    def test_rejects_zero_byte_runtime_binary(self) -> None:
        self.model.write_bytes(b"")
        self.assertRejected("zero-byte runtime binary")

    def test_rejects_oversized_runtime_binary(self) -> None:
        with self.model.open("wb") as handle:
            handle.truncate(validator.MAX_BYTES_BY_CLASS["models"] + 1)
        self._write_native_sidecar()
        self.assertRejected("exceeds models budget")

    def test_rejects_unknown_runtime_class(self) -> None:
        assets = self._assets(); assets[0]["path"] = "assets/3d/runtime/mystery/future.webp"; self._write_manifest(assets)
        self.assertRejected("unsupported runtime class")

    def test_rejects_wrong_schema_version(self) -> None:
        self._write_manifest(self._assets(), schema=2)
        self.assertRejected("schemaVersion must be 1")

    def test_rejects_native_size_drift(self) -> None:
        self._write_native_sidecar(size=self.model.stat().st_size + 1)
        self.assertRejected("byteLength mismatch")

    def test_rejects_native_checksum_drift(self) -> None:
        self._write_native_sidecar(sha="0" * 64)
        self.assertRejected("sha256 mismatch")


if __name__ == "__main__":
    unittest.main(verbosity=2)
