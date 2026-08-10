#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "FEATURE_CATALOG.md"
STATUS = ROOT / "docs" / "STATUS.md"
WORK = ROOT / "docs" / "work" / "TEST-010.md"

RUN = "Flutter CI #822 / run `31384332431`"
HEAD = "`fc560c2668fcf6eef8aded139e13b1aa329a467d`"
ARTIFACT = "#9061312211"
SIZE = "80,633,603"
DIGEST = "`d5d370e02469ba47db3f773e1de88e97293f394df5d904f5f881cf450275028a`"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one match, found {count}")
    return text.replace(old, new, 1)


catalog = CATALOG.read_text(encoding="utf-8")
old_row = "| TEST-010 | Dashboard/catalog parser validation | P1 | IN PROGRESS | ENG-007 | Issue #187 / branch `agent/test-010-dashboard-catalog-parity` are active. Dedicated parser-parity, dependency-cycle, full-status-vocabulary, and no-hard-coded-aggregate CI contracts are being added on top of the VERIFIED ENG-007 integrity baseline. |"
new_row = (
    "| TEST-010 | Dashboard/catalog parser validation | P1 | VERIFIED | ENG-007 | "
    "Issue #187 / PR #188 add a dedicated dashboard/catalog parity validator plus 9 focused regressions, strict six-column/feature-ID/priority/status parsing, exact seven-status vocabulary parity, acyclic dependency validation, and hard-coded aggregate rejection. The gate exposed and corrected four circular planning edges without changing runtime behavior. "
    f"{RUN} passed all 45 workflow steps on {HEAD}, including TEST-007, TEST-010, formatting, Analyze, full Flutter tests, Debug APK build, artifact security, and upload. Debug artifact {ARTIFACT} is {SIZE} bytes with SHA-256 {DIGEST}. |"
)
catalog = replace_once(catalog, old_row, new_row, "catalog TEST-010 row")
catalog = replace_once(
    catalog,
    "## IN PROGRESS\n\n- `TEST-010` Dashboard/catalog parser validation — issue #187; dedicated parity/regression gate is the sole primary workstream.\n\n## NEXT READY\n\n- None while TEST-010 is IN PROGRESS; preserve TEST-007 and latest-verified-APK gates.",
    "## IN PROGRESS\n\n- None. TEST-010 is VERIFIED; select exactly one next workstream only after a fresh dependency-ready scan.\n\n## NEXT READY\n\n- Run the catalog dependency-ready scan and select exactly one next primary workstream; preserve TEST-007, TEST-010, and latest-verified-APK gates.",
    "catalog active queue",
)
recent = "## Recently verified\n\n"
recent_entry = (
    "- `TEST-010` Dashboard/catalog parser validation — issue #187 / PR #188 add strict independent dashboard/catalog parsing parity, complete status-vocabulary coverage, cycle rejection, aggregate-drift protection, and blocking pre-restore CI gates. "
    f"{RUN} passed all 45 steps on {HEAD}; artifact {ARTIFACT} is {SIZE} bytes with SHA-256 {DIGEST}.\n"
)
catalog = replace_once(catalog, recent, recent + recent_entry, "catalog recently verified")
CATALOG.write_text(catalog, encoding="utf-8")

