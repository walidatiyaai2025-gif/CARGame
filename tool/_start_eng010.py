from pathlib import Path

catalog_path = Path('docs/FEATURE_CATALOG.md')
catalog = catalog_path.read_text()
old = '| ENG-010 | Secret and credential handling | P0 | PLANNED | ENG-009 | No secret is committed; local/CI injection, rotation, and redaction rules are documented and tested. |'
new = '| ENG-010 | Secret and credential handling | P0 | IN PROGRESS | ENG-009 | Issue #113 audits committed-secret scanning, local/CI injection, rotation/recovery guidance, and runtime diagnostic redaction. Current gap: forced-tracked `*.credentials.local.json` is ignored locally but not explicitly rejected by the scanner; scanner regression coverage is also missing. |'
if old not in catalog:
    raise SystemExit('ENG-010 catalog row not found')
catalog_path.write_text(catalog.replace(old, new, 1))

status_path = Path('docs/STATUS.md')
status = status_path.read_text()
replacements = {
    '| Primary feature | None after `GAME-016` verification; next RC P0 is `ENG-010` secret and credential handling. |': '| Primary feature | `ENG-010` secret and credential handling — issue #113. |',
    '| Status | `GAME-016` VERIFIED: repeated warehouse input and cargo reselection during resolution remain deterministic with exactly one move/feedback event; boosters, restart, and back are disabled while resolving, and result-boundary races remain covered by `TEST-004`. |': '| Status | IN PROGRESS — auditing secret scanner policy, diagnostic redaction, local/CI release input injection, and rotation/recovery evidence. Initial gap: forced-tracked `*.credentials.local.json` is not explicitly forbidden by the scanner and the scanner has no focused regression harness. |',
    '| Next recommended feature | Start `ENG-010` secret and credential handling audit, then continue the remaining unblocked RC P0 gaps. |': '| Next recommended feature | Finish `ENG-010` scanner regression/hardening, then reconcile redaction/injection/rotation evidence and continue remaining RC P0 gaps. |',
}
for old, new in replacements.items():
    if old not in status:
        raise SystemExit(f'status row not found: {old}')
    status = status.replace(old, new, 1)
status_path.write_text(status)
