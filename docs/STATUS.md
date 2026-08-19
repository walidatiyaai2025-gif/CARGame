# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | Android RC hardening — issue #79 |
| Primary feature | `AST-007` 100+ cargo visual pack — IN PROGRESS on issue #210. The first 12 project-original cargo WebP assets now have matching provenance/checksums; 112 cargo identities remain to be admitted. |
| Completed checkpoint | `AST-007` production intake hardening — 100/100 source-controlled checkpoints complete via PR #218; squash merge `6546cd978cba2c7c6cd560879df54a57f70e873c` and exact-main Flutter CI #915 / run `31494288422` passed all 70 gates. |
| Status | AST-007 intake is mechanically production-ready and Batch 01 has moved from handoff to real admission: 133 descriptors / 12 approved provenance records / 12 runtime cargo WebP. All 12 files are project-original procedural artwork with real export SHA-256 checksums; 112 cargo identities remain, so AST-007 stays IN PROGRESS and GAME-012 stays blocked. |
| Previous checkpoint | `A11Y-003` reduced-motion accessibility — IMPLEMENTED with 100/100 source-controlled checkpoints and exact-main verification. |
| Next recommended feature | Continue AST-007 with the next deterministic production cargo-art batch. Batch 01 has begun real WebP + provenance admission; do not start a second primary feature while 112 cargo identities remain. |
| Known blocker | `AST-007` has admitted 12/124 runtime cargo WebP identities with matching provenance; 112 remain, so `GAME-012` remains blocked. `TEST-011` VERIFIED still requires real production AdMob Privacy & messaging/UMP regulated-region/device evidence. `TEST-009` remains blocked on PERF-001 physical-device frame profiling. `REL-007`/`REL-008` require real production AdMob/signing inputs and a production-signed candidate; final install/upgrade/device smoke requires an Android device/testing track. |

## AST-007 cargo visual pack — 2026-08-11

- Production-intake PR #215 merged as `356aff3b6901f17036b5e9c8d8e002e7f226ce10` after Flutter CI #901 / run `31487583861` passed all 69 gates; PR artifact #9099976486 is 80,673,122 bytes with SHA-256 `a394e2c0feb7f76b084c2603fced63c5ada4438370b69c13f9398e9af91f28f7`.
- Exact-main Flutter CI #902 / run `31488362505` repeated all 69 gates successfully on `356aff3b6901f17036b5e9c8d8e002e7f226ce10`; main artifact #9100262930 is 80,673,121 bytes with SHA-256 `3ae614db8a1b90675d312b8371fc4ce841aa7c14526d88bad92667053022e0a0`.
- `GameAssetIntakePlan` and `tool/plan_ast_007_asset_intake.dart` now turn the 124 descriptor backlog into deterministic batches, prioritize interrupted partial admissions, normalize Windows/Linux runtime paths, validate any existing provenance against its manifest descriptor, and expose JSON handoff output. AST-007 machine ownership now includes 10/10 mutation regressions.
- First deterministic 12-item production batch: `cargo.accessory_box`, `cargo.accessory_carton`, `cargo.action_figure_box`, `cargo.apparel_box`, `cargo.apple_crate`, `cargo.archive_box`, `cargo.auto_part_crate`, `cargo.bakery_box`, `cargo.basketball_bag`, `cargo.battery_pack`, `cargo.board_game_box`, `cargo.boot_carton`. No binary or provenance is claimed for these IDs yet.
- Issue #210 remains the single active source-controlled/product-art workstream; PR #213 completed and merged the first source integration checkpoint.
- The 18 stable `CargoItem` gameplay archetype IDs remain the matching/save/reward authority. The 150-level generator seed, item IDs, moves and difficulty truth are unchanged.
- `CargoVisualCatalog` adds 124 stable `cargo.*` identities across all 18 archetypes. Deterministic level/archetype resolution reaches at least 100 distinct identities across the real 150-level catalog while keeping duplicate cargo, its sorting target and travel flight visually coherent.
- `assets/3d/manifest.json` now contains 133 descriptors total: 9 existing + 124 descriptor-only cargo records using `pcargo` / 384x384 and `assets/3d/runtime/cargo/...` taxonomy. Approved provenance remains 0 and runtime WebP remains 0.
- `CargoVisualAsset` routes Cargo Bay, Sorting Docks and travel flight through `GameManifestAssetView`; with no admitted binaries, exact legacy fallbacks remain visible.
- Full-suite verification exposed and fixed a real manifest-readiness regression: root-bundle diagnostics proved all 133 descriptors parsed; `GameManifestAssetView` now caches both the in-flight Future and resolved registry so post-preload widgets resolve synchronously rather than flashing legacy fallback.
- Final PR head `0330458b3b3becaa9248a694d56fe3b9f8261fd5` passed Flutter CI #892 / run `31477806852` all 69 gates, including AST-007 validator/regressions, full suite, coverage, Debug APK, artifact security and upload; PR artifact #9096224674 (80,673,122 bytes; SHA-256 `e45405e154f209d106c5758852457c45f0d7a8b9c3ec11ab46098ccd500172c3`).
- PR #213 squash-merged as `132c0cff75057e21a8bdea50550b6b8bcd7e04f6`. Exact-main Flutter CI #893 / run `31478580634` passed all 69 gates; main artifact #9096533997 (80,673,119 bytes; SHA-256 `73c77fd51540696d1327141856ba9d62570adffbb75f54e61803adce9439fbbb`).
- Latest Verified APK promotion run `31479328315` initially hit a transient Maven Central HTTP 403 while resolving Kotlin artifacts; rerunning the same failed job without code/config changes passed release build, artifact security and promotion. Promotion commit `a80b987bdc0a533958b381506f46012eaa2ae6f3` retained a 56,044,747-byte QA APK with SHA-256 `62177e3056dba6f303f68e32f426142ed0bff461300049a77610cbaba2312d61`, ephemeral CI signing and runtime ads disabled.
- Intake-hardening PR #218 merged as `6546cd978cba2c7c6cd560879df54a57f70e873c` after Flutter CI #913 / run `31493446170` passed all 70 gates; exact-main CI #915 / run `31494288422` also passed all 70 gates. The source-controlled H001-H100 sprint is complete, including readiness metrics, orphan detection, filtered paging, JSON/CSV/strict handoff, the intake runbook, and 24 composed mutation protections. Production binary/provenance counts remain 0/0.
- AST-007 remains IN PROGRESS. The next checkpoint is admission of real commercial-use cargo WebP assets with complete AST-011 provenance; no second primary feature should start and GAME-012 remains blocked until that evidence exists.

## A11Y-003 reduced-motion accessibility — 2026-08-11

- Issue #208 / PR #209 complete the 100-checkpoint source-controlled accessibility sprint; repository status is IMPLEMENTED.
- Shared motion is explicitly classified as essential, nonessential or cinematic. Effective reduced motion removes spatial/decorative motion while preserving semantic, gameplay, reward, callback and navigation completion.
- `GameCinematicGate`, cargo travel, ambient motion and action feedback have deterministic no-ticker reduced paths. GameButton and route motion consume the intent-aware shared policy.
- The checked-in direct-motion audit covers the current primitive inventory and the machine validator blocks unclassified source drift.
- Final PR head `04abd449451e0fb44f5a95eca6f74af263a35665` passed Flutter CI #872 / run `31472254901` through full tests/coverage, Debug APK, artifact security and upload; PR artifact #9094044902 (80,659,591 bytes; sha256:bfa4d84edc21eaf6efdd376dcdc04b0101a5e21efc7de555dda18fae09709d3c).
- PR #209 squash-merged as `996bebf50e9f5b150e10a9f6455a27015a67355f`. Exact-main Flutter CI #873 / run `31473003490` then passed all gates; main Debug artifact #9094321792 (80,659,593 bytes; sha256:ee95a99a8460d1824a28fb9512d12454d3e9f69648a9e0bd5506e34ccf2be98d).
- No physical assistive-technology/device observation is invented; that broader evidence remains separate.
- Fresh dependency-ready/product-risk scan selects `AST-007` issue #210 next: introduce 100+ stable cargo visual variants without changing the 18 gameplay archetype IDs or existing 150-level gameplay truth.

## UI3D-007 reduced motion and adaptive visual effects — 2026-08-11

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

## TEST-011 privacy consent and security verification — 2026-08-11

- Issue #202 / PR #203 complete the 100-checkpoint source-controlled sprint. Repository status is IMPLEMENTED, not VERIFIED.
- The release contract mechanically protects UMP consent refresh/form handling/live `canRequestAds`, fail-closed Mobile Ads initialization and banner/rewarded/interstitial paths, runtime revocation disposal, Settings privacy options, and offline-core availability.
- Local export/deletion, analytics/diagnostics privacy isolation, redaction, tracked-secret checks, dependency advisories, network/trust-boundary parity, and packaged APK security remain blocking CI evidence.
- TEST-011 machine validation passes with 17/17 mutation regressions; the focused Flutter privacy/consent/security matrix passes 38/38.
- Final PR head `d07dc2a1b84f5f949cf1cf5925b8348c581cb27b` passed Flutter CI #856 / run `31440184413`: 345 Flutter tests, 88.22% authored-source coverage, Debug APK, artifact security and upload. Artifact #9082737774 is 80,650,503 bytes with artifact ZIP SHA-256 `f2e73219019f78fa16f67f56a0cd551ab822f2d2cad52b301b6eddc834800cb7`.
- PR #203 squash-merged as `eb3f4df464173dab6729bfb6ed4ccf7289747057`. Exact-main Flutter CI #857 / run `31440863970` passed all 60 gates and uploaded artifact #9082985280 (80,650,506 bytes; artifact ZIP SHA-256 `30024ca046038fb7c9ed3b1425d72366830750389bb011a65b4a3b86648ad3ca`).
- Production AdMob Privacy & messaging/UMP configuration and regulated-region/device observations remain external PENDING evidence. CI success must not promote TEST-011 to VERIFIED.
- Fresh dependency-ready scan found no higher source-controlled P0 that can be completed without external/device evidence. `UI3D-007` is selected next at P1 via MOT-001; its old world-map branch is 45 commits behind and reference-only.

## PERF-002 memory and image budget — 2026-08-10

- Issue #199 / branch `agent/perf-002-memory-image-budget` are the single active source-controlled workstream after a fresh P0 dependency scan.
- `GameImageMemoryPolicy.standard` defines 96 global Flutter ImageCache entries, 48 MiB global decoded cache bytes, 6 MiB per manifest image, a 1536 px hard decode dimension, and a 1024 px layout-free precache target.
- `GameAssetView` converts logical render size through DPR and passes bounded `cacheWidth`/`cacheHeight`, never upsamples beyond authored dimensions, preserves aspect ratio, and falls back to bounded sizing when layout hints are absent or invalid.
- AST-004 production precache now uses the same resize policy while retaining its injected `AssetImage` callbacks for existing deterministic tests; production eviction uses the matching resized provider.
- Startup explicitly configures Flutter `ImageCache`; application LRU/failure history remains independently bounded by AST-004.
- `docs/MEMORY_IMAGE_BUDGET.md` records the safety and verification boundary: CI can prove source budgets/build behavior, while real process RSS/GPU/device memory profiling remains separate evidence.

