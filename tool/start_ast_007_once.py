#!/usr/bin/env python3
from pathlib import Path
import re

ISSUE = '#210'
BRANCH = 'agent/ast-007-cargo-visual-pack'

catalog_path = Path('docs/FEATURE_CATALOG.md')
catalog = catalog_path.read_text(encoding='utf-8')
pattern = re.compile(r'^\| AST-007 \| 100\+ 3D cargo product pack \| P1 \| ([A-Z ]+) \| AST-002 \| (.*?) \|$', re.M)
match = pattern.search(catalog)
if not match:
    raise SystemExit('AST-007 catalog row not found')
if match.group(1) != 'PLANNED':
    raise SystemExit(f'AST-007 expected PLANNED before start, found {match.group(1)}')
new_row = (
    '| AST-007 | 100+ 3D cargo product pack | P1 | IN PROGRESS | AST-002 | '
    'Issue #210 / branch `agent/ast-007-cargo-visual-pack` implements a migration-safe 100+ cargo visual layer: '
    'the existing 18 gameplay archetype IDs remain authoritative for matching/save/reward truth, while 124 stable `cargo.*` visual identities '
    'resolve deterministically per level/archetype through the existing manifest/fallback/provenance boundary. No runtime WebP or provenance is fabricated; '
    'real binaries remain fail-closed under AST-011 until licensed/admitted. |'
)
catalog = pattern.sub(new_row, catalog, count=1)
catalog_path.write_text(catalog, encoding='utf-8')

status_path = Path('docs/STATUS.md')
status = status_path.read_text(encoding='utf-8')
old_primary = '| Primary feature | None — `A11Y-003` source-controlled work is complete and reconciled as IMPLEMENTED; `AST-007` issue #210 is selected next but not started. |'
new_primary = '| Primary feature | `AST-007` 100+ cargo visual pack — IN PROGRESS on issue #210 / `agent/ast-007-cargo-visual-pack`. |'
if old_primary not in status:
    raise SystemExit('Expected no-primary AST-007 selection line missing')
status = status.replace(old_primary, new_primary, 1)
old_next = '| Next recommended feature | `AST-007` 100+ cargo visual variants — P1, dependency-ready via AST-002 and selected as issue #210 because it unblocks the P0 `GAME-012` production 3D board/products path while preserving stable gameplay IDs. |'
new_next = '| Next recommended feature | AST-007 is the active primary; no second source-controlled feature should start until its checkpoint is reconciled. |'
if old_next not in status:
    raise SystemExit('Expected AST-007 next-selection line missing')
status = status.replace(old_next, new_next, 1)
marker = '## A11Y-003 reduced-motion accessibility — 2026-08-11\n'
section = '''## AST-007 cargo visual pack — 2026-08-11\n\n- Issue #210 is the single active source-controlled workstream after A11Y-003 reconciliation.\n- Baseline gameplay truth remains 18 stable `CargoItem` archetype IDs across the deterministic 150-level catalog; matching, moves, difficulty, rewards and persisted progress must not change.\n- The implementation target is a separate typed visual layer with 124 stable `cargo.*` identities, deterministic level/archetype selection, and consistent source/warehouse/flight visuals.\n- Cargo descriptors use the existing `pcargo` 384x384 manifest contract and `assets/3d/runtime/cargo/...` taxonomy.\n- Missing binaries stay fallback-safe. No WebP, license, creator, prompt, checksum or provenance approval is invented; AST-011 remains the admission authority.\n- Source work can establish the catalog/resolver/UI bridge/tests/CI while actual production-art admission remains evidence-dependent.\n\n'''
if '## AST-007 cargo visual pack — 2026-08-11' not in status:
    if marker not in status:
        raise SystemExit('STATUS insertion marker missing')
    status = status.replace(marker, section + marker, 1)
status_path.write_text(status, encoding='utf-8')

work = Path('docs/work/AST-007.md')
work.write_text('''# AST-007 — 100+ Cargo Visual Pack\n\nIssue: #210\nBranch: `agent/ast-007-cargo-visual-pack`\n\n## State\n\nIN PROGRESS — selected after A11Y-003 final reconciliation.\n\n## Baseline\n\n- Production gameplay currently has 18 stable `CargoItem` archetypes.\n- The deterministic catalog contains 150 levels and existing TEST-002/TEST-007 contracts protect gameplay identity and critical-path behavior.\n- `assets/3d/manifest.json` currently has 9 non-cargo descriptors, 0 approved provenance records and 0 runtime WebP binaries.\n- `GAME-012` remains blocked on AST-007.\n\n## Architecture decision\n\nDo not renumber or expand the gameplay archetype IDs as a visual-content shortcut. Add a separate visual identity layer:\n\n1. gameplay archetype ID remains the matching/save/reward authority;\n2. each archetype owns multiple stable `cargo.*` visual identities;\n3. a pure deterministic resolver chooses a visual by level number + archetype ID;\n4. cargo tile, warehouse target and travel flight use the same resolved visual;\n5. missing/unadmitted runtime images render the existing Flutter fallback;\n6. AST-011 provenance/licensing remains mandatory before a real WebP can be admitted.\n\n## First implementation checkpoint\n\n- typed immutable cargo visual model/catalog;\n- 124 stable identities across all 18 archetypes;\n- deterministic resolver with uniqueness/coverage/reachability tests;\n- cargo manifest descriptors using `pcargo`/384x384 and runtime taxonomy;\n- `CargoVisualAsset` bridge over `GameManifestAssetView`;\n- production Cargo Bay / Sorting Docks / flight integration without changing matching truth;\n- AST-007 machine validator + mutation tests + normal CI ownership.\n\n## Verification boundary\n\nSource code may become IMPLEMENTED with green CI while runtime cargo binaries remain absent. AST-007 must not be marked VERIFIED as a production art pack until real WebP files and complete commercial-use provenance are admitted.\n''', encoding='utf-8')

print('AST-007 tracking state applied')
