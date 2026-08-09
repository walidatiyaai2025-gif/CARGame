# CARGame Developer Workflows

This is the canonical developer workflow for the CARGame repository. It is written for the current Android-first Flutter project and the tooling that is already tracked in this repository.

## Golden path

### Existing checkout

From Windows, start with:

```powershell
.\START_CARGAME_TOOL.bat
```

The launcher resolves the repository and opens the project tooling through `START_CARGAME_TOOL.ps1` / `SETUP_TOOL.ps1`. Use the menu for routine environment checks, source update, Android execution, build, and maintenance operations.

### First machine / first run

For a new Windows workstation or a newly cloned checkout:

```powershell
.\FIRST_TIME_SETUP_AND_RUN.ps1
```

The script validates the current Flutter/JDK/Android prerequisites, restores packages, performs the repository's supported setup/repair steps, and prepares an Android run without rewriting the checked-in platform projects.

Do not regenerate Flutter/Android/iOS scaffolding over this checkout. The platform projects are source-controlled and contain release, privacy, signing, and CI contracts that must be preserved.

## Day-to-day development

1. Update the checkout through the project tooling or normal Git workflow.
2. Restore the locked package graph:

```powershell
flutter pub get --enforce-lockfile
```

3. Generate localization after ARB changes:

```powershell
flutter gen-l10n
```

4. Run the app using the tool menu or the dynamic Android runner:

```powershell
.\RUN_ON_EMULATOR.ps1
```

Android target selection must remain dynamic. Do not embed a workstation-specific emulator/device serial in documentation, scripts, tests, or source.

## CI-parity verification

Before opening or updating a pull request, use the same verification intent as `.github/workflows/flutter_ci.yml`:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug --no-pub
```

Repository policy gates also run in GitHub Actions, including privacy, security, dependency, catalog/dashboard, asset-provenance, developer-workflow, formatting, and packaged-artifact checks. GitHub Actions remains the authoritative full merge gate.

For Python policy tools on a Windows workstation, use the available Python 3 launcher/runtime. The CI canonical form is `python3 tool/<tool>.py`.

## Android build repair

Use the narrowest supported repair path first. Do not delete arbitrary Gradle/Android files or regenerate the project.

### General Android build/cache failure

```powershell
.\REPAIR_ANDROID_BUILD.ps1
```

### Kotlin incremental/cache failure

```powershell
.\REPAIR_KOTLIN_CACHE_AND_BUILD.ps1
```

After a repair, rerun Analyze/tests and the applicable Android build rather than assuming the repair produced a valid candidate.

## Development dashboard

Open the repository status/dashboard through:

```powershell
.\OPEN_DEVELOPMENT_DASHBOARD.ps1
```

`docs/FEATURE_CATALOG.md` is the detailed work source of truth and `docs/STATUS.md` is the live operational summary. The dashboard derives project state from repository evidence; do not maintain a second manual status copy.

## Release preflight and packaging

Production release values are external inputs. Never commit production signing material, `key.properties`, keystores, reusable credentials, or production AdMob values into tracked source files.

First validate the release inputs:

```powershell
.\VERIFY_RELEASE_INPUTS.ps1 -AndroidAdMobAppId '<production-app-id>'
```

Build the release APK through the guarded RC path:

```powershell
.\BUILD_RC.ps1 -AndroidAdMobAppId '<production-app-id>'
```

Build the App Bundle through the same guarded path:

```powershell
.\BUILD_RC.ps1 -BuildAppBundle -AndroidAdMobAppId '<production-app-id>'
```

Signing values/keystore location and production advertising IDs must be supplied through the documented external environment/production handoff path. See `docs/ANDROID_SIGNING.md`, `docs/BUILD_CONFIGURATION.md`, and `docs/SECRET_HANDLING.md`.

Google UMP consent/privacy integration already exists in the app under ADS-007. Release work must configure and verify the production Google privacy message/AdMob setup; it must not add a second manual consent implementation.

## Privacy and data controls

The app's current privacy contract is documented in:

- `docs/PRIVACY_DATA_INVENTORY.md`
- `docs/PRIVACY_POLICY.md`
- `docs/privacy/data_inventory.json`
- `docs/privacy/play_data_safety.json`

Settings > Privacy contains Google privacy choices when required plus first-party local JSON export and confirmed local deletion/reset. Any new network SDK, first-party analytics, account/backend, cloud save, remote diagnostics, or persisted key family requires the corresponding privacy inventory/disclosure update before merge.

## Troubleshooting matrix

| Symptom | Supported first action | Follow-up |
|---|---|---|
| Flutter/JDK/Android setup uncertain | `FIRST_TIME_SETUP_AND_RUN.ps1` | Use `SETUP_TOOL.ps1` diagnostics if a prerequisite remains unhealthy. |
| No Android device/emulator selected | `RUN_ON_EMULATOR.ps1` | Let the tooling discover/select a current target; do not hard-code a serial. |
| General Gradle/Android cache/build failure | `REPAIR_ANDROID_BUILD.ps1` | Rerun Analyze/tests and Debug APK. |
| Kotlin incremental/cache error | `REPAIR_KOTLIN_CACHE_AND_BUILD.ps1` | Rerun the failed Android build. |
| Need project state / next task | `OPEN_DEVELOPMENT_DASHBOARD.ps1` | Read `docs/STATUS.md` and `docs/FEATURE_CATALOG.md`. |
| Release signing/AdMob preflight fails | `VERIFY_RELEASE_INPUTS.ps1` | Follow `docs/ANDROID_SIGNING.md` / `docs/BUILD_CONFIGURATION.md`; keep values external. |
| Release APK/AAB needed | `BUILD_RC.ps1` | Use `-BuildAppBundle` for AAB; do not bypass preflight. |
| Privacy/Data Safety drift gate fails | Read the validator error plus privacy docs | Update source-of-truth inventory/disclosure together with the behavior change. |
| Dependency/security gate fails | Read the exact CI policy output | Follow `docs/DEPENDENCY_GOVERNANCE.md`, `docs/SECRET_HANDLING.md`, or `docs/SECURITY_SCANNING.md`. |

## Rules that protect the repository

- Preserve the checked-in platform projects; do not overwrite them with generated scaffolding.
- Keep production AdMob IDs, signing passwords, keystores, and credentials outside source control.
- Use the existing UMP/consent architecture instead of introducing a duplicate privacy state or consent UI.
- Keep Android target discovery dynamic.
- Do not bypass `VERIFY_RELEASE_INPUTS.ps1` / `BUILD_RC.ps1` for a production candidate.
- Do not mark work VERIFIED until its relevant automated and external acceptance criteria are actually satisfied.