## PERF-001 adaptive frame performance budget — 2026-08-10

- Issue #196 remains open only for real Android device/profile verification; source implementation PR #197 is merged and no source-controlled primary workstream is active after reconciliation.
- `FramePerformancePolicy.mobile60Hz` defines a 60 Hz target, nominal 16.67 ms frame budget, >24 ms jank threshold, >34 ms severe-jank threshold, 60-frame bounded history, 30-sample warmup, and 15-frame evaluation stride.
- Sustained pressure degrades visual quality one level at a time from full to constrained to reduced; recovery requires three healthy evaluation windows and also occurs one level at a time to prevent oscillation.
- `FramePerformanceScope` observes Flutter `FrameTiming` for the full app route tree. Shared motion shortens/scales nonessential effects under pressure, and ambient motion stops outside full quality; system reduced-motion remains the strongest override.
- `FramePerformanceSnapshot` is local-only, bounded diagnostic state. PERF-001 adds no remote telemetry, persistence, packages, production identifiers, or gameplay/economy/ad/privacy changes.
- `docs/PERFORMANCE_BUDGET.md` records the verification boundary: CI proves deterministic policy/integration/build safety, while actual device-tier frame measurements remain later device/profile evidence and must not be fabricated.
- Final evidence-bearing PR head `7ad6d67e0963de15d2b08c6ce7a734ee6980de1a` passed Flutter CI #848 / run `31414950411`; PR #197 squash-merged as `f2b2c829755a5abdd3342dba731e1e669f42f57f`.
- Exact-main Flutter CI #849 / run `31415750686` passed 332/332 tests, 88.21% authored-source coverage, Debug APK, artifact security and upload. Main artifact #9073641322 is 80,644,379 bytes with artifact ZIP SHA-256 `4d2726add801d28d517cc29461506e2d4580e57fb86b6b50e362847d0628f13b`.
- Latest-verified promotion #37 / run `31416602117` succeeded and committed `3e2fa6592e98c18216e7dff9a79888cc3e5e7dbc`; the QA release APK is 55,943,559 bytes with SHA-256 `358d38a81708fce2a667f9b78a00b6b1bd28ae2f68013cdb60266ecbc65da1a2`, ephemeral CI signing, ads disabled, and not production/Play Store signed.
- PERF-001 is IMPLEMENTED, not VERIFIED: issue #196 remains open for real Android device/profile frame measurements, and TEST-009 stays dependency-blocked until that evidence exists.

## AST-004 bounded asset precache and memory policy — 2026-08-10

- Issue #192 / PR #193 complete the 100-checkpoint AST-004 sprint; issue #192 is closed completed.
- `GameAssetCachePolicy` shares concurrent same-ID load operations, permits independent different-ID loads, and uses global/per-ID generations so `clear()` or `forget(id)` cannot be reversed by stale async completion.
- Completed cache state and failure history remain bounded; cache hits update LRU priority without reload; near-future work is sequential/deduplicated/budget-clamped and skips known failures unless retry is explicit.
- Immutable snapshots expose hit/miss, joined request, successful load, load failure, eviction, stale completion, and eviction-failure counters; reset affects statistics only.
- `tool/verify_asset_cache_policy.py` mechanically blocks raw production `precacheImage` bypasses and required CI/test drift; its regression suite passes 6/6. Focused cache widget coverage passes 14/14.
- Final clean PR head `61c5741ba8340e0baafb2d2cea9989137b25a279` passed Flutter CI #839 / run `31408977215`: 320 Flutter tests, 88.34% authored-source coverage, Debug APK, artifact security and upload. Artifact #9071093253 is 80,633,602 bytes with SHA-256 `0e6da3e6d75212817f22c91592009e97532d838f4f395a4f4f1c9f488a59f5bb`.
- PR #193 squash-merged as `22239a6cdd7af3770a03a4b9a86e8d32d078a01b`. Exact-main Flutter CI #840 / run `31409971405` passed all 51 gates, the full 320-test suite, 88.34% coverage, Debug APK, artifact security and upload; main artifact #9071436511 is 80,633,603 bytes with artifact ZIP SHA-256 `b7150ca0969b0f32e3741ca4a47e9c51e7c8d6ce02880af9d47b5f1cfbfec562`.
- Latest-verified promotion run `31410745473` succeeded and committed `4379937b51309644a11bffc43d7375888e258823`; the QA release APK is 55,878,023 bytes with SHA-256 `df60e5bc0471cdf99ab66a3e01987cc7948fc52ba353da647070b29bcd137a72`, ephemeral CI signing, ads disabled, and is not production/Play Store signed.
- Asset admission remains deliberately unchanged at 9 descriptors / 0 provenance records / 0 runtime WebP files; missing art remains fallback-safe. No gameplay, economy, persistence, ads, privacy runtime, production identifiers, signing, packages, or binary art changed.
- Fresh dependency scan selects `PERF-001` as the next P0 workstream; AST-004 verification also satisfies the asset-cache dependency for PERF-002/AST-010.
## TEST-008 coverage thresholds and flaky-test policy — 2026-08-10

- Issue #190 is closed completed; PR #191 squash-merged as `87ab162c1fe1a73b962dd98370ac04aee7d15b90`.
- The 50-checkpoint sprint is complete: strict authored-source LCOV validation, 35% hard floor, 60% target, zero blanket retries, bounded owned/issue-linked quarantines, and 30 focused validator regressions are versioned and enforced.
- Final clean PR head `456c762818e6b1e0746651ef6f9b3cefcbb32dea` passed Flutter CI #835 / run `31405428616`; the full Flutter suite passed 310 tests at 88.01% line coverage (5,584/6,345 authored lines).
- Exact-merge main CI #836 / run `31406357471` passed all workflow gates and uploaded debug artifact #9070055072 (80,633,605 bytes; artifact ZIP SHA-256 `5b66f915d19184feda6ca2a061e73fdaaa6abed4ac6cc9b2c2002c3c33e9a476`).
- Maintain Latest Verified APK run `31407149670` passed release-mode QA build/security/current-main promotion and committed `3945b6fad174ec913c381fabfc8788de4e5323d7`; `Last verified APK` is 55,878,023 bytes with SHA-256 `adf8907ad545b6c30113c17eabbd4d8a572c79d3821b05212cee0f562468f64a`, ephemeral CI signing, ads disabled, and not production/Play Store signed.
- TEST-007 and TEST-010 remain blocking normal-CI gates. No gameplay, economy, persistence, navigation, ads, privacy runtime, signing policy, packages, or assets changed.

## TEST-010 dashboard/catalog parser validation — 2026-08-10

- Issue #187 / PR #188 establish a dedicated release-quality parser-parity contract on top of ENG-007 without creating a second feature-catalog source of truth.
- `tool/verify_dashboard_catalog.py` independently models dashboard Markdown identity parsing, requires exact A-S phase and feature identity parity, exact seven-status vocabulary coverage, strict parser guards, and runtime fetch/audit/render anchors.
- The dependency graph validator rejects missing, self, and strongly connected cyclic dependencies; the first full-catalog run exposed four circular planning edges, which were corrected at NAV-003/RET-008, WORLD-006/MOT-009, REW-008/RET-005, and PERF-007/REL-008 without changing production code.
- `tool/test_dashboard_catalog.py` provides 9 focused regressions; the existing CI integrity suite remains 15/15 green. TEST-010 is a blocking normal-CI gate before package restore and preserves TEST-007.
- Implementation CI #822 / run `31384332431` passed the initial TEST-010 implementation checkpoint.
- Final clean PR head `a7fd43118ec42852984aaf3f2b4f723534fad6b5` passed all 45 steps in Flutter CI #827 / run `31385221550`; debug artifact #9061656030 is 80,633,607 bytes with SHA-256 `04a7620731d146aac4aec44f305d895fd21454472e2126cab46e365ea3a4d0e3`.
- PR #188 squash-merged as `d148ac820ee7dcfbacd0f88304a9cf168bc66b41`; Issue #187 closed completed. Main Flutter CI #828 / run `31385904664` then passed all 45 steps on the exact merge SHA; main debug artifact #9061890276 is 80,633,607 bytes with SHA-256 `a2684e4697cf2e153ee75f471cc1bfeaaf0feb15638e43a788984c2bc585b173`.
- Maintain Latest Verified APK run `31386487136` passed release input preflight, ephemeral signing, release APK build, packaged-artifact security, current-main verification, and promotion. Commit `743356b2a8e66b699feadb09e1c9f5fa60b858a7` updated `Last verified APK`; the QA/installable release-mode APK is 55,878,023 bytes with SHA-256 `7b24570855c3e3f48007f53eac9770cde3a6a9fe0de519abff35fcb36925383f`, runtime ads disabled, and is explicitly not production/Play Store signed.
- No gameplay, economy, persistence, navigation runtime, ads, privacy runtime, signing policy, production identifiers, packages, or assets changed. Repository-owned TEST-010 acceptance is VERIFIED and merged.

## TEST-007 critical-path integration contract — 2026-08-10

- Issue #181 / PR #184 implement exactly 50 named release checkpoints T01..T50 as one deterministic release contract.
- The executable path covers fresh state, Home, World Map, Mission Briefing, Gameplay, completion/result, authoritative reward/XP, duplicate reward protection, Shop purchase/recovery, restart, and fresh-store restore.
- EN/LTR and AR/RTL plus compact/reference/tablet surfaces are included; the test uses in-memory/local persistence and introduces no live network dependency, production identifier, balance change, or new package.
- `tool/verify_test_007_critical_path.py` requires T01..T50 exactly once, production journey/state anchors, the offline boundary, and blocking CI execution; six focused Python regressions protect the validator itself.
- Flutter CI #810 / run `31379676066` passed all repository gates including formatting, Analyze, core screen matrix, focused TEST-007, full Flutter suite, Debug APK build, artifact security, and upload on implementation head `4882ac1b9449fb399ea3456ce89fa460dcfbcb98`.
- Debug artifact #9059551183 is 80,633,604 bytes with SHA-256 `283bf954510ac7eec6cb78e36f58995157379b3afe923b2af524003d3a4b415b`.
- Repository-owned TEST-007 acceptance is VERIFIED. Final-head Flutter CI #816 / run `31380502193` passed all 43 workflow steps, including Debug APK build, artifact security, and upload; artifact #9059883319 is 80,633,608 bytes with SHA-256 `76756ff72098c353f676ffd18008e253a2c1532da88208d8f3730b19b92c3e70`. PR #184 squash-merged to `main` as `b7f858f9cac6c1a8c5b0d1f9058be599f9ce792c`, and Issue #181 closed completed.

