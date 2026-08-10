#!/usr/bin/env python3
"""One-shot TEST-011 branch bootstrap after PERF-002 exact-main verification."""

from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one anchor, found {count}: {old[:110]!r}")
    p.write_text(text.replace(old, new, 1), encoding="utf-8")


def replace_line(path: str, prefix: str, new_line: str) -> None:
    p = Path(path)
    lines = p.read_text(encoding="utf-8").splitlines()
    indexes = [i for i, line in enumerate(lines) if line.startswith(prefix)]
    if len(indexes) != 1:
        raise SystemExit(f"{path}: expected one line starting {prefix!r}, found {len(indexes)}")
    lines[indexes[0]] = new_line
    p.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    catalog = "docs/FEATURE_CATALOG.md"
    replace_line(
        catalog,
        "| PERF-002 |",
        "| PERF-002 | Memory and image budget | P0 | IMPLEMENTED | AST-004 | Issue #199 / PR #200 implement explicit Flutter ImageCache ceilings (96 entries / 48 MiB), a 6 MiB per-image decoded RGBA budget, 1536 px hard decode dimension, 1024 px layout-free precache target, DPR-aware near-display decode sizing, resize-aware AST-004 precache/eviction, focused regressions and CI ownership gates. Final PR head `d8e1fa2d315406173a180b751a7601670dcc484e` passed Flutter CI #852; PR #200 squash-merged as `5298d70218d8e33d766a54813d423bd7de090d16`. Because that squash message inherited historical skip markers, docs-only PR #201 re-ran the complete merged runtime tree in CI #853 and merged as `27ddbe3e9d2e20b32e7b89dfc3f56c6c171153cb`; exact-main Flutter CI #854 then passed every normal gate. Source-controlled acceptance is IMPLEMENTED; physical-device process RSS/GPU residency remains required before VERIFIED. |",
    )
    replace_line(
        catalog,
        "| TEST-011 |",
        "| TEST-011 | Privacy, consent, and security verification | P0 | IN PROGRESS | PRIV-001, SEC-001 | Issue #202 consolidates repository-owned UMP/ad-request gating, local export/deletion, analytics/diagnostics privacy, redaction, secret/dependency/network-policy checks, APK artifact scanning, a dedicated evidence matrix, mutation-tested validator, and normal-CI focused matrix. Production UMP/privacy-message regulated-region/device evidence remains external; CI-only evidence cannot mark this feature VERIFIED. |",
    )
    replace_once(
        catalog,
        "- `PERF-002` Memory and image budget — IN PROGRESS under issue #199 on `agent/perf-002-memory-image-budget`; no other primary source-controlled workstream should start until it is reconciled.",
        "- `TEST-011` Privacy, consent, and security verification — IN PROGRESS under issue #202 on `agent/test-011-privacy-security-verification`; it is the only primary source-controlled workstream.",
    )
    replace_once(
        catalog,
        "- Finish PERF-002 source budgets, focused/full CI, Debug APK and reconciliation; keep TEST-009 blocked on PERF-001 physical-device verification.",
        "- Complete TEST-011 repository-owned privacy/consent/security evidence and CI gates, merge as IMPLEMENTED if green, and keep VERIFIED blocked until real production UMP regulated-region/device evidence exists.",
    )
    replace_once(
        catalog,
        "- `TEST-011` has its declared PRIV-001/SEC-001 prerequisites satisfied, SEC-002 is VERIFIED, and PRIV-003 local export/deletion controls are VERIFIED; final acceptance still requires production Google UMP/privacy-message behavior to be verified in the actual regulated-region/device configuration.",
        "- `TEST-011` source-controlled verification is active under issue #202; its final VERIFIED transition remains externally blocked on production Google UMP/privacy-message regulated-region/device evidence.",
    )

    status = "docs/STATUS.md"
    replace_line(
        status,
        "| Primary feature |",
        "| Primary feature | `TEST-011` Privacy, consent, and security verification — IN PROGRESS under issue #202 on `agent/test-011-privacy-security-verification`. |",
    )
    replace_line(
        status,
        "| Completed checkpoint |",
        "| Completed checkpoint | `PERF-002` memory and image budget — IMPLEMENTED; PR #200 merged as `5298d70218d8e33d766a54813d423bd7de090d16`, full merged-tree retrigger CI #853 passed, PR #201 merged as `27ddbe3e9d2e20b32e7b89dfc3f56c6c171153cb`, and exact-main Flutter CI #854 passed every normal gate. Physical-device RSS/GPU residency remains unclaimed. |",
    )
    replace_line(
        status,
        "| Status |",
        "| Status | TEST-011 is active: repository-owned UMP request gating, local privacy controls, analytics/diagnostics privacy, redaction, secret/dependency/network-policy checks, and APK security are being consolidated into one mutation-tested release contract. CI cannot satisfy the separate production UMP regulated-region/device evidence. |",
    )
    replace_line(
        status,
        "| Next recommended feature |",
        "| Next recommended feature | Finish TEST-011 source-controlled evidence/CI and reconcile as IMPLEMENTED if green; then run a fresh dependency-ready scan. TEST-009 remains blocked on PERF-001 physical-device profiling. |",
    )
    marker = "## PERF-002 memory and image budget — 2026-08-10\n"
    p = Path(status)
    text = p.read_text(encoding="utf-8")
    section = """## TEST-011 privacy consent and security verification — 2026-08-11

- Issue #202 owns a 100-checkpoint P0 verification sprint and is the single active source-controlled workstream.
- Existing Google UMP integration refreshes consent information, handles required forms, exposes live `canRequestAds`, re-opens privacy options from Settings, and keeps first-party analytics consent separate.
- Mobile Ads initialization plus banner/rewarded/interstitial request paths are fail-closed behind current consent eligibility; revocation disposes app-owned loaded ads and UMP failure does not block offline core play.
- Existing PRIV-001/PRIV-002/PRIV-003 and SEC-001/SEC-002 controls cover inventory/Data Safety, local export/deletion, redaction, secrets, dependency advisories, trust boundaries, and packaged-artifact security.
- `docs/TEST_011_PRIVACY_SECURITY.md`, `tool/verify_test_011_privacy_security.py`, and mutation regressions make the combined release assertion executable. Normal Flutter CI also runs a focused consent/privacy/security/local-data matrix.
- Production AdMob Privacy & messaging configuration and regulated-region/device behavior are explicitly external evidence. TEST-011 may become IMPLEMENTED from repository CI but MUST NOT become VERIFIED while that evidence is pending.

"""
    if section.splitlines()[0] not in text:
        if marker not in text:
            raise SystemExit("STATUS PERF-002 section anchor missing")
        p.write_text(text.replace(marker, section + marker, 1), encoding="utf-8")

    perf_work = "docs/work/PERF-002.md"
    replace_once(perf_work, "- State: IN PROGRESS", "- State: IMPLEMENTED")
    replace_once(perf_work, "- [ ] T50 ", "- [x] T50 ")
    p = Path(perf_work)
    text = p.read_text(encoding="utf-8")
    if "## Final source-controlled reconciliation" not in text:
        text += """
## Final source-controlled reconciliation

- Final PR head `d8e1fa2d315406173a180b751a7601670dcc484e` passed Flutter CI #852 and PR #200 squash-merged as `5298d70218d8e33d766a54813d423bd7de090d16`.
- Historical skip markers inherited into that squash message prevented the normal main push workflow. Docs-only PR #201 therefore re-ran the merged runtime tree in Flutter CI #853, which passed all normal gates, and merged as `27ddbe3e9d2e20b32e7b89dfc3f56c6c171153cb` without a skip directive.
- Exact-main Flutter CI #854 passed every normal gate against that main SHA. PERF-002 source-controlled acceptance is IMPLEMENTED. No physical-device process RSS/GPU residency measurement is claimed; issue #199 remains the place for later VERIFIED evidence.
"""
        p.write_text(text, encoding="utf-8")

    ci = ".github/workflows/flutter_ci.yml"
    replace_once(
        ci,
        """      - name: Test PERF-002 memory budget validator
        run: python3 tool/test_memory_image_budget.py

      - name: Restore packages
""",
        """      - name: Test PERF-002 memory budget validator
        run: python3 tool/test_memory_image_budget.py

      - name: Verify TEST-011 privacy consent and security contract
        run: python3 tool/verify_test_011_privacy_security.py

      - name: Test TEST-011 privacy consent and security validator
        run: python3 tool/test_test_011_privacy_security.py

      - name: Restore packages
""",
    )
    replace_once(
        ci,
        """      - name: Test PERF-002 memory and image budget
        run: >-
          flutter test
          test/core/assets/game_image_memory_policy_test.dart
          test/core/assets/game_asset_view_memory_test.dart
          test/core/assets/game_asset_cache_policy_test.dart

      - name: Test core screen widget matrix
""",
        """      - name: Test PERF-002 memory and image budget
        run: >-
          flutter test
          test/core/assets/game_image_memory_policy_test.dart
          test/core/assets/game_asset_view_memory_test.dart
          test/core/assets/game_asset_cache_policy_test.dart

      - name: Test TEST-011 privacy consent and security matrix
        run: >-
          flutter test
          test/core/ads/ad_consent_controller_test.dart
          test/core/ads/ad_request_gate_test.dart
          test/features/settings/settings_privacy_consent_test.dart
          test/core/privacy/local_data_controller_test.dart
          test/features/settings/settings_local_data_test.dart
          test/core/analytics/privacy_gated_analytics_test.dart
          test/core/diagnostics/privacy_gated_crash_reporting_test.dart
          test/core/logging/app_logger_gate_test.dart
          test/core/security/secret_redactor_test.dart

      - name: Test core screen widget matrix
""",
    )

    work = Path("docs/work/TEST-011.md")
    text = work.read_text(encoding="utf-8")
    for number in range(1, 87):
        old = f"- [ ] T{number:03d} "
        new = f"- [x] T{number:03d} "
        if old not in text:
            raise SystemExit(f"TEST-011 checkpoint T{number:03d} missing or already completed")
        text = text.replace(old, new, 1)
    work.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
