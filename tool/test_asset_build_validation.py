import json
import tempfile
import unittest
from pathlib import Path

from verify_asset_build import validate_asset_build


def _manifest(path: str = "assets/3d/runtime/ui/item.webp") -> dict:
    return {
        "schemaVersion": 1,
        "assets": [
            {
                "id": "ui.item",
                "path": path,
                "category": "ui",
                "semantics": {"englishConcept": "Item", "localizationKey": "item", "decorative": False},
                "fallback": {"kind": "icon", "token": "inventory_2"},
                "dimensions": {"width": 256, "height": 256},
                "rarity": "common",
                "world": None,
                "profile": "pui",
            }
        ],
    }


class AssetBuildValidationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "assets/3d/runtime/ui").mkdir(parents=True)
        (self.root / "assets/3d").mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_manifest(self, payload: dict) -> None:
        (self.root / "assets/3d/manifest.json").write_text(json.dumps(payload), encoding="utf-8")

    def test_descriptor_only_manifest_is_allowed(self) -> None:
        self.write_manifest(_manifest())
        result = validate_asset_build(self.root)
        self.assertTrue(result.ok, result.errors)
        self.assertEqual(1, result.descriptor_count)
        self.assertEqual(0, result.runtime_file_count)

    def test_declared_non_empty_webp_passes(self) -> None:
        self.write_manifest(_manifest())
        (self.root / "assets/3d/runtime/ui/item.webp").write_bytes(b"RIFF" + b"x" * 64)
        result = validate_asset_build(self.root)
        self.assertTrue(result.ok, result.errors)

    def test_duplicate_id_is_rejected(self) -> None:
        payload = _manifest()
        payload["assets"].append({**payload["assets"][0], "path": "assets/3d/runtime/ui/second.webp"})
        self.write_manifest(payload)
        result = validate_asset_build(self.root)
        self.assertTrue(any("duplicate asset id" in error for error in result.errors))

    def test_undeclared_runtime_binary_is_rejected(self) -> None:
        self.write_manifest(_manifest())
        (self.root / "assets/3d/runtime/ui/orphan.webp").write_bytes(b"data")
        result = validate_asset_build(self.root)
        self.assertTrue(any("undeclared runtime binary" in error for error in result.errors))

    def test_zero_byte_runtime_binary_is_rejected(self) -> None:
        self.write_manifest(_manifest())
        (self.root / "assets/3d/runtime/ui/item.webp").write_bytes(b"")
        result = validate_asset_build(self.root)
        self.assertTrue(any("zero-byte runtime binary" in error for error in result.errors))

    def test_unsupported_format_is_rejected(self) -> None:
        self.write_manifest(_manifest("assets/3d/runtime/ui/item.png"))
        result = validate_asset_build(self.root)
        self.assertTrue(any("unsupported manifest runtime format" in error for error in result.errors))

    def test_path_traversal_is_rejected(self) -> None:
        self.write_manifest(_manifest("assets/3d/runtime/../secret.webp"))
        result = validate_asset_build(self.root)
        self.assertTrue(any("traversal" in error for error in result.errors))

    def test_oversized_webp_is_rejected(self) -> None:
        self.write_manifest(_manifest())
        (self.root / "assets/3d/runtime/ui/item.webp").write_bytes(b"x" * (2 * 1024 * 1024 + 1))
        result = validate_asset_build(self.root)
        self.assertTrue(any("exceeds" in error for error in result.errors))


if __name__ == "__main__":
    unittest.main()