## TEST-003 core screen widget matrix — 2026-08-10

- Issue #179 / PR #180 are completed and merged; the explicit release matrix covers Home, World Map, Mission Briefing, Gameplay, Result, and Shop across compact/reference/tablet classes and EN/AR behavior.
- Missing locale/viewport gaps were closed without changing production UI behavior, adding golden snapshots, or introducing network dependencies.
- `tool/verify_core_screen_widget_matrix.py` is a blocking CI guard for the six screen families and compact/reference/tablet plus EN/AR anchors.
- Flutter CI #803 / run `31344139284` passed formatting, Analyze, focused matrix tests, full Flutter suite, Debug APK, privacy/security/dependency/catalog gates, artifact security, and upload on head `8d7c48fbde9dceffeb9fb6edb87a02bd941643ab`.
- Debug artifact #9046841743 is 80,633,606 bytes with SHA-256 `f4f2b86d7dae9c44ecaf66042a91321a121356f8bd36f355dc38cf227e69e94f`.
- PR #180 squash-merged as `4ca093a843ab685dfeef8df2c86e3950a13f482f`; TEST-003 is VERIFIED and its dependency on P0 TEST-007 is satisfied.
## ENG-013 crash reporting and non-fatal diagnostics — 2026-08-10

- Issue #177 / PR #178 add schema-v1 `CrashReport`/`CrashReportContext` plus vendor-neutral reporting/privacy ports.
- `ENABLE_DIAGNOSTICS` now effectively gates local `AppLogger` initialization, retention, persistence, debug output, runtime broadcasts, and clipboard diagnostics while the error boundary remains installed.
- Flutter, platform, isolate, and explicit non-fatal failures flow through the fail-closed reporting boundary; emitter failures are isolated from startup/gameplay.
- `ENABLE_REMOTE_DIAGNOSTICS` defaults false. Production runtime privacy is deny-all and no remote crash SDK, emitter, processor, queue, persistence, or network upload path is installed.
- Crash payloads are secret/path-redacted and hard-bounded before any future emitter and carry only schema/severity/source/version/build/environment/UTC timestamp correlation.
- `tool/verify_crash_reporting_privacy.py` blocks remote crash SDK/processor drift, network/storage/ads coupling, default-on reporting, missing redaction/bounds, and `pubspec.yaml` version/build correlation drift.
- Flutter CI #796 / run `31342815876` passed all repository gates including Analyze, focused ENG-013 tests, the full Flutter suite, Debug APK build, artifact security, and upload on head `b7a5851aa0ad028746d0b5631c8bec14f9551847`.
- Debug artifact #9046424192 is 80,633,604 bytes with SHA-256 `c724866c8b1eef49bcc084221697db299d604215b00c473145b9aac585431276`.
- Repository-owned ENG-013 acceptance is VERIFIED. Any future remote diagnostics processor remains a separate privacy/security/disclosure decision.

## ENG-012 analytics schema and privacy gate — 2026-08-10

- Issue #175 / PR #176 implement schema v1 with stable event names, typed/allowlisted properties, required-property validation, numeric bounds, immutable validated payloads, and explicit wire serialization.
- `AnalyticsPort` and `AnalyticsPrivacyPort` keep the application boundary vendor-neutral; `PrivacyGatedAnalytics` requires build enablement, explicit first-party runtime privacy eligibility, and an outward emitter before collection can become active.
- `ENABLE_ANALYTICS` defaults to false. Production composition installs `DenyAllAnalyticsPrivacy` and no emitter, so first-party analytics remains non-collecting even if the build flag is accidentally enabled.
- Google UMP advertising consent is not reused as first-party analytics consent. No analytics SDK, processor, persistence queue, upload, or network transport was introduced.
- `tool/verify_analytics_privacy.py` blocks analytics SDK/processor drift, non-versioned/unbounded schema changes, advertising/storage/network coupling, default-on collection, and production emitter installation.
- Flutter CI #785 / run `31341159553` passed privacy/security/dependency/catalog gates, formatting, Analyze, focused analytics tests, existing focused regressions, the full Flutter suite, Debug APK build, artifact security and upload on head `eb8dd6623cc35809bd6c7eb270235c30437627cf`.
- Debug artifact #9045957178 is 80,626,055 bytes with SHA-256 `102b965b14dab94df5fa4137ac760a58ee2281c6ad512127f553955f74723720`.
- All repository-owned ENG-012 acceptance criteria are VERIFIED; any future real collector/processor still requires an explicit first-party privacy decision plus inventory/disclosure review before enablement.

## ENG-011 developer tooling and documentation — 2026-08-10

- Issue #173 / PR #174 replace obsolete README bootstrap/release instructions with a current canonical developer path over the repository's existing tooling rather than introducing another launcher.
- `docs/DEVELOPER_WORKFLOWS.md` documents clean checkout/first run, daily Android execution with dynamic target selection, CI-parity verification, Android/Kotlin repair, dashboard access, privacy contracts, guarded APK/AAB release packaging, and a troubleshooting matrix.
- `README.md` now points to `START_CARGAME_TOOL.bat`, `FIRST_TIME_SETUP_AND_RUN.ps1`, `RUN_ON_EMULATOR.ps1`, repair/dashboard scripts, and the guarded `VERIFY_RELEASE_INPUTS.ps1` / `BUILD_RC.ps1` release path; production signing/AdMob values remain external and ADS-007 UMP integration is treated as authoritative.
- `tool/verify_developer_workflows.py` protects 16 required entry-point/doc files and current guidance while rejecting project-regeneration commands, obsolete bootstrap guidance, tracked AdMob replacement instructions, manual duplicate UMP integration, hard-coded emulator serials, and direct unguarded release builds.
- `tool/test_developer_workflows.py` provides 10 focused regressions for valid text/repository contracts and every protected stale/missing workflow class.
- Flutter CI now runs the developer-workflow validator and regression suite as blocking gates before package restore.
- Flutter CI #773 / run `31339612397` passed both ENG-011 gates, privacy/security/dependency/dashboard/catalog/assets checks, formatting, whitespace, Analyze, focused privacy/service/widget tests, the full Flutter suite, Debug APK build, packaged-artifact security scan and upload on implementation head `c34881bda12a6a355930755b39e47d09d24f0f3d`.
- Debug artifact #9045499219 is 80,619,633 bytes with SHA-256 `2baf734f6a3362837f140cbbd25863c7ea189b15de3ea81d75d5b7dde43e7d5b`.
- Repository search found no current first-party analytics implementation; ENG-012 is the next dependency-ready source-controlled feature and must preserve the existing analytics-disabled privacy posture until an explicit gate permits collection.

## PRIV-003 user data export/deletion readiness — 2026-08-10

- Issue #171 / PR #172 add `LocalDataController` as the first-party local data export/delete boundary without introducing a backend, network export path, dependency, or new storage permission.
- **Copy data export** produces schema-versioned JSON containing the CARGame-managed SharedPreferences snapshot and already-redacted local diagnostic entries, explicitly records `networkTransfer: false`, and copies the export only through an explicit user action.
- **Delete & reset local data** requires confirmation, serializes concurrent requests, clears the app-owned SharedPreferences namespace including progression/economy/settings data, shop/reward journals, completed reward transaction IDs, economy metadata and `storage_recovery_backup_v1`, and clears local diagnostic logs.
- After deletion the app builds fresh `ProgressStore` and `AppSettingsStore` instances and returns the navigator to its first route so stale pre-delete reward/recovery/settings state cannot survive only in memory or be re-saved from an old route.
- Settings copy explicitly distinguishes CARGame first-party local deletion from Google Mobile Ads processor-side retention; existing UMP privacy choices remain the Google advertising privacy control.
- PRIV-001 human/machine inventory and the PRIV-002 draft policy/Play mapping now describe the local export/reset path; `deletionRequestMechanismAvailable` is true and the completed `in-app-data-controls` gap was removed.
- `tool/verify_privacy_disclosures.py` now source-anchors `LocalDataController` plus the Settings export/delete/confirmation controls and rejects regression of the deletion mechanism or reintroduction of the old PRIV-003 gap. The focused policy suite now contains 15 regressions.
- CI debugging found the first Settings test harness depended on platform clipboard/pending UI work; the tests were hardened with an isolated clipboard method-channel mock, bounded deterministic pumps, and explicit UI disposal without changing production behavior.
- Flutter CI #768 / run `31338337454` passed privacy inventory, Play Data Safety validation, all 15 disclosure regressions, security/dependency/dashboard/assets gates, formatting, whitespace, Analyze, dedicated `LocalDataController` tests, dedicated Settings local-data tests, optional-service/GameButton checks, the full Flutter suite, Debug APK build, packaged-artifact security scan and upload on implementation head `64da8aeaefaefe60fb57d765bc0c7d26521e0c83`.
- Debug artifact #9045113026 is 80,619,639 bytes with SHA-256 `6c101a90e89053b48836dd48be72b76ceb9290401ae3643310ad46730b653ddf`.
- PRIV-003 is VERIFIED because all repository-owned acceptance criteria pass and CARGame has no first-party account/backend/cloud-save/remote-diagnostic data path requiring an external remote deletion implementation.
- TEST-011 is no longer blocked by repository-owned deletion/export controls; its remaining acceptance blocker is external production UMP/privacy-message behavior in the actual regulated-region/device configuration.

## PRIV-002 privacy policy and Play Data Safety mapping — 2026-08-09

- Issue #169 / PR #170 implement the source-controlled PRIV-002 contract without changing runtime gameplay, persistence, economy, navigation, or ad-request behavior.
- `docs/PRIVACY_POLICY.md` is a release-ready DRAFT and intentionally retains publication/contact/audience blockers rather than fabricating external evidence.
- `docs/privacy/play_data_safety.json` maps all six PRIV-001 flows exactly once: five local-only flows remain on-device-only; `ad-sdk-processing` is the sole off-device network flow through Google Mobile Ads.
- The conservative Google Mobile Ads mapping covers approximate location from IP, app interactions, diagnostics, and device/other IDs for advertising, analytics, and fraud-prevention/security; the production owner must re-check the exact SDK/configuration at release.
- `tool/verify_privacy_disclosures.py` plus 12 regressions fail on inventory/disclosure/policy drift, local-flow off-device claims, processor mismatch, GMA data/purpose loss, stale absent capabilities, and fabricated publication states.
- Flutter CI #746 / run `31335858470` passed privacy inventory, the new disclosure gates, security/dependency/dashboard/assets/format/Analyze, the full Flutter suite, Debug APK, artifact security and upload on implementation head `1da1ce6e57d9fc29b30a514360a847078820a7dc`.
- Debug artifact #9044388801 is 80,608,681 bytes with SHA-256 `03e81188e97a1b9ab867d18c48894603f7586bd5d0963014516de35e8b8e868a`.
- PRIV-002 is IMPLEMENTED rather than VERIFIED until publisher contact, a stable HTTPS policy URL, target audience/Families applicability, production Google Mobile Ads/UMP configuration, and submitted/reviewed Play Console answers exist.
- PRIV-003 now supplies the first-party local export/delete/reset controls referenced by the policy and Play mapping; external production consent/publication/store evidence remains separate.

