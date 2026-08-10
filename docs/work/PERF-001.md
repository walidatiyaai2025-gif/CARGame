# PERF-001 — Adaptive frame performance budget

- Issue: #196
- Branch: `agent/perf-001-frame-budget`
- State: IN PROGRESS
- Dependencies: MOT-001 IMPLEMENTED, AST-004 VERIFIED

## Objective

Establish a deterministic 60 Hz frame-budget policy and bounded runtime adaptation that sheds nonessential visual work under sustained frame pressure without changing gameplay truth.

## 50-task execution contract

### A. Selection and budget definition
- [x] T01 Verify AST-004 final reconciliation is merged.
- [x] T02 Confirm PERF-001 is the selected P0 dependency-ready workstream.
- [x] T03 Confirm no active PERF-001 issue exists before opening #196.
- [x] T04 Confirm no active PERF-001 PR exists.
- [x] T05 Confirm no active PERF-001 branch exists.
- [x] T06 Create issue #196 and dedicated branch from current main.
- [x] T07 Preserve TEST-007, TEST-008, TEST-010 and AST-004 gates.
- [x] T08 Define a 60 Hz target.
- [x] T09 Define nominal 16.67 ms frame budget.
- [x] T10 Define explicit jank and severe-jank thresholds.

### B. Bounded runtime policy
- [x] T11 Add typed visual-quality modes.
- [x] T12 Add immutable frame-performance policy.
- [x] T13 Bound rolling history to 60 frames by default.
- [x] T14 Delay evaluation until a minimum sample count.
- [x] T15 Evaluate only at a bounded stride rather than every frame.
- [x] T16 Track total frames without retaining unbounded per-frame history.
- [x] T17 Expose average frame duration.
- [x] T18 Expose worst rolling frame duration.
- [x] T19 Expose jank ratio.
- [x] T20 Expose severe-jank ratio.

### C. Degrade/recover state machine
- [x] T21 Ignore invalid negative durations.
- [x] T22 Keep isolated slow frames below degradation threshold.
- [x] T23 Degrade full to constrained under sustained pressure.
- [x] T24 Degrade constrained to reduced one evaluation later under sustained pressure.
- [x] T25 Never degrade below reduced.
- [x] T26 Reset recovery hysteresis under renewed pressure.
- [x] T27 Require healthy windows before recovery.
- [x] T28 Recover reduced to constrained one level at a time.
- [x] T29 Recover constrained to full one level at a time.
- [x] T30 Prevent neutral windows from accumulating false recovery credit.

### D. Flutter integration and graceful fallback
- [x] T31 Add lifecycle-safe `FramePerformanceScope`.
- [x] T32 Observe Flutter `FrameTiming` through SchedulerBinding.
- [x] T33 Remove timings callback on scope disposal.
- [x] T34 Support injected controller and scheduler-off mode for deterministic tests.
- [x] T35 Wrap the app above MaterialApp so all routes share one performance mode.
- [x] T36 Integrate adaptive quality into `GameMotionProfile`.
- [x] T37 Preserve system reduced-motion as the strongest override.
- [x] T38 Reduce nonessential motion amplitude under constrained/reduced quality.
- [x] T39 Shorten nonessential animation duration under constrained/reduced quality.
- [x] T40 Pause ambient animation when quality is no longer full.

### E. Tests, policy ownership, CI, and handoff
- [x] T41 Add bounded-history and diagnostic regressions.
- [x] T42 Add degradation/recovery/hysteresis regressions.
- [x] T43 Add scope propagation and reduced-motion precedence widget regressions.
- [x] T44 Add machine ownership/drift validator and its focused regressions.
- [x] T45 Add PERF-001 validator and focused Flutter tests to normal CI.
- [x] T46 Update FEATURE_CATALOG and STATUS to IN PROGRESS with honest verification boundary.
- [x] T47 Run formatting and Analyze.
- [x] T48 Pass focused PERF-001 tests plus full Flutter coverage suite and TEST-008 threshold.
- [x] T49 Build/security-scan/upload Debug APK through normal Flutter CI.
- [ ] T50 Merge only after final-head CI is green; run exact-main verification/promotion, then reconcile source-controlled PERF-001 evidence without inventing physical-device frame measurements.

## Safety boundary

No gameplay, economy, persistence, ads, privacy, security, analytics, production identifiers, packages, or asset binaries are changed by this feature. Device-tier profiling remains external evidence under later compatibility/performance validation work.

## Clean PR verification evidence

- Clean implementation head `5ead71d5c204d30f25888f7dabd2b59d67a2cc8f` passed Flutter CI #847 / run `31414052377` end-to-end.
- PERF-001 machine validator passed with 8/8 focused validator regressions; the focused Flutter performance/motion suite passed 15/15.
- Formatting and whitespace gates passed; `flutter analyze --no-fatal-infos --no-fatal-warnings` completed with no fatal finding (one pre-existing non-fatal TEST-007 unused-local warning remains outside PERF-001 scope).
- Full Flutter suite passed 332/332 tests. Authored-source coverage is 5,775 / 6,547 = 88.21%, above the TEST-008 35% floor and 60% target.
- Debug APK build and packaged-artifact security passed. Artifact #9072989254 is 80,644,379 bytes with artifact ZIP SHA-256 `d2150f51c7ede40a889e0aa7a92f1db8586df73351ebef9b4d335bf073ca47bf`.
- TEST-007, TEST-008, TEST-010, AST-004, privacy/security/dependency, dashboard/catalog, asset-pipeline and Debug APK gates all remained green.
- The next gate is a full normal-CI run on this evidence-bearing final PR head before merge; device-tier profiling is still deliberately not claimed.
