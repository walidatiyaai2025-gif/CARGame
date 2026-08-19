#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace(relative: str, old: str, new: str) -> None:
    path = ROOT / relative
    text = path.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'{relative}: missing migration marker: {old!r}')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


def main() -> int:
    replace(
        'docs/work/AST-007.md',
        'Current branch: `agent/ast-007-cargo-batch-01`',
        'Current branch: `agent/ast-007-batch01-procedural-art`',
    )
    replace(
        'docs/work/AST-007.md',
        'IN PROGRESS — source integration and deterministic production-intake tooling are merged and exact-main verified; Batch 01 production handoff is active while real cargo WebP/provenance admission remains open.',
        'IN PROGRESS — source integration and deterministic production-intake tooling are merged and exact-main verified; Batch 01 now admits 12 project-original provenance-backed cargo WebP assets while the remaining 112 production identities stay open.',
    )
    replace('docs/work/AST-007.md', 'Approved provenance records: 0.', 'Approved provenance records: 12.')
    replace('docs/work/AST-007.md', 'Runtime WebP binaries: 0.', 'Runtime WebP binaries: 12.')
    replace(
        'docs/work/AST-007.md',
        '- Active branch: `agent/ast-007-cargo-batch-01`.',
        '- Active branch: `agent/ast-007-batch01-procedural-art`.',
    )
    replace(
        'docs/work/AST-007.md',
        '- This checkpoint deliberately creates no runtime WebP and no provenance. The production truth remains 133 descriptors / 0 approved provenance / 0 runtime WebP until real art is supplied and admitted.',
        '- Batch 01 now contains 12 runtime WebP files and 12 matching provenance records generated from source-controlled project-original procedural artwork. Production truth is 133 descriptors / 12 approved provenance / 12 runtime cargo WebP; AST-007 remains IN PROGRESS with 112 cargo identities still unadmitted.',
    )
    replace(
        'docs/work/AST-007.md',
        'The source-controlled visual identity, manifest, resolver, runtime bridge, deterministic intake planner, and Batch 01 handoff contract are complete or active. The feature remains IN PROGRESS because the production art pack itself is not present: 124 cargo descriptors exist, but approved provenance records and runtime cargo WebP binaries remain at zero. Real assets must be created/supplied, recorded with complete commercial-use provenance, validated against `pcargo` budgets, admitted through AST-011, and then exercised in device/profile visual and memory checks before AST-007 can be VERIFIED or GAME-012 can be unblocked.',
        'The source-controlled visual identity, manifest, resolver, runtime bridge, deterministic intake planner, and first production-art admission batch are active. The feature remains IN PROGRESS: 124 cargo descriptors exist, 12 now have provenance-backed runtime WebP binaries, and 112 remain unadmitted. Remaining assets must be created with complete commercial-use provenance, validated against `pcargo` budgets, admitted through AST-011, and then exercised in device/profile visual and memory checks before AST-007 can be VERIFIED or GAME-012 can be unblocked.',
    )

    replace(
        'docs/work/AST-007-BATCH-01.md',
        'Branch: `agent/ast-007-cargo-batch-01`',
        'Branch: `agent/ast-007-batch01-procedural-art`',
    )
    replace(
        'docs/work/AST-007-BATCH-01.md',
        'Prepare a reproducible production-art handoff for the first 12 deterministic cargo assets selected by the merged AST-007 intake planner. This checkpoint defines what must be created and how it must be validated; it does not pretend that artwork, commercial-use approval, or runtime admission already exists.',
        'Record and enforce the first admitted production-art batch for the 12 deterministic cargo assets selected by the AST-007 intake planner. The runtime artwork is project-original procedural WebP generated from source-controlled geometry instructions, and each admitted file has matching provenance and a verified export checksum.',
    )
    replace('docs/work/AST-007-BATCH-01.md', 'Runtime binary status: `NOT_CREATED`', 'Runtime binary status: `READY`')
    replace('docs/work/AST-007-BATCH-01.md', 'Provenance status: `NOT_CREATED`', 'Provenance status: `READY`')
    replace(
        'docs/work/AST-007-BATCH-01.md',
        'For each asset, the next production step is:\n\n1. create/render the original asset against `spec.json`;\n2. export the runtime WebP to its exact manifest path under the 120 KiB pcargo budget;\n3. record complete AST-011 provenance with commercial-use evidence and real checksums;\n4. change the spec status only when the corresponding artifact/record actually exists;\n5. run AST-007 validation, AST-011 asset admission, full Flutter CI, and device/profile visual/memory checks;\n6. keep the existing Flutter fallback active for any item not successfully admitted.',
        'For each asset in this batch the source-controlled admission sequence is now complete through the repository gate:\n\n1. render the original deterministic project-owned asset from the checked-in generator;\n2. export the runtime WebP to its exact manifest path under the 120 KiB pcargo budget;\n3. record AST-011 provenance with commercial-use evidence and real source/export checksums;\n4. mark the spec READY only because the corresponding binary and provenance record exist;\n5. verify WebP container, byte budget and SHA-256 equality against provenance;\n6. keep device/profile visual and memory observation as separate evidence and keep fallbacks for all still-unadmitted cargo identities.',
    )
    replace(
        'docs/work/AST-007-BATCH-01.md',
        '- No runtime cargo WebP is added by this handoff checkpoint.\n- No provenance record is added or auto-approved.\n- No commercial-use license is inferred from a prompt.\n- No production signing or physical-device visual evidence is claimed.\n- `AST-007` remains IN PROGRESS and `GAME-012` remains blocked.',
        '- This checkpoint admits exactly 12 runtime cargo WebP files and 12 matching source-controlled provenance records; it does not claim the remaining 112 cargo identities are complete.\n- Commercial-use status comes from the project-original source-controlled procedural artwork record, not from prompt text alone.\n- No production signing or physical-device visual/performance evidence is claimed.\n- `AST-007` remains IN PROGRESS and `GAME-012` remains blocked until the full production pack and required device evidence are complete.',
    )

    replace(
        'docs/STATUS.md',
        '| Primary feature | `AST-007` 100+ cargo visual pack — IN PROGRESS on issue #210. Source integration and deterministic production-intake tooling are merged; real cargo WebP/provenance admission is the active remaining work. |',
        '| Primary feature | `AST-007` 100+ cargo visual pack — IN PROGRESS on issue #210. The first 12 project-original cargo WebP assets now have matching provenance/checksums; 112 cargo identities remain to be admitted. |',
    )
    replace(
        'docs/STATUS.md',
        '| Status | AST-007 intake is now mechanically production-ready for handoff: immutable readiness metrics, orphan detection, deterministic offset/state paging, human/JSON/CSV output, strict completion mode, Batch-01 integration, 24 composed mutation protections and normal-CI smoke are green. Exact-main artifact #9102597251 (80,673,118 bytes; SHA-256 `13bbc58b07c3e772ed57b45b30c30943e155af83fa3312228370697610ca5917`). Production truth remains 133 descriptors / 0 approved provenance / 0 runtime WebP, so parent AST-007 remains IN PROGRESS and GAME-012 remains blocked. |',
        '| Status | AST-007 intake is mechanically production-ready and Batch 01 has moved from handoff to real admission: 133 descriptors / 12 approved provenance records / 12 runtime cargo WebP. All 12 files are project-original procedural artwork with real export SHA-256 checksums; 112 cargo identities remain, so AST-007 stays IN PROGRESS and GAME-012 stays blocked. |',
    )
    replace(
        'docs/STATUS.md',
        '| Next recommended feature | Continue AST-007 with real production cargo-art batch admission. The deterministic first 12-item batch is defined; do not start a second primary feature until real WebP + commercial-use provenance begin passing AST-011 admission. |',
        '| Next recommended feature | Continue AST-007 with the next deterministic production cargo-art batch. Batch 01 has begun real WebP + provenance admission; do not start a second primary feature while 112 cargo identities remain. |',
    )
    replace(
        'docs/STATUS.md',
        '| Known blocker | `AST-007` still has 0 runtime cargo WebP and 0 approved provenance, so `GAME-012` remains blocked.',
        '| Known blocker | `AST-007` has admitted 12/124 runtime cargo WebP identities with matching provenance; 112 remain, so `GAME-012` remains blocked.',
    )

    replace(
        'tool/verify_ast_007_cargo_visuals.py',
        "        'Approved provenance records: 0.',\n        'Runtime WebP binaries: 0.',",
        "        'Approved provenance records: 12.',\n        'Runtime WebP binaries: 12.',",
    )
    replace(
        'tool/verify_ast_007_cargo_visuals.py',
        "        'Runtime binary status: `NOT_CREATED`',\n        'Provenance status: `NOT_CREATED`',",
        "        'Runtime binary status: `READY`',\n        'Provenance status: `READY`',",
    )
    replace(
        'tool/verify_ast_007_cargo_visuals.py',
        "    'docs/work/AST-007-INTAKE-HARDENING-100.md',\n    '.github/workflows/flutter_ci.yml',",
        "    'docs/work/AST-007-INTAKE-HARDENING-100.md',\n    'docs/work/AST-007-batch01.md',\n    '.github/workflows/flutter_ci.yml',",
    )
    replace(
        'tool/verify_ast_007_cargo_visuals.py',
        "    hardening_doc = _read(root, 'docs/work/AST-007-INTAKE-HARDENING-100.md')",
        "    admission_doc = _read(root, 'docs/work/AST-007-batch01.md')\n    for token in [\n        'Generator SHA-256:',\n        '12 assets',\n        'No third-party image, logo, trademark, model, or licensed visual source is incorporated.',\n        'AST-007 remains IN PROGRESS',\n    ]:\n        if token not in admission_doc:\n            raise ValidationError(f'AST-007 batch 01 admission evidence missing: {token}')\n\n    hardening_doc = _read(root, 'docs/work/AST-007-INTAKE-HARDENING-100.md')",
    )
    replace(
        'tool/test_ast_007_cargo_visuals.py',
        "            'Approved provenance records: 0.',\n            'Approved provenance records: 124.',",
        "            'Approved provenance records: 12.',\n            'Approved provenance records: 124.',",
    )

    print('AST-007 Batch 01 tracking migrated to 12 admitted / 112 remaining')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
