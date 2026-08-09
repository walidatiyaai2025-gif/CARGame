from pathlib import Path

MERGE_SHA = "b915d95b938d459133a9a8b120f38815178b1852"
PR_HEAD = "2df14361ec829ae00739aac2e72e6b43cdc0a7e4"
PR_ARTIFACT = "#9032765167 (80,530,583 bytes; SHA-256 `534037a3cdd4fe75d54a53df6452f8188d4c81cdcc859040a51725315f20070b`)"
MAIN_ARTIFACT = "#9032856259 (80,530,585 bytes; SHA-256 `2a57cb7a377eabddde79b79f4ea2159387d6ab6c0799ae0a22bef4e32a767d1b`)"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Missing {label} anchor: {old}")
    return text.replace(old, new, 1)


status_path = Path("docs/STATUS.md")
status = status_path.read_text()
status = replace_once(
    status,
    "| Primary feature | `REW-007` IN PROGRESS — issue #119 / draft PR #120 on `agent/rew-007-reward-ledger`. |",
    f"| Primary feature | `REW-007` VERIFIED — issue #119 / PR #120 merged as `{MERGE_SHA}`; main Flutter CI #624 passed the full gate set. |",
    "STATUS primary feature",
)
status = replace_once(
    status,
    "| Completed checkpoint | `GAME-016` input determinism — PR #111 merged as `093d9a9384aec2d18503284a8edc95ba1ce1ecfb` after Flutter CI #580 passed formatting, Analyze, all 215 Flutter tests, Debug APK build, and artifact upload. |",
    f"| Completed checkpoint | `REW-007` reward transaction ledger/reconciliation — PR #120 merged as `{MERGE_SHA}` after PR CI #623 and main CI #624 passed formatting, Analyze, 226 Flutter tests, Debug APK build, and artifact upload. |",
    "STATUS completed checkpoint",
)
status = replace_once(
    status,
    "| Status | `REW-007` implementation adds an interruption-safe absolute-state reward journal, bounded completed-idempotency ledger, deterministic recovery before load, and stable gameplay-attempt IDs; CI/build verification remains before VERIFIED. |",
    "| Status | `REW-007` is VERIFIED: release-critical level, milestone/world, daily reward, daily mission, and explicit heart grants use stable idempotency/recovery boundaries; completed IDs are persisted before in-memory acknowledgement and pending cleanup is best-effort after durable commit. |",
    "STATUS state",
)
status = replace_once(
    status,
    "| Previous checkpoint | `TEST-004` navigation-race verification — PR #109 merged as `24aa922453f88af507e01e950f7d26048e1c6c3f`; its final current-head verification completed on Flutter CI #574. |",
    "| Previous checkpoint | `ADS-002` release ad configuration — PR #117 merged as `0e2f13329835bfe69c79b985153c65e68ac32bb2`, then reconciliation PR #118 merged as `9adb1cd33ee421ab3afa5469afe6be2ff4029b27`. |",
    "STATUS previous checkpoint",
)
status = replace_once(
    status,
    "| Next recommended feature | Complete `REW-007` CI/build verification and tracking reconciliation; then select the next unblocked RC P0 from the catalog. |",
    "| Next recommended feature | `PRIV-001` privacy inventory, consent, and data minimization — next unblocked RC P0 in the catalog queue; reconcile actual SDK/data flows, purposes, retention, processors, consent, and deletion behavior. |",
    "STATUS next feature",
)

section_anchor = "## ADS-002 release ad configuration verification — 2026-08-09"
if "## REW-007 reward transaction verification — 2026-08-09" not in status:
    section = "\n".join(
        [
            "## REW-007 reward transaction verification — 2026-08-09",
            "",
            "- Issue #119 / PR #120 close the RC reward-integrity gap where multi-key reward persistence could be interrupted into a partial wallet/stat/progression state.",
            "- `ProgressStore` now uses a versioned absolute-state pending reward journal plus a bounded completed-idempotency ledger; recovery runs before normal hydration, legacy saves default safely, and malformed journals are discarded without replaying grants.",
            "- Stable transaction IDs cover gameplay attempts, milestone/world first-clear rewards, daily rewards, daily missions, and explicit heart grants without changing existing reward amounts.",
            "- Durability hardening persists the completed transaction ID before mutating the in-memory ledger and treats pending-journal cleanup as best-effort only after durable completion.",
            f"- PR Flutter CI #623 passed formatting, Analyze, all 226 Flutter tests, Debug APK build and upload on head `{PR_HEAD}`; debug artifact {PR_ARTIFACT}.",
            f"- PR #120 merged to `main` as `{MERGE_SHA}`. Main Flutter CI #624 repeated the full gate set successfully on the merge commit; debug artifact {MAIN_ARTIFACT}.",
            "- `REW-007` is VERIFIED. Next unblocked RC P0 selected from the catalog queue: `PRIV-001` privacy inventory, consent, and data minimization.",
            "",
            "",
        ]
    )
    status = replace_once(status, section_anchor, section + section_anchor, "STATUS section")
