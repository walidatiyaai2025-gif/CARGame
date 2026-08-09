# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | Android RC hardening — issue #79 |
| Primary feature | `ENG-006` Dependency and package governance — Issue #157 / branch `agent/eng-006-dependency-governance`. |
| Completed checkpoint | `ENG-005` enforceable clean-architecture boundary checkpoint — PR #155 merged as `07fb50182efe5ce315cdda8bf823ba4da855c2df` after green Flutter CI #726. |
| Status | ENG-006 audit and implementation are active. Direct hosted package sources, lockfile alignment, reviewed license families, and upgrade drift are now enforced/reported by code; no production dependency version change is planned for this checkpoint. |
| Previous checkpoint | `UI3D-009` premium Mission Result Debrief and tracking reconciliation — PRs #152/#153. |
| Next recommended feature | Complete `ENG-006` governance verification and full CI/APK before selecting the next dependency-ready catalog item. |
| Known blocker | `REL-007`/`REL-008` require real production AdMob/signing inputs and a production-signed candidate; final install/upgrade/device smoke requires an Android device or testing track. `TEST-009` also remains dependency-blocked while `PERF-001` is PLANNED. Visual Studio C++ components remain optional for Windows desktop only. |

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
- Current runtime gaps are recorded rather than overstated: `AdService` request/load/show calls honor `ENABLE_ADS=false` but bootstrap still initializes `MobileAds`; `ENABLE_DIAGNOSTICS` exists but does not suppress local logger installation; complete in-app reset/export/delete remains pending. Owners remain ADS-007, ENG-013, and PRIV-003 respectively, while PRIV-002 owns policy/store mapping.
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
