#!/usr/bin/env python3
from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected 1 match, found {count}")
    file.write_text(text.replace(old, new, 1), encoding="utf-8")


def main() -> None:
    replace_once(
        "docs/FEATURE_CATALOG.md",
        "| ENG-013 | Crash reporting and non-fatal diagnostics | P1 | PLANNED | ENG-004, PRIV-001 | Release-safe crash/non-fatal capture is privacy-gated, strips sensitive data, and supports symbol/version correlation. |",
        "| ENG-013 | Crash reporting and non-fatal diagnostics | P1 | VERIFIED | ENG-004, PRIV-001 | Issue #177 / PR #178 make `ENABLE_DIAGNOSTICS` an effective local logging gate and add schema-v1 vendor-neutral crash/non-fatal reporting with secret/path redaction, hard payload bounds, and app version/build/environment correlation. `ENABLE_REMOTE_DIAGNOSTICS` defaults false; production uses deny-all runtime privacy and no emitter/SDK/processor/persistence/network path. Flutter CI #796 / run `31342815876` passed privacy/security/dependency/catalog/format/Analyze/focused diagnostics/full Flutter/Debug APK/artifact-security gates; artifact #9046424192 is 80,633,604 bytes with SHA-256 `c724866c8b1eef49bcc084221697db299d604215b00c473145b9aac585431276`. |",
    )
    replace_once(
        "docs/FEATURE_CATALOG.md",
        "## IN PROGRESS\n\n- None.\n\n## NEXT READY\n\n- `ENG-013` Crash reporting and non-fatal diagnostics — P1; `ENG-004` is IMPLEMENTED and `PRIV-001` is VERIFIED. Keep remote crash reporting absent until the feature defines release-safe redaction, privacy/config gating, symbol/version correlation, and processor/disclosure ownership.",
        "## IN PROGRESS\n\n- None.\n\n## NEXT READY\n\n- None pending the post-ENG-013 dependency-ready scan; do not start another primary workstream until PR #178 is merged.",
    )

    status = Path("docs/STATUS.md")
    text = status.read_text(encoding="utf-8")
    old = "| Primary feature | None — `ENG-012` analytics event schema and privacy gating is VERIFIED on PR #176. |\n| Completed checkpoint | `ENG-012` versioned analytics schema and fail-closed privacy gate — VERIFIED after Flutter CI #785 / run `31341159553`. |\n| Status | ENG-012 is VERIFIED: schema v1 and the application analytics boundary are source-controlled, production first-party collection remains disabled by build/runtime gates with no emitter/processor/network path, and UMP advertising consent is not reused. |\n| Previous checkpoint | `ENG-011` developer tooling/documentation — VERIFIED and squash-merged via PR #174 as `52d983dc251d3daf839b468d8065a13e849505db`. |\n| Next recommended feature | `ENG-013` Crash reporting and non-fatal diagnostics — P1; ENG-004 is IMPLEMENTED and PRIV-001 is VERIFIED. |"
    new = "| Primary feature | None — `ENG-013` crash reporting and non-fatal diagnostics is VERIFIED on PR #178 pending merge. |\n| Completed checkpoint | `ENG-013` privacy-gated crash/non-fatal diagnostics boundary — VERIFIED after Flutter CI #796 / run `31342815876`. |\n| Status | ENG-013 is VERIFIED: local diagnostics obey `ENABLE_DIAGNOSTICS`; remote diagnostics defaults off and remains deny-all/no-emitter in production; crash payloads are redacted, bounded, and correlated to version/build/environment without account/device identifiers. |\n| Previous checkpoint | `ENG-012` analytics schema/privacy gate — VERIFIED and squash-merged via PR #176 as `d09f51d24c9ea6fc5e8e75e0bad6632d727ea9e3`. |\n| Next recommended feature | Run the dependency-ready scan after PR #178 merges; keep a single primary workstream. |"
    if text.count(old) != 1:
        raise SystemExit(
            f"docs/STATUS.md: expected current-work block once, found {text.count(old)}"
        )
    text = text.replace(old, new, 1)
    marker = "## ENG-012 analytics schema and privacy gate — 2026-08-10\n"
    if marker not in text:
        raise SystemExit("docs/STATUS.md: ENG-012 marker missing")
    section = """## ENG-013 crash reporting and non-fatal diagnostics — 2026-08-10

- Issue #177 / PR #178 add schema-v1 `CrashReport`/`CrashReportContext` plus vendor-neutral reporting/privacy ports.
- `ENABLE_DIAGNOSTICS` now effectively gates local `AppLogger` initialization, retention, persistence, debug output, runtime broadcasts, and clipboard diagnostics while the error boundary remains installed.
- Flutter, platform, isolate, and explicit non-fatal failures flow through the fail-closed reporting boundary; emitter failures are isolated from startup/gameplay.
- `ENABLE_REMOTE_DIAGNOSTICS` defaults false. Production runtime privacy is deny-all and no remote crash SDK, emitter, processor, queue, persistence, or network upload path is installed.
- Crash payloads are secret/path-redacted and hard-bounded before any future emitter and carry only schema/severity/source/version/build/environment/UTC timestamp correlation.
- `tool/verify_crash_reporting_privacy.py` blocks remote crash SDK/processor drift, network/storage/ads coupling, default-on reporting, missing redaction/bounds, and `pubspec.yaml` version/build correlation drift.
- Flutter CI #796 / run `31342815876` passed all repository gates including Analyze, focused ENG-013 tests, the full Flutter suite, Debug APK build, artifact security, and upload on head `b7a5851aa0ad028746d0b5631c8bec14f9551847`.
- Debug artifact #9046424192 is 80,633,604 bytes with SHA-256 `c724866c8b1eef49bcc084221697db299d604215b00c473145b9aac585431276`.
- Repository-owned ENG-013 acceptance is VERIFIED. Any future remote diagnostics processor remains a separate privacy/security/disclosure decision.

"""
    status.write_text(text.replace(marker, section + marker, 1), encoding="utf-8")

    privacy = Path("docs/PRIVACY_DATA_INVENTORY.md")
    text = privacy.read_text(encoding="utf-8")
    replacements = [
        (
            "`ENABLE_DIAGNOSTICS` also exists in `AppBuildConfig`, but current bootstrap installs the local `AppLogger` unconditionally. Diagnostics remain local-only and redacted; ENG-013 owns any future privacy-gated remote crash/non-fatal reporting and the effective build/runtime diagnostics gate.",
            "`ENABLE_DIAGNOSTICS` now effectively gates local `AppLogger` initialization/retention while the error boundary remains installed. ENG-013 also adds a separate `ENABLE_REMOTE_DIAGNOSTICS=false` eligibility gate and privacy-gated crash/non-fatal contract; production runtime privacy is deny-all and no remote emitter, SDK, processor, persistence queue, or upload path is installed.",
        ),
        (
            "Current gate truth: local logging is installed during bootstrap. `ENABLE_DIAGNOSTICS` is represented in build configuration but is not currently an effective bootstrap gate; this gap is recorded for ENG-013 rather than hidden by the inventory.",
            "Current gate truth: the error boundary remains installed, but `ENABLE_DIAGNOSTICS` controls whether `AppLogger` retains or persists local diagnostics. Remote crash/non-fatal reporting is independently build/privacy gated, redacted, and bounded before any future emitter; current production has deny-all runtime eligibility and no emitter/processor.",
        ),
        (
            "- **ENG-013 — diagnostics gate:** `ENABLE_DIAGNOSTICS` exists but is not currently wired to suppress bootstrap installation of the local logger. Remote crash reporting remains absent.",
            "- No repository-owned ENG-013 diagnostics gap remains. Remote diagnostic upload is intentionally absent; any future processor requires a new privacy/security/disclosure review before enablement.",
        ),
        (
            "`tool/verify_privacy_disclosures.py` additionally requires the local deletion mechanism to remain available, rejects reintroduction of the completed `in-app-data-controls` gap, and verifies the source anchors for `LocalDataController` plus Settings export/delete/confirmation controls.",
            "`tool/verify_crash_reporting_privacy.py` additionally enforces ENG-013: local diagnostics gating is effective, remote diagnostics defaults off, known crash SDKs/processors remain absent, crash payload redaction/bounds are present, production has no emitter, and version/build correlation defaults match `pubspec.yaml`.\n\n`tool/verify_privacy_disclosures.py` additionally requires the local deletion mechanism to remain available, rejects reintroduction of the completed `in-app-data-controls` gap, and verifies the source anchors for `LocalDataController` plus Settings export/delete/confirmation controls.",
        ),
        (
            "This keeps PRIV-001/PRIV-002/PRIV-003/ENG-012 aligned with current source instead of relying on a one-time prose audit.",
            "This keeps PRIV-001/PRIV-002/PRIV-003/ENG-012/ENG-013 aligned with current source instead of relying on a one-time prose audit.",
        ),
        (
            "- ENG-013: effective diagnostics gating and any future privacy-gated remote crash reporting.",
            "- ENG-013: effective local diagnostics gating and a default-off privacy-gated crash/non-fatal reporting boundary are VERIFIED; any future remote processor/emitter remains a separate reviewed privacy/security/disclosure decision.",
        ),
    ]
    for old, new in replacements:
        count = text.count(old)
        if count != 1:
            raise SystemExit(
                "docs/PRIVACY_DATA_INVENTORY.md: expected one match for "
                f"{old[:50]!r}, found {count}"
            )
        text = text.replace(old, new, 1)
    privacy.write_text(text, encoding="utf-8")

    work = Path("docs/work/ENG-013.md")
    text = work.read_text(encoding="utf-8")
    replace_from = "`IN PROGRESS` — add a vendor-neutral crash reporting contract, effective local diagnostics build gate, separate default-off remote diagnostics build/privacy gate, redacted bounded crash payloads, and version/build/environment correlation without introducing a remote processor."
    replace_to = "`VERIFIED` — vendor-neutral crash reporting, effective local diagnostics build gating, default-off remote diagnostics privacy/config gating, bounded redacted payloads, release correlation, machine drift protection, and full repository verification are complete."
    if text.count(replace_from) != 1:
        raise SystemExit("docs/work/ENG-013.md: current checkpoint text drifted")
    text = text.replace(replace_from, replace_to, 1)
    pending = "- Analyze, focused ENG-013 tests, full Flutter suite, Debug APK, and artifact-security verification remain pending on the formatted head."
    evidence = "- Flutter CI #796 / run `31342815876` on formatted implementation head `b7a5851aa0ad028746d0b5631c8bec14f9551847` passed formatting, whitespace, Analyze, focused ENG-013 tests, all existing focused regressions, the full Flutter suite, Debug APK build, artifact security, and upload.\n- Debug artifact #9046424192: 80,633,604 bytes; SHA-256 `c724866c8b1eef49bcc084221697db299d604215b00c473145b9aac585431276`.\n- Repository-owned ENG-013 acceptance is VERIFIED; remote diagnostics remains intentionally disabled with no production emitter/SDK/processor/network path."
    if text.count(pending) != 1:
        raise SystemExit("docs/work/ENG-013.md: pending verification line drifted")
    work.write_text(text.replace(pending, evidence, 1), encoding="utf-8")


if __name__ == "__main__":
    main()
