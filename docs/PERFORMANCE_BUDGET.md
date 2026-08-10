# CARGame Frame Performance Budget

PERF-001 defines the source-controlled runtime frame budget for the Android RC. It is a graceful-degradation policy, not a claim that every physical device has already been profiled.

## Target

- Primary refresh target: **60 Hz**.
- Nominal frame budget: **16.67 ms**.
- Jank threshold: **>24 ms**.
- Severe-jank threshold: **>34 ms**.
- Runtime history is a bounded rolling window of **60 frames**.
- Evaluation begins after **30 samples** and runs every **15 new frames**.

## Adaptive visual quality

The runtime starts at `full`. Sustained pressure can move visual quality one level at a time:

1. `full` — complete shared motion and ambient animation.
2. `constrained` — ambient motion pauses and nonessential motion amplitude/duration is reduced.
3. `reduced` — ambient motion remains paused and shared effects are reduced further.

A single slow frame does not trigger degradation. The default policy degrades when the rolling window reaches at least 12% jank frames or 4% severe-jank frames.

Recovery is deliberately slower than degradation. The controller requires three healthy evaluation windows at or below 3% jank with zero severe-jank frames before recovering one quality level. This hysteresis prevents rapid mode oscillation.

## Safety boundaries

Performance mode is presentation-only. It must never alter:

- level generation or solvability;
- move counts, sorting correctness, win/loss rules, rewards, economy, hearts, boosters, or persistence;
- ad eligibility, consent, privacy, security, analytics, or diagnostics policy;
- route identity or transaction idempotency.

System accessibility reduced-motion has higher priority than adaptive quality and always removes nonessential travel/scale motion.

## Observability

`FramePerformanceSnapshot` exposes bounded local diagnostics: quality mode, rolling sample count, total observed frames, average/worst frame duration, jank/severe-jank ratios, and recovery-window count. No remote telemetry or new persistence is introduced by PERF-001.

## Verification boundary

CI can prove policy determinism, bounded memory, integration, motion fallback, source ownership, regression coverage, and build safety. Actual device-tier frame-time evidence remains part of the later device/API compatibility and profiling work; repository documentation must not fabricate physical-device measurements.
