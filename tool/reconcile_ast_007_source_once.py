#!/usr/bin/env python3
from pathlib import Path
import re

MERGE_SHA = '132c0cff75057e21a8bdea50550b6b8bcd7e04f6'
PR_HEAD = '0330458b3b3becaa9248a694d56fe3b9f8261fd5'
PR_RUN = '31477806852'
PR_ARTIFACT = '#9096224674 (80,673,122 bytes; SHA-256 `e45405e154f209d106c5758852457c45f0d7a8b9c3ec11ab46098ccd500172c3`)'
MAIN_RUN = '31478580634'
MAIN_ARTIFACT = '#9096533997 (80,673,119 bytes; SHA-256 `73c77fd51540696d1327141856ba9d62570adffbb75f54e61803adce9439fbbb`)'
PROMOTION_RUN = '31479328315'
PROMOTION_COMMIT = 'a80b987bdc0a533958b381506f46012eaa2ae6f3'
QA_APK_SIZE = '56,044,747'
QA_APK_SHA = '62177e3056dba6f303f68e32f426142ed0bff461300049a77610cbaba2312d61'

catalog_path = Path('docs/FEATURE_CATALOG.md')
catalog = catalog_path.read_text(encoding='utf-8')

ast007_pattern = re.compile(r'^\| AST-007 \| 100\+ 3D cargo product pack \| P1 \| IN PROGRESS \| AST-002 \| .*? \|$', re.M)
ast007_row = (
    '| AST-007 | 100+ 3D cargo product pack | P1 | IN PROGRESS | AST-002 | '
    f'Issue #210 / PR #213 merged the source-controlled cargo visual identity/admission/UI checkpoint as `{MERGE_SHA}` after final-head Flutter CI #892 / run `{PR_RUN}` passed all 69 gates; PR artifact {PR_ARTIFACT}. '
    f'Exact-main Flutter CI #893 / run `{MAIN_RUN}` then passed all 69 gates with main artifact {MAIN_ARTIFACT}. '
    'The checkpoint preserves the 18 gameplay archetype IDs and deterministic 150-level gameplay truth while adding 124 stable `cargo.*` visual identities, deterministic level/archetype resolution, Cargo Bay / Sorting Docks / flight integration, fallback-safe `GameManifestAssetView` readiness, 7 mutation-tested machine regressions, and normal CI ownership. '
    f'Latest-verified QA promotion run `{PROMOTION_RUN}` succeeded after one transient Maven 403 retry and committed `{PROMOTION_COMMIT}`; QA APK is {QA_APK_SIZE} bytes, SHA-256 `{QA_APK_SHA}`, ephemeral CI signed with ads disabled. '
    'AST-007 deliberately remains IN PROGRESS: current main has 124 cargo descriptors but 0 approved provenance records and 0 runtime cargo WebP binaries, so the production art pack is not complete and GAME-012 remains blocked. |'
)
if not ast007_pattern.search(catalog):
    raise SystemExit('AST-007 catalog row changed unexpectedly')
catalog = ast007_pattern.sub(ast007_row, catalog, count=1)

ast011_pattern = re.compile(r'^\| AST-011 \| Asset licensing and provenance \| P0 \| VERIFIED \| AST-001 \| .*? \|$', re.M)
ast011_row = (
    '| AST-011 | Asset licensing and provenance | P0 | VERIFIED | AST-001 | '
    'The versioned provenance catalog, typed commercial-use validation, `GameAssetAdmission`, focused regressions, and CI admission gate remain VERIFIED. '
    f'Current main after AST-007 intentionally contains 133 manifest descriptors (9 existing descriptors + 124 descriptor-only cargo identities), 0 approved provenance records, and 0 runtime WebP binaries; exact-main Flutter CI #893 / run `{MAIN_RUN}` passed `Validate 3D asset registry and provenance`. '
    'Descriptor-only records are allowed and fallback-safe, while any future runtime WebP still fails closed unless it has a matching manifest record and complete commercial-use provenance. No license/source/prompt/checksum/approval evidence is fabricated. |'
)
if not ast011_pattern.search(catalog):
    raise SystemExit('AST-011 catalog row changed unexpectedly')
