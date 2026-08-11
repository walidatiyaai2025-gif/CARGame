#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

STATUS = ROOT / 'docs/STATUS.md'
CATALOG = ROOT / 'docs/FEATURE_CATALOG.md'
WORK = ROOT / 'docs/work/AST-007.md'

MERGE_SHA = '356aff3b6901f17036b5e9c8d8e002e7f226ce10'
PR_RUN = '31487583861'
MAIN_RUN = '31488362505'
PR_ARTIFACT_SHA = 'a394e2c0feb7f76b084c2603fced63c5ada4438370b69c13f9398e9af91f28f7'
MAIN_ARTIFACT_SHA = '3ae614db8a1b90675d312b8371fc4ce841aa7c14526d88bad92667053022e0a0'

FIRST_BATCH = (
    '`cargo.accessory_box`, `cargo.accessory_carton`, `cargo.action_figure_box`, '
    '`cargo.apparel_box`, `cargo.apple_crate`, `cargo.archive_box`, '
    '`cargo.auto_part_crate`, `cargo.bakery_box`, `cargo.basketball_bag`, '
    '`cargo.battery_pack`, `cargo.board_game_box`, `cargo.boot_carton`'
)


def replace_prefixed_line(text: str, prefix: str, replacement: str) -> str:
    lines = text.splitlines()
    matches = [index for index, line in enumerate(lines) if line.startswith(prefix)]
    if len(matches) != 1:
        raise RuntimeError(f'Expected exactly one line starting with {prefix!r}, found {len(matches)}')
    lines[matches[0]] = replacement
    return '\n'.join(lines) + ('\n' if text.endswith('\n') else '')


def update_status() -> None:
    text = STATUS.read_text(encoding='utf-8')
    text = replace_prefixed_line(
        text,
        '| Primary feature |',
        '| Primary feature | `AST-007` 100+ cargo visual pack — IN PROGRESS on issue #210. Source integration and deterministic production-intake tooling are merged; real cargo WebP/provenance admission is the active remaining work. |',
    )
    text = replace_prefixed_line(
        text,
        '| Completed checkpoint |',
        f'| Completed checkpoint | `AST-007` production asset intake tooling — PR #215 merged as `{MERGE_SHA}`; PR Flutter CI #901 / run `{PR_RUN}` and exact-main Flutter CI #902 / run `{MAIN_RUN}` both passed all 69 gates. |',
    )
    text = replace_prefixed_line(
        text,
        '| Status |',
        f'| Status | AST-007 now has deterministic production intake planning in addition to the merged 124-identity visual layer. `GameAssetIntakePlan` classifies admitted/missing-binary/missing-provenance states, validates descriptor/provenance alignment, normalizes runtime paths, and the CLI emits stable 12-item or configurable JSON handoff batches. PR #215 artifact #9099976486 is 80,673,122 bytes (SHA-256 `{PR_ARTIFACT_SHA}`); exact-main artifact #9100262930 is 80,673,121 bytes (SHA-256 `{MAIN_ARTIFACT_SHA}`). Production truth remains 133 descriptors / 0 approved provenance / 0 runtime WebP, so AST-007 remains IN PROGRESS. |',
    )
    text = replace_prefixed_line(
        text,
        '| Next recommended feature |',
        '| Next recommended feature | Continue AST-007 with real production cargo-art batch admission. The deterministic first 12-item batch is defined; do not start a second primary feature until real WebP + commercial-use provenance begin passing AST-011 admission. |',
    )
    text = replace_prefixed_line(
        text,
        '| Known blocker |',
        '| Known blocker | `AST-007` still has 0 runtime cargo WebP and 0 approved provenance, so `GAME-012` remains blocked. `TEST-011` VERIFIED still requires real production AdMob Privacy & messaging/UMP regulated-region/device evidence. `TEST-009` remains blocked on PERF-001 physical-device frame profiling. `REL-007`/`REL-008` require real production AdMob/signing inputs and a production-signed candidate; final install/upgrade/device smoke requires an Android device/testing track. |',
    )

    marker = '## AST-007 cargo visual pack — 2026-08-11\n\n'
    if marker not in text:
        raise RuntimeError('AST-007 STATUS section marker missing')
    checkpoint = (
        f'- Production-intake PR #215 merged as `{MERGE_SHA}` after Flutter CI #901 / run `{PR_RUN}` passed all 69 gates; PR artifact #9099976486 is 80,673,122 bytes with SHA-256 `{PR_ARTIFACT_SHA}`.\n'
        f'- Exact-main Flutter CI #902 / run `{MAIN_RUN}` repeated all 69 gates successfully on `{MERGE_SHA}`; main artifact #9100262930 is 80,673,121 bytes with SHA-256 `{MAIN_ARTIFACT_SHA}`.\n'
        '- `GameAssetIntakePlan` and `tool/plan_ast_007_asset_intake.dart` now turn the 124 descriptor backlog into deterministic batches, prioritize interrupted partial admissions, normalize Windows/Linux runtime paths, validate any existing provenance against its manifest descriptor, and expose JSON handoff output. AST-007 machine ownership now includes 10/10 mutation regressions.\n'
        f'- First deterministic 12-item production batch: {FIRST_BATCH}. No binary or provenance is claimed for these IDs yet.\n'
    )
    if 'Production-intake PR #215 merged' not in text:
        text = text.replace(marker, marker + checkpoint, 1)
    STATUS.write_text(text, encoding='utf-8')


