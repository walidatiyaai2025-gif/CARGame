from pathlib import Path
import re

catalog_path = Path('docs/FEATURE_CATALOG.md')
status_path = Path('docs/STATUS.md')
work_path = Path('docs/work/SEC-002.md')

catalog = catalog_path.read_text(encoding='utf-8')
verified_row = "| SEC-002 | Dependency, secret, and artifact security scans | P0 | VERIFIED | ENG-006, ENG-010, ENG-007 | Issue #163 / PR #164 enforce tracked-secret blocking, `--enforce-lockfile` dependency advisory verification with explicit expiring exceptions, and packaged Debug/release APK+AAB artifact leakage scans. Focused probe `31327275686` passed 269 tracked-file secret hygiene, 13/13 security regressions, zero active advisories, Analyze, Debug APK build and artifact scan. Flutter CI #738 / run `31327747831` passed the full suite and Debug artifact scan/upload; Android Release Packaging Smoke #7 / run `31327747834` passed release APK+AAB builds and both artifact scans. PR #164 squash-merged as `5b96ee94f1d82a36bb6bbffd53b7719b64c175d3`. |"
catalog, count = re.subn(r'^\| SEC-002 \|.*$', verified_row, catalog, count=1, flags=re.MULTILINE)
if count != 1:
    raise SystemExit('SEC-002 catalog row not found exactly once')

catalog, count = re.subn(
    r'## IN PROGRESS\n\n.*?(?=\n## )',
    '## IN PROGRESS\n\n- None.\n',
    catalog,
    count=1,
    flags=re.DOTALL,
)
if count != 1:
    raise SystemExit('IN PROGRESS queue section not found')

catalog, count = re.subn(
    r'## NEXT READY\n\n.*?(?=\n## )',
    '## NEXT READY\n\n- `ADS-007` Consent/privacy integration — P1; `ADS-002` and `PRIV-001` are VERIFIED. It is the first catalog-ordered dependency-ready blocker remaining before `TEST-011`; `PRIV-003` remains the other required blocker.\n',
    catalog,
    count=1,
    flags=re.DOTALL,
)
if count != 1:
    raise SystemExit('NEXT READY queue section not found')

catalog = catalog.replace(
    '- `TEST-011` has its declared PRIV-001/SEC-001 prerequisites satisfied, but acceptance remains blocked until ADS-007 consent, PRIV-003 deletion controls, and the active SEC-002 dependency/artifact scanning checkpoint are complete.',
    '- `TEST-011` has its declared PRIV-001/SEC-001 prerequisites satisfied and SEC-002 is now VERIFIED, but acceptance remains blocked until ADS-007 consent and PRIV-003 deletion controls are complete.',
    1,
)
catalog_path.write_text(catalog, encoding='utf-8')

status = status_path.read_text(encoding='utf-8')
replacements = {
    '| Primary feature | `SEC-002` Dependency, secret, and artifact security scans — Issue #163 / branch `agent/sec-002-security-scans`. |':
        '| Primary feature | None — `SEC-002` is VERIFIED; `ADS-007` is the next dependency-ready blocker toward `TEST-011`. |',
    '| Completed checkpoint | `ENG-007` CI verification and dashboard integrity — PR #161 merged as `1e1ffd1c36f1338dc36820a3f38e78ae4bbcb47a` after green Flutter CI #734. |':
        '| Completed checkpoint | `SEC-002` dependency, secret, and artifact security scans — PR #164 merged as `5b96ee94f1d82a36bb6bbffd53b7719b64c175d3` after green Flutter CI #738 and Release Packaging Smoke #7. |',
    '| Status | SEC-002 is IN PROGRESS: preserve tracked-secret blocking, add enforced-lock/advisory dependency verification, and scan generated artifacts before upload. |':
        '| Status | SEC-002 is VERIFIED: CI enforces the committed lockfile, blocks active unreviewed dependency advisories, preserves tracked-secret scanning, and scans Debug/release APK+AAB artifacts before evidence upload. |',
    '| Previous checkpoint | `ENG-007` CI verification workflow — VERIFIED after PRs #161/#162. |':
        '| Previous checkpoint | `ENG-007` CI verification workflow — VERIFIED after PRs #161/#162. |',
    '| Next recommended feature | Complete `SEC-002` first. `TEST-011` remains P0 but its catalog blocker note requires `ADS-007`, `PRIV-003`, and `SEC-002` before its acceptance can pass. |':
        '| Next recommended feature | `ADS-007` Consent/privacy integration — P1, dependency-ready (`ADS-002`, `PRIV-001` VERIFIED). `TEST-011` still waits on ADS-007 and PRIV-003; SEC-002 is now satisfied. |',
}
for old, new in replacements.items():
    if old not in status:
        raise SystemExit(f'STATUS replacement baseline missing: {old}')
    status = status.replace(old, new, 1)

