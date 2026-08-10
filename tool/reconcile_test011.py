#!/usr/bin/env python3
"""One-shot TEST-011 post-merge tracking reconciliation."""

from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one anchor, found {count}: {old[:120]!r}")
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
        "| TEST-011 |",
        "| TEST-011 | Privacy, consent, and security verification | P0 | IMPLEMENTED | PRIV-001, SEC-001 | Issue #202 / PR #203 complete the 100-checkpoint repository-owned privacy, consent, and security sprint: UMP/ad-request fail-closed contracts, local export/deletion, analytics/diagnostics privacy, redaction, secret/dependency/network-policy checks, packaged APK security, a dedicated evidence matrix, 17 mutation-tested validator regressions, and a focused 38-test Flutter matrix. Final PR head `d07dc2a1b84f5f949cf1cf5925b8348c581cb27b` passed Flutter CI #856 / run `31440184413`: 345 Flutter tests, 88.22% authored-source coverage, Debug APK security/upload, artifact #9082737774 (80,650,503 bytes; artifact ZIP SHA-256 `f2e73219019f78fa16f67f56a0cd551ab822f2d2cad52b301b6eddc834800cb7`). PR #203 squash-merged as `eb3f4df464173dab6729bfb6ed4ccf7289747057`; exact-main Flutter CI #857 / run `31440863970` passed all 60 gates and uploaded artifact #9082985280 (80,650,506 bytes; artifact ZIP SHA-256 `30024ca046038fb7c9ed3b1425d72366830750389bb011a65b4a3b86648ad3ca`). Source-controlled acceptance is IMPLEMENTED, not VERIFIED: production AdMob Privacy & messaging/UMP regulated-region/device evidence remains explicitly PENDING. |",
    )
    replace_once(
        catalog,
        "- `TEST-011` Privacy, consent, and security verification — IN PROGRESS under issue #202 on `agent/test-011-privacy-security-verification`; it is the only primary source-controlled workstream.",
        "- None. `TEST-011` completed its 100/100 source-controlled sprint as IMPLEMENTED; exactly one next workstream may start after the recorded dependency-ready selection.",
    )
    replace_once(
        catalog,
        "- Complete TEST-011 repository-owned privacy/consent/security evidence and CI gates, merge as IMPLEMENTED if green, and keep VERIFIED blocked until real production UMP regulated-region/device evidence exists.",
        "- `UI3D-007` Reduced motion and low-performance visual mode — P1 and dependency-ready via MOT-001. It is the selected next source-controlled workstream but is not started. Start from current `main`; stale `agent/ui3d-007-world-map-refresh` is 45 commits behind and reference-only.",
    )
    replace_once(
        catalog,
        "- `TEST-011` source-controlled verification is active under issue #202; its final VERIFIED transition remains externally blocked on production Google UMP/privacy-message regulated-region/device evidence.",
        "- `TEST-011` is IMPLEMENTED after its 100/100 repository sprint; final VERIFIED transition remains externally blocked on production Google UMP/privacy-message regulated-region/device evidence.",
    )
    marker = "## Recently implemented\n\n"
    p = Path(catalog)
    text = p.read_text(encoding="utf-8")
    entry = "- `TEST-011` Privacy, consent, and security verification — issue #202 / PR #203 complete 100/100 repository-owned checkpoints. Final PR CI #856 / run `31440184413` passed 17/17 validator mutations, the 38-test focused privacy/consent/security matrix, 345 Flutter tests, 88.22% coverage, Debug APK security and upload; artifact #9082737774 is 80,650,503 bytes with artifact ZIP SHA-256 `f2e73219019f78fa16f67f56a0cd551ab822f2d2cad52b301b6eddc834800cb7`. PR #203 merged as `eb3f4df464173dab6729bfb6ed4ccf7289747057`; exact-main CI #857 / run `31440863970` passed all 60 gates and uploaded artifact #9082985280 (80,650,506 bytes; artifact ZIP SHA-256 `30024ca046038fb7c9ed3b1425d72366830750389bb011a65b4a3b86648ad3ca`). External production UMP/privacy-message regulated-region/device evidence remains PENDING, so status is intentionally IMPLEMENTED rather than VERIFIED.\n"
    if entry not in text:
        if text.count(marker) != 1:
            raise SystemExit("FEATURE_CATALOG Recently implemented anchor missing/duplicated")
        p.write_text(text.replace(marker, marker + entry, 1), encoding="utf-8")

    status = "docs/STATUS.md"
    replace_line(
        status,
        "| Primary feature |",
        "| Primary feature | None — `TEST-011` completed 100/100 source-controlled checkpoints as IMPLEMENTED; `UI3D-007` is selected next but not started. |",
    )
    replace_line(
        status,
        "| Completed checkpoint |",
        "| Completed checkpoint | `TEST-011` privacy, consent, and security verification — IMPLEMENTED; issue #202 / PR #203 completed 100/100 repository checkpoints, PR #203 merged as `eb3f4df464173dab6729bfb6ed4ccf7289747057`, and exact-main Flutter CI #857 / run `31440863970` passed all 60 gates. |",
    )
    replace_line(
        status,
        "| Status |",
        "| Status | TEST-011 repository-owned acceptance is IMPLEMENTED: 17/17 mutation regressions, 38 focused privacy/consent/security tests, 345 full-suite tests, 88.22% authored-source coverage, Debug APK build/security/upload, and exact-main verification are green. External production UMP/privacy-message regulated-region/device evidence remains PENDING, so VERIFIED is intentionally blocked. |",
    )
    replace_line(
        status,
        "| Previous checkpoint |",
        "| Previous checkpoint | `PERF-002` memory and image budget — IMPLEMENTED with final PR CI #852, merged-runtime CI #853, and exact-main CI #854; physical-device RSS/GPU residency remains unclaimed. |",
    )
    replace_line(
        status,
        "| Next recommended feature |",
        "| Next recommended feature | `UI3D-007` Reduced motion and low-performance visual mode — P1, dependency-ready via MOT-001. Start fresh from current `main`; stale `agent/ui3d-007-world-map-refresh` is reference-only. |",
    )
    replace_line(
        status,
        "| Known blocker |",
        "| Known blocker | `TEST-011` VERIFIED still requires real production AdMob Privacy & messaging/UMP regulated-region/device evidence. `TEST-009` remains blocked on PERF-001 physical-device frame profiling. `REL-007`/`REL-008` require real production AdMob/signing inputs and a production-signed candidate; final install/upgrade/device smoke requires an Android device/testing track. |",
    )
    p = Path(status)
    text = p.read_text(encoding="utf-8")
    start = text.find("## TEST-011 privacy consent and security verification — 2026-08-11\n")
    end = text.find("\n## PERF-002 memory and image budget — 2026-08-10\n", start)
    if start < 0 or end < 0:
        raise SystemExit("STATUS TEST-011 section boundary missing")
    final_section = """## TEST-011 privacy consent and security verification — 2026-08-11

- Issue #202 / PR #203 complete the 100-checkpoint source-controlled sprint. Repository status is IMPLEMENTED, not VERIFIED.
- The release contract mechanically protects UMP consent refresh/form handling/live `canRequestAds`, fail-closed Mobile Ads initialization and banner/rewarded/interstitial paths, runtime revocation disposal, Settings privacy options, and offline-core availability.
- Local export/deletion, analytics/diagnostics privacy isolation, redaction, tracked-secret checks, dependency advisories, network/trust-boundary parity, and packaged APK security remain blocking CI evidence.
- TEST-011 machine validation passes with 17/17 mutation regressions; the focused Flutter privacy/consent/security matrix passes 38/38.
- Final PR head `d07dc2a1b84f5f949cf1cf5925b8348c581cb27b` passed Flutter CI #856 / run `31440184413`: 345 Flutter tests, 88.22% authored-source coverage, Debug APK, artifact security and upload. Artifact #9082737774 is 80,650,503 bytes with artifact ZIP SHA-256 `f2e73219019f78fa16f67f56a0cd551ab822f2d2cad52b301b6eddc834800cb7`.
- PR #203 squash-merged as `eb3f4df464173dab6729bfb6ed4ccf7289747057`. Exact-main Flutter CI #857 / run `31440863970` passed all 60 gates and uploaded artifact #9082985280 (80,650,506 bytes; artifact ZIP SHA-256 `30024ca046038fb7c9ed3b1425d72366830750389bb011a65b4a3b86648ad3ca`).
- Production AdMob Privacy & messaging/UMP configuration and regulated-region/device observations remain external PENDING evidence. CI success must not promote TEST-011 to VERIFIED.
- Fresh dependency-ready scan found no higher source-controlled P0 that can be completed without external/device evidence. `UI3D-007` is selected next at P1 via MOT-001; its old world-map branch is 45 commits behind and reference-only.
"""
    p.write_text(text[:start] + final_section + text[end:], encoding="utf-8")

    work = "docs/work/TEST-011.md"
    replace_once(work, "- State: IN PROGRESS", "- State: IMPLEMENTED")
    p = Path(work)
    text = p.read_text(encoding="utf-8")
    for number in range(87, 101):
        old = f"- [ ] T{number:03d} "
        new = f"- [x] T{number:03d} "
        if old not in text:
            raise SystemExit(f"TEST-011 T{number:03d} missing/already closed")
        text = text.replace(old, new, 1)
    if "## Final source-controlled completion evidence" not in text:
        text += """

## Final source-controlled completion evidence

- Final PR head `d07dc2a1b84f5f949cf1cf5925b8348c581cb27b` passed Flutter CI #856 / run `31440184413`: formatting/whitespace, Analyze, TEST-011 validator, 17/17 mutation regressions, focused TEST-011 matrix 38/38, full Flutter suite 345/345, authored-source coverage 5,840 / 6,620 = 88.22%, Debug APK build, packaged-artifact security and upload.
- PR artifact #9082737774 is 80,650,503 bytes with artifact ZIP SHA-256 `f2e73219019f78fa16f67f56a0cd551ab822f2d2cad52b301b6eddc834800cb7`.
- PR #203 squash-merged to `main` as `eb3f4df464173dab6729bfb6ed4ccf7289747057`.
- Exact-main Flutter CI #857 / run `31440863970` passed every one of the 60 workflow gates, including TEST-011 validator/mutations/focused matrix, full suite, coverage, Debug APK, artifact security and upload. Main artifact #9082985280 is 80,650,506 bytes with artifact ZIP SHA-256 `30024ca046038fb7c9ed3b1425d72366830750389bb011a65b4a3b86648ad3ca`.
- T001-T100 are complete for the repository-owned sprint. TEST-011 remains IMPLEMENTED because production AdMob Privacy & messaging/UMP regulated-region/device verification is an explicit external evidence boundary and remains PENDING.
- T100 fresh dependency scan selects P1 `UI3D-007` Reduced motion and low-performance visual mode as the next source-controlled workstream. It must start from current `main`; stale `agent/ui3d-007-world-map-refresh` is 45 commits behind and reference-only.
"""
    p.write_text(text, encoding="utf-8")

    evidence = "docs/TEST_011_PRIVACY_SECURITY.md"
    replace_once(evidence, "Repository status: IN PROGRESS", "Repository status: IMPLEMENTED")
    p = Path(evidence)
    text = p.read_text(encoding="utf-8")
    if "## Source-controlled completion evidence" not in text:
        text += """

## Source-controlled completion evidence

- Issue #202 / PR #203 complete all 100 repository-owned checkpoints.
- Final PR head `d07dc2a1b84f5f949cf1cf5925b8348c581cb27b` passed Flutter CI #856 / run `31440184413`: TEST-011 mutation regressions 17/17, focused consent/privacy/security/local-data matrix 38/38, full Flutter suite 345/345, authored-source coverage 88.22%, Debug APK, packaged-artifact security and upload.
- PR artifact #9082737774 is 80,650,503 bytes with artifact ZIP SHA-256 `f2e73219019f78fa16f67f56a0cd551ab822f2d2cad52b301b6eddc834800cb7`.
- PR #203 merged as `eb3f4df464173dab6729bfb6ed4ccf7289747057`; exact-main Flutter CI #857 / run `31440863970` passed all 60 gates and uploaded artifact #9082985280 (80,650,506 bytes; artifact ZIP SHA-256 `30024ca046038fb7c9ed3b1425d72366830750389bb011a65b4a3b86648ad3ca`).
- Repository status is IMPLEMENTED. `External UMP regulated-device verification: PENDING` remains authoritative, so TEST-011 MUST NOT be marked VERIFIED from CI-only evidence.
"""
        p.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