def update_catalog() -> None:
    text = CATALOG.read_text(encoding='utf-8')
    row = (
        f'| AST-007 | 100+ 3D cargo product pack | P1 | IN PROGRESS | AST-002 | Issue #210 keeps AST-007 as the single active product-art workstream. PR #213 merged the 124-identity source layer as `132c0cff75057e21a8bdea50550b6b8bcd7e04f6`; PR #215 then merged deterministic production-intake tooling as `{MERGE_SHA}`. PR Flutter CI #901 / run `{PR_RUN}` passed all 69 gates with artifact #9099976486 (80,673,122 bytes; SHA-256 `{PR_ARTIFACT_SHA}`), and exact-main Flutter CI #902 / run `{MAIN_RUN}` repeated all 69 gates with artifact #9100262930 (80,673,121 bytes; SHA-256 `{MAIN_ARTIFACT_SHA}`). `GameAssetIntakePlan` classifies admitted/missing-binary/missing-provenance states, validates descriptor/provenance alignment, normalizes runtime paths and produces deterministic CLI/JSON batches; AST-007 validator ownership now includes 10/10 mutation regressions. Gameplay truth remains 18 stable archetype IDs across the deterministic 150-level catalog. Production art is deliberately not claimed complete: main has 133 manifest descriptors total, 0 approved provenance records and 0 runtime cargo WebP binaries. AST-007 therefore remains IN PROGRESS and GAME-012 remains blocked until real commercial-use WebP/provenance and device/profile evidence exist. |'
    )
    text = replace_prefixed_line(text, '| AST-007 |', row)
    CATALOG.write_text(text, encoding='utf-8')


def update_work() -> None:
    text = WORK.read_text(encoding='utf-8')
    text = replace_prefixed_line(
        text,
        'Current branch:',
        'Current branch: intake checkpoint merged on `main`; next real production-art branch not started.',
    )

    marker = '## Remaining AST-007 acceptance\n'
    if marker not in text:
        raise RuntimeError('AST-007 remaining-acceptance marker missing')
    evidence = (
        '## Production intake verification evidence\n\n'
        f'- PR #215 final head `87c06301c1d92d3c92ce0f737887a98203bf944d` passed Flutter CI #901 / run `{PR_RUN}` all 69 gates, including the 10/10 AST-007 mutation regressions, canonical formatting, Analyze, full Flutter suite, coverage, Debug APK, artifact security and upload.\n'
        f'- PR artifact #9099976486: 80,673,122 bytes; SHA-256 `{PR_ARTIFACT_SHA}`.\n'
        f'- PR #215 squash-merged as `{MERGE_SHA}`.\n'
        f'- Exact-main Flutter CI #902 / run `{MAIN_RUN}` passed all 69 gates on `{MERGE_SHA}`.\n'
        f'- Exact-main artifact #9100262930: 80,673,121 bytes; SHA-256 `{MAIN_ARTIFACT_SHA}`.\n'
        f'- With the truthful 0-binary / 0-provenance baseline, the first deterministic 12-item batch is: {FIRST_BATCH}. These are handoff targets only; no runtime binary, commercial-use approval or device evidence is fabricated.\n\n'
    )
    if '## Production intake verification evidence' not in text:
        text = text.replace(marker, evidence + marker, 1)
    WORK.write_text(text, encoding='utf-8')


def main() -> None:
    update_status()
    update_catalog()
    update_work()
    print('AST-007 intake tracking reconciliation applied.')


if __name__ == '__main__':
    main()
