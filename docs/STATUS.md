# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | Android RC hardening — issue #79 |
| Primary feature | `ECON-005` IN PROGRESS — issue #122 on `agent/econ-005-versioned-economy-config`. |
| Completed checkpoint | `GAME-016` input determinism — PR #111 merged as `093d9a9384aec2d18503284a8edc95ba1ce1ecfb` after Flutter CI #580 passed formatting, Analyze, all 215 Flutter tests, Debug APK build, and artifact upload. |
| Status | `ECON-005` audit confirms release-critical economy values are scattered across gameplay, progress/rewards, and shop presentation. v1 will centralize/version/validate the existing numbers without rebalancing player outcomes. |
| Previous checkpoint | `TEST-004` navigation-race verification — PR #109 merged as `24aa922453f88af507e01e950f7d26048e1c6c3f`; its final current-head verification completed on Flutter CI #574. |
| Next recommended feature | Complete `ECON-005` typed v1 configuration, parity/migration regressions, and full Android CI verification before selecting another RC P0. |
| Known blocker | `REL-007`/`REL-008` require real production AdMob/signing inputs and a production-signed candidate; final install/upgrade/device smoke requires an Android device or testing track. `TEST-009` also remains dependency-blocked while `PERF-001` is PLANNED. Visual Studio C++ components remain optional for Windows desktop only. |

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
