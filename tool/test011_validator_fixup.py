#!/usr/bin/env python3
"""Tighten TEST-011 Settings local-data validation before bootstrap commit."""

from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one fixup anchor, found {count}")
    p.write_text(text.replace(old, new, 1), encoding="utf-8")


def main() -> None:
    replace_once(
        "tool/verify_test_011_privacy_security.py",
        '''    settings_local = _read(root, "test/features/settings/settings_local_data_test.dart")
    for needle in ("export", "delete", "reset"):
        _require(settings_local.lower(), needle, "Settings local-data regression coverage")
''',
        '''    settings_local = _read(root, "test/features/settings/settings_local_data_test.dart")
    for needle, label in (
        ("privacy-export-data-button", "Settings export control regression"),
        ("delete requires confirmation and clears local first-party data", "Settings delete flow regression"),
        ("privacy-delete-cancel-button", "Settings delete cancellation regression"),
        ("privacy-delete-confirm-button", "Settings delete confirmation regression"),
        ("rehydrateCalls", "Settings post-delete rehydration regression"),
    ):
        _require(settings_local, needle, label)
''',
    )

    replace_once(
        "tool/test_test_011_privacy_security.py",
        '''def test_rejects_missing_external_pending_boundary() -> None:
''',
        '''def test_rejects_missing_settings_delete_confirmation_regression() -> None:
    _mutated_failure(
        "test/features/settings/settings_local_data_test.dart",
        "privacy-delete-confirm-button",
        "privacy-delete-confirmation-removed",
        "Settings delete confirmation regression",
    )


def test_rejects_missing_external_pending_boundary() -> None:
''',
    )
    replace_once(
        "tool/test_test_011_privacy_security.py",
        '''        test_rejects_missing_local_delete_regression,
        test_rejects_missing_external_pending_boundary,
''',
        '''        test_rejects_missing_local_delete_regression,
        test_rejects_missing_settings_delete_confirmation_regression,
        test_rejects_missing_external_pending_boundary,
''',
    )


if __name__ == "__main__":
    main()
