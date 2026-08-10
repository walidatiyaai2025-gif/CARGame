#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "FEATURE_CATALOG.md"
STATUS = ROOT / "docs" / "STATUS.md"
WORK = ROOT / "docs" / "work" / "TEST-010.md"

FINAL_HEAD = "a7fd43118ec42852984aaf3f2b4f723534fad6b5"
MERGE_SHA = "d148ac820ee7dcfbacd0f88304a9cf168bc66b41"
PROMOTION_COMMIT = "743356b2a8e66b699feadb09e1c9f5fa60b858a7"
PR_RUN = "31385221550"
MAIN_RUN = "31385904664"
PROMOTION_RUN = "31386487136"
PR_ARTIFACT = "9061656030"
MAIN_ARTIFACT = "9061890276"
PR_DEBUG_SHA = "04a7620731d146aac4aec44f305d895fd21454472e2126cab46e365ea3a4d0e3"
MAIN_DEBUG_SHA = "a2684e4697cf2e153ee75f471cc1bfeaaf0feb15638e43a788984c2bc585b173"
RELEASE_SIZE = "55,878,023"
RELEASE_SHA = "7b24570855c3e3f48007f53eac9770cde3a6a9fe0de519abff35fcb36925383f"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one match, found {count}")
    return text.replace(old, new, 1)


catalog = CATALOG.read_text(encoding="utf-8")
old_row = "| TEST-010 | Dashboard/catalog parser validation | P1 | VERIFIED | ENG-007 | Issue #187 / PR #188 add a dedicated dashboard/catalog parity validator plus 9 focused regressions, strict six-column/feature-ID/priority/status parsing, exact seven-status vocabulary parity, acyclic dependency validation, and hard-coded aggregate rejection. The gate exposed and corrected four circular planning edges without changing runtime behavior. Flutter CI #822 / run `31384332431` passed all 45 workflow steps on `fc560c2668fcf6eef8aded139e13b1aa329a467d`, including TEST-007, TEST-010, formatting, Analyze, full Flutter tests, Debug APK build, artifact security, and upload. Debug artifact #9061312211 is 80,633,603 bytes with SHA-256 `d5d370e02469ba47db3f773e1de88e97293f394df5d904f5f881cf450275028a`. |"
new_row = (
    "| TEST-010 | Dashboard/catalog parser validation | P1 | VERIFIED | ENG-007 | "
    "Issue #187 / PR #188 add a dedicated dashboard/catalog parity validator plus 9 focused regressions, strict six-column/feature-ID/priority/status parsing, exact seven-status vocabulary parity, acyclic dependency validation, and hard-coded aggregate rejection. The gate exposed and corrected four circular planning edges without changing runtime behavior. "
    f"Final clean PR head `{FINAL_HEAD}` passed all 45 Flutter CI steps in #827 / run `{PR_RUN}`; PR #188 squash-merged as `{MERGE_SHA}` and Issue #187 closed completed. Main Flutter CI #828 / run `{MAIN_RUN}` then passed all 45 steps on the exact merge SHA, uploading debug artifact #{MAIN_ARTIFACT} (80,633,607 bytes; SHA-256 `{MAIN_DEBUG_SHA}`). Latest-verified promotion run `{PROMOTION_RUN}` built and security-checked the release-mode QA APK, then committed it as `{PROMOTION_COMMIT}`; `Last verified APK` is {RELEASE_SIZE} bytes with SHA-256 `{RELEASE_SHA}`, ephemeral CI signing, ads disabled, and is not production/Play Store signed. |"
)
catalog = replace_once(catalog, old_row, new_row, "catalog TEST-010 row")
old_recent = "- `TEST-010` Dashboard/catalog parser validation — issue #187 / PR #188 add strict independent dashboard/catalog parsing parity, complete status-vocabulary coverage, cycle rejection, aggregate-drift protection, and blocking pre-restore CI gates. Flutter CI #822 / run `31384332431` passed all 45 steps on `fc560c2668fcf6eef8aded139e13b1aa329a467d`; artifact #9061312211 is 80,633,603 bytes with SHA-256 `d5d370e02469ba47db3f773e1de88e97293f394df5d904f5f881cf450275028a`."
new_recent = (
    "- `TEST-010` Dashboard/catalog parser validation — issue #187 / PR #188 are completed and merged. "
    f"Final clean-head CI #827 / run `{PR_RUN}` and exact-merge main CI #828 / run `{MAIN_RUN}` each passed all 45 steps; main debug artifact #{MAIN_ARTIFACT} is 80,633,607 bytes with SHA-256 `{MAIN_DEBUG_SHA}`. Latest-verified promotion run `{PROMOTION_RUN}` produced the {RELEASE_SIZE}-byte release-mode QA APK with SHA-256 `{RELEASE_SHA}` and committed it as `{PROMOTION_COMMIT}`."
)
catalog = replace_once(catalog, old_recent, new_recent, "catalog recent TEST-010")
CATALOG.write_text(catalog, encoding="utf-8")

