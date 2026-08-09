from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
status = Path('docs/STATUS.md')
work = Path('docs/work/ADS-002.md')

catalog_text = catalog.read_text(encoding='utf-8')
old_row = "| ADS-002 | Debug test IDs and release configuration | P0 | IN PROGRESS | ADS-001, ENG-009 | Issue #116 audits debug Google test IDs, runtime AdService wiring, Android manifest/Gradle injection, and release fail-closed validation. Current gap: typed Dart release configuration rejects empty/Google-test IDs but does not reject malformed non-test ad-unit IDs when builds bypass the RC preflight. |"
new_row = "| ADS-002 | Debug test IDs and release configuration | P0 | VERIFIED | ADS-001, ENG-009 | Issue #116 / PR #117 verify environment- and platform-safe AdMob configuration: debug retains Google's public test IDs; Android release application IDs/signing stay externally injected and fail closed in Gradle/preflight; typed runtime validation now checks only the active platform, rejects malformed ad-unit IDs and Google test IDs in release, and preserves ads-disabled fallback. Flutter CI #595 passed formatting, Analyze, the full Flutter suite, Debug APK build and artifact upload. Debug artifact #9032228970 is 80,520,644 bytes with SHA-256 `e801630e475047590b2ad97299d912681457aa081f43f2bd87832d4dcad9b459`. |"
if old_row not in catalog_text:
    raise SystemExit('ADS-002 catalog row not found')
catalog.write_text(catalog_text.replace(old_row, new_row), encoding='utf-8')

status_text = status.read_text(encoding='utf-8')
status_text = status_text.replace(
    "| Primary feature | `ADS-002` debug test IDs and release ad configuration — issue #116. |",
    "| Primary feature | `ADS-002` verification complete — issue #116 / PR #117; transitioning to the next RC P0. |",
)
status_text = status_text.replace(
    "| Next recommended feature | Finish `ADS-002` typed release ad-unit format validation and configuration regression coverage, then reconcile the existing Android manifest/Gradle/preflight evidence. |",
    "| Next recommended feature | `REW-007` reward transaction ledger and reconciliation: add stable grant reasons/idempotency keys and interruption-safe audit/reconciliation on top of the verified persistence/reward flows. |",
)
marker = "## ENG-010 secret and credential handling verification — 2026-08-09\n"
section = """## ADS-002 release ad configuration verification — 2026-08-09

- Issue #116 / PR #117 fixed a release-only configuration defect: Android RC builds inject Android ad-unit IDs only, so typed validation now scopes completeness/test-ID checks to the active runtime platform instead of rejecting valid Android releases because unused iOS defaults remain Google test IDs.
- Active-platform runtime ad units must match the AdMob `ca-app-pub-<16 digits>/<10 digits>` shape; malformed direct `--dart-define` values fail closed even if a build bypasses the PowerShell RC preflight.
- Existing defense-in-depth remains: debug uses Google's public test application/ad-unit IDs; Android release app ID and signing are externally injected; Gradle and `VERIFY_RELEASE_INPUTS.ps1` reject missing/test release inputs; `AdService` consumes only `AppBuildConfig.current` IDs; ads-disabled/offline paths remain non-blocking.
- Flutter CI #595 passed secret/privacy/security gates, formatting, whitespace, Analyze, focused checks, the full Flutter test suite, Debug APK build, and artifact upload on head `26851ed3cba7b6bd04ac24db7f068b6a68efc63c`.
- Debug artifact #9032228970 is 80,520,644 bytes with SHA-256 `e801630e475047590b2ad97299d912681457aa081f43f2bd87832d4dcad9b459`.
- PR #117 squash-merged to `main` as `0e2f13329835bfe69c79b985153c65e68ac32bb2`; `ADS-002` is VERIFIED.
- Next RC P0: `REW-007` reward transaction ledger/reconciliation.

"""
if marker not in status_text:
    raise SystemExit('STATUS insertion marker not found')
if '## ADS-002 release ad configuration verification' not in status_text:
    status_text = status_text.replace(marker, section + marker)
status.write_text(status_text, encoding='utf-8')

work_text = work.read_text(encoding='utf-8')
work_text = work_text.replace('Status: IN PROGRESS', 'Status: VERIFIED')
work_text = work_text.replace(
    "## Verification required before completion\n\n- Flutter CI formatting and whitespace checks.\n- `flutter analyze --no-fatal-infos --no-fatal-warnings`.\n- Full Flutter test suite.\n- Debug APK build and artifact upload.\n- Final PR diff/head review, squash merge, then catalog/status reconciliation and issue closure.\n",
    "## Verification evidence\n\n- Flutter CI #595 passed formatting, whitespace, Analyze, focused checks, the full Flutter test suite, Debug APK build, and artifact upload on head `26851ed3cba7b6bd04ac24db7f068b6a68efc63c`.\n- Debug artifact #9032228970: 80,520,644 bytes; SHA-256 `e801630e475047590b2ad97299d912681457aa081f43f2bd87832d4dcad9b459`.\n- PR #117 squash-merged to `main` as `0e2f13329835bfe69c79b985153c65e68ac32bb2`.\n- Catalog/status reconciliation records ADS-002 as VERIFIED; issue #116 can close after this docs-only reconciliation merges.\n",
)
work.write_text(work_text, encoding='utf-8')