## ADS-007 consent/privacy client integration — 2026-08-09

- Issue #166 / PR #167 add Google UMP as the runtime privacy source of truth without persisting a duplicate app-side consent-granted value.
- Launch refreshes consent info and shows required UMP forms before Mobile Ads initialization; `canRequestAds` gates SDK startup plus banner/rewarded/interstitial app-owned request/load/show paths.
- Loaded app-owned ads are disposed when eligibility is revoked, and Settings exposes a publisher privacy entry that re-opens Google privacy options when required; choices update request eligibility without restart.
- First-party analytics remains absent/disabled; ENG-012 remains the owner of any future analytics event collection and privacy gate.
- Focused implementation/UI probe `31331329428` passed 12 consent/request/composition/Settings tests, privacy inventory validation (6 flows, 2 processors, 33 persisted key families), security baseline validation, Analyze and whitespace checks.
- Flutter CI #742 / run `31331414894` passed privacy/security/dependency/dashboard/assets/format/Analyze gates, the full Flutter suite, Debug APK build, SEC-002 packaged-artifact security scan and upload on head `af3edcba29919151e83a3d59f614faa41eb06a7c`.
- Debug artifact #9043116329 is 80,608,682 bytes with SHA-256 `60ec4df1b88a24bfe2b19e0019ba05d07b4c99a17aa6a91479151895a023840a`.
- PR #167 squash-merged to main as `865a31a8790c1b93b550f4da49f4e7d9f4720b28`.
- ADS-007 remains IMPLEMENTED rather than VERIFIED because actual production AdMob Privacy & messaging configuration and regulated-region/device behavior are external to this repository; Issue #166 remains open for that evidence.
- Post-merge dependency audit `31331857275` identifies PRIV-002 as the next P0 dependency-ready feature. TEST-011 is not selected despite its declared dependencies because its acceptance still requires production consent verification and PRIV-003 deletion/export controls.

## SEC-002 security scan verification — 2026-08-09

- Issue #163 / PR #164 add blocking dependency-advisory and packaged-artifact security controls without changing production dependency versions or runtime gameplay behavior.
- Existing tracked-secret/signing-material verification remains blocking; focused probe run `31327275686` scanned 269 tracked files and passed the existing secret-policy regression.
- `flutter pub get --enforce-lockfile` is now the CI restore path. `tool/verify_dependency_security.py` rejects active unreviewed GHSA advisories, pubspec-level advisory suppression, expired/malformed/package-mismatched exceptions, and stale exceptions. Baseline: 0 active advisories and 0 exceptions.
- `tool/verify_build_artifact_security.py` scans bounded text entries and forbidden file names inside APK/AAB archives while avoiding arbitrary compressed-binary false positives. Thirteen focused SEC-002 regressions passed.
- ENG-007 CI contracts now require the dependency-security and artifact-security gates; contract-hardening run `31327658032` passed 15/15 CI-integrity regressions plus 13/13 SEC-002 regressions.
- Flutter CI #738 / run `31327747831` passed all security/privacy/dependency/dashboard/assets/format/analyze tests, the full Flutter suite, Debug APK build, Debug APK artifact scan, and upload on head `0201c611a967fb795ad28f67835700108f9440fd`.
- Debug artifact #9042097866 is 80,594,411 bytes with SHA-256 `64359046108d96929c58967d1877caf0bba49f3fd93670d075f179f7092d99c2`.
- Android Release Packaging Smoke #7 / run `31327747834` passed enforced-lock advisory verification, release preflight, ephemeral CI signing, ads-disabled release APK+AAB builds, and both packaged-artifact scans. Release APK SHA-256: `aa84e87d4815064e8bf2f89d05694c897b6bfed23f82261e17cf9006d21a738a`; AAB SHA-256: `3c8fb5b1cfb8b0cf8d3ba7e6156172e67477da54bba67b24c46b2ed8659e8892`.
- Release evidence artifact #9042103273 is 464 bytes with SHA-256 `6c261bc007aefb0142b8b09a96080aaff6e1bcf17bbaacdcdb7a4c1c46f8c0ea`.
- PR #164 squash-merged to main as `5b96ee94f1d82a36bb6bbffd53b7719b64c175d3`; Issue #163 closed Completed. SEC-002 has no remaining acceptance blocker and is VERIFIED.
- Historical note: TEST-011 previously also waited on PRIV-003; PRIV-003 is now VERIFIED, leaving external production UMP/privacy-message evidence as the remaining privacy acceptance blocker.

## ENG-007 CI verification workflow — 2026-08-09

- Issue #160 / PR #161 close the remaining CI acceptance gaps without changing runtime behavior.
- `tool/verify_ci_integrity.py` validates all 19 catalog phases and 192 current feature rows, exact six-column Markdown structure, stable/unique feature IDs, status/priority vocabulary, dependency references, and the single-primary-work invariant.
- The same verifier protects the Developer Portal runtime parser contract so `docs/dashboard/index.html` continues to load and audit `docs/FEATURE_CATALOG.md` instead of maintaining a second status copy.
- The protected release-smoke contract requires release-input preflight, ephemeral CI signing, synthetic compile-only AdMob input, ads-disabled release APK+AAB builds, output/checksum evidence, and artifact upload while rejecting production repository-secret dependencies.
- Twelve focused regressions cover catalog, dashboard, and release-workflow failure modes. Focused probe run `31325591817` passed the real 19-phase / 192-feature catalog, all 12 tests, Analyze, and whitespace validation.
- Flutter CI #734 / run `31325664494` passed the new ENG-007 gates plus dynamic Android, secret/privacy/security/dependency/assets, formatting, whitespace, Analyze, optional-service/GameButton coverage, full Flutter suite, Debug APK build, and artifact upload on head `644a7635bc5f1f3289c05cd3d88bcf9510fee157`.
- Debug artifact #9041540363 is 80,594,411 bytes with SHA-256 `35e6836f0b85a890bb8a159f0f71657ac3b4be1af8abdda1581fd3ae77822cf4`.
- PR #161 squash-merged to main as `1e1ffd1c36f1338dc36820a3f38e78ae4bbcb47a`; Issue #160 closed Completed. ENG-007 has no remaining acceptance blocker and is VERIFIED.
- Follow-up catalog reconciliation found that `TEST-011` cannot yet satisfy acceptance: the catalog explicitly requires `ADS-007`, `PRIV-003`, and `SEC-002`. `SEC-002` is the true P0 dependency-ready blocker because `ENG-006`, `ENG-010`, and `ENG-007` are VERIFIED.

## ENG-006 dependency governance verification — 2026-08-09

- Issue #157 / PR #158 implement dependency governance without changing any production dependency version or runtime behavior.
- The committed `pubspec.lock` remains authoritative for application builds; direct hosted dependencies must resolve from `https://pub.dev`, match their manifest constraint/direct kind, and have a reviewed installed license family.
- Git/path/custom-host direct dependencies and `dependency_overrides` are rejected by the governance verifier until explicitly reviewed.
- The reviewed direct inventory is: Flame 1.38.0 MIT; Google Mobile Ads 9.0.0 Apache-2.0; Shared Preferences 2.5.5 BSD-3-Clause; Path Provider 2.1.6 BSD-3-Clause; Cupertino Icons 1.0.9 MIT; Flutter Lints 6.0.0 BSD-3-Clause; Shared Preferences Platform Interface 2.4.2 BSD-3-Clause.
- Eight focused policy regressions cover valid hosted resolution, git/custom-source rejection, lock-constraint drift, mandatory license review on direct upgrades, missing/mismatched licenses, and dependency overrides.
- `flutter pub outdated --json` remains non-blocking review evidence; the baseline reported seven newer versions outside current constraints and all seven are transitive, so ENG-006 intentionally performs no package upgrade.
- Flutter CI #730 / run `31324376214` passed the new dependency-governance gates, dynamic Android/secret/privacy/security/assets gates, formatting, whitespace, Analyze, optional-service isolation, GameButton coverage, full Flutter suite, Debug APK build, and artifact upload on head `2bf80a697e17a28af9b30a0d479452c1e6dbad24`.
- Debug artifact #9041192218 is 80,594,411 bytes with SHA-256 `ebd0fefb2d148323693361a68a0e0729b5b8d697863572e5f9584575549e1f0d`.
- PR #158 squash-merged to main as `e8e474e54ada81b5936bd5adf0d9aa9e31ff117e`; Issue #157 closed Completed. ENG-006 has no remaining acceptance blocker and is VERIFIED.

## ENG-006 dependency governance audit — 2026-08-09

- Issue #157 audits the dependency graph against the committed `pubspec.yaml` / `pubspec.lock` pair before changing any package version.
- Direct hosted packages resolve from pub.dev with reviewed licenses: Flame 1.38.0 MIT; Google Mobile Ads 9.0.0 Apache-2.0; Shared Preferences 2.5.5 BSD-3-Clause; Path Provider 2.1.6 BSD-3-Clause; Cupertino Icons 1.0.9 MIT; Flutter Lints 6.0.0 BSD-3-Clause; Shared Preferences Platform Interface 2.4.2 BSD-3-Clause.
- `flutter pub outdated --json` reports seven newer versions outside current constraints, all transitive (`hooks`, `intl`, `matcher`, `meta`, `record_use`, `test_api`, `vector_math`); no direct hosted dependency requires a version change for this checkpoint.
- The implementation adds an executable source/constraint/lock/license contract, a reviewed direct-license inventory, regression tests, CI enforcement after package restore, and non-blocking drift visibility.

## ENG-005 clean architecture boundary checkpoint — 2026-08-09

