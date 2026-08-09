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
    "| ENG-012 | Analytics event schema and privacy gating | P1 | IN PROGRESS | ENG-005, PRIV-001 | Issue #175: implement a pure-Dart versioned event schema, application analytics port, and fail-closed privacy/config gate. No analytics SDK, processor, persistence, or network transfer is introduced; `ENABLE_ANALYTICS` must default false and production runtime privacy eligibility must remain false until an explicit first-party privacy decision exists. |",
    "| ENG-012 | Analytics event schema and privacy gating | P1 | VERIFIED | ENG-005, PRIV-001 | Issue #175 / PR #176 add schema v1 with stable typed/allowlisted event properties, an application analytics port, `ENABLE_ANALYTICS=false` by default, and a separate runtime privacy gate. Production remains fail-closed with deny-all first-party analytics privacy and no emitter/SDK/processor/persistence/network path; UMP ad consent is not reused. Flutter CI #785 / run `31341159553` passed the ENG-012 privacy validator, formatting, Analyze, focused analytics tests, the full Flutter suite, Debug APK build, artifact security and upload on head `eb8dd6623cc35809bd6c7eb270235c30437627cf`; artifact #9045957178 is 80,626,055 bytes with SHA-256 `102b965b14dab94df5fa4137ac760a58ee2281c6ad512127f553955f74723720`. |",
    "ENG-012 catalog row",
)
catalog = replace_once(
    catalog,
    "## IN PROGRESS\n\n- `ENG-012` Analytics event schema and privacy gating — issue #175; checkpoint: pure-Dart versioned schema + application port + disabled-by-default privacy/config gate, with no SDK, persistence, processor, or network transfer.",
    "## IN PROGRESS\n\n- None.",
    "ENG-012 in-progress queue",
)
catalog = replace_once(
    catalog,
    "## NEXT READY\n\n- None while `ENG-012` is the active primary feature; select the next dependency-ready item only after this checkpoint reaches a clean verified/implemented/blocked state.",
    "## NEXT READY\n\n- `ENG-013` Crash reporting and non-fatal diagnostics — P1; `ENG-004` is IMPLEMENTED and `PRIV-001` is VERIFIED. Keep remote crash reporting absent until the feature defines release-safe redaction, privacy/config gating, symbol/version correlation, and processor/disclosure ownership.",
    "ENG-013 next-ready queue",
)
catalog_path.write_text(catalog, encoding="utf-8")

status_path = Path("docs/STATUS.md")
status = status_path.read_text(encoding="utf-8")
old_summary = """| Primary feature | `ENG-012` Analytics event schema and privacy gating — IN PROGRESS under Issue #175. |
| Completed checkpoint | `ENG-011` canonical developer workflows and documentation drift guard — VERIFIED and squash-merged via PR #174 as `52d983dc251d3daf839b468d8065a13e849505db`. |
| Status | ENG-012 is IN PROGRESS: define a versioned pure-Dart event contract and application port, add a build/runtime privacy gate that fails closed, and keep production analytics non-collecting with no SDK/network processor. |
| Previous checkpoint | `ENG-011` developer tooling/documentation — VERIFIED after final-head Flutter CI #778 / run `31340173104` and merged as `52d983dc251d3daf839b468d8065a13e849505db`. |
| Next recommended feature | Complete ENG-012 acceptance and verification before selecting another primary feature. |"""
new_summary = """| Primary feature | None — `ENG-012` analytics event schema and privacy gating is VERIFIED on PR #176. |
| Completed checkpoint | `ENG-012` versioned analytics schema and fail-closed privacy gate — VERIFIED after Flutter CI #785 / run `31341159553`. |
| Status | ENG-012 is VERIFIED: schema v1 and the application analytics boundary are source-controlled, production first-party collection remains disabled by build/runtime gates with no emitter/processor/network path, and UMP advertising consent is not reused. |
| Previous checkpoint | `ENG-011` developer tooling/documentation — VERIFIED and squash-merged via PR #174 as `52d983dc251d3daf839b468d8065a13e849505db`. |
| Next recommended feature | `ENG-013` Crash reporting and non-fatal diagnostics — P1; ENG-004 is IMPLEMENTED and PRIV-001 is VERIFIED. |"""
status = replace_once(status, old_summary, new_summary, "ENG-012 current-work summary")
old_section = """## ENG-012 analytics schema and privacy gate — 2026-08-10

- Issue #175 / branch `agent/eng-012-analytics-schema` is the single active primary workstream.
- Current repository truth has no first-party analytics implementation or analytics network processor; Google Mobile Ads remains the sole declared network processor.
- The checkpoint will add a pure-Dart versioned event vocabulary plus an application-layer port while preserving the ENG-005 inward dependency rule.
- `ENABLE_ANALYTICS` will default to false, and production runtime privacy eligibility will also default to false; both gates are required before an outward adapter may accept an event.
- Google UMP advertising consent is not reused as first-party analytics consent, and this checkpoint persists no analytics-consent value.
- No event is queued, persisted, uploaded, or transmitted by the production composition in this checkpoint.
- Acceptance requires focused schema/gate tests plus the full privacy/security/dependency/catalog/Analyze/Flutter-test/Debug-APK/artifact-security CI path."""
new_section = """## ENG-012 analytics schema and privacy gate — 2026-08-10

- Issue #175 / PR #176 implement schema v1 with stable event names, typed/allowlisted properties, required-property validation, numeric bounds, immutable validated payloads, and explicit wire serialization.
- `AnalyticsPort` and `AnalyticsPrivacyPort` keep the application boundary vendor-neutral; `PrivacyGatedAnalytics` requires build enablement, explicit first-party runtime privacy eligibility, and an outward emitter before collection can become active.
- `ENABLE_ANALYTICS` defaults to false. Production composition installs `DenyAllAnalyticsPrivacy` and no emitter, so first-party analytics remains non-collecting even if the build flag is accidentally enabled.
- Google UMP advertising consent is not reused as first-party analytics consent. No analytics SDK, processor, persistence queue, upload, or network transport was introduced.
- `tool/verify_analytics_privacy.py` blocks analytics SDK/processor drift, non-versioned/unbounded schema changes, advertising/storage/network coupling, default-on collection, and production emitter installation.
- Flutter CI #785 / run `31341159553` passed privacy/security/dependency/catalog gates, formatting, Analyze, focused analytics tests, existing focused regressions, the full Flutter suite, Debug APK build, artifact security and upload on head `eb8dd6623cc35809bd6c7eb270235c30437627cf`.
- Debug artifact #9045957178 is 80,626,055 bytes with SHA-256 `102b965b14dab94df5fa4137ac760a58ee2281c6ad512127f553955f74723720`.
- All repository-owned ENG-012 acceptance criteria are VERIFIED; any future real collector/processor still requires an explicit first-party privacy decision plus inventory/disclosure review before enablement."""
status = replace_once(status, old_section, new_section, "ENG-012 status section")
status_path.write_text(status, encoding="utf-8")

