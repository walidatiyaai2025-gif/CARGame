from pathlib import Path


def replace(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected exactly one match, found {count}: {old[:100]!r}')
    p.write_text(text.replace(old, new, 1), encoding='utf-8')

replace(
    'docs/FEATURE_CATALOG.md',
    '| UI3D-007 | Reduced motion and low-performance visual mode | P1 | IN PROGRESS | MOT-001 | Issue #205 / branch `agent/ui3d-007-adaptive-visual-effects` implement persistent user reduced-effects plus PERF-001 automatic graceful degradation across shared motion and visual-effect budgets; final CI/merge evidence pending. |',
    '| UI3D-007 | Reduced motion and low-performance visual mode | P1 | IMPLEMENTED | MOT-001 | Issue #205 / PR #206 implement persistent Automatic/Reduced visual-effects preference, app-wide effective reduction combining OS accessibility and user choice, PERF-001 full/constrained/reduced automatic quality, shared blur/shadow/particle/intensity/simultaneous-effect budgets, lifecycle/ambient/route/action integration, EN/AR live Settings control, privacy-inventory ownership, focused tests, 13/13 validator regressions, and permanent Flutter CI gates. Final PR head `2c0eb9f9983125d23a9d65d878ba142484d24975` passed Flutter CI #862 / run `31465635259` all 63 gates and artifact #9091564070; PR #206 squash-merged as `a342b3befed9259326fa769735f327e6916d1a5a`; exact-main CI #863 / run `31466188761` passed all 63 gates and artifact #9091803001. Source-controlled acceptance is IMPLEMENTED; physical-device visual/performance observation is not fabricated. |',
)

replace(
    'docs/STATUS.md',
    '| Primary feature | `UI3D-007` Reduced motion and adaptive visual effects — IN PROGRESS on issue #205 / `agent/ui3d-007-adaptive-visual-effects`. |',
    '| Primary feature | None — `UI3D-007` completed 100/100 source-controlled checkpoints as IMPLEMENTED; `A11Y-003` is selected next but not started. |',
)
replace(
    'docs/STATUS.md',
    '| Completed checkpoint | `TEST-011` privacy, consent, and security verification — IMPLEMENTED; issue #202 / PR #203 completed 100/100 repository checkpoints, PR #203 merged as `eb3f4df464173dab6729bfb6ed4ccf7289747057`, and exact-main Flutter CI #857 / run `31440863970` passed all 60 gates. |',
    '| Completed checkpoint | `UI3D-007` reduced motion and adaptive visual effects — IMPLEMENTED; issue #205 / PR #206 completed 100/100 source-controlled checkpoints, PR #206 merged as `a342b3befed9259326fa769735f327e6916d1a5a`, and exact-main Flutter CI #863 / run `31466188761` passed all 63 gates. |',
)
replace(
    'docs/STATUS.md',
    '| Status | TEST-011 repository-owned acceptance is IMPLEMENTED: 17/17 mutation regressions, 38 focused privacy/consent/security tests, 345 full-suite tests, 88.22% authored-source coverage, Debug APK build/security/upload, and exact-main verification are green. External production UMP/privacy-message regulated-region/device evidence remains PENDING, so VERIFIED is intentionally blocked. |',
    '| Status | UI3D-007 source-controlled acceptance is IMPLEMENTED: persistent Automatic/Reduced visual effects, app-wide accessibility/performance policy, shared effect budgets, EN/AR live Settings control, privacy inventory, 13/13 validator regressions, focused Flutter coverage, full suite/coverage, Debug APK build/security/upload, and exact-main verification are green. Physical-device visual/performance observation remains separate evidence and is not claimed. |',
)
replace(
    'docs/STATUS.md',
    '| Previous checkpoint | `PERF-002` memory and image budget — IMPLEMENTED with final PR CI #852, merged-runtime CI #853, and exact-main CI #854; physical-device RSS/GPU residency remains unclaimed. |',
    '| Previous checkpoint | `TEST-011` privacy, consent, and security verification — IMPLEMENTED with 100/100 repository checkpoints; external production UMP regulated-region/device evidence remains pending. |',
)
replace(
    'docs/STATUS.md',
    '| Next recommended feature | UI3D-007 is the active primary; no second source-controlled feature should start until its merge/reconciliation completes. |',
    '| Next recommended feature | `A11Y-003` Reduced motion — P1, dependency-ready now that UI3D-007 is implemented; selected next but not started. |',
)

status_path = Path('docs/STATUS.md')
status = status_path.read_text(encoding='utf-8')
anchor = '## TEST-011 privacy consent and security verification — 2026-08-11\n'
section = '''## UI3D-007 reduced motion and adaptive visual effects — 2026-08-11

- Issue #205 / PR #206 complete the 100-checkpoint source-controlled sprint. Repository status is IMPLEMENTED.
- The persistent local setting offers Automatic (default) and Reduced effects; unknown persisted values fail safely to Automatic and the setting applies live without restart.
- System Reduce Motion remains authoritative. PERF-001 remains the automatic performance-pressure authority beneath accessibility/user reduction.
- Shared `GameMotion` policy now governs duration, distance, scale, curves, blur, shadows, particles, intensity, decorative/expensive effects and simultaneous-effect budgets; lifecycle tickers, ambient visuals, routes and action feedback consume the effective profile.
- Settings exposes the control in English and Arabic. The new `settings_visual_effects` key is declared as local-only in the privacy inventory and follows the existing local reset/deletion contract.
- UI3D-007 machine validation and 13/13 validator regressions are permanent normal-CI gates. The focused UI3D matrix, TEST-007/TEST-011 regressions, Full Flutter Suite and coverage gate all pass.
- Final PR head `2c0eb9f9983125d23a9d65d878ba142484d24975` passed Flutter CI #862 / run `31465635259` all 63 gates. Debug artifact #9091564070 is 80,656,826 bytes with SHA-256 `4932211b4269edc245d008ded40011f4bce83edd37d1cef672ac1a8744b945c2`.
- PR #206 squash-merged as `a342b3befed9259326fa769735f327e6916d1a5a`. Exact-main Flutter CI #863 / run `31466188761` passed all 63 gates. Main debug artifact #9091803001 is 80,656,824 bytes with SHA-256 `8064cd7b0b1941db47b5df614e38666865972a5995020731baff4323bb9e5922`.
- No physical-device frame/visual result is invented. That broader observation remains separate from source-controlled acceptance.
- Fresh dependency-ready scan selects exactly one next source-controlled workstream: `A11Y-003` Reduced motion (P1), now unblocked by UI3D-007. It is selected but not started.

'''
if status.count(anchor) != 1:
    raise SystemExit('docs/STATUS.md: TEST-011 section anchor mismatch')
status_path.write_text(status.replace(anchor, section + anchor, 1), encoding='utf-8')

Path('docs/work/UI3D-007.md').write_text('''# UI3D-007 Reduced Motion and Adaptive Visual Effects

Issue: #205
Implementation PR: #206
Merge: `a342b3befed9259326fa769735f327e6916d1a5a`

## State

IMPLEMENTED — 100/100 source-controlled checkpoints complete. The historical world-map visual-refresh branch that reused UI3D-007 is stale/reference-only.

## Runtime contract

- Persistent user setting: Automatic (default) or Reduced visual effects; malformed/unknown persisted values fail safely to Automatic.
- System `MediaQuery.disableAnimations` remains authoritative.
- PERF-001 `FramePerformanceScope` remains the automatic full/constrained/reduced performance-quality authority.
- `GameMotion` combines user/system accessibility with performance pressure and exposes deterministic duration, distance, scale, curve, blur, shadow, particle, intensity, decorative/expensive-effect and simultaneous-effect budgets.
- Shared ambient motion, route motion, action feedback and lifecycle ticker policy consume the shared effective profile; existing travel/button consumers continue through `GameMotion`.
- Visual reduction never changes gameplay, rewards, haptics, sound dispatch, navigation identity, ads/privacy behavior or completion callbacks.
- `settings_visual_effects` is local-only privacy-inventoried state and participates in the existing Settings local reset/deletion flow.

## 100-checkpoint evidence

- T001-T080: source/runtime/settings integration complete.
- T081-T096: focused persistence/scope/policy/Settings tests, machine validator, 13/13 mutation regressions and permanent normal-CI ownership complete.
- T097-T098: final PR CI #862 / run `31465635259` passed all 63 gates including Full Flutter Suite, coverage threshold, Debug APK, packaged artifact security and upload. Artifact #9091564070: 80,656,826 bytes; SHA-256 `4932211b4269edc245d008ded40011f4bce83edd37d1cef672ac1a8744b945c2`.
- T099: PR #206 squash-merged as `a342b3befed9259326fa769735f327e6916d1a5a`; exact-main CI #863 / run `31466188761` passed all 63 gates. Main artifact #9091803001: 80,656,824 bytes; SHA-256 `8064cd7b0b1941db47b5df614e38666865972a5995020731baff4323bb9e5922`.
- T100: fresh dependency-ready scan selects exactly one next source-controlled workstream: `A11Y-003` Reduced motion (P1), dependency UI3D-007 satisfied; selected but not started.

## Verification boundary

UI3D-007 is IMPLEMENTED from repository-owned evidence. No physical-device frame-rate or subjective visual-quality measurement is claimed by CI; those observations must remain separate real-device evidence where required by broader release/performance validation.
''', encoding='utf-8')

print('UI3D-007 reconciliation patch applied: 100/100 -> IMPLEMENTED; A11Y-003 selected next')