status = STATUS.read_text(encoding="utf-8")
status = replace_once(
    status,
    "| Completed checkpoint | `TEST-010` dashboard/catalog parser validation — VERIFIED; Flutter CI #822 / run `31384332431` passed all 45 workflow steps on `fc560c2668fcf6eef8aded139e13b1aa329a467d`, including the dedicated parity validator/regressions, full Flutter suite, Debug APK, artifact security, and upload. |",
    f"| Completed checkpoint | `TEST-010` dashboard/catalog parser validation — VERIFIED and merged; final clean-head Flutter CI #827 / run `{PR_RUN}` passed 45/45 on `{FINAL_HEAD}`, PR #188 squash-merged as `{MERGE_SHA}`, and exact-merge main CI #828 / run `{MAIN_RUN}` also passed 45/45. |",
    "STATUS completed checkpoint",
)
status = replace_once(
    status,
    "| Status | TEST-010 repository-owned acceptance is VERIFIED: the catalog/dashboard contract now enforces strict parser parity, complete status vocabulary, an acyclic dependency graph, and no maintained hard-coded aggregate totals; no game runtime behavior changed. |",
    f"| Status | TEST-010 is VERIFIED on main. Main debug artifact #{MAIN_ARTIFACT} is 80,633,607 bytes (SHA-256 `{MAIN_DEBUG_SHA}`); latest-verified promotion run `{PROMOTION_RUN}` produced and committed the release-mode QA APK ({RELEASE_SIZE} bytes; SHA-256 `{RELEASE_SHA}`) with ephemeral CI signing and ads disabled. No game runtime behavior changed. |",
    "STATUS status",
)
old_section_tail = "- Flutter CI #822 / run `31384332431` passed all 45 workflow steps on implementation head `fc560c2668fcf6eef8aded139e13b1aa329a467d`, including privacy/security/dependency gates, TEST-007, TEST-010, formatting, Analyze, widget/integration tests, full Flutter suite, Debug APK, artifact security, and upload.\n- Debug artifact #9061312211 is 80,633,603 bytes with SHA-256 `d5d370e02469ba47db3f773e1de88e97293f394df5d904f5f881cf450275028a`.\n- No gameplay, economy, persistence, navigation runtime, ads, privacy runtime, signing, production identifiers, packages, or assets changed. Repository-owned TEST-010 acceptance is VERIFIED."
new_section_tail = (
    "- Implementation CI #822 / run `31384332431` passed the initial TEST-010 implementation checkpoint.\n"
    f"- Final clean PR head `{FINAL_HEAD}` passed all 45 steps in Flutter CI #827 / run `{PR_RUN}`; debug artifact #{PR_ARTIFACT} is 80,633,607 bytes with SHA-256 `{PR_DEBUG_SHA}`.\n"
    f"- PR #188 squash-merged as `{MERGE_SHA}`; Issue #187 closed completed. Main Flutter CI #828 / run `{MAIN_RUN}` then passed all 45 steps on the exact merge SHA; main debug artifact #{MAIN_ARTIFACT} is 80,633,607 bytes with SHA-256 `{MAIN_DEBUG_SHA}`.\n"
    f"- Maintain Latest Verified APK run `{PROMOTION_RUN}` passed release input preflight, ephemeral signing, release APK build, packaged-artifact security, current-main verification, and promotion. Commit `{PROMOTION_COMMIT}` updated `Last verified APK`; the QA/installable release-mode APK is {RELEASE_SIZE} bytes with SHA-256 `{RELEASE_SHA}`, runtime ads disabled, and is explicitly not production/Play Store signed.\n"
    "- No gameplay, economy, persistence, navigation runtime, ads, privacy runtime, signing policy, production identifiers, packages, or assets changed. Repository-owned TEST-010 acceptance is VERIFIED and merged."
)
status = replace_once(status, old_section_tail, new_section_tail, "STATUS TEST-010 evidence")
STATUS.write_text(status, encoding="utf-8")

