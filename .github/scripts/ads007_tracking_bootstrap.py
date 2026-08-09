from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old = '| ADS-007 | Consent/privacy integration | P1 | PLANNED | ADS-002, PRIV-001 | Consent state controls personalized ads/analytics and is re-openable. |'
new = '| ADS-007 | Consent/privacy integration | P1 | IN PROGRESS | ADS-002, PRIV-001 | Issue #166: UMP consent must gate Mobile Ads initialization and every ad request; privacy options must be re-openable from Settings; first-party analytics remains disabled until ENG-012. |'
if old not in text:
    raise SystemExit('ADS-007 catalog row mismatch')
catalog.write_text(text.replace(old, new, 1), encoding='utf-8')

status = Path('docs/STATUS.md')
text = status.read_text(encoding='utf-8')
replacements = {
    '| Primary feature | None — `SEC-002` is VERIFIED; `ADS-007` is the next dependency-ready blocker toward `TEST-011`. |': '| Primary feature | `ADS-007` Consent/privacy integration — Issue #166 / branch `agent/ads-007-consent-privacy`. |',
    '| Status | SEC-002 is VERIFIED: CI enforces the committed lockfile, blocks active unreviewed dependency advisories, preserves tracked-secret scanning, and scans Debug/release APK+AAB artifacts before evidence upload. |': '| Status | ADS-007 is IN PROGRESS: implement UMP consent before Mobile Ads initialization/requests, runtime fail-closed ad eligibility, and re-openable privacy options from Settings. |',
    '| Previous checkpoint | `ENG-007` CI verification workflow — VERIFIED after PRs #161/#162. |': '| Previous checkpoint | `SEC-002` dependency, secret, and artifact security scans — VERIFIED after PRs #164/#165. |',
    '| Next recommended feature | `ADS-007` Consent/privacy integration — P1, dependency-ready (`ADS-002`, `PRIV-001` VERIFIED). `TEST-011` still waits on ADS-007 and PRIV-003; SEC-002 is now satisfied. |': '| Next recommended feature | Complete `ADS-007` first. `TEST-011` remains blocked by ADS-007 and PRIV-003; PRIV-003 is the next remaining dependency-ready blocker after consent integration. |',
}
for old_value, new_value in replacements.items():
    if old_value not in text:
        raise SystemExit(f'STATUS text mismatch: {old_value[:50]}')
    text = text.replace(old_value, new_value, 1)
status.write_text(text, encoding='utf-8')

work = Path('docs/work/ADS-007.md')
if work.exists():
    raise SystemExit('ADS-007 work file already exists')
work.write_text('''# ADS-007 — Consent/privacy integration\n\nState: IN PROGRESS\nIssue: #166\nBranch: `agent/ads-007-consent-privacy`\nStarted: 2026-08-09\n\n## Why this task is active\n\n`ADS-002` and `PRIV-001` are VERIFIED. `TEST-011` still requires consent/privacy integration and user-data controls; ADS-007 is the first dependency-ready blocker in catalog order and also unlocks PRIV-002.\n\n## Acceptance\n\n- Google UMP is the consent source of truth; no duplicate cached consent-granted preference.\n- Consent info refresh runs on launch and required forms are shown before Mobile Ads initialization/requesting.\n- `canRequestAds` gates SDK initialization plus banner/rewarded/interstitial request paths.\n- Settings exposes a publisher-rendered privacy entry that re-opens Google privacy options when required.\n- Runtime eligibility updates after privacy choices without an app restart.\n- UMP/Mobile Ads failure never blocks offline/core play.\n- First-party analytics stays absent/disabled; ENG-012 remains the owner of future analytics collection.\n- PRIV-001 inventory and automated privacy checks reflect the new truth.\n- Focused tests, Analyze, full Flutter suite, Debug APK and normal CI pass before verification.\n\n## Non-goals\n\n- No analytics SDK or event collection.\n- No production AdMob IDs or credentials.\n- No app-side persistence of a duplicate consent decision.\n''', encoding='utf-8')