- Issue #154 / PR #155 document and enforce inward dependency direction: composition root -> adapters/presentation -> application -> domain.
- `AppComposition` owns ProgressStore, AppSettingsStore, and optional-service construction/disposal; `main.dart` no longer imports or constructs those concrete adapters directly.
- `CargoSortApp` moved to a bootstrap/presentation shell and remains re-exported from `main.dart` for source compatibility with existing callers/tests.
- Optional-service state is pure Dart in `core/domain`; `OptionalServicePort` lives in `core/application`; `OptionalServiceCoordinator` remains the outward implementation with a narrow compatibility export.
- `tool/architecture/architecture_contract.dart` plus focused tests automatically reject Flutter, feature, storage, service implementation, and other outward imports from domain/application code.
- Focused branch verification passed architecture 4/4, composition 2/2, optional-service 6/6, splash responsive 2/2, Home/widget 3/3, Analyze, and whitespace validation.
- Flutter CI #726 / run `31322368738` passed dynamic Android, secret/privacy/security/asset gates, formatting, whitespace, Analyze, optional-service isolation, animated GameButton, the full Flutter suite, Debug APK build, and artifact upload on head `4f1a4e2cade00cb8dadbec527aefb8d6a3dfe86f`.
- Debug artifact #9040624907 is 80,594,413 bytes with SHA-256 `ccae51e0c45fa6062017c07ac2fc9bf95049bbd1e95a7d51705517a36bb82f81`.
- PR #155 squash-merged to main as `07fb50182efe5ce315cdda8bf823ba4da855c2df`; Issue #154 closed Completed.
- ENG-005 remains IMPLEMENTED rather than VERIFIED because existing feature presentation still has direct storage/ad adapter dependencies that should migrate behind application ports incrementally.

## UI3D-009 mission result debrief verification — 2026-08-09

- Issue #151 / PR #152 replace the generic result sheet with a premium `MISSION DEBRIEF` for both victory and failure states.
- Victory exposes route/world identity, stars, coins, XP, best combo and bonus/world rewards through the shared premium hierarchy; failure exposes `MISSION INTERRUPTED`, rewarded +5 moves and Retry recovery without altering the underlying state machine.
- Exact regression semantics `Retry`, `Next and back to map`, and `Watch ad for five moves` remain stable; `_resultVisible`, `_resultActionBusy`, sheet-dismissal, heart-loss, no-fill and duplicate-action behavior remain owned by the existing `GameScreen` methods.
- Compact 360x640 overflow hardening uses bounded scale-down for debrief labels; reduced-motion disables reward-icon animation.
- Superseded private gameplay presentation widgets left after GAME-003 were removed; `_CargoFlight` and active gameplay/motion logic were preserved.
- Flutter CI #722 / run `31314119391` passed dynamic Android, secret/privacy/security/asset gates, formatting, whitespace, Analyze, optional-service isolation, animated GameButton coverage, the full Flutter suite, Debug APK build and artifact upload on head `9f6ceb97d0e1e2ab45aa30136dce0b184999609d`.
- Debug artifact #9038304448 is 80,597,376 bytes with SHA-256 `76be94bd048b7f6029472035076c891ff4257c0d1f7ddc5d45cfde915403f9a2`.
- PR #152 squash-merged to main as `462ec0590866879f654a4e031209731bd4eb84fd`; Issue #151 closed Completed.
- REW-001 and REW-002 remain IMPLEMENTED because complete authored 3D reward animation is still tracked separately by REW-006; `ENG-005` remains the next dependency-ready catalog item.

## GAME-003 gameplay operations deck verification — 2026-08-09

- Issue #148 / PR #149 replace the generic gameplay AppBar/flat board presentation with a premium live operations deck aligned with Home, World Map, and Mission Control.
- The active run now exposes a mission command bar, live mission banner, moves/cargo/combo/heart-or-shield telemetry, `CARGO BAY`, `SORTING DOCKS`, and a shared `GameButton` / `ThreeDGameIcon` booster dock.
- Deterministic cargo ordering, move consumption, combo/shield/hint/extra-move rules, reward transaction identity, ads, persistence, result guards, and win/loss behavior were not changed.
- `game-moves`, `cargo-*`, and `warehouse-*` keys plus `GameTravelMotion` and `GameActionFeedback` authority remain stable for anti-spam and motion regressions.
- The branch was reconciled with TEST-002 verification main `653f29aca08f1a88a7487695d199448ec0913b85` before the final gate.
- Flutter CI #718 / run `31312628308` passed formatting, whitespace, Analyze, optional-service isolation, animated GameButton coverage, the full Flutter suite, Debug APK build, and artifact upload on head `3fd8e5627a098df80aef6ed7049621e82f370a73`.
- Debug artifact #9037881344 is 80,593,016 bytes with SHA-256 `b408561b1d6234336d180836d47ede432cdac8f4604ac4127caf84cb0ec37381`.
- PR #149 squash-merged to main as `dfd92944791a35aa3c9b194c6401b3bf17bc5626`; Issue #148 closed Completed.
- GAME-003 remains IMPLEMENTED rather than VERIFIED because authored 3D board/product integration is still owned by GAME-012/AST-007; `ENG-005` remains the next dependency-ready catalog item.

## TEST-002 integrated level release contract verification — 2026-08-09

- Issue #143 / PR #144 add `level_release_contract_test.dart` as one release-level gate over the exact production `levels` catalog.
- The gate requires exact sequential identity 1..150, regenerates every level and compares stable number/world/moves/difficulty plus ordered product IDs, then validates the full catalog through both `LevelSolvabilityValidator` and `LevelDifficultyCurve`.
- Required release boundaries 1, 25, 26, and 150 pass both structural and quantitative contracts explicitly; detailed negative cases remain in their existing owning suites.
- No production level, progression, save, economy, reward, or UI content changed for TEST-002.
- UI3D-007 / PR #141 advanced main during verification, so TEST-002 was reconciled to main `c6e22c1fca7e82e8c48a3d79071ff0dc515471de` before the final gate.
- Final Flutter CI #697 / run `31310666540` passed dynamic-target, secret/privacy/security/asset gates, formatting, whitespace, Analyze, optional-service regressions, the full Flutter suite, Debug APK build, and artifact upload on head `a0f1de0e14b78f090bb770643c93492cc5164ebe`.
- Debug artifact #9037363042 is 80,562,923 bytes with SHA-256 `ef6c18142dc7b1925f131848217ba8db8386f534aaee24becaede3d3ed598a9b`.
- PR #144 squash-merged to main as `d9afbb06564a08ee571ed7c9e4784adf99a7c3fe`.
- `TEST-002` is VERIFIED; no PLANNED P0 is currently dependency-ready, so `ENG-005` is the next highest-priority unblocked catalog item.

## LEVEL-002 quantitative difficulty curve verification — 2026-08-09

- Issue #134 / PR #137 introduced typed Tutorial, Easy, Medium, Hard, and Expert bands covering levels 1..150 with no gaps or overlaps.
- `LevelDifficultyCurve` validates declared difficulty, cargo count, distinct-product count, move slack, complete-set identity, boundary levels, and macro pressure progression while keeping structural solvability in LEVEL-003.
- Expert levels 121..150 deliberately use a base safety budget of one move, producing 1..3 spare moves; other bands preserve the prior deterministic generator behavior.
- Stable level numbers, six-world boundaries, product generation, persistence keys, unlock IDs, and reward transaction identity are preserved.
- Final Flutter CI #681 / run `31309097571` passed release/privacy/security/asset gates, formatting, Analyze, optional-service regressions, the full Flutter suite, Debug APK build, and artifact upload on head `1c1c39ad5d1fb336da2e5b3f7845a83d04d454ff`.
- Debug artifact #9036909677 is 80,547,511 bytes with SHA-256 `e3d2acc260fdc39462b299f19295660dccae130a89b63a8cc52aeddf38647ee6`.
- PR #137 squash-merged to main as `938ed6ea100a987b2513e5f5221aab90a850c2d6`.
- `LEVEL-002` is VERIFIED; `TEST-002` is the next dependency-ready P0.

## LEVEL-003 level solvability validator current-main verification — 2026-08-09

- Historical commit `c06e23ec272a8800a039d99cbdcb02a4b0391670` added `LevelSolvabilityValidator`; current main retains the validator in `lib/features/game/level_validator.dart`.
- Individual-level validation enforces the 1..150 level range, exact six-world/25-level mapping, difficulty 1..10, non-empty cargo, canonical product identity/metadata, at least two product types, no orphan product occurrences, and a positive move budget at least equal to cargo count.
- Complete-set validation rejects duplicate level numbers and requires the exact 1..150 set.
- `test/features/game/level_validator_test.dart` verifies all 150 generated levels, explicitly checks levels 1, 25, 26, 50, 51, 125, 126, and 150, and rejects insufficient moves, empty/single-target layouts, orphan/unknown products, world/difficulty/product mismatches, and duplicate/incomplete sets.
- `lib/features/game/level_data.dart` deterministically generates the 150 levels from stable level-number-derived inputs, so the suite does not depend on runtime randomness.
- Current Flutter CI #659 / run `31301158763` passed Analyze, all 240 Flutter tests including this validator suite, Debug APK build, and artifact upload.
- Debug artifact #9034604961 is 80,544,511 bytes with SHA-256 `79d61a1977614296dd06a38a850e7960a730c6d632890801e77d99d5983ac6b6`.
- Issue #132 reconciles stale tracking only; no duplicate production validator code was added.
- `LEVEL-003` is VERIFIED; quantitative difficulty balancing remains a separate `LEVEL-002` P0 task.

## AST-011 asset licensing and provenance current-main verification — 2026-08-09

- Historical implementation on main added the typed/versioned provenance model, complete commercial-use/source/generated-prompt/hash validation, `GameAssetAdmission`, focused tests, and the `Validate 3D asset registry and provenance` CI gate.
- Historical implementation head `1d6597de0c298b40dd1f1c305f7fdeca26a2d37a` passed Flutter CI #121 / run `31185774162`; debug artifact #8996933307 is 80,450,231 bytes with SHA-256 `9048ad078046154a0db92dd4d6ed918154e91b15c35c3b60feac2b9b1257d213`.
- Current-main audit under issue #130 confirms `assets/3d/manifest.json` has 9 stable descriptors, `assets/3d/provenance/catalog.json` has 0 approved records, and `assets/3d/runtime/` is absent, so 0 runtime WebP binaries are currently admitted.
- The 9/0/0 state is intentional: descriptors support typed binding/fallback before binary art exists. The project does not invent source/license/prompt records for nonexistent binaries.
- `GameAssetAdmission` rejects runtime WebPs missing manifest/provenance, rejects orphan provenance records without binaries, and enforces matching path/profile/dimensions/revision plus required commercial-use/hash/prompt metadata.
- Current Flutter CI #657 / run `31300595956` reports `ASSET PIPELINE VALIDATION PASSED`, `Manifest entries : 9`, `Provenance records: 0`, `Runtime WebP files: 0`; it also passed Analyze, all 240 Flutter tests, Debug APK build, and artifact upload.
- Current debug artifact #9034434441 is 80,544,514 bytes with SHA-256 `5932514475e58a4336d953590dcf9690c0354a19eaf933b870af0c51c7b01c14`.
- `AST-011` is VERIFIED on current main; issue #130 is a tracking reconciliation and receives a fresh docs-only CI before closure.
- Next unblocked P0 audit selected: `LEVEL-003`, because current main already contains `LevelSolvabilityValidator` and a regression validating all 150 generated levels.