work_path = Path("docs/work/ENG-012.md")
work = work_path.read_text(encoding="utf-8")
work = replace_once(
    work,
    "`IN PROGRESS` — establish a pure-Dart event schema, an application-layer analytics port, and a production composition that is disabled by default and remains fail-closed until both build configuration and an explicit first-party runtime privacy eligibility signal permit collection.",
    "`VERIFIED` — schema v1, application analytics ports, disabled-by-default build configuration, fail-closed runtime privacy gating, production no-emitter composition, machine drift protection, and full repository verification are complete.",
    "ENG-012 work status",
)
old_verification = """## Verification

- Flutter CI #780 / run `31340929081` passed dynamic-target, secret-hygiene, privacy-inventory, ENG-012 analytics-privacy, Play Data Safety, security-baseline, developer-workflow, dependency, dashboard/release-contract, asset, and localization gates before identifying canonical Dart formatting drift in exactly three new ENG-012 files.
- One-shot formatter run `31340970538` succeeded and applied Dart 3.12 / Flutter 3.44.8 canonical formatting to those three files, then removed its temporary workflow/trigger.
- Analyze, focused analytics tests, full Flutter tests, Debug APK, and artifact-security evidence remain required on the formatted implementation head before this feature can leave `IN PROGRESS`."""
new_verification = """## Verification

- Flutter CI #780 / run `31340929081` passed all pre-format privacy/security/dependency/analytics gates and identified canonical Dart formatting drift in exactly three new ENG-012 files.
- One-shot formatter run `31340970538` succeeded, applied Flutter 3.44.8 / Dart 3.12 canonical formatting, and removed its temporary workflow/trigger.
- Flutter CI #785 / run `31341159553` on implementation head `eb8dd6623cc35809bd6c7eb270235c30437627cf` passed the ENG-012 machine privacy contract, all existing privacy/security/dependency/dashboard/catalog/assets gates, formatting, whitespace, Analyze, focused analytics schema/privacy/config/composition tests, existing focused regressions, the full Flutter test suite, Debug APK build, artifact security, and artifact upload.
- Debug artifact #9045957178: 80,626,055 bytes; SHA-256 `102b965b14dab94df5fa4137ac760a58ee2281c6ad512127f553955f74723720`.
- Production first-party analytics remains disabled: no analytics SDK, network processor, persistence queue, outward emitter, or UMP-to-analytics consent reuse exists in this checkpoint.
- Repository-owned acceptance is VERIFIED. A future real analytics transport remains a separate privacy/disclosure/processor decision."""
work = replace_once(work, old_verification, new_verification, "ENG-012 work verification")
work_path.write_text(work, encoding="utf-8")
