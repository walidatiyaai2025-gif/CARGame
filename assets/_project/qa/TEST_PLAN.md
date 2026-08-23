# CARGO V2 QA TEST PLAN

## Scope
Validate every CARGO V2 PR against the exact PR head before CAPTAIN integration into `cargo-v2`.

## Mandatory checks
1. Branch is reconciled with latest `cargo-v2` before the PR checkpoint.
2. Changes stay inside the assigned team ownership area unless CAPTAIN coordination is recorded.
3. Flutter formatting/analyzer/tests relevant to the change are green when CI/runtime is available.
4. No final APK/AAB build is produced by CARGO_COMMAND_CENTER.
5. Visible checkpoints cover small mobile width, large mobile width, Arabic RTL, English LTR and reduced motion.
6. No RenderFlex/critical horizontal overflow.
7. No duplicate navigation, duplicate reward or duplicate purchase/economy mutation on repeated taps.
8. Missing or delayed assets have a safe fallback.
9. Mission/reward/slots balance is deterministic and locally available offline.
10. FPS is recorded for the first runtime-capable visible checkpoint; target is stable 60 FPS with graceful degradation.

## Surface matrix
- Splash
- Loading
- Onboarding
- WorldMap
- Mission
- Reward
- Slots
- Cards
- Tournament
- Store
- Profile

## Visual/economy smoke
- Navy `#0A1A2F`, Gold `#FFC107`, White `#FFFFFF` remain coherent.
- Gold signals action/value/reward rather than becoming decorative noise.
- Reward animation cannot award value twice.
- Slot stake and payout cannot race on repeated input.
- Mission energy/time/reward values match the approved CARGO V2 balance contract.

## Evidence format
For each PR record: head SHA, checks run, pass/fail, bug IDs, FPS if measured, screenshots/video if genuinely captured, and merge recommendation.
