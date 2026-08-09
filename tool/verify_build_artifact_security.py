#!/usr/bin/env python3
"""Scan generated build artifacts for signing material, local secrets, and credentials."""

from __future__ import annotations

import argparse
import os
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath
from typing import Iterable

MAX_TEXT_BYTES = 2 * 1024 * 1024

FORBIDDEN_SUFFIXES = {
    ".jks",
    ".keystore",
    ".p12",
    ".pfx",
    ".pem",
    ".pk8",
}
FORBIDDEN_NAMES = {
    ".env",
    "key.properties",
    "dart-defines.local.json",
    "dart_defines.local.json",
}
TEXT_SUFFIXES = {
    ".txt",
    ".json",
    ".xml",
    ".properties",
    ".yaml",
    ".yml",
    ".html",
    ".js",
    ".css",
    ".gradle",
    ".kts",
    ".md",
}

PRIVATE_KEY_RE = re.compile(
    r"-----BEGIN(?: [A-Z0-9]+)* PRIVATE KEY-----",
    re.IGNORECASE,
)
KNOWN_SECRET_PATTERNS = [
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b"),
    re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{20,}\b"),
]
CREDENTIAL_ASSIGNMENT_RE = re.compile(
    r'''\b(password|passwd|pwd|token|access[_-]?token|refresh[_-]?token|api[_-]?key|apikey|client[_-]?secret|secret)\b\s*[:=]\s*["']?([A-Za-z0-9_./+=-]{16,})''',
    re.IGNORECASE,
)
PLACEHOLDER_FRAGMENTS = {
    "placeholder",
    "example",
    "sample",
    "dummy",
    "redacted",
    "changeme",
    "change-me",
    "your-",
    "your_",
    "not-real",
    "fake",
}


def _normalized_parts(name: str) -> tuple[str, ...]:
    normalized = name.replace("\\", "/")
    return tuple(part.lower() for part in PurePosixPath(normalized).parts if part not in {"", "."})


def forbidden_name_reason(name: str) -> str | None:
    parts = _normalized_parts(name)
    if not parts:
        return None
    base = parts[-1]
    suffix = Path(base).suffix.lower()
    if suffix in FORBIDDEN_SUFFIXES:
        return "signing/private-key file type is forbidden in build artifacts"
    if base in FORBIDDEN_NAMES:
        return "local secret/config file is forbidden in build artifacts"
    if base.startswith(".env.") and base != ".env.example":
        return "environment secret file is forbidden in build artifacts"
    if "secrets" in parts:
        return "secrets directory content is forbidden in build artifacts"
    if base.endswith(".credentials.local.json"):
        return "local credentials file is forbidden in build artifacts"
    return None


def _looks_like_placeholder(value: str) -> bool:
    lowered = value.lower()
    return any(fragment in lowered for fragment in PLACEHOLDER_FRAGMENTS)


def text_violation_reason(text: str) -> str | None:
    if PRIVATE_KEY_RE.search(text):
        return "private-key material detected"
    for pattern in KNOWN_SECRET_PATTERNS:
        if pattern.search(text):
            return "high-confidence credential/token pattern detected"
    assignment = CREDENTIAL_ASSIGNMENT_RE.search(text)
    if assignment is not None and not _looks_like_placeholder(assignment.group(2)):
        return "credential-like assignment detected"
    return None


def _is_text_candidate(name: str, size: int) -> bool:
    if size > MAX_TEXT_BYTES:
        return False
    suffix = Path(PurePosixPath(name).name).suffix.lower()
    return suffix in TEXT_SUFFIXES


def _decode_text(data: bytes) -> str | None:
    if b"\x00" in data[:4096]:
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return None


def scan_zip(path: Path) -> list[str]:
    violations: list[str] = []
    try:
        with zipfile.ZipFile(path) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                reason = forbidden_name_reason(info.filename)
                if reason is not None:
                    violations.append(f"{path}:{info.filename}: {reason}")
                    continue
                if not _is_text_candidate(info.filename, info.file_size):
                    continue
                try:
                    data = archive.read(info)
                except (OSError, RuntimeError, zipfile.BadZipFile) as exc:
                    violations.append(f"{path}:{info.filename}: unable to inspect entry: {exc}")
                    continue
                text = _decode_text(data)
                if text is None:
                    continue
                reason = text_violation_reason(text)
                if reason is not None:
                    violations.append(f"{path}:{info.filename}: {reason}")
    except (OSError, zipfile.BadZipFile) as exc:
        return [f"{path}: invalid or unreadable archive: {exc}"]
    return violations


def scan_plain_file(path: Path, *, display_name: str | None = None) -> list[str]:
    label = display_name or str(path)
    reason = forbidden_name_reason(label)
    if reason is not None:
        return [f"{label}: {reason}"]
    try:
        size = path.stat().st_size
    except OSError as exc:
        return [f"{label}: unable to stat file: {exc}"]
    if not _is_text_candidate(label, size):
        return []
    try:
        data = path.read_bytes()
    except OSError as exc:
        return [f"{label}: unable to inspect file: {exc}"]
    text = _decode_text(data)
    if text is None:
        return []
    reason = text_violation_reason(text)
    return [f"{label}: {reason}"] if reason is not None else []


def scan_path(path: Path) -> list[str]:
    if not path.exists():
        return [f"{path}: artifact path does not exist"]
    if path.is_file():
        if zipfile.is_zipfile(path):
            return scan_zip(path)
        return scan_plain_file(path)

    violations: list[str] = []
    for root, _, files in os.walk(path):
        root_path = Path(root)
        for file_name in files:
            file_path = root_path / file_name
            relative = file_path.relative_to(path).as_posix()
            if zipfile.is_zipfile(file_path):
                violations.extend(scan_zip(file_path))
            else:
                violations.extend(scan_plain_file(file_path, display_name=relative))
    return violations


def verify_paths(paths: Iterable[Path]) -> list[str]:
    violations: list[str] = []
    for path in paths:
        violations.extend(scan_path(path))
    return violations


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args(argv)

    violations = verify_paths(args.paths)
    if violations:
        print("Build artifact security verification failed:", file=sys.stderr)
        for violation in violations:
            print(f" - {violation}", file=sys.stderr)
        return 1

    joined = ", ".join(str(path) for path in args.paths)
    print(f"Build artifact security verification passed: {joined}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
