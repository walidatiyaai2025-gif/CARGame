# CARGame — Cargo Sort

Android-first, offline-first Flutter cargo-sorting game with 150 deterministic levels across six worlds, Arabic/English localization, persistent progression/economy, guarded rewards and purchases, consent-gated advertising, local privacy controls, and repository-enforced release/security gates.

## Supported development environment

The CI baseline is the reproducibility reference:

- Flutter 3.44.8
- Dart 3.12.2
- JDK 17
- Android SDK/tooling compatible with the tracked project configuration
- Windows PowerShell for the repository's supported workstation tooling

## Quick start

For an existing Windows checkout:

```powershell
.\START_CARGAME_TOOL.bat
```

For first-machine / first-run setup:

```powershell
.\FIRST_TIME_SETUP_AND_RUN.ps1
```

The Android and iOS platform projects are already tracked. Preserve them; do not regenerate or overwrite project scaffolding on top of this checkout.

The full supported setup, run, repair, dashboard, verification, privacy, and release workflow is documented in [`docs/DEVELOPER_WORKFLOWS.md`](docs/DEVELOPER_WORKFLOWS.md).

## Daily Android development

Use the project tool menu or the dynamic Android runner:

```powershell
.\RUN_ON_EMULATOR.ps1
```

Android device/emulator selection must remain dynamic rather than workstation-specific.

For a manual verification pass before a PR:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug --no-pub
```

GitHub Actions is the authoritative merge gate and also runs privacy, security, dependency, dashboard/catalog, asset-provenance, developer-workflow, formatting, and packaged-artifact checks.

## Build repair

For a general Android/Gradle build problem:

```powershell
.\REPAIR_ANDROID_BUILD.ps1
```

For Kotlin incremental/cache failures:

```powershell
.\REPAIR_KOTLIN_CACHE_AND_BUILD.ps1
```

After repair, rerun Analyze/tests and the applicable Android build.

## Development dashboard

```powershell
.\OPEN_DEVELOPMENT_DASHBOARD.ps1
```

`docs/FEATURE_CATALOG.md` is the detailed work source of truth and `docs/STATUS.md` is the live operational summary.

## Production release

Production advertising and signing values are external inputs. Keep production AdMob values, signing passwords, keystores, `key.properties`, and reusable credentials outside source control.

Run the guarded release preflight:

```powershell
.\VERIFY_RELEASE_INPUTS.ps1 -AndroidAdMobAppId '<production-app-id>'
```

Build the release APK through the RC wrapper:

```powershell
.\BUILD_RC.ps1 -AndroidAdMobAppId '<production-app-id>'
```

Build the AAB through the same guarded path:

```powershell
.\BUILD_RC.ps1 -BuildAppBundle -AndroidAdMobAppId '<production-app-id>'
```

See [`docs/ANDROID_SIGNING.md`](docs/ANDROID_SIGNING.md), [`docs/BUILD_CONFIGURATION.md`](docs/BUILD_CONFIGURATION.md), and [`docs/SECRET_HANDLING.md`](docs/SECRET_HANDLING.md) for production handoff rules.

Google UMP consent/privacy integration is already implemented under ADS-007. Production release work must configure and verify the real Google privacy message and AdMob settings; it must not introduce a duplicate consent state or second consent flow.

## Current engineering state

- 150 deterministic levels across six worlds, with solvability and quantitative difficulty validation
- Offline SharedPreferences progression, economy, settings, transaction/reward journals, and corruption recovery
- Interruption-safe shop/reward transaction reconciliation and versioned economy configuration
- Premium Home, World Map, Mission Briefing, gameplay operations deck, results/debrief, Shop, Progress Hub, and Settings surfaces
- Arabic RTL and English LTR support
- Shared button, route, ambient, cargo-travel, feedback, and lifecycle-aware motion systems
- Google UMP-gated Mobile Ads initialization/request paths with fail-closed ad behavior
- Settings privacy controls for local JSON export and confirmed first-party local data deletion/reset
- Redacted local diagnostics with no remote crash-reporting upload in the current product
- CI gates for secrets, privacy/Data Safety, dependency governance/advisories, asset provenance, catalog/dashboard integrity, Flutter analysis/tests, Debug APK, and packaged-artifact security

## Privacy and security

Current privacy truth is maintained in:

- [`docs/PRIVACY_DATA_INVENTORY.md`](docs/PRIVACY_DATA_INVENTORY.md)
- [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md)
- `docs/privacy/data_inventory.json`
- `docs/privacy/play_data_safety.json`

Any new network SDK, analytics, remote diagnostics, account/backend, cloud save, or persisted data family requires the corresponding privacy/security inventory update before merge.

## Project references

- Developer workflow: [`docs/DEVELOPER_WORKFLOWS.md`](docs/DEVELOPER_WORKFLOWS.md)
- Live status: [`docs/STATUS.md`](docs/STATUS.md)
- Feature catalog: [`docs/FEATURE_CATALOG.md`](docs/FEATURE_CATALOG.md)
- Implementation plan: [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md)
- Baseline/architecture audit: [`docs/BASELINE_AUDIT.md`](docs/BASELINE_AUDIT.md)
- 3D asset contract: [`docs/ASSET_CATALOG.md`](docs/ASSET_CATALOG.md)
- Signing: [`docs/ANDROID_SIGNING.md`](docs/ANDROID_SIGNING.md)
- Dependency governance: [`docs/DEPENDENCY_GOVERNANCE.md`](docs/DEPENDENCY_GOVERNANCE.md)
- Security scanning: [`docs/SECURITY_SCANNING.md`](docs/SECURITY_SCANNING.md)
