from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text()
old_victory = '| REW-001 | Victory result flow | P0 | IMPLEMENTED | GAME-011 | Stars, coins, XP, replay/map actions exist; final 3D animation remains. |'
new_victory = '| REW-001 | Victory result flow | P0 | IMPLEMENTED | GAME-011 | Issue #151 / PR #152 complete the premium Mission Debrief presentation checkpoint: world/city/level identity, stars, coins, XP, best combo and bonus/world reward metrics now use the shared result hierarchy while existing reward transaction and Next/map guards remain authoritative. Flutter CI #722 passed formatting, Analyze, the full Flutter suite, Debug APK build and artifact upload; PR #152 squash-merged as `462ec0590866879f654a4e031209731bd4eb84fd`. Full 3D reward animation remains REW-006. |'
old_failure = '| REW-002 | Failure result flow | P0 | IMPLEMENTED | GAME-011 | Retry/return flow exists and heart loss cannot duplicate; final design remains. |'
new_failure = '| REW-002 | Failure result flow | P0 | IMPLEMENTED | GAME-011 | Issue #151 / PR #152 complete the premium failure/recovery design with `MISSION INTERRUPTED`, compact scroll-safe recovery controls, exact Retry/rewarded semantics, and preserved heart-loss, rewarded +5 moves, no-fill and duplicate-action guards. Flutter CI #722 passed the full suite and Debug APK build before merge `462ec0590866879f654a4e031209731bd4eb84fd`. |'
for old, new, label in ((old_victory, new_victory, 'REW-001'), (old_failure, new_failure, 'REW-002')):
    if old not in text:
        raise SystemExit(f'{label} catalog row not found')
    text = text.replace(old, new, 1)
catalog.write_text(text)

status = Path('docs/STATUS.md')
text = status.read_text()
old_block = '''| Primary feature | None — `GAME-003` interaction polish is merged; `ENG-005` remains the next dependency-ready catalog item. |
| Completed checkpoint | `GAME-003` premium gameplay operations deck — PR #149 merged as `dfd92944791a35aa3c9b194c6401b3bf17bc5626` after current-main reconciliation and green Flutter CI #718. |
| Status | GAME-003 remains IMPLEMENTED with production interaction polish complete: live mission command/telemetry, Cargo Bay, Sorting Docks, premium booster dock, stable motion coordinates, and all deterministic input/result contracts passed the full Flutter suite. Authored 3D board/product assets remain under GAME-012/AST-007. |
| Previous checkpoint | `TEST-002` integrated production level release contract and verification tracking — PRs #144/#147; current-main reconciliation completed before GAME-003 final CI. |'''
new_block = '''| Primary feature | None — `UI3D-009` Mission Debrief is merged; `ENG-005` remains the next dependency-ready catalog item. |
| Completed checkpoint | `UI3D-009` premium Mission Result Debrief — PR #152 merged as `462ec0590866879f654a4e031209731bd4eb84fd` after green Flutter CI #722. |
| Status | Victory/failure presentation now completes the premium Home → World Map → Mission Control → Gameplay → Mission Debrief journey while preserving reward, heart-loss, rewarded continuation, no-fill, duplicate-action and navigation contracts. REW-001/REW-002 remain IMPLEMENTED; full 3D reward animation remains REW-006. |
| Previous checkpoint | `GAME-003` premium gameplay operations deck and tracking reconciliation — PRs #149/#150; current-main verification completed before UI3D-009. |'''
if old_block not in text:
    raise SystemExit('STATUS current-work block not found')
text = text.replace(old_block, new_block, 1)
marker = '## GAME-003 gameplay operations deck verification — 2026-08-09\n'
section = '''## UI3D-009 mission result debrief verification — 2026-08-09

- Issue #151 / PR #152 replace the generic result sheet with a premium `MISSION DEBRIEF` for both victory and failure states.
- Victory exposes route/world identity, stars, coins, XP, best combo and bonus/world rewards through the shared premium hierarchy; failure exposes `MISSION INTERRUPTED`, rewarded +5 moves and Retry recovery without altering the underlying state machine.
- Exact regression semantics `Retry`, `Next and back to map`, and `Watch ad for five moves` remain stable; `_resultVisible`, `_resultActionBusy`, sheet-dismissal, heart-loss, no-fill and duplicate-action behavior remain owned by the existing `GameScreen` methods.
- Compact 360x640 overflow hardening uses bounded scale-down for debrief labels; reduced-motion disables reward-icon animation.
- Superseded private gameplay presentation widgets left after GAME-003 were removed; `_CargoFlight` and active gameplay/motion logic were preserved.
- Flutter CI #722 / run `31314119391` passed dynamic Android, secret/privacy/security/asset gates, formatting, whitespace, Analyze, optional-service isolation, animated GameButton coverage, the full Flutter suite, Debug APK build and artifact upload on head `9f6ceb97d0e1e2ab45aa30136dce0b184999609d`.
- Debug artifact #9038304448 is 80,597,376 bytes with SHA-256 `76be94bd048b7f6029472035076c891ff4257c0d1f7ddc5d45cfde915403f9a2`.
- PR #152 squash-merged to main as `462ec0590866879f654a4e031209731bd4eb84fd`; Issue #151 closed Completed.
- REW-001 and REW-002 remain IMPLEMENTED because complete authored 3D reward animation is still tracked separately by REW-006; `ENG-005` remains the next dependency-ready catalog item.

'''
if marker not in text:
    raise SystemExit('GAME-003 status marker not found')
status.write_text(text.replace(marker, section + marker, 1))

work = Path('docs/work/UI3D-009.md')
text = work.read_text()
old_state = 'IN PROGRESS.'
new_state = 'IMPLEMENTED. PR #152 passed current-main Flutter CI #722 and squash-merged to `main` as `462ec0590866879f654a4e031209731bd4eb84fd`. REW-001/REW-002 remain IMPLEMENTED while full authored 3D reward animation stays tracked by REW-006.'
if old_state not in text:
    raise SystemExit('UI3D-009 work state not found')
text = text.replace(old_state, new_state, 1)
text += '''

## Verification evidence

- Focused branch gate passed premium win/loss visual contracts, compact result/back safety, repeated Next/Retry guards, rewarded no-fill, Analyze, and whitespace validation.
- Final Flutter CI #722 / run `31314119391` passed formatting, Analyze, the full Flutter suite, Debug APK build, and artifact upload on head `9f6ceb97d0e1e2ab45aa30136dce0b184999609d`.
- Debug artifact #9038304448: 80,597,376 bytes; SHA-256 `76be94bd048b7f6029472035076c891ff4257c0d1f7ddc5d45cfde915403f9a2`.
- Issue #151 closed Completed when PR #152 merged to main as `462ec0590866879f654a4e031209731bd4eb84fd`.
'''
work.write_text(text)
