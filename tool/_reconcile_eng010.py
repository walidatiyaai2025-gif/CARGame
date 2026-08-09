from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old = "| ENG-010 | Secret and credential handling | P0 | IN PROGRESS | ENG-009 | Issue #113 audits committed-secret scanning, local/CI injection, rotation/recovery guidance, and runtime diagnostic redaction. Current gap: forced-tracked `*.credentials.local.json` is ignored locally but not explicitly rejected by the scanner; scanner regression coverage is also missing. |"
new = "| ENG-010 | Secret and credential handling | P0 | VERIFIED | ENG-009 | Issue #113 / PR #114 align tracked-secret scanning with local ignore policy, add focused scanner regression coverage, redact standalone high-confidence GitHub/AWS/Google/Slack credentials in diagnostics, and document local/CI injection plus rotation/recovery rules. Flutter CI #588 passed secret hygiene, policy regression, formatting, Analyze, full Flutter tests, Debug APK build, and artifact upload. Debug artifact #9031846609 is 80,518,478 bytes with SHA-256 `913d9a9ae3107cde00ced9e6e7197098f5f15e640de59ae3e474715661cf33df`. |"
if old not in text:
    raise SystemExit('ENG-010 catalog row not found')
catalog.write_text(text.replace(old, new), encoding='utf-8')

status = Path('docs/STATUS.md')
s = status.read_text(encoding='utf-8')
s = s.replace("| Primary feature | `ENG-010` secret and credential handling — issue #113. |", "| Primary feature | None after `ENG-010` verification; next RC P0 audit is `ADS-002` debug/release ad configuration. |")
s = s.replace("| Status | IN PROGRESS — auditing secret scanner policy, diagnostic redaction, local/CI release input injection, and rotation/recovery evidence. Initial gap: forced-tracked `*.credentials.local.json` is not explicitly forbidden by the scanner and the scanner has no focused regression harness. |", "| Status | `ENG-010` VERIFIED: tracked secret/config artifacts fail closed, scanner policy has focused regression coverage, standalone provider credentials are redacted from diagnostics, and local/CI injection plus rotation/recovery guidance is documented. |")
s = s.replace("| Next recommended feature | Finish `ENG-010` scanner regression/hardening, then reconcile redaction/injection/rotation evidence and continue remaining RC P0 gaps. |", "| Next recommended feature | Audit `ADS-002` against the existing ENG-009 release configuration so debug uses only public test IDs and release requires injected production IDs without fallback. |")
anchor = "## GAME-016 input determinism verification — 2026-08-09"
section = "## ENG-010 secret and credential handling verification — 2026-08-09\n\n- Issue #113 / PR #114 hardened the tracked-file secret scanner, added a focused temporary-repository regression harness, and extended runtime diagnostic redaction to standalone high-confidence GitHub/AWS/Google/Slack credential signatures.\n- Existing `.gitignore`, Android signing procedure, and secret-handling policy keep keystores, `key.properties`, environment overrides, local credential JSON and reusable CI credentials outside source control; rotation/recovery procedures remain documented without storing secret values.\n- Flutter CI #588 passed secret hygiene, scanner policy regression, formatting, Analyze, the full Flutter test suite, Debug APK build, and artifact upload on head `84b9705e8fcfc950ac973b951cca407afd8b5bec`. Artifact #9031846609 is 80,518,478 bytes with SHA-256 `913d9a9ae3107cde00ced9e6e7197098f5f15e640de59ae3e474715661cf33df`.\n\n"
if anchor not in s:
    raise SystemExit('STATUS anchor not found')
status.write_text(s.replace(anchor, section + anchor, 1), encoding='utf-8')
