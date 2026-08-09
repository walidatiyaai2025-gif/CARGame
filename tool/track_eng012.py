#!/usr/bin/env python3
from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


catalog_path = Path("docs/FEATURE_CATALOG.md")
catalog = catalog_path.read_text(encoding="utf-8")
catalog = replace_once(
    catalog,
    "| ENG-012 | Analytics event schema and privacy gating | P1 | PLANNED | ENG-005, PRIV-001 | Versioned event names/properties exist; collection is disabled until consent/config permits it. |",
    "| ENG-012 | Analytics event schema and privacy gating | P1 | IN PROGRESS | ENG-005, PRIV-001 | Issue #175: implement a pure-Dart versioned event schema, application analytics port, and fail-closed privacy/config gate. No analytics SDK, processor, persistence, or network transfer is introduced; `ENABLE_ANALYTICS` must default false and production runtime privacy eligibility must remain false until an explicit first-party privacy decision exists. |",
    "ENG-012 catalog row",
)
catalog = replace_once(
    catalog,
    "## IN PROGRESS\n\n- None.",
    "## IN PROGRESS\n\n- `ENG-012` Analytics event schema and privacy gating — issue #175; checkpoint: pure-Dart versioned schema + application port + disabled-by-default privacy/config gate, with no SDK, persistence, processor, or network transfer.",
    "ENG-012 in-progress queue",
)
catalog = replace_once(
    catalog,
    "## NEXT READY\n\n- `ENG-012` Analytics event schema and privacy gating — P1; `ENG-005` is IMPLEMENTED and `PRIV-001` is VERIFIED. Repository search confirms no current first-party analytics implementation, so the next safe checkpoint is a versioned schema/port that remains disabled until explicit privacy/config eligibility rather than introducing a network SDK.",
    "## NEXT READY\n\n- None while `ENG-012` is the active primary feature; select the next dependency-ready item only after this checkpoint reaches a clean verified/implemented/blocked state.",
    "ENG-012 next-ready queue",
)
catalog_path.write_text(catalog, encoding="utf-8")

status_path = Path("docs/STATUS.md")
status = status_path.read_text(encoding="utf-8")
old_summary = """| Primary feature | None — `ENG-011` developer tooling/documentation is VERIFIED on PR #174. |
| Completed checkpoint | `ENG-011` canonical developer workflows and documentation drift guard — VERIFIED after Flutter CI #773 / run `31339612397`. |
| Status | ENG-011 is VERIFIED: README and `docs/DEVELOPER_WORKFLOWS.md` now define the supported setup/run/repair/dashboard/verification/release path, and CI blocks stale or dangerous workflow documentation from returning. |
| Previous checkpoint | `PRIV-003` user data export/deletion readiness — VERIFIED after PR #172 / Flutter CI #771. |
| Next recommended feature | `ENG-012` Analytics event schema and privacy gating — P1; ENG-005 is IMPLEMENTED and PRIV-001 is VERIFIED. No first-party analytics implementation exists yet, so the safe next step is a disabled-by-default versioned schema/port with explicit privacy/config eligibility. |"""
new_summary = """| Primary feature | `ENG-012` Analytics event schema and privacy gating — IN PROGRESS under Issue #175. |
| Completed checkpoint | `ENG-011` canonical developer workflows and documentation drift guard — VERIFIED and squash-merged via PR #174 as `52d983dc251d3daf839b468d8065a13e849505db`. |
| Status | ENG-012 is IN PROGRESS: define a versioned pure-Dart event contract and application port, add a build/runtime privacy gate that fails closed, and keep production analytics non-collecting with no SDK/network processor. |
| Previous checkpoint | `ENG-011` developer tooling/documentation — VERIFIED after final-head Flutter CI #778 / run `31340173104` and merged as `52d983dc251d3daf839b468d8065a13e849505db`. |
| Next recommended feature | Complete ENG-012 acceptance and verification before selecting another primary feature. |"""
status = replace_once(status, old_summary, new_summary, "ENG-012 current-work summary")
status = replace_once(
    status,
    "## ENG-011 developer tooling and documentation — 2026-08-10",
    """## ENG-012 analytics schema and privacy gate — 2026-08-10

- Issue #175 / branch `agent/eng-012-analytics-schema` is the single active primary workstream.
- Current repository truth has no first-party analytics implementation or analytics network processor; Google Mobile Ads remains the sole declared network processor.
- The checkpoint will add a pure-Dart versioned event vocabulary plus an application-layer port while preserving the ENG-005 inward dependency rule.
- `ENABLE_ANALYTICS` will default to false, and production runtime privacy eligibility will also default to false; both gates are required before an outward adapter may accept an event.
- Google UMP advertising consent is not reused as first-party analytics consent, and this checkpoint persists no analytics-consent value.
- No event is queued, persisted, uploaded, or transmitted by the production composition in this checkpoint.
- Acceptance requires focused schema/gate tests plus the full privacy/security/dependency/catalog/Analyze/Flutter-test/Debug-APK/artifact-security CI path.

## ENG-011 developer tooling and documentation — 2026-08-10""",
    "ENG-012 status section",
)
status_path.write_text(status, encoding="utf-8")
