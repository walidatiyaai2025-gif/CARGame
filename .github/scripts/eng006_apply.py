from pathlib import Path

CATALOG_OLD = '| ENG-006 | Dependency and package governance | P1 | PLANNED | ENG-001 | Dependencies are reviewed, pinned sensibly, licensed, and upgrade policy is documented. |'
CATALOG_NEW = '| ENG-006 | Dependency and package governance | P1 | IN PROGRESS | ENG-001 | Issue #157 implements executable package governance: approved pub.dev/SDK sources, manifest-to-lock alignment, reviewed direct-package licenses, explicit upgrade review, and non-blocking drift reporting without changing production dependency versions. |'

STATUS_REPLACEMENTS = {
    '| Primary feature | None — `ENG-005` first architecture-boundary checkpoint is merged; `ENG-006` is the next dependency-ready engineering item. |': '| Primary feature | `ENG-006` Dependency and package governance — Issue #157 / branch `agent/eng-006-dependency-governance`. |',
    '| Status | ENG-005 is IMPLEMENTED at the core/composition boundary: `main.dart` is thin, process dependencies are owned by `AppComposition`, optional-service state/port live in inward layers, and architecture tests prohibit outward domain/application imports. Presentation-to-adapter migration debt remains, so ENG-005 is not VERIFIED. |': '| Status | ENG-006 audit and implementation are active. Direct hosted package sources, lockfile alignment, reviewed license families, and upgrade drift are now enforced/reported by code; no production dependency version change is planned for this checkpoint. |',
    '| Next recommended feature | `ENG-006` Dependency and package governance — review/pin dependency policy, licenses, and safe upgrade workflow now that the architecture boundary is enforceable. |': '| Next recommended feature | Complete `ENG-006` governance verification and full CI/APK before selecting the next dependency-ready catalog item. |',
}

STATUS_SECTION = '''## ENG-006 dependency governance audit — 2026-08-09

- Issue #157 audits the dependency graph against the committed `pubspec.yaml` / `pubspec.lock` pair before changing any package version.
- Direct hosted packages resolve from pub.dev with reviewed licenses: Flame 1.38.0 MIT; Google Mobile Ads 9.0.0 Apache-2.0; Shared Preferences 2.5.5 BSD-3-Clause; Path Provider 2.1.6 BSD-3-Clause; Cupertino Icons 1.0.9 MIT; Flutter Lints 6.0.0 BSD-3-Clause; Shared Preferences Platform Interface 2.4.2 BSD-3-Clause.
- `flutter pub outdated --json` reports seven newer versions outside current constraints, all transitive (`hooks`, `intl`, `matcher`, `meta`, `record_use`, `test_api`, `vector_math`); no direct hosted dependency requires a version change for this checkpoint.
- The implementation adds an executable source/constraint/lock/license contract, a reviewed direct-license inventory, regression tests, CI enforcement after package restore, and non-blocking drift visibility.

'''

WORK_AUDIT = '''
## Audit findings

- Direct runtime: `flame` 1.38.0 MIT; `google_mobile_ads` 9.0.0 Apache-2.0; `shared_preferences` 2.5.5 BSD-3-Clause; `path_provider` 2.1.6 BSD-3-Clause; `cupertino_icons` 1.0.9 MIT.
- Direct development: `flutter_lints` 6.0.0 BSD-3-Clause; `shared_preferences_platform_interface` 2.4.2 BSD-3-Clause.
- The committed lockfile is internally aligned with every direct hosted manifest constraint.
- The outdated audit found seven newer versions outside current constraints, all transitive: `hooks`, `intl`, `matcher`, `meta`, `record_use`, `test_api`, and `vector_math`.
- No direct package upgrade is required for this checkpoint; governance is being added around the current known-good graph.
'''


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old in text:
        return text.replace(old, new, 1)
    if new in text:
        return text
    raise SystemExit(f'{label} marker not found')


def main() -> None:
    catalog = Path('docs/FEATURE_CATALOG.md')
    catalog_text = catalog.read_text(encoding='utf-8')
    catalog_text = replace_once(
        catalog_text,
        CATALOG_OLD,
        CATALOG_NEW,
        'ENG-006 catalog row',
    )
    catalog.write_text(catalog_text, encoding='utf-8')

    status = Path('docs/STATUS.md')
    status_text = status.read_text(encoding='utf-8')
    for old, new in STATUS_REPLACEMENTS.items():
        status_text = replace_once(status_text, old, new, 'ENG-006 status row')
    if '## ENG-006 dependency governance audit — 2026-08-09' not in status_text:
        marker = '## ENG-005 clean architecture boundary checkpoint — 2026-08-09\n'
        if marker not in status_text:
            raise SystemExit('ENG-005 status insertion marker not found')
        status_text = status_text.replace(marker, STATUS_SECTION + marker, 1)
    status.write_text(status_text, encoding='utf-8')

    work = Path('docs/work/ENG-006.md')
    work_text = work.read_text(encoding='utf-8').rstrip()
    if '## Audit findings' not in work_text:
        work_text += WORK_AUDIT
    work.write_text(work_text.rstrip() + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
