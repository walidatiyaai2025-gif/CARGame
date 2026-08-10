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
        "| TEST-003 | Core screen widget tests | P1 | PLANNED | UI3D-006 | Home, map, briefing, game, result, and shop pass key sizes/languages. |",
        "| TEST-003 | Core screen widget tests | P1 | IN PROGRESS | UI3D-006 | Issue #179: consolidate the existing Home/World Map/Mission Briefing/Gameplay/Result/Shop responsive coverage into an explicit compact/reference/tablet plus EN/AR widget contract, adding only missing locale/viewport cases and a CI matrix guard. Completing this task unblocks P0 TEST-007. |",
    )
    replace_once(
        "docs/FEATURE_CATALOG.md",
        "## IN PROGRESS\n\n- None.\n\n## NEXT READY\n\n- None pending the post-ENG-013 dependency-ready scan; do not start another primary workstream until PR #178 is merged.",
        "## IN PROGRESS\n\n- `TEST-003` Core screen widget tests — issue #179; close missing real-locale and viewport coverage across Home, World Map, Mission Briefing, Gameplay, Result, and Shop, then add a machine matrix guard.\n\n## NEXT READY\n\n- None while `TEST-003` is the active primary workstream. When VERIFIED, `TEST-007` becomes dependency-ready P0 work because TEST-001 is already VERIFIED.",
    )

    status = Path("docs/STATUS.md")
    text = status.read_text(encoding="utf-8")
    old = "| Primary feature | None — `ENG-013` crash reporting and non-fatal diagnostics is VERIFIED on PR #178 pending merge. |\n| Completed checkpoint | `ENG-013` privacy-gated crash/non-fatal diagnostics boundary — VERIFIED after Flutter CI #796 / run `31342815876`. |\n| Status | ENG-013 is VERIFIED: local diagnostics obey `ENABLE_DIAGNOSTICS`; remote diagnostics defaults off and remains deny-all/no-emitter in production; crash payloads are redacted, bounded, and correlated to version/build/environment without account/device identifiers. |\n| Previous checkpoint | `ENG-012` analytics schema/privacy gate — VERIFIED and squash-merged via PR #176 as `d09f51d24c9ea6fc5e8e75e0bad6632d727ea9e3`. |\n| Next recommended feature | Run the dependency-ready scan after PR #178 merges; keep a single primary workstream. |"
    new = "| Primary feature | `TEST-003` Core screen widget tests — IN PROGRESS under Issue #179. |\n| Completed checkpoint | `ENG-013` privacy-gated crash/non-fatal diagnostics boundary — VERIFIED and squash-merged via PR #178 as `cdf57de2269d8ffb0356ba3ccdfe66dc2bb6e000`; final-head Flutter CI #801 / run `31343310250` was green. |\n| Status | TEST-003 is IN PROGRESS: preserve existing responsive tests, add the missing real Arabic locale/reference/tablet cases across the six critical screens, and enforce the matrix in CI without duplicating TEST-006 golden or TEST-007 E2E scope. |\n| Previous checkpoint | `ENG-013` crash reporting/non-fatal diagnostics — VERIFIED and merged as `cdf57de2269d8ffb0356ba3ccdfe66dc2bb6e000`. |\n| Next recommended feature | Complete TEST-003; once VERIFIED, P0 `TEST-007` becomes dependency-ready because TEST-001 is already VERIFIED. |"
    if text.count(old) != 1:
        raise SystemExit(f"docs/STATUS.md: current work block drifted ({text.count(old)} matches)")
    text = text.replace(old, new, 1)
    marker = "## ENG-013 crash reporting and non-fatal diagnostics — 2026-08-10\n"
    if marker not in text:
        raise SystemExit("docs/STATUS.md: ENG-013 marker missing")
    section = """## TEST-003 core screen widget matrix — 2026-08-10

- Issue #179 / branch `agent/test-003-core-screen-widget-matrix` is the single active primary workstream.
- Existing responsive tests already cover all six required surfaces, but locale/viewport coverage is uneven rather than an explicit release matrix.
- World Map and Mission Briefing already prove compact English, Arabic RTL, and tablet behavior; they will be preserved rather than rewritten.
- Home lacks Arabic locale coverage; Gameplay and Shop currently use manual RTL instead of a real Arabic locale; Result currently proves only the compact English loss state.
- The checkpoint will add only those missing deterministic cases and a machine CI guard requiring the six screen families plus compact/reference/tablet and EN/AR coverage anchors.
- No production UI behavior, assets, network services, golden snapshots, or TEST-007 full E2E flow are in scope.
- VERIFIED TEST-003 will satisfy the final dependency blocking P0 TEST-007.

"""
    status.write_text(text.replace(marker, section + marker, 1), encoding="utf-8")


if __name__ == "__main__":
    main()
