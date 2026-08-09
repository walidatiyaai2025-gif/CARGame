from pathlib import Path
import re

catalog_path = Path('docs/FEATURE_CATALOG.md')
status_path = Path('docs/STATUS.md')

catalog = catalog_path.read_text(encoding='utf-8')
old_row = '| SEC-002 | Dependency, secret, and artifact security scans | P0 | PLANNED | ENG-006, ENG-010, ENG-007 | CI blocks committed secrets, critical vulnerable dependencies, and sensitive build artifacts. |'
new_row = '| SEC-002 | Dependency, secret, and artifact security scans | P0 | IN PROGRESS | ENG-006, ENG-010, ENG-007 | Issue #163 is adding enforce-lockfile/advisory verification and post-build artifact scanning while preserving the existing tracked-secret gate and normal Flutter CI pipeline. |'
if old_row not in catalog:
    raise SystemExit('SEC-002 catalog row did not match expected baseline')
catalog = catalog.replace(old_row, new_row, 1)

catalog = catalog.replace('## IN PROGRESS\n\n- None.', '## IN PROGRESS\n\n- `SEC-002` Dependency, secret, and artifact security scans — P0; Issue #163 / branch `agent/sec-002-security-scans`.', 1)

catalog = re.sub(
    r'## NEXT READY\n\n- `ENG-005`[^\n]*',
    '## NEXT READY\n\n- Complete `SEC-002` first; `TEST-011` remains a P0 verification target but cannot pass until `ADS-007`, `PRIV-003`, and `SEC-002` are complete.',
    catalog,
    count=1,
)

catalog = catalog.replace(
    '- `SEC-002` remains dependency-blocked while `ENG-006` and `ENG-007` are PLANNED.\n',
    '',
    1,
)
catalog = catalog.replace(
    '- `TEST-011` now has its declared PRIV-001/SEC-001 prerequisites satisfied, but its acceptance cannot pass until ADS-007 consent, PRIV-003 deletion controls, and SEC-002 dependency/artifact scanning are completed.',
    '- `TEST-011` has its declared PRIV-001/SEC-001 prerequisites satisfied, but acceptance remains blocked until ADS-007 consent, PRIV-003 deletion controls, and the active SEC-002 dependency/artifact scanning checkpoint are complete.',
    1,
)
catalog_path.write_text(catalog, encoding='utf-8')

status = status_path.read_text(encoding='utf-8')
status = status.replace(
    '| Primary feature | None — `ENG-007` CI verification workflow is VERIFIED; `TEST-011` is the highest-priority dependency-ready catalog item. |',
    '| Primary feature | `SEC-002` Dependency, secret, and artifact security scans — Issue #163 / branch `agent/sec-002-security-scans`. |',
    1,
)
status = status.replace(
    '| Status | ENG-007 is VERIFIED: normal Flutter CI now blocks dashboard/catalog parser drift and protected release-smoke contract regressions, backed by 12 focused tests, while preserving the full existing verification pipeline. |',
    '| Status | SEC-002 is IN PROGRESS: preserve tracked-secret blocking, add enforced-lock/advisory dependency verification, and scan generated artifacts before upload. |',
    1,
)
status = status.replace(
    '| Previous checkpoint | `ENG-006` dependency/package governance — VERIFIED after PRs #158/#159. |',
    '| Previous checkpoint | `ENG-007` CI verification workflow — VERIFIED after PRs #161/#162. |',
    1,
)
status = status.replace(
    '| Next recommended feature | `TEST-011` Privacy, consent, and security verification — P0; dependencies `PRIV-001` and `SEC-001` are satisfied. `REL-013` is not considered ready while its human-readable dependency “All P0 release blockers” remains unresolved. |',
    '| Next recommended feature | Complete `SEC-002` first. `TEST-011` remains P0 but its catalog blocker note requires `ADS-007`, `PRIV-003`, and `SEC-002` before its acceptance can pass. |',
    1,
)
status = status.replace(
    '- A dependency-ready queue audit selects `TEST-011` (P0, dependencies `PRIV-001` and `SEC-001`) as the next valid feature. `REL-013` is intentionally excluded until its human-readable “All P0 release blockers” condition is truly satisfied.',
    '- Follow-up catalog reconciliation found that `TEST-011` cannot yet satisfy acceptance: the catalog explicitly requires `ADS-007`, `PRIV-003`, and `SEC-002`. `SEC-002` is the true P0 dependency-ready blocker because `ENG-006`, `ENG-010`, and `ENG-007` are VERIFIED.',
    1,
)
status_path.write_text(status, encoding='utf-8')