section = """## SEC-002 security scan verification — 2026-08-09

- Issue #163 / PR #164 add blocking dependency-advisory and packaged-artifact security controls without changing production dependency versions or runtime gameplay behavior.
- Existing tracked-secret/signing-material verification remains blocking; focused probe run `31327275686` scanned 269 tracked files and passed the existing secret-policy regression.
- `flutter pub get --enforce-lockfile` is now the CI restore path. `tool/verify_dependency_security.py` rejects active unreviewed GHSA advisories, pubspec-level advisory suppression, expired/malformed/package-mismatched exceptions, and stale exceptions. Baseline: 0 active advisories and 0 exceptions.
- `tool/verify_build_artifact_security.py` scans bounded text entries and forbidden file names inside APK/AAB archives while avoiding arbitrary compressed-binary false positives. Thirteen focused SEC-002 regressions passed.
- ENG-007 CI contracts now require the dependency-security and artifact-security gates; contract-hardening run `31327658032` passed 15/15 CI-integrity regressions plus 13/13 SEC-002 regressions.
- Flutter CI #738 / run `31327747831` passed all security/privacy/dependency/dashboard/assets/format/analyze tests, the full Flutter suite, Debug APK build, Debug APK artifact scan, and upload on head `0201c611a967fb795ad28f67835700108f9440fd`.
- Debug artifact #9042097866 is 80,594,411 bytes with SHA-256 `64359046108d96929c58967d1877caf0bba49f3fd93670d075f179f7092d99c2`.
- Android Release Packaging Smoke #7 / run `31327747834` passed enforced-lock advisory verification, release preflight, ephemeral CI signing, ads-disabled release APK+AAB builds, and both packaged-artifact scans. Release APK SHA-256: `aa84e87d4815064e8bf2f89d05694c897b6bfed23f82261e17cf9006d21a738a`; AAB SHA-256: `3c8fb5b1cfb8b0cf8d3ba7e6156172e67477da54bba67b24c46b2ed8659e8892`.
- Release evidence artifact #9042103273 is 464 bytes with SHA-256 `6c261bc007aefb0142b8b09a96080aaff6e1bcf17bbaacdcdb7a4c1c46f8c0ea`.
- PR #164 squash-merged to main as `5b96ee94f1d82a36bb6bbffd53b7719b64c175d3`; Issue #163 closed Completed. SEC-002 has no remaining acceptance blocker and is VERIFIED.
- `TEST-011` remains blocked by `ADS-007` consent/privacy integration and `PRIV-003` user-data export/deletion readiness. Both are P1 and dependency-ready; catalog order selects ADS-007 next.

"""
marker = '## ENG-007 CI verification workflow — 2026-08-09\n'
if marker not in status:
    raise SystemExit('ENG-007 STATUS section marker missing')
status = status.replace(marker, section + marker, 1)
status_path.write_text(status, encoding='utf-8')

work = work_path.read_text(encoding='utf-8')
if 'State: IN PROGRESS' not in work:
    raise SystemExit('SEC-002 work state baseline missing')
work = work.replace('State: IN PROGRESS', 'State: VERIFIED', 1)
work += """

## Verification evidence

- Focused security probe `31327275686`: tracked-secret scan across 269 files GREEN; 13/13 SEC-002 regressions GREEN; enforced lockfile GREEN; 0 active advisories; Analyze GREEN; Debug APK build and artifact scan GREEN.
- CI-contract hardening `31327658032`: 15/15 CI-integrity regressions GREEN; 13/13 security-scan regressions GREEN; dashboard/release/Flutter CI contracts GREEN.
- Flutter CI #738 / run `31327747831`: full pipeline, full Flutter suite, Debug APK build, packaged-artifact security scan and upload GREEN.
- Debug artifact #9042097866: 80,594,411 bytes; SHA-256 `64359046108d96929c58967d1877caf0bba49f3fd93670d075f179f7092d99c2`.
- Android Release Packaging Smoke #7 / run `31327747834`: enforced dependency advisory check, ephemeral signing, release APK+AAB, both artifact scans, checksums and evidence upload GREEN.
- Release APK SHA-256 `aa84e87d4815064e8bf2f89d05694c897b6bfed23f82261e17cf9006d21a738a`; AAB SHA-256 `3c8fb5b1cfb8b0cf8d3ba7e6156172e67477da54bba67b24c46b2ed8659e8892`.
- Release evidence artifact #9042103273: SHA-256 `6c261bc007aefb0142b8b09a96080aaff6e1bcf17bbaacdcdb7a4c1c46f8c0ea`.
- Implementation PR #164 squash-merged as `5b96ee94f1d82a36bb6bbffd53b7719b64c175d3`; Issue #163 closed Completed.
- Remaining TEST-011 blockers: ADS-007 and PRIV-003. ADS-007 is selected next by catalog order among the two dependency-ready P1 blockers.
"""
work_path.write_text(work, encoding='utf-8')