catalog = ast011_pattern.sub(ast011_row, catalog, count=1)
catalog_path.write_text(catalog, encoding='utf-8')

status_path = Path('docs/STATUS.md')
status = status_path.read_text(encoding='utf-8')

replacements = {
    '| Completed checkpoint | `A11Y-003` reduced-motion accessibility — IMPLEMENTED; issue #208 / PR #209 completed 100/100 source-controlled checkpoints, PR #209 merged as `996bebf50e9f5b150e10a9f6455a27015a67355f`, and exact-main Flutter CI #873 / run `31473003490` passed all gates. |': f'| Completed checkpoint | `AST-007` source integration checkpoint — merged as `{MERGE_SHA}` with 124 stable cargo visual identities and exact-main Flutter CI #893 / run `{MAIN_RUN}` green; production WebP/provenance admission remains open, so AST-007 stays IN PROGRESS. |',
    '| Status | A11Y-003 source-controlled acceptance is IMPLEMENTED: shared motion intent classification, deterministic no-ticker reduced paths, cinematic skip semantics, direct-motion audit, EN/AR Settings copy, validator regressions, focused/full tests, coverage, Debug APK security/upload and exact-main verification are green. Main artifact #9094321792 (80,659,593 bytes; sha256:ee95a99a8460d1824a28fb9512d12454d3e9f69648a9e0bd5506e34ccf2be98d). Physical assistive-technology/device observation is separate evidence and is not claimed. |': f'| Status | AST-007 source checkpoint is merged and exact-main verified: 18 gameplay IDs remain stable, 124 deterministic `cargo.*` visual identities are reachable across the existing 150-level catalog, Cargo Bay/Sorting Docks/flight use the shared manifest bridge with legacy fallbacks, and manifest readiness no longer flashes stale fallback after preload. PR CI #892 and exact-main CI #893 passed full suite/coverage/Debug APK/security/upload; main artifact {MAIN_ARTIFACT}. Current production-art admission is still 0 provenance / 0 runtime WebP, so the feature remains IN PROGRESS. |',
    '| Previous checkpoint | `UI3D-007` reduced motion and adaptive visual effects — IMPLEMENTED with 100/100 source-controlled checkpoints and exact-main verification. |': '| Previous checkpoint | `A11Y-003` reduced-motion accessibility — IMPLEMENTED with 100/100 source-controlled checkpoints and exact-main verification. |',
}
for old, new in replacements.items():
    if old not in status:
        raise SystemExit(f'STATUS expected line missing: {old[:80]}')
    status = status.replace(old, new, 1)

ast_section_marker = '## AST-007 cargo visual pack — 2026-08-11\n\n'
if ast_section_marker not in status:
    raise SystemExit('AST-007 STATUS section missing')