status = STATUS.read_text(encoding="utf-8")
status = replace_once(
    status,
    "| Primary feature | `TEST-010` Dashboard/catalog parser validation — IN PROGRESS on issue #187 / `agent/test-010-dashboard-catalog-parity`. |",
    "| Primary feature | None — TEST-010 Dashboard/catalog parser validation is VERIFIED; run the dependency-ready scan before starting the next single primary workstream. |",
    "STATUS primary",
)
status = replace_once(
    status,
    "| Completed checkpoint | `TEST-007` critical path — 50/50 release checkpoints VERIFIED; final-head Flutter CI #816 / run `31380502193` passed all gates on `874fe658456723c5f0455e6c1935bd5b9dada8b5`, and PR #184 squash-merged as `b7f858f9cac6c1a8c5b0d1f9058be599f9ce792c`. |",
    f"| Completed checkpoint | `TEST-010` dashboard/catalog parser validation — VERIFIED; {RUN} passed all 45 workflow steps on {HEAD}, including the dedicated parity validator/regressions, full Flutter suite, Debug APK, artifact security, and upload. |",
    "STATUS completed",
)
status = replace_once(
    status,
    "| Status | Dependency-ready scan selected TEST-010 as the next source-contained P1 gate; implementation is adding parser parity, dependency-cycle rejection, complete status-vocabulary coverage, and dashboard aggregate-drift protection without touching runtime behavior. |",
    "| Status | TEST-010 repository-owned acceptance is VERIFIED: the catalog/dashboard contract now enforces strict parser parity, complete status vocabulary, an acyclic dependency graph, and no maintained hard-coded aggregate totals; no game runtime behavior changed. |",
    "STATUS status",
)
status = replace_once(
    status,
    "| Previous checkpoint | `TEST-003` Core screen widget matrix — VERIFIED by CI #803 and squash-merged via PR #180 as `4ca093a843ab685dfeef8df2c86e3950a13f482f`. |",
    "| Previous checkpoint | `TEST-007` critical path — 50/50 release checkpoints VERIFIED; final-head Flutter CI #816 / run `31380502193` passed all gates and PR #184 squash-merged as `b7f858f9cac6c1a8c5b0d1f9058be599f9ce792c`. |",
    "STATUS previous",
)
status = replace_once(
    status,
    "| Next recommended feature | Finish TEST-010 focused validator/regressions, run normal Flutter CI, reconcile evidence, then select the next single dependency-ready workstream. |",
    "| Next recommended feature | Run the catalog dependency-ready scan and select exactly one next primary workstream; preserve the verified TEST-007 and TEST-010 CI gates. |",
    "STATUS next",
)
insert_after = "| Known blocker | `TEST-011` requires real production UMP/privacy-message/regulatory-device verification. `REL-007`/`REL-008` require real production AdMob/signing inputs and a production-signed candidate; final install/upgrade/device smoke requires an Android device or testing track. `TEST-009` also remains dependency-blocked while `PERF-001` is PLANNED. Visual Studio C++ components remain optional for Windows desktop only. |\n\n"
section = (
    "## TEST-010 dashboard/catalog parser validation — 2026-08-10\n\n"
    "- Issue #187 / PR #188 establish a dedicated release-quality parser-parity contract on top of ENG-007 without creating a second feature-catalog source of truth.\n"
    "- `tool/verify_dashboard_catalog.py` independently models dashboard Markdown identity parsing, requires exact A-S phase and feature identity parity, exact seven-status vocabulary coverage, strict parser guards, and runtime fetch/audit/render anchors.\n"
    "- The dependency graph validator rejects missing, self, and strongly connected cyclic dependencies; the first full-catalog run exposed four circular planning edges, which were corrected at NAV-003/RET-008, WORLD-006/MOT-009, REW-008/RET-005, and PERF-007/REL-008 without changing production code.\n"
    "- `tool/test_dashboard_catalog.py` provides 9 focused regressions; the existing CI integrity suite remains 15/15 green. TEST-010 is a blocking normal-CI gate before package restore and preserves TEST-007.\n"
    f"- {RUN} passed all 45 workflow steps on implementation head {HEAD}, including privacy/security/dependency gates, TEST-007, TEST-010, formatting, Analyze, widget/integration tests, full Flutter suite, Debug APK, artifact security, and upload.\n"
    f"- Debug artifact {ARTIFACT} is {SIZE} bytes with SHA-256 {DIGEST}.\n"
    "- No gameplay, economy, persistence, navigation runtime, ads, privacy runtime, signing, production identifiers, packages, or assets changed. Repository-owned TEST-010 acceptance is VERIFIED.\n\n"
)
status = replace_once(status, insert_after, insert_after + section, "STATUS TEST-010 section")
STATUS.write_text(status, encoding="utf-8")

work = WORK.read_text(encoding="utf-8")
work = replace_once(work, "## State\n\nIN PROGRESS", "## State\n\nVERIFIED", "work state")
work = work.replace("- [ ]", "- [x]")
work += (
    "\n## Verification evidence\n\n"
    f"- PR: #188; implementation head: {HEAD}.\n"
    "- Catalog integrity: 19 phases / 192 features; dashboard-equivalent identity matches the authoritative parser; seven dashboard statuses match the catalog vocabulary; dependency graph is acyclic.\n"
    "- Focused regressions: existing CI integrity 15/15 PASS; TEST-010 parity regressions 9/9 PASS.\n"
    f"- {RUN}: all 45 workflow steps PASS, including TEST-007, TEST-010, formatting, Analyze, full Flutter tests, Debug APK build, artifact security and upload.\n"
    f"- Debug artifact {ARTIFACT}: {SIZE} bytes; SHA-256 {DIGEST}.\n"
    "- Final merge remains gated on a normal Flutter CI run of the reconciled tracking head.\n"
)
WORK.write_text(work, encoding="utf-8")

print("Reconciled TEST-010 to VERIFIED using Flutter CI #822 evidence")