## SEC-001 mobile security baseline current-main verification — 2026-08-09

- Historical PR #35 established the original human/machine mobile threat model and CI security-baseline gate; issue #34 was reopened because later privacy, persistence, transaction, economy, signing, and secret-hardening work changed current-main security truth.
- PR #128 reconciles the client/local-storage/Google Mobile Ads/CI-secret-store/future-backend trust boundaries and classifies six protected asset groups, including transaction/reward recovery state and the storage-recovery snapshot.
- The threat model now distinguishes `AdService` request/load/show gating from the still-ungated `MobileAds` SDK bootstrap, and records the ineffective `ENABLE_DIAGNOSTICS` bootstrap gate while preserving redacted local-only diagnostics. Owners remain ADS-007 and ENG-013.
- `tool/verify_security_baseline.py` cross-checks security runtime-control truth against PRIV-001, network processors against trust boundaries, protected-asset ownership/location, security-relevant privacy gap ownership, required threat categories/structure, and ENG-010 secret-policy controls.
- REL-004, SHOP-002, REW-007, ECON-005, REL-006, and ENG-010 are reflected as verified mitigation inputs without falsely completing SEC-002, SEC-003, ADS-007, ENG-013, PRIV-002, or TEST-011.
- Final implementation head `e25c4f8239635981d43e7c0865c2f9f04c3e8b8e` passed Flutter CI #655 / run `31300172519`, including privacy/security validation, formatting, Analyze, full Flutter tests, Debug APK build, and upload.
- Debug artifact #9034317021 is 80,544,512 bytes with SHA-256 `67938778535d63de844f455b324796a4488b1a33efe20ea004fe9894d9db135d`.
- PR #128 squash-merged to `main` as `c0e7c561e0bafa810ef9248322102b10b684a490`; `SEC-001` is VERIFIED.
- Next release-critical unblocked P0 selected for audit: `AST-011`.

## PRIV-001 privacy inventory current-main verification — 2026-08-09

- Historical PR #33 established the original human/machine privacy inventory and CI validation gate; issue #32 was reopened because later SHOP-002, REL-004, REW-007, and ECON-005 work expanded local persistence.
- PR #126 reconciles the inventory with all 33 current SharedPreferences key/prefix families across gameplay/progress, settings, transaction/migration integrity metadata, and the storage-recovery snapshot.
- `tool/verify_privacy_inventory.py` now extracts persisted key declarations from `ProgressStore`, `AppSettingsStore`, and `RecoveringPreferences` and fails on missing, stale, or duplicate inventory ownership.
- Google Mobile Ads remains the only declared production network data processor; no first-party analytics, account, cloud-save, or remote diagnostics SDK is enabled.
- Historical gap note: at that checkpoint complete in-app reset/export/delete was pending under PRIV-003. Current mainline work now supplies those controls; ENG-013 remains the owner of effective diagnostics gating.
- Final implementation head `659a78ce00b6fc3f95e7213bf1c04ceaa680cd55` passed Flutter CI #651 / run `31299285194`, including the strengthened privacy drift gate, security baseline, formatting, Analyze, full Flutter tests, Debug APK build, and upload.
- Debug artifact #9034063433 is 80,544,514 bytes with SHA-256 `6fc839b195551ffcdbb0bd30b69bb9f29124aa5b9f5277ab8aa981d3508f4f9c`.
- PR #126 squash-merged to `main` as `dd076dd383d6c3cd0dd33986f980e8b4f012b38b`; `PRIV-001` is VERIFIED.
- Next release-critical reconciliation target: `SEC-001`.

## ECON-005 economy configuration verification — 2026-08-09

- Issue #122 / PR #124 replace scattered release-critical economy constants with immutable validated `EconomyConfig.v1` while preserving the exact shipped v1 numbers.
- Centralized rules cover starter coins/hearts/boosters, heart cap/refill cadence, XP level step, daily mission thresholds, gameplay reward formulas, hint/extra-move sinks, milestone/world rewards, and all shop offer prices/quantities.
- `ProgressStore`, `GameScreen`, and `ShopScreen` consume config-derived values; production shop flows use stable authoritative offer IDs instead of trusting presentation-supplied prices or quantities.
- `economy_config_version` adoption writes only the v1 marker for legacy saves, leaves balances/entitlements untouched, treats same-version loads as no-ops, and fails closed for non-positive/corrupt or future markers before reward/shop recovery.
- Configured heart purchases debit coins, grant hearts, and clear the refill timestamp atomically through the existing SHOP-002 absolute-state journal; REW-007 and SHOP-002 recovery/idempotency behavior remains preserved.
- Focused review-hardening run `31296816764` passed Analyze plus ECON-005, ProgressStore, SHOP-002, and REW-007 regressions.
- Final implementation head `05217d3a1134b21ff014a58864615683db3ccb22` passed Flutter CI #647 / run `31296918681`: secret/privacy/security gates, formatting, whitespace, Analyze, optional-service checks, full Flutter tests, Debug APK build, and artifact upload.
- Debug artifact #9033326885 is 80,544,514 bytes with SHA-256 `bbca79f780b9effc07a93ecc8a5a0b0dd73b523e6706531fe292127165d2872a`.
- PR #124 squash-merged to `main` as `2091cf35ff9b4a261fa76f9d90975735711c58e3`; `ECON-005` is VERIFIED.
- Next release-critical unblocked P0 selected for execution: `PRIV-001`.

## REW-007 reward transaction reconciliation — 2026-08-09

- Issue #119 / PR #120 replace multi-key reward persistence risk with a validated absolute-state pending journal plus a bounded completed idempotency ledger.
- Gameplay completion uses a stable per-attempt transaction ID; daily reward and daily mission claims use stable per-day keys; explicit heart grants are journaled and can clear the refill timestamp atomically when hearts reach the cap.
- Recovery runs before normal state load, malformed journals are discarded safely, completed IDs are persisted before mutating the in-memory ledger, and stale pending cleanup is best-effort after the durable ledger is authoritative.
- Legacy saves remain compatible because absent reward-ledger keys default to empty state; existing shop transaction recovery remains unchanged.
- Flutter CI #623 / run `31295126718` passed secret/privacy/security gates, formatting, whitespace, Analyze, focused checks, the full Flutter test suite, Debug APK build, and artifact upload on head `2df14361ec829ae00739aac2e72e6b43cdc0a7e4`.
- Debug artifact #9032765167 is 80,530,583 bytes with SHA-256 `534037a3cdd4fe75d54a53df6452f8188d4c81cdcc859040a51725315f20070b`.
- PR #120 squash-merged to `main` as `b915d95b938d459133a9a8b120f38815178b1852`; `REW-007` is VERIFIED.
- Next recommended RC P0: `ECON-005` versioned economy configuration and balance rules.

## ADS-002 release ad configuration verification — 2026-08-09

- Issue #116 / PR #117 fixed a release-only configuration defect: Android RC builds inject Android ad-unit IDs only, so typed validation now scopes completeness/test-ID checks to the active runtime platform instead of rejecting valid Android releases because unused iOS defaults remain Google test IDs.
- Active-platform runtime ad units must match the AdMob `ca-app-pub-<16 digits>/<10 digits>` shape; malformed direct `--dart-define` values fail closed even if a build bypasses the PowerShell RC preflight.
- Existing defense-in-depth remains: debug uses Google's public test application/ad-unit IDs; Android release app ID and signing are externally injected; Gradle and `VERIFY_RELEASE_INPUTS.ps1` reject missing/test release inputs; `AdService` consumes only `AppBuildConfig.current` IDs; ads-disabled/offline paths remain non-blocking.
- Flutter CI #595 passed secret/privacy/security gates, formatting, whitespace, Analyze, focused checks, the full Flutter test suite, Debug APK build, and artifact upload on head `26851ed3cba7b6bd04ac24db7f068b6a68efc63c`.
- Debug artifact #9032228970 is 80,520,644 bytes with SHA-256 `e801630e475047590b2ad97299d912681457aa081f43f2bd87832d4dcad9b459`.
- PR #117 squash-merged to `main` as `0e2f13329835bfe69c79b985153c65e68ac32bb2`; `ADS-002` is VERIFIED.
- Next RC P0: `REW-007` reward transaction ledger/reconciliation.

## ENG-010 secret and credential handling verification — 2026-08-09

- Issue #113 / PR #114 hardened the tracked-file secret scanner, added a focused temporary-repository regression harness, and extended runtime diagnostic redaction to standalone high-confidence GitHub/AWS/Google/Slack credential signatures.
- Existing `.gitignore`, Android signing procedure, and secret-handling policy keep keystores, `key.properties`, environment overrides, local credential JSON and reusable CI credentials outside source control; rotation/recovery procedures remain documented without storing secret values.
- Flutter CI #588 passed secret hygiene, scanner policy regression, formatting, Analyze, the full Flutter test suite, Debug APK build, and artifact upload on head `84b9705e8fcfc950ac973b951cca407afd8b5bec`. Artifact #9031846609 is 80,518,478 bytes with SHA-256 `913d9a9ae3107cde00ced9e6e7197098f5f15e640de59ae3e474715661cf33df`.

## GAME-016 input determinism verification — 2026-08-09

- Issue #110 / PR #111 extended the existing warehouse-spam regression with deterministic cargo-reselection coverage during placement resolution; attempts made while locked cannot become a latent selection after feedback completes.
- Existing production guards keep cargo/warehouse selection, boosters, Restart, and Back locked while `_resolving`; no production-code change was required after the regression proved the state machine behavior.
- `TEST-004` remains the result-boundary companion evidence for repeated Next/Retry/Home Start and idempotent result-sheet dismissal.
- Flutter CI #580 passed formatting, Analyze, all 215 Flutter tests, Debug APK build, and artifact upload on head `3fdba02dfa101bf9ab2f2e479d6cfabc7859b73b`.
- Debug artifact #9031438726 is 80,515,901 bytes with SHA-256 `afa0597b32a4d08f5fdaf76f109c92821eb84f3ad6b4e0a388b9b29d7fee1ae6`.
- PR #111 squash-merged to `main` as `093d9a9384aec2d18503284a8edc95ba1ce1ecfb`; `GAME-016` is VERIFIED.

## TEST-004 navigation race verification — 2026-08-09

- Issue #108 / PR #109 hardened result-sheet dismissal so repeated result actions cannot remove an already-removed modal route or duplicate the gameplay route exit.
- Deterministic integration regressions cover repeated Next, repeated Retry without duplicate heart loss, and repeated Home Start with exactly one journey push; existing `GameNavigator` tests cover concurrent and named duplicate-push guards.
- Flutter CI #571 passed formatting, Analyze, the full 214-test Flutter suite, Debug APK build, and artifact upload.
- Debug artifact #9031075109 is 80,515,902 bytes with SHA-256 `299e710a467672c57c91fd956669d67506cf5534b8741499066032ff9e60b539`.
- `TEST-004` is VERIFIED; the next RC P0 audit target is `GAME-016` rapid-input determinism.

