# CARGO V2 QA REPORT

## Baseline
- Source base: `main` at `48331037d5e7fa59c6692a551d2a918f0a155edc`.
- Integration branch: `cargo-v2`.
- Final build is explicitly out of scope for CARGO_COMMAND_CENTER.

## Required QA gates
- Source formatting/analyzer/test gates applicable to each changed area.
- No critical startup or navigation crash.
- No duplicate reward/economy mutation from repeated taps.
- Small-phone and large-phone layout sanity.
- Arabic RTL and English LTR sanity.
- Reduced-motion behavior for animated surfaces.
- Missing asset fallback and semantic labeling.
- Mission/reward/slots economy stays deterministic and locally available.
- FPS evidence recorded when a runtime-capable checkpoint is available.

## Current result
Status: NOT STARTED.
Bugs found: 0 because no CARGO V2 implementation PR has yet passed through the QA gate.
FPS: not measured.
Video: not captured.

## Merge rule
A CAPTAIN merge into `cargo-v2` requires QA evidence for the exact PR head. Passing documentation-only checks does not qualify a user-facing feature as visually complete.
