from pathlib import Path

MERGE_SHA = 'e8e474e54ada81b5936bd5adf0d9aa9e31ff117e'
CI_RUN = '31324376214'
CI_NUMBER = '730'
HEAD_SHA = '2bf80a697e17a28af9b30a0d479452c1e6dbad24'
ARTIFACT_ID = '9041192218'
ARTIFACT_SIZE = '80,594,411'
ARTIFACT_SHA = 'ebd0fefb2d148323693361a68a0e0729b5b8d697863572e5f9584575549e1f0d'


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old in text:
        return text.replace(old, new, 1)
    if new in text:
        return text
    raise SystemExit(f'{label} marker not found')


def main() -> None:
    catalog = Path('docs/FEATURE_CATALOG.md')
    text = catalog.read_text(encoding='utf-8')
    old = '| ENG-006 | Dependency and package governance | P1 | IN PROGRESS | ENG-001 | Issue #157 implements executable package governance: approved pub.dev/SDK sources, manifest-to-lock alignment, reviewed direct-package licenses, explicit upgrade review, and non-blocking drift reporting without changing production dependency versions. |'
    new = f'| ENG-006 | Dependency and package governance | P1 | VERIFIED | ENG-001 | Issue #157 / PR #158 add executable dependency governance for approved pub.dev/SDK sources, manifest-to-lock alignment, reviewed direct-package licenses, controlled upgrades, and non-blocking drift reporting without changing production dependency versions. The baseline reviewed all seven direct hosted packages and found only transitive outdated drift. Flutter CI #{CI_NUMBER} passed the new governance gates, Analyze, full Flutter suite, Debug APK build, and artifact upload; PR #158 squash-merged as `{MERGE_SHA}`. |'
    catalog.write_text(replace_once(text, old, new, 'ENG-006 catalog row'), encoding='utf-8')

    status = Path('docs/STATUS.md')
    text = status.read_text(encoding='utf-8')
    replacements = {
        '| Primary feature | `ENG-006` Dependency and package governance — Issue #157 / branch `agent/eng-006-dependency-governance`. |': '| Primary feature | None — `ENG-006` dependency/package governance is verified; `ENG-007` CI verification workflow is the next dependency-ready engineering item. |',
        '| Completed checkpoint | `ENG-005` enforceable clean-architecture boundary checkpoint — PR #155 merged as `07fb50182efe5ce315cdda8bf823ba4da855c2df` after green Flutter CI #726. |': f'| Completed checkpoint | `ENG-006` dependency and package governance — PR #158 merged as `{MERGE_SHA}` after green Flutter CI #{CI_NUMBER}. |',
        '| Status | ENG-006 audit and implementation are active. Direct hosted package sources, lockfile alignment, reviewed license families, and upgrade drift are now enforced/reported by code; no production dependency version change is planned for this checkpoint. |': '| Status | ENG-006 is VERIFIED: normal Flutter CI now enforces approved dependency sources, direct manifest/lock alignment, reviewed direct-package licenses and policy regressions while reporting upstream version drift without auto-upgrading. |',
        '| Previous checkpoint | `UI3D-009` premium Mission Result Debrief and tracking reconciliation — PRs #152/#153. |': '| Previous checkpoint | `ENG-005` enforceable clean-architecture boundary checkpoint — PRs #155/#156. |',
        '| Next recommended feature | Complete `ENG-006` governance verification and full CI/APK before selecting the next dependency-ready catalog item. |': '| Next recommended feature | `ENG-007` CI verification workflow — close the remaining CI acceptance gaps around dashboard/parser validation and protected release checks while preserving the existing green Flutter pipeline. |',
    }
    for old_value, new_value in replacements.items():
        text = replace_once(text, old_value, new_value, 'ENG-006 status row')

    marker = '## ENG-006 dependency governance audit — 2026-08-09\n'
    verification = f'''## ENG-006 dependency governance verification — 2026-08-09

- Issue #157 / PR #158 implement dependency governance without changing any production dependency version or runtime behavior.
- The committed `pubspec.lock` remains authoritative for application builds; direct hosted dependencies must resolve from `https://pub.dev`, match their manifest constraint/direct kind, and have a reviewed installed license family.
- Git/path/custom-host direct dependencies and `dependency_overrides` are rejected by the governance verifier until explicitly reviewed.
- The reviewed direct inventory is: Flame 1.38.0 MIT; Google Mobile Ads 9.0.0 Apache-2.0; Shared Preferences 2.5.5 BSD-3-Clause; Path Provider 2.1.6 BSD-3-Clause; Cupertino Icons 1.0.9 MIT; Flutter Lints 6.0.0 BSD-3-Clause; Shared Preferences Platform Interface 2.4.2 BSD-3-Clause.
- Eight focused policy regressions cover valid hosted resolution, git/custom-source rejection, lock-constraint drift, mandatory license review on direct upgrades, missing/mismatched licenses, and dependency overrides.
- `flutter pub outdated --json` remains non-blocking review evidence; the baseline reported seven newer versions outside current constraints and all seven are transitive, so ENG-006 intentionally performs no package upgrade.
- Flutter CI #{CI_NUMBER} / run `{CI_RUN}` passed the new dependency-governance gates, dynamic Android/secret/privacy/security/assets gates, formatting, whitespace, Analyze, optional-service isolation, GameButton coverage, full Flutter suite, Debug APK build, and artifact upload on head `{HEAD_SHA}`.
- Debug artifact #{ARTIFACT_ID} is {ARTIFACT_SIZE} bytes with SHA-256 `{ARTIFACT_SHA}`.
- PR #158 squash-merged to main as `{MERGE_SHA}`; Issue #157 closed Completed. ENG-006 has no remaining acceptance blocker and is VERIFIED.

'''
    if '## ENG-006 dependency governance verification — 2026-08-09' not in text:
        if marker not in text:
            raise SystemExit('ENG-006 audit insertion marker not found')
        text = text.replace(marker, verification + marker, 1)
    status.write_text(text, encoding='utf-8')

    work = Path('docs/work/ENG-006.md')
    text = work.read_text(encoding='utf-8')
    old_state = 'IN PROGRESS.'
    new_state = f'VERIFIED. PR #158 passed Flutter CI #{CI_NUMBER} and squash-merged to `main` as `{MERGE_SHA}`. The source/lock/license/upgrade policy is enforced in normal CI, and no direct dependency upgrade was required for this checkpoint.'
    text = replace_once(text, old_state, new_state, 'ENG-006 work state')
    if '## Verification evidence' not in text:
        text = text.rstrip() + f'''

## Verification evidence

- Governance verifier passed against the restored production dependency graph.
- Eight focused dependency-policy regression tests passed.
- Normal Flutter CI #{CI_NUMBER} / run `{CI_RUN}` exercised the newly added governance verifier, policy regression suite, and non-blocking outdated report before Analyze/full tests/APK.
- Full Flutter suite, Debug APK build, and artifact upload passed on `{HEAD_SHA}`.
- Debug artifact #{ARTIFACT_ID}: {ARTIFACT_SIZE} bytes; SHA-256 `{ARTIFACT_SHA}`.
- PR #158 squash-merged as `{MERGE_SHA}` and Issue #157 closed Completed.
- No direct dependency version changed; the only observed outdated drift was seven transitive packages, recorded for future controlled review.
'''
    work.write_text(text.rstrip() + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