section_start = status.index(ast_section_marker) + len(ast_section_marker)
next_section = status.index('\n## A11Y-003 reduced-motion accessibility — 2026-08-11', section_start)
new_ast_section = f'''- Issue #210 remains the single active source-controlled/product-art workstream; PR #213 completed and merged the first source integration checkpoint.\n- The 18 stable `CargoItem` gameplay archetype IDs remain the matching/save/reward authority. The 150-level generator seed, item IDs, moves and difficulty truth are unchanged.\n- `CargoVisualCatalog` adds 124 stable `cargo.*` identities across all 18 archetypes. Deterministic level/archetype resolution reaches at least 100 distinct identities across the real 150-level catalog while keeping duplicate cargo, its sorting target and travel flight visually coherent.\n- `assets/3d/manifest.json` now contains 133 descriptors total: 9 existing + 124 descriptor-only cargo records using `pcargo` / 384x384 and `assets/3d/runtime/cargo/...` taxonomy. Approved provenance remains 0 and runtime WebP remains 0.\n- `CargoVisualAsset` routes Cargo Bay, Sorting Docks and travel flight through `GameManifestAssetView`; with no admitted binaries, exact legacy fallbacks remain visible.\n- Full-suite verification exposed and fixed a real manifest-readiness regression: root-bundle diagnostics proved all 133 descriptors parsed; `GameManifestAssetView` now caches both the in-flight Future and resolved registry so post-preload widgets resolve synchronously rather than flashing legacy fallback.\n- Final PR head `{PR_HEAD}` passed Flutter CI #892 / run `{PR_RUN}` all 69 gates, including AST-007 validator/regressions, full suite, coverage, Debug APK, artifact security and upload; PR artifact {PR_ARTIFACT}.\n- PR #213 squash-merged as `{MERGE_SHA}`. Exact-main Flutter CI #893 / run `{MAIN_RUN}` passed all 69 gates; main artifact {MAIN_ARTIFACT}.\n- Latest Verified APK promotion run `{PROMOTION_RUN}` initially hit a transient Maven Central HTTP 403 while resolving Kotlin artifacts; rerunning the same failed job without code/config changes passed release build, artifact security and promotion. Promotion commit `{PROMOTION_COMMIT}` retained a {QA_APK_SIZE}-byte QA APK with SHA-256 `{QA_APK_SHA}`, ephemeral CI signing and runtime ads disabled.\n- AST-007 remains IN PROGRESS. The next checkpoint is admission of real commercial-use cargo WebP assets with complete AST-011 provenance; no second primary feature should start and GAME-012 remains blocked until that evidence exists.\n'''
status = status[:section_start] + new_ast_section + status[next_section:]
status_path.write_text(status, encoding='utf-8')

work_path = Path('docs/work/AST-007.md')
work = work_path.read_text(encoding='utf-8')
work = re.sub(
    r'## State\n\n.*?\n\n## Baseline',
    '## State\n\nIN PROGRESS — source integration checkpoint merged and exact-main verified; production cargo WebP/provenance admission remains open.\n\n## Baseline',
    work,
    count=1,
    flags=re.S,
)
work += f'''\n## Merged source checkpoint evidence\n\n- Final PR head: `{PR_HEAD}`.\n- Flutter CI #892 / run `{PR_RUN}`: all 69 gates PASSED, including AST-007 machine contract, 7/7 mutation regressions, Analyze, focused matrices, full Flutter suite, coverage, Debug APK, artifact security and upload.\n- PR Debug artifact: {PR_ARTIFACT}.\n- PR #213 squash merge: `{MERGE_SHA}`.\n- Exact-main Flutter CI #893 / run `{MAIN_RUN}`: all 69 gates PASSED.\n- Exact-main Debug artifact: {MAIN_ARTIFACT}.\n- Latest Verified APK promotion run `{PROMOTION_RUN}`: first attempt failed only on a transient external Maven Central HTTP 403 while downloading Kotlin artifacts; rerunning the same failed job without source/config changes PASSED release APK build, packaged-artifact security and current-main promotion.\n- Promotion commit: `{PROMOTION_COMMIT}`.\n- Retained QA release-mode APK: {QA_APK_SIZE} bytes; SHA-256 `{QA_APK_SHA}`; ephemeral CI signing; runtime ads disabled; not production/Play Store signed.\n\n## Remaining AST-007 acceptance\n\nThe source-controlled visual identity, manifest, resolver, runtime bridge and CI ownership are complete and stable on main. The feature remains IN PROGRESS because the production art pack itself is not present: 124 cargo descriptors exist, but approved provenance records and runtime cargo WebP binaries remain at zero. Real assets must be created/supplied, recorded with complete commercial-use provenance, validated against `pcargo` budgets, admitted through AST-011, and then exercised in device/profile visual and memory checks before AST-007 can be VERIFIED or GAME-012 can be unblocked.\n'''
work_path.write_text(work, encoding='utf-8')

print('AST-007 source checkpoint reconciliation applied')