## RC persistence/signing verification reconciliation — 2026-08-09

- PR #102 (`REL-006`) merged as `8f2e4ddb69d339938ba05911fb297960859e1a77`.
- Flutter CI #544 passed secret/privacy/security checks, formatting, Analyze, focused tests, the full Flutter suite, Debug APK build, and artifact upload. Debug artifact #9030167112 has SHA-256 `53f309ad514a9c2525555c8b23f66374769f3be26bd358557eeddb63af52eb54`.
- Android Release Packaging Smoke #4 passed the PowerShell preflight contract, shared redacted release-input preflight, ephemeral signing, release APK build, release AAB build, output verification, and evidence upload. Evidence artifact #9030181913 has SHA-256 `6b27c786fe315739f27825e39514971a1f05f182bb34cdb36ac77cc0a625589f`.
- `REL-006` is VERIFIED: `VERIFY_RELEASE_INPUTS.ps1`, `BUILD_RC.ps1`, `docs/ANDROID_SIGNING.md`, safe signing fixtures, backup/recovery/rotation guidance, and production handoff now satisfy the catalog acceptance without committed or echoed secrets.
- PR #104 (`TEST-001`) merged as `2ab3578ecc214f995f194eff95f1a27b7cc3f442` and added explicit legacy/unversioned save compatibility coverage while leaving production persistence code unchanged.
- Flutter CI #546 passed dynamic Android target validation, secret/privacy/security checks, formatting, Analyze, focused tests, the full Flutter suite, Debug APK build, and artifact upload. Debug artifact #9030311765 has SHA-256 `cdef9c5c5fbc9576d1760009956aab53ab6e63491248a2ba43ea5288797855b7`.
- `TEST-001` is VERIFIED: coverage now explicitly includes wallet bounds, hearts, boosters, stars, milestone/world first-clear rewards, duplicate daily-mission claims, corrupt-value backup/repair, interruption-safe shop transactions, and legacy-save compatibility with safe defaults for newer fields.
- `REL-001` is VERIFIED from the same current CI gate: `tool/verify_dynamic_android_targets.dart` rejected fixed emulator serials, literal AVD targets/defaults, and fixed `adb -s` targets across all 38 discovered PowerShell/batch scripts.
- `REL-007` and `REL-008` remain PLANNED because ephemeral smoke signing is intentionally non-distributable and does not replace a real production-signed candidate/device/store verification.
- `TEST-009` is not currently NEXT READY because its declared `PERF-001` dependency remains PLANNED.
- The next release-critical unblocked reconciliation target is `REL-004` storage corruption backup/recovery.

## REL-006 signing/key-management implementation — 2026-08-09

- Issue #101 was completed by PR #102 and is closed.
- The implementation branch `agent/rel-006-signing-procedure` added `VERIFY_RELEASE_INPUTS.ps1`, a reusable release-input preflight shared by humans/automation and `BUILD_RC.ps1`; it validates production AdMob ID formats, rejects Google test IDs, resolves signing inputs with environment-over-`key.properties` precedence, verifies keystore presence, and reports only redacted configuration state.
- `BUILD_RC.ps1` delegates release-input checks to the shared preflight instead of maintaining a second weaker validation implementation.
- `tool/test_release_input_preflight.ps1` covers missing signing inputs, environment-backed signing, Google test application/ad-unit rejection, and `key.properties` relative-keystore resolution using safe fixtures.
- `docs/ANDROID_SIGNING.md` defines upload-key generation, production input handoff, ownership/access, encrypted backup, recovery, replacement/rotation, and validation rules without containing credentials.
- `android/key.properties.example` recommends an absolute production keystore path and documents environment-variable precedence.
- The Android Release Packaging Smoke workflow runs the preflight contract and the shared preflight before release APK/AAB compilation.
- `REL-006` is VERIFIED by PR #102, Flutter CI #544, and Android Release Packaging Smoke #4.

## RC P0 audit and release reconciliation — 2026-08-09

- Issue #79 remains the Android Release Candidate umbrella.
- `UI3D-006` responsive acceptance is VERIFIED through PRs #86–#92.
- PR #95 (`RC-002`) merged as `887739aef683964cf2b54b0684e6ef255d665907` and hardened Android release configuration: debug retains official Google test configuration, while release requires an externally supplied non-test AdMob application ID and external signing values/keystore and no longer falls back to debug signing.
- `ENG-009` is VERIFIED: PR #95 implemented the release guards and PR #99 exercised the guarded release APK/AAB packaging path successfully while normal Flutter CI remained green.
- PR #97 (`RC-003`) merged as `e5a40cb7e3e5d071bbd42952a288cff793e00818`; shop theme/booster purchases persist an idempotent absolute-state journal, replay interrupted writes safely, reject malformed journals, and serialize overlapping purchases.
- `SHOP-002` is VERIFIED by PR #97 plus Flutter CI #536.
- `TEST-001` is VERIFIED after PR #104/CI #546 closed the final explicit legacy-save/default migration coverage gap on top of the existing heart, economy, milestone, world, duplicate-guard, corruption, and shop-recovery tests.
- PR #99 (`RC-004`) merged as `35e53031fbf59741da0ace89fad36d84eb738377` and added a dedicated release-packaging smoke workflow.
- Release Packaging Smoke #2 built a non-distributable release APK (55.8 MB, SHA-256 `2f6b2b5d3eb7de9a9029b0f51ae2e8a7e69a3c3278feb230abb116e4b56778dd`) and release AAB (57.0 MB, SHA-256 `957c1d4b696ee2547e97faa796544b3ab514fa2660681d4f01876af83a48c548`).
- Smoke signing is generated ephemerally inside the runner; generated passwords are masked before build steps. Only checksum/evidence text is uploaded, never the smoke binaries. Evidence artifact #9029778593 has SHA-256 `45e8057fb3a835b946dfe5ae001c48485c463ea4755aa9938b42e5beeb665059`.
- Flutter CI #539 on the same PR head passed secret/security checks, formatting, Analyze, focused checks, the full Flutter test suite, Debug APK build, and debug artifact upload.
- PR #100 reconciled `ENG-009` and `SHOP-002` to VERIFIED and kept `REL-007`/`REL-008` PLANNED; Flutter CI #541 passed and uploaded debug artifact #9029962050 with SHA-256 `3289c9a41ef4cfad4c45e81fb4a40b621e87d902094b4d4b343d134ecab80906`.
- `REL-007` and `REL-008` remain PLANNED: packaging is proven, but acceptance requires a real production-signed candidate and install/store/device validation. Smoke outputs are explicitly non-distributable.

## RC / UI3D reconciliation — 2026-08-09

- RC tracking remains under issue #79. UI3D-006 automated responsive acceptance is complete; execution has advanced into P0/P1 runtime and release-hardening work.
- `docs/work/UI3D-006.md` records the feature as VERIFIED; `docs/FEATURE_CATALOG.md` is reconciled to the same state.
- PR #85 completed Mission Briefing -> Gameplay adoption through `GameNavigator` and closed the known NAV-002 mission-flow gap.
- PR #86 merged as `9d04dc9848706a46043d0fd9e6a4ef13eeeea6bf`; Flutter CI #503 passed formatting, Analyze, optional-service isolation, GameButton tests, the full Flutter test suite, Debug APK build, and debug APK artifact upload.
- PR #87 merged as `323f7fe0fb4bf55b5c0206059f8d04e6eb6a235b`; Flutter CI #505 passed the same full gate set while adding gameplay RTL and cutout coverage.
- PR #88 merged as `0dfcfd7c46d5ba80b0aee9648fcdf5973091b634`; Flutter CI #507 passed the same full gate set while validating the compact loss-result sheet, reachable Retry action, and guarded system-back behavior.
- PR #90 merged as `ffc437dc486cf560383e27e38c15b3db676516ce`; Flutter CI #511 passed the full gate set while validating Shop RTL and cutout layouts.
- PR #91 merged as `7eb16d6cf747d9db23fa15703386cfbbf67d9da8`; Flutter CI #516 passed the full gate set while validating Progress Hub cutout/safe-area behavior and scroll reachability.
- PR #92 merged as `88c17828afa4fd7de52cfe29550a107cb34d1ee3`; Flutter CI #522 passed formatting, whitespace, Analyze, focused tests, full Flutter tests, Debug APK build, and artifact upload while validating Settings RTL layout.
- CI #522 artifact `cargame-debug-apk`: artifact id `9029071810`, 80,509,116 bytes, SHA-256 `c70c51470539b1de3a8594023a6bf149c17958b64826618dc9dbcb45231d1792`.
- Physical-device visual review remains part of RC/device verification and does not reopen the automated UI3D-006 feature acceptance.

## Tracking reconciliation — 2026-08-07

- Repository evidence shows the typed asset model, manifest, registry, runtime asset views, and focused tests already exist under `lib/core/assets` and `test/core/assets`.
- `AST-002` and `AST-003` are IMPLEMENTED; they must not be marked VERIFIED until their remaining release/device acceptance is complete.
- UI3D-006 was the sole active feature during the responsive workstream; it is now VERIFIED by the 2026-08-09 reconciliation above.
- PR #62 merged the first NAV-002 Home/app-shell checkpoint; later NAV-002 mission-flow adoption is recorded in the 2026-08-09 reconciliation above.
- Issue #54 tracks remaining historical catalog reconciliation so status and feature catalog stay consistent with repository evidence.

## Workstation Android toolchain evidence — 2026-08-07

- Flutter stable 3.44.8 and Dart 3.12.2 are available from `C:\flutter`.
- Android SDK 37.0.0, platform android-37.1, build-tools 37.0.0, and Emulator 37.1.11 are installed.
- Flutter is explicitly configured to use Temurin JDK 17.0.20+8.
- All Android SDK licenses are accepted and network resources are available.
- `flutter doctor` reports the Android toolchain healthy.
- No Android hardware/emulator was online during this diagnostic snapshot; Windows, Chrome, and Edge were the three detected targets.
- Visual Studio Enterprise 2022 is installed but lacks the Desktop development with C++ workload/components. This is optional for the Android-first product and does not block APK/AAB development.

## Setup Tool safe-directory repair — 2026-08-07

- `SETUP_TOOL.ps1` upgraded to v2.6.1 after Option 14 failed on a Windows repository whose owner SID differed from the current user SID.
- Git operations now call a centralized `Ensure-GitSafeDirectory` preflight before `git -C <project>` commands.
- The tool adds only the current project path to global `safe.directory`; it does not use wildcard trust.
- If Git still returns `dubious ownership`/`safe.directory`, the command is repaired and retried once.
- Startup diagnostics now reports the Git safe-directory state and attempts automatic repair before reading remotes/branch data.
- First clone also registers the newly cloned project path as safe before normal repository operations.
- Fix commit: `1b56d3ba13ab4e413f7562bd01c77becbecd7df9`.

