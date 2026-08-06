# CARGame Live Project Status

This document is the short operational dashboard. Detailed tracking lives in `docs/FEATURE_CATALOG.md`; counts and percentages are calculated dynamically by the Developer Portal.

## Project objective

Build a production-quality Flutter cargo sorting game with 150 levels, 6 worlds, unified premium 3D visuals, responsive living motion, offline-first progress, Arabic/English support, measurable quality, privacy/security/legal readiness, and Android store release operations.

## Current work

| Field | Value |
|---|---|
| Current phase | A — Engineering foundation |
| Active primary feature | `ENG-002` Stable Android build toolchain |
| Coupled feature | `REL-001` Dynamic ADB/device scripts |
| Status | IMPLEMENTED checkpoint; Windows verification pending |
| Branch | main |
| Blocker | The GitHub execution environment cannot run Windows PowerShell, Android SDK, JDK, Gradle, Flutter builds, or an emulator. |
| Completed checkpoint | Central JDK 17/SDK/Gradle initialization, Kotlin cache recovery, reproducible build entry points, and static toolchain self-test. |
| Next checkpoint | Run the documented environment self-test plus Debug APK, Release APK, and AAB builds on Windows. |

## ENG-002 implementation evidence — 2026-08-07

- `BUILD_COMMON.ps1` dynamically resolves the Android SDK from environment variables or the standard Android Studio location.
- JDK discovery validates a complete JDK 17 using both `java.exe` and `javac.exe`.
- Java selection checks `JAVA_HOME`, `JDK_HOME`, PATH, Flutter configuration, and common vendor roots without committing a local machine path.
- `JAVA_HOME`, `JDK_HOME`, `ANDROID_HOME`, and `ANDROID_SDK_ROOT` are applied to the current process.
- `org.gradle.java.home` is normalized and written before Gradle execution.
- Gradle caching, parallel execution, Kotlin incremental compilation, Kotlin daemon, and Kotlin caches remain disabled for the recurring Windows cache-lock defect.
- Debug APK, Release APK, and Release AAB use one build/retry implementation.
- A failed build triggers one deep Kotlin/Gradle cleanup and one deterministic retry.
- `TEST_BUILD_TOOLCHAIN.ps1` checks PowerShell syntax and rejects fixed emulator IDs, fixed AVD/model names, local JDK paths, and PowerShell ISE usage.
- Optional `-EnvironmentCheck` validates JDK 17, Android SDK, ADB, and the Gradle wrapper on the developer machine.

## Reproducible commands

Static repository audit:

```powershell
cd "D:\Apps\CARGame"
.\TEST_BUILD_TOOLCHAIN.ps1
```

Local toolchain audit:

```powershell
.\TEST_BUILD_TOOLCHAIN.ps1 -EnvironmentCheck
```

Build verification through the unified menu:

```powershell
.\COLD_BOOT_AND_RUN.ps1
# 2 = Debug APK
# 3 = Release APK
# 4 = Release AAB
```

Direct release verification:

```powershell
.\BUILD_RELEASE_V2.ps1
```

## Phase overview

| Phase | Current evidence state |
|---|---|
| A Engineering foundation | ENG-002 implementation checkpoint completed; external Windows verification remains. |
| B Shared 3D design system | Partial; no changes in this infrastructure checkpoint. |
| C Motion and living interface | Planned; no changes in this infrastructure checkpoint. |
| D 3D asset pipeline | Planned; no changes in this infrastructure checkpoint. |
| E–S | No functional or status promotion performed by this checkpoint. |

## Verification ledger

| Date | Scope | Verification | Result | Commit |
|---|---|---|---|---|
| 2026-08-07 | ENG-002 static implementation review | Central JDK/SDK initialization, Gradle property pinning, Kotlin repair integration, deterministic retry, and self-test script added. | IMPLEMENTED | Current checkpoint |
| 2026-08-07 | ENG-002 Windows parser/environment/build checks | `TEST_BUILD_TOOLCHAIN.ps1 -EnvironmentCheck`, Debug APK, Release APK, and AAB require Windows tooling. | BLOCKED by execution environment | - |
| 2026-08-07 | Dashboard compatibility | Catalog table schema and statuses were not changed; existing parser contract remains intact. | PASSED — static compatibility | Current checkpoint |

## Known high-priority risks

1. `ENG-002` must not be promoted to `VERIFIED` until the documented Windows commands pass.
2. Emulator/ADB instability can still end a debug attachment even when the application process remains alive.
3. Kotlin cache behavior requires multi-machine verification.
4. Existing implemented game features still need systematic regression evidence.
5. Current 3D presentation remains primarily procedural and was not touched in this toolchain checkpoint.

## Next ready work

1. Execute the ENG-002 verification commands on Windows and record exact outputs.
2. Converge `REL-001` to a clean evidence-based status after the repository-wide forbidden-pattern audit passes.
3. Complete `ENG-001` baseline audit and capture format/analyze/test/debug-build results.
4. Implement `MOT-001` shared motion tokens and lifecycle-safe primitives.
5. Implement `AST-001` taxonomy and provenance rules.

## Last update

- Hardened the Android build toolchain without changing game UI, motion, RTL/LTR, responsive layouts, offline behavior, persistence, or gameplay.
- Added a self-test for script syntax and forbidden hard-coded environment/device values.
- Kept ENG-002 below `VERIFIED` because Windows execution evidence is not available in this environment.