work = WORK.read_text(encoding="utf-8")
old_evidence = "- PR: #188; implementation head: `fc560c2668fcf6eef8aded139e13b1aa329a467d`.\n- Catalog integrity: 19 phases / 192 features; dashboard-equivalent identity matches the authoritative parser; seven dashboard statuses match the catalog vocabulary; dependency graph is acyclic.\n- Focused regressions: existing CI integrity 15/15 PASS; TEST-010 parity regressions 9/9 PASS.\n- Flutter CI #822 / run `31384332431`: all 45 workflow steps PASS, including TEST-007, TEST-010, formatting, Analyze, full Flutter tests, Debug APK build, artifact security and upload.\n- Debug artifact #9061312211: 80,633,603 bytes; SHA-256 `d5d370e02469ba47db3f773e1de88e97293f394df5d904f5f881cf450275028a`.\n- Final merge remains gated on a normal Flutter CI run of the reconciled tracking head."
new_evidence = (
    "- PR: #188; Issue #187 closed completed after squash merge.\n"
    "- Catalog integrity: 19 phases / 192 features; dashboard-equivalent identity matches the authoritative parser; seven dashboard statuses match the catalog vocabulary; dependency graph is acyclic.\n"
    "- Focused regressions: existing CI integrity 15/15 PASS; TEST-010 parity regressions 9/9 PASS.\n"
    "- Implementation checkpoint: Flutter CI #822 / run `31384332431` passed all 45 steps.\n"
    f"- Final clean-head checkpoint: `{FINAL_HEAD}` passed Flutter CI #827 / run `{PR_RUN}` 45/45; debug artifact #{PR_ARTIFACT} is 80,633,607 bytes, SHA-256 `{PR_DEBUG_SHA}`.\n"
    f"- Merge: PR #188 squash-merged as `{MERGE_SHA}`. Exact-merge main Flutter CI #828 / run `{MAIN_RUN}` passed 45/45; debug artifact #{MAIN_ARTIFACT} is 80,633,607 bytes, SHA-256 `{MAIN_DEBUG_SHA}`.\n"
    f"- Latest verified APK promotion: run `{PROMOTION_RUN}` passed release build/security/promotion and committed `{PROMOTION_COMMIT}`. `Last verified APK/CARGame-latest-verified.apk` is {RELEASE_SIZE} bytes with SHA-256 `{RELEASE_SHA}`; ephemeral CI signing, ads disabled, QA/installable evidence only, not production/Play Store signed.\n"
    "- TEST-010 is fully VERIFIED, merged, and reconciled. The next workstream must be selected by a fresh dependency-ready scan."
)
work = replace_once(work, old_evidence, new_evidence, "work verification evidence")
WORK.write_text(work, encoding="utf-8")

print("TEST-010 post-merge evidence reconciled")