## Workstation release-build evidence — 2026-08-07

- User workstation completed the full Flutter test suite successfully: 159 tests passed.
- User workstation completed `flutter build apk --release --no-pub` successfully.
- Latest release artifact reported at `build/app/outputs/flutter-apk/app-release.apk` with size 53.4 MB.
- Material icon tree shaking reduced the font asset by 99.2% during release build.
- Flutter Analyze previously completed with only two informational unnecessary-import findings; both redundant imports were removed in follow-up commits.
- Historical note: Flutter previously reported Gradle 8.13.0 as nearing end of support. Current repository validation no longer treats that warning as an active Android blocker.

## MOT-004 implementation evidence — 2026-08-07

- Added `GameRoute` as the single shared route-motion primitive with fade plus shared-axis slide.
- Route direction automatically mirrors for Arabic RTL versus English LTR.
- Reduced Motion removes the lateral slide and uses a bounded fade transition.
- Added `GameNavigator` to centralize route names, replacement, and duplicate-push guards.
- Guard keys are released in `finally`, so returning from a route cannot leave navigation permanently locked.
- Added focused tests for route names/results, replacement, RTL/LTR motion, Reduced Motion, and concurrent duplicate-push rejection.
- World Map city navigation now opens `CityBriefingScreen` through `GameNavigator` using `/briefing/level/<number>` route names and per-level guard keys.
- Added a World Map regression test that verifies the first unlocked city opens through the named shared route without relying on `pumpAndSettle` while ambient motion is active.
- Implementation commits include `c7244ac4b0934c6415d38b2638d4a9646e2cfa31`, `c209b3433b1750e11727b26f6f01254315cfefd9`, `aee4063b78f63064c1f2dba101db277134b6b9c4`, `c279f2648d39e406a11ce2dc1d767adea4152988`, and `94b7ecab2c76616a547699e19fbf13abb11420db`.
- `MOT-004` is IMPLEMENTED rather than VERIFIED because full-route adoption is intentionally tracked separately by `NAV-002`.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Flutter doctor — Android toolchain | PASSED — Flutter 3.44.8, Dart 3.12.2, Android SDK 37.0.0, JDK 17.0.20, all licenses accepted |
| 2026-08-07 | Flutter doctor — Windows desktop | OPTIONAL INCOMPLETE — Visual Studio lacks C++ workload/components; does not block Android release work |
| 2026-08-07 | Full Flutter test suite on workstation | PASSED — 159 tests |
| 2026-08-07 | Workstation Release APK | PASSED — `app-release.apk` built successfully, 53.4 MB |
| 2026-08-07 | Material icon tree shaking | PASSED — 99.2% reduction reported in release build |
| 2026-08-07 | Setup Tool Git ownership recovery | IMPLEMENTED — v2.6.1 adds project-scoped `safe.directory` repair and one retry for dubious ownership |
| 2026-08-07 | MOT-004 shared route primitive and World Map adoption | IMPLEMENTED — CI/device-wide route adoption remains under NAV-002 |
| 2026-08-07 | NAV-002 Home/app-shell checkpoint | PASSED — PR #62 merged after Flutter CI run #433 completed successfully with Debug APK artifact uploaded |
| 2026-08-09 | UI3D-006 GameFitView hardening | PASSED — PR #86 / CI #503, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Gameplay RTL/cutout validation | PASSED — PR #87 / CI #505, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Compact result/back-guard validation | PASSED — PR #88 / CI #507, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Shop RTL/cutout validation | PASSED — PR #90 / CI #511, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Progress Hub cutout validation | PASSED — PR #91 / CI #516, full tests + Debug APK + artifact |
| 2026-08-09 | UI3D-006 Settings RTL validation | PASSED — PR #92 / CI #522, full tests + Debug APK + artifact `9029071810` / SHA-256 `c70c51470539b1de3a8594023a6bf149c17958b64826618dc9dbcb45231d1792` |
| 2026-08-09 | ENG-009 release configuration hardening | PASSED — PR #95 externalized release AdMob/signing inputs and removed debug signing/test-ID fallbacks; subsequent current release-packaging smoke passed |
| 2026-08-09 | SHOP-002 interruption-safe purchases | PASSED — PR #97 / Flutter CI #536 / full tests + Debug APK + artifact |
| 2026-08-09 | Android release APK packaging smoke | PASSED — PR #99 / Release Packaging Smoke #2 / 55.8 MB / SHA-256 `2f6b2b5d3eb7de9a9029b0f51ae2e8a7e69a3c3278feb230abb116e4b56778dd` |
| 2026-08-09 | Android release AAB packaging smoke | PASSED — PR #99 / Release Packaging Smoke #2 / 57.0 MB / SHA-256 `957c1d4b696ee2547e97faa796544b3ab514fa2660681d4f01876af83a48c548` |
| 2026-08-09 | Release smoke credential redaction | PASSED — ephemeral signing passwords masked as `***`; only checksum evidence artifact #9029778593 uploaded |
| 2026-08-09 | Flutter CI after release-smoke workflow | PASSED — CI #539 full suite + Debug APK + artifact on PR #99 head |
| 2026-08-09 | RC tracking reconciliation | PASSED — PR #100 / CI #541 / Debug APK artifact #9029962050 / SHA-256 `3289c9a41ef4cfad4c45e81fb4a40b621e87d902094b4d4b343d134ecab80906` |
| 2026-08-09 | REL-006 signing/key-management verification | PASSED — PR #102 / Flutter CI #544 + Release Packaging Smoke #4 / debug artifact #9030167112 / release evidence #9030181913 |
| 2026-08-09 | TEST-001 progress/economy + legacy-save compatibility | PASSED — PR #104 / Flutter CI #546 / full suite + Debug APK artifact #9030311765 / SHA-256 `cdef9c5c5fbc9576d1760009956aab53ab6e63491248a2ba43ea5288797855b7` |
| 2026-08-09 | REL-001 dynamic Android targets | PASSED — Flutter CI #546 validated 38 PowerShell/batch scripts with no fixed emulator/AVD/adb target |
| 2026-08-09 | LEVEL-003 level solvability validator current-main reconciliation | PASSED — Flutter CI #659 / run `31301158763` / full 240-test suite including all-150-level validator coverage / debug artifact #9034604961 / SHA-256 `79d61a1977614296dd06a38a850e7960a730c6d632890801e77d99d5983ac6b6` |
| 2026-08-09 | AST-011 asset licensing/provenance current-main reconciliation | PASSED — current CI #657 / run `31300595956` asset gate reports 9 manifest descriptors / 0 provenance records / 0 runtime WebPs; historical implementation CI #121 / run `31185774162` passed with artifact #8996933307 / SHA-256 `9048ad078046154a0db92dd4d6ed918154e91b15c35c3b60feac2b9b1257d213` |
| 2026-08-09 | SEC-001 mobile security baseline current-main reconciliation | PASSED — PR #128 / Flutter CI #655 / run `31300172519` / debug artifact #9034317021 / SHA-256 `67938778535d63de844f455b324796a4488b1a33efe20ea004fe9894d9db135d` |
| 2026-08-09 | PRIV-001 privacy inventory current-main reconciliation | PASSED — PR #126 / Flutter CI #651 / run `31299285194` / debug artifact #9034063433 / SHA-256 `6fc839b195551ffcdbb0bd30b69bb9f29124aa5b9f5277ab8aa981d3508f4f9c` |
| 2026-08-09 | ECON-005 versioned economy configuration | PASSED — PR #124 / Flutter CI #647 / run `31296918681` / debug artifact #9033326885 / SHA-256 `bbca79f780b9effc07a93ecc8a5a0b0dd73b523e6706531fe292127165d2872a` |
| 2026-08-09 | PRIV-002 privacy policy / Play Data Safety contract | PASSED — PR #170 / Flutter CI #746 / run `31335858470` / 12 disclosure regressions + full Flutter suite + Debug APK artifact #9044388801 / SHA-256 `03e81188e97a1b9ab867d18c48894603f7586bd5d0963014516de35e8b8e868a`; source state IMPLEMENTED, external publication/store evidence pending |
| 2026-08-10 | PRIV-003 local data export/deletion readiness | PASSED — PR #172 / Flutter CI #768 / run `31338337454` / 15 disclosure regressions + focused controller/Settings tests + full Flutter suite + Debug APK artifact #9045113026 / SHA-256 `6c101a90e89053b48836dd48be72b76ceb9290401ae3643310ad46730b653ddf`; repository-owned state VERIFIED |
| 2026-08-10 | ENG-011 canonical developer workflows | PASSED — PR #174 / Flutter CI #773 / run `31339612397` / 16-entry-point workflow validator + 10 regressions + full Flutter suite + Debug APK artifact #9045499219 / SHA-256 `2baf734f6a3362837f140cbbd25863c7ea189b15de3ea81d75d5b7dde43e7d5b`; repository-owned state VERIFIED |

## Test locally

```powershell
cd "D:\Apps\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
dart format lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
.\VERIFY_RELEASE_INPUTS.ps1 -AndroidAdMobAppId '<production-app-id>'
# Production release builds require real external AdMob/signing inputs.
.\BUILD_RC.ps1 -AndroidAdMobAppId '<production-app-id>'
.\BUILD_RC.ps1 -BuildAppBundle -AndroidAdMobAppId '<production-app-id>'
flutter run
```

## Fullscreen home + banner checkpoint — 2026-08-07

- Android/iOS app shell requests immersive-sticky fullscreen at startup while retaining portrait orientation policy.
- Home no longer uses a ListView/scroll container; content scales down as one bounded composition and compact resource/hero cards reclaim vertical space.
- Google Mobile Ads banner footer is isolated from offline core play, uses official debug test IDs, and occupies no footer space until an ad actually loads.
- Full checkpoint verification passed in GitHub Actions: Dart format, Flutter Analyze with no issues, full Flutter tests, and Debug APK build.
- Added regression coverage for 360x640 and 412x915 home layouts with no ListView/SingleChildScrollView and no captured Flutter layout exception.
- Release ad unit injection/consent remain separate ADS-002/ADS-007 work and are not claimed complete.

## UI3D-006 fit shell checkpoint — 2026-08-07

- Added reusable `GameFitView` for bounded game screens that must remain fully visible without a scroll container.
- Home uses the shared fit primitive instead of a screen-local FittedBox implementation.
- Mission Briefing uses the shared fit primitive with tighter vertical rhythm while preserving boosters, wallet, RTL/LTR, SafeArea, and guarded mission launch.
- The automated responsive matrix is now VERIFIED; physical-device visual review is carried by the broader RC/device validation gates.
