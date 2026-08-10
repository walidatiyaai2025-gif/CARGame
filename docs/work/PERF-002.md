# PERF-002 — Bounded memory and near-display image decode budget

- Issue: #199
- Branch: `agent/perf-002-memory-image-budget`
- State: IMPLEMENTED
- Dependency: AST-004 VERIFIED

## Objective

Bound Flutter image-cache retention and manifest-backed decoded image memory while preserving AST-004 race-safe precache behavior and all gameplay truth.

## 50-task execution contract

### A. Selection and audit
- [x] T01 Confirm PERF-001 reconciliation is merged on current main.
- [x] T02 Run a fresh P0 dependency-ready scan.
- [x] T03 Confirm PERF-002 is the highest ready source-controlled P0.
- [x] T04 Confirm AST-004 is VERIFIED.
- [x] T05 Confirm no active PERF-002 issue exists.
- [x] T06 Confirm no active PERF-002 PR exists.
- [x] T07 Confirm no active PERF-002 branch exists.
- [x] T08 Open issue #199.
- [x] T09 Create `agent/perf-002-memory-image-budget` from current main.
- [x] T10 Audit `GameAssetView`, manifest bridge, AST-004 cache, bootstrap, and cache tests.

### B. Global and per-image budgets
- [x] T11 Add immutable `GameImageMemoryPolicy`.
- [x] T12 Add immutable decoded-target diagnostics.
- [x] T13 Define an explicit 96-entry Flutter ImageCache ceiling.
- [x] T14 Define an explicit 48 MiB Flutter ImageCache byte ceiling.
- [x] T15 Define a 6 MiB estimated decoded RGBA ceiling per manifest image.
- [x] T16 Define a 1536 px longest-side hard decode cap.
- [x] T17 Define a 1024 px layout-free precache target.
- [x] T18 Configure Flutter ImageCache during startup.
- [x] T19 Keep AST-004 completed-cache entries separately bounded at 24 by default.
- [x] T20 Keep all budget state local and non-persistent.

### C. Near-display decode sizing
- [x] T21 Convert logical display size through device pixel ratio.
- [x] T22 Never upscale beyond authored native dimensions.
- [x] T23 Preserve source aspect ratio.
- [x] T24 Implement `contain`/`scaleDown` physical sizing.
- [x] T25 Implement `cover` physical sizing.
- [x] T26 Implement fit-width and fit-height physical sizing.
- [x] T27 Bound fill/none requests without distorting the source target.
- [x] T28 Fall back safely for absent/invalid layout hints.
- [x] T29 Enforce longest-side cap before decode.
- [x] T30 Enforce decoded-byte cap conservatively.

### D. Runtime view and precache integration
- [x] T31 Pass bounded `cacheWidth`/`cacheHeight` through `GameAssetView`.
- [x] T32 Use descriptor-native dimensions as sizing authority.
- [x] T33 Preserve existing visible error/fallback behavior.
- [x] T34 Preserve existing semantic-label behavior.
- [x] T35 Make production AST-004 precache resize-aware.
- [x] T36 Preserve legacy/injected `AssetImage` precache callback compatibility.
- [x] T37 Preserve legacy/injected `AssetImage` eviction callback compatibility.
- [x] T38 Evict the matching resized provider in production.
- [x] T39 Preserve AST-004 LRU/in-flight/failure/invalidation behavior.
- [x] T40 Keep near-future precache sequential and bounded.

### E. Tests, ownership, CI, and handoff
- [x] T41 Add global ImageCache ceiling regression.
- [x] T42 Add DPR/native/no-upsample sizing regressions.
- [x] T43 Add fit/aspect/hard-cap/byte-cap sizing regressions.
- [x] T44 Add `GameAssetView` ResizeImage widget regressions.
- [x] T45 Add PERF-002 machine ownership/drift validator and regressions.
- [x] T46 Add PERF-002 gates to normal Flutter CI and mark tracking IN PROGRESS.
- [x] T47 Run formatting, Analyze, PERF-002 focused tests, and AST-004 regressions.
- [x] T48 Pass full Flutter suite and TEST-008 coverage floor/target.
- [x] T49 Build/security-scan/upload the Debug APK through normal Flutter CI.
- [x] T50 Merge only after final-head CI is green; run exact-main verification/promotion and reconcile honestly without inventing device RSS/GPU measurements.

## Safety boundary

No gameplay, economy, persistence, ads, consent/privacy, analytics, navigation identity, package versions, asset provenance, or binary asset changes are in scope. Physical-device memory profiling remains separate evidence.

## Clean PR verification evidence

- Clean implementation head `2aac141babbd3bc170c831fc4fac30b7e3357fba` passed Flutter CI #851 / run `31419243682` end-to-end.
- PERF-002 machine ownership validation passed with 9/9 focused validator regressions; the focused memory/view/AST-004 Flutter suite passed 26/26.
- Changed-Dart formatting, whitespace integrity, and `flutter analyze --no-fatal-infos --no-fatal-warnings` passed.
- Full Flutter suite passed 344/344 tests. Authored-source coverage is 5,838 / 6,620 = 88.19%, above the TEST-008 35% floor and 60% target.
- Debug APK build and packaged-artifact security passed. Artifact #9074950206 is 80,650,504 bytes with artifact ZIP SHA-256 `760003d5c5cca8c151c15a8aaf562f946aad803cc231df31c64bab78976a43c1`.
- TEST-007, TEST-008, TEST-010, AST-004, PERF-001, privacy/security/dependency, dashboard/catalog, asset-pipeline, full coverage and Debug APK gates all remained green.
- The next gate is a full normal-CI run on this evidence-bearing final PR head before merge. Physical-device process RSS/GPU residency is still deliberately not claimed.

## Final source-controlled reconciliation

- Final PR head `d8e1fa2d315406173a180b751a7601670dcc484e` passed Flutter CI #852 and PR #200 squash-merged as `5298d70218d8e33d766a54813d423bd7de090d16`.
- Historical skip markers inherited into that squash message prevented the normal main push workflow. Docs-only PR #201 therefore re-ran the merged runtime tree in Flutter CI #853, which passed all normal gates, and merged as `27ddbe3e9d2e20b32e7b89dfc3f56c6c171153cb` without a skip directive.
- Exact-main Flutter CI #854 passed every normal gate against that main SHA. PERF-002 source-controlled acceptance is IMPLEMENTED. No physical-device process RSS/GPU residency measurement is claimed; issue #199 remains the place for later VERIFIED evidence.
