# CARGame Live Project Status

This document is the short operational dashboard. Detailed function tracking lives in `docs/FEATURE_CATALOG.md`.
Codex must update this file during every implementation task.

## Project objective

Build a production-quality Flutter cargo sorting game with 150 levels, 6 worlds,
a completely unified 3D-rendered visual style, responsive animation, offline-first
progress, Arabic/English support, and Android release readiness.

## Current work

| Field | Value |
|---|---|
| Current phase | Engineering foundation and baseline stabilization |
| Active feature | `ENG-002` Stable Android build toolchain / `REL-001` dynamic device scripts |
| Status | IN PROGRESS |
| Branch | main |
| Blocker | Repeated emulator/ADB offline behavior requires dynamic and resilient handling |
| Next checkpoint | Verify all scripts contain no fixed device/AVD names and complete a debug run on any supported selected device |

## Overall progress by area

| Area | State | Notes |
|---|---|---|
| Engineering foundation | In progress | Build repair, startup resilience, diagnostics mostly implemented; audit and CI remain. |
| Shared 3D design system | Partial | Reusable 3D-style icon component and several converted screens exist. |
| Motion system | Planned | Requirements documented; reusable motion tokens/primitives are next. |
| 3D asset pipeline | Planned | Folder taxonomy, manifest, typed registry, and production WebP packs remain. |
| Home | Partial | 3D-style redesign exists; production assets and full motion pass remain. |
| World/city map | Partial | Six worlds/150 cities and responsive map exist; production assets/unlock motion remain. |
| Mission briefing | Partial | Loadout and 3D-style presentation exist; transition/motion verification remain. |
| Gameplay | Partial | Core sorting, moves, combo, boosters, win/loss exist; full 3D board/products/effects remain. |
| Levels | Partial | 150 entries exist; balancing, solvability validation, and boss mechanics remain. |
| Rewards/economy/shop | Partial | Core persistence and rewards exist; tests and final 3D/motion pass remain. |
| Retention | Partial | Daily reward and mission exist; weekly/achievements/streak/event systems remain. |
| Ads | Partial | Non-blocking startup exists; safe IDs, rewarded flows, consent, pacing remain. |
| Audio/haptics | Planned | Service, content, settings, and synchronized profiles remain. |
| Localization/accessibility | Partial | EN/AR framework exists; hard-coded text and accessibility audit remain. |
| Testing | Early | Systematic unit/widget/regression/golden coverage remains. |
| Release | Not ready | Signing, release validation, CI, Play readiness remain. |

## Active task checklist

- [ ] Read `AGENTS.md` and `docs/FEATURE_CATALOG.md`.
- [ ] Confirm selected feature is marked `IN PROGRESS`.
- [ ] Record affected modules and acceptance criteria.
- [ ] Implement the smallest coherent production change.
- [ ] Run format.
- [ ] Run analyze.
- [ ] Run tests.
- [ ] Run applicable Android build or document external blocker.
- [ ] Update feature status and evidence.
- [ ] Update this dashboard.
- [ ] Commit one coherent change.

## Verification ledger

| Date | Feature | Verification | Result | Commit |
|---|---|---|---|---|
| Not recorded | Baseline | A systematic baseline has not yet been recorded under the new workflow. | Pending | - |

## Known high-priority risks

1. Emulator/ADB instability can end debug sessions even when the application is still running.
2. Kotlin incremental cache failures recur on Windows and require the shared repair workflow.
3. Existing implemented features lack a complete regression test suite.
4. The current 3D appearance is primarily procedural Flutter styling, not yet a full production WebP asset pipeline.
5. Some user-facing text and Material icons may still bypass the final design/localization system.

## Next ready features

1. Finish `ENG-002` and `REL-001` with repository-wide script audit and verification.
2. Complete `ENG-001` repository baseline audit.
3. Implement `MOT-001` shared motion tokens and reusable animation primitives.
4. Implement `AST-001` 3D asset taxonomy and naming standard.
5. Implement `TEST-001` progress/economy unit tests.

## Last update

- Added the formal feature catalog and live engineering workflow.
- Existing feature states are preliminary and must be verified before changing from `IMPLEMENTED` to `VERIFIED`.