status_path.write_text(status)

catalog_path = Path("docs/FEATURE_CATALOG.md")
catalog = catalog_path.read_text()
old_rew = "| REW-007 | Reward transaction ledger and reconciliation | P0 | IN PROGRESS | ENG-008, REW-001 | Issue #119 / PR #120 add stable reason/idempotency keys, a bounded completed ledger, an absolute-state pending journal, and deterministic interruption recovery for level, daily reward, and daily mission grants; full CI/build verification is in progress. |"
new_rew = f"| REW-007 | Reward transaction ledger and reconciliation | P0 | VERIFIED | ENG-008, REW-001 | Issue #119 / PR #120 add stable reason/idempotency keys, a bounded completed ledger, an absolute-state pending journal, deterministic interruption recovery, and explicit heart-grant journaling while preserving reward amounts and legacy saves. Durability hardening persists completed IDs before in-memory acknowledgement and makes post-commit pending cleanup best-effort. PR CI #623 passed 226 Flutter tests plus Debug APK/upload; PR #120 merged as `{MERGE_SHA}`, and main CI #624 repeated all gates successfully. Main debug artifact {MAIN_ARTIFACT}. |"
catalog = replace_once(catalog, old_rew, new_rew, "catalog REW-007 row")
catalog = replace_once(
    catalog,
    "## IN PROGRESS\n\n- None after `GAME-016` verification.",
    "## IN PROGRESS\n\n- None after `REW-007` verification.",
    "catalog active IN PROGRESS",
)
old_next = "\n".join(
    [
        "## NEXT READY",
        "",
        "1. `ENG-010` Secret and credential handling — `ENG-009` is VERIFIED; audit injection, redaction, rotation, and CI protection gaps.",
        "2. `PRIV-001` Privacy inventory, consent, and data minimization — `ENG-001` is VERIFIED and the current privacy inventory gate provides a baseline for reconciliation.",
        "3. `ADS-002` Debug test IDs and release configuration — `ADS-001` and `ENG-009` are implemented/verified; reconcile remaining release-ad configuration evidence.",
    ]
)
new_next = "\n".join(
    [
        "## NEXT READY",
        "",
        "1. `PRIV-001` Privacy inventory, consent, and data minimization — `ENG-001` is VERIFIED and the current privacy inventory gate provides a baseline for reconciling actual SDK/data behavior.",
        "2. `SEC-001` Mobile security baseline and threat model — `ENG-010` is VERIFIED; reconcile trust boundaries, secure-storage/network/tamper risks, and mitigations against the current app.",
        "3. `ECON-005` Versioned economy configuration and balance rules — `ECON-001` is implemented and `REW-007` is VERIFIED; centralize reward/price/source/sink/cap rules without changing live balances.",
    ]
)
catalog = replace_once(catalog, old_next, new_next, "catalog NEXT READY")
recent_anchor = "## Recently verified\n\n"
if "- `REW-007` Reward transaction ledger and reconciliation" not in catalog:
    recent = "\n".join(
        [
            f"- `REW-007` Reward transaction ledger and reconciliation — PR #120 merged as `{MERGE_SHA}` after PR CI #623 and main CI #624 passed formatting, Analyze, 226 Flutter tests, Debug APK build and artifact upload; main artifact {MAIN_ARTIFACT}.",
            "- `ADS-002` Debug test IDs and release configuration — PR #117 and reconciliation PR #118 are merged; release config is platform-safe and verified by CI #595/#597.",
            "- `ENG-010` Secret and credential handling — issue #113 / PR #114 are verified with secret scanning, diagnostic redaction, injection/rotation guidance, and CI evidence.",
            "",
        ]
    )
    catalog = replace_once(catalog, recent_anchor, recent_anchor + recent, "catalog recently verified")
catalog_path.write_text(catalog)

work_path = Path("docs/work/REW-007.md")
work = work_path.read_text()
work = replace_once(work, "Status: IN PROGRESS  ", "Status: VERIFIED", "work status")
if "## Verification evidence" not in work:
    verification = "\n".join(
        [
            "",
            "",
            "## Verification evidence",
            "",
            f"- PR #120 head `{PR_HEAD}`: Flutter CI #623 passed formatting, Analyze, all 226 Flutter tests, Debug APK build, and artifact upload; artifact {PR_ARTIFACT}.",
            f"- PR #120 merged to `main` as `{MERGE_SHA}`.",
            f"- Merge commit `{MERGE_SHA}`: Flutter CI #624 passed the complete gate set again, including 226 Flutter tests, Debug APK build, and artifact upload; artifact {MAIN_ARTIFACT}.",
            "- FEATURE_CATALOG/STATUS reconciliation marks REW-007 VERIFIED and advances the next unblocked RC P0 to PRIV-001.",
            "",
        ]
    )
    work = work.rstrip() + verification
work_path.write_text(work)
