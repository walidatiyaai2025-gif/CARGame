# CARGO V2 METHODOLOGY

## 1. GIT
- Integration branch: `cargo-v2`, created from `main`.
- Team branches requested as `cargo-v2/<team>` cannot coexist with the Git ref `cargo-v2` because Git refs cannot be both a file and a directory. Operational equivalents are:
  - `cargo-v2-ui-team`
  - `cargo-v2-logic-team`
  - `cargo-v2-asset-team`
  - `cargo-v2-data-team`
  - `cargo-v2-qa-team`
- Only the CAPTAIN integrates team PRs into `cargo-v2` after QA gate evidence.
- Before each team push/checkpoint, reconcile with the latest `cargo-v2` state.
- Commit convention: `[CARGO V2][TEAM] Action`.

## 2. NO EXTERNAL FILES
Gameplay balance and baseline configuration remain deterministic and local. CARGO V2 must not depend on a remote file to start or play core content.

## 3. VISUAL FIRST
Target effort split: 50% runtime/game logic and 50% visible polish, motion, feedback, assets, accessibility, and responsive behavior.

## 4. PALETTE
- Navy: `#0A1A2F`
- Gold: `#FFC107`
- White: `#FFFFFF`

The uploaded reference set confirms a dark navy logistics/game shell with luminous amber-gold trucks, cargo, reward objects, CTA surfaces, glow, and world-map lighting.

## 5. ANIMATION
The repository is currently Flutter/Dart. Use the existing Flutter motion/particle architecture (AnimationController/Tween/CustomPainter/runtime 3D adapters) as the executable equivalent of the requested DOTween + Particles behavior. Do not add dead Unity-only C# or DOTween dependencies unless an actual Unity module is explicitly introduced into the repository.

## 6. NO CRASHES
Use bounded error handling at adapter and async boundaries, safe fallbacks for assets, guarded navigation/actions, and recovery states. Do not blanket-swallow programming errors.

## 7. MOBILE FIRST
Android-first responsive design with small-phone, large-phone, tablet, safe-area, Arabic RTL, English LTR, large-text, and reduced-motion coverage.

## 8. QA GATE
No team PR is integrated into `cargo-v2` until QA evidence is recorded. No final build is produced by CARGO_COMMAND_CENTER; work stops at reviewed PR/checkpoint plus runtime evidence when available.

## Path normalization
The repository already uses lowercase `docs/` and `assets/`. CARGO V2 uses those existing canonical roots to avoid Windows case-collision problems with parallel `Docs/` or `Assets/` directories.
