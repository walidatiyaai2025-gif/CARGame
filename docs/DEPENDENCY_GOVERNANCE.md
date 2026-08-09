# Dependency and Package Governance

ENG-006 defines the package policy for the CARGame Flutter application. The goal is deterministic application builds, explicit license review, and controlled upgrades without silently changing production dependencies.

## Dependency source policy

- Flutter SDK packages are allowed through `sdk: flutter` only.
- Hosted direct dependencies must use the default `https://pub.dev` source.
- Direct `git`, `path`, custom-hosted, and unknown map-style dependencies are rejected until a dedicated review changes the policy and adds evidence.
- `dependency_overrides` are prohibited in the production manifest because they bypass the reviewed dependency graph.

## Version and lockfile policy

- Direct hosted packages use either a caret semantic-version constraint such as `^2.5.3` or an exact semantic version.
- `pubspec.lock` is authoritative and committed because CARGame is an application, not a reusable package.
- The governance verifier requires every direct hosted package to appear in the lockfile with the correct `direct main` or `direct dev` classification, a `hosted` source, the approved pub.dev URL, and a resolved version allowed by the manifest constraint.
- The committed lockfile is never regenerated as a side effect of dependency review. Any lockfile change is an intentional code-review change.

## License policy

The reviewed direct hosted dependency inventory is stored in `tool/dependency_license_policy.json`. CI validates the installed package that corresponds to the committed lockfile after `flutter pub get`.

Allowed direct-package license families at this checkpoint:

- MIT
- BSD-3-Clause
- Apache-2.0

An upgrade that changes the resolved direct-package version must also update the reviewed inventory. CI then re-reads the installed package license and fails when the license is missing, unrecognized, outside the allowlist, or different from the reviewed family.

### Reviewed direct dependency inventory — 2026-08-09

| Package | Kind | Manifest constraint | Locked/reviewed version | License |
|---|---|---|---:|---|
| `flame` | runtime | `^1.38.0` | `1.38.0` | MIT |
| `google_mobile_ads` | runtime | `^9.0.0` | `9.0.0` | Apache-2.0 |
| `shared_preferences` | runtime | `^2.5.3` | `2.5.5` | BSD-3-Clause |
| `path_provider` | runtime | `^2.1.5` | `2.1.6` | BSD-3-Clause |
| `cupertino_icons` | runtime | `^1.0.8` | `1.0.9` | MIT |
| `flutter_lints` | development | `^6.0.0` | `6.0.0` | BSD-3-Clause |
| `shared_preferences_platform_interface` | development | `^2.4.1` | `2.4.2` | BSD-3-Clause |

Flutter SDK dependencies are governed by the pinned Flutter toolchain in CI and are not duplicated in the hosted-package license inventory.

## Upgrade workflow

1. Start from a green `main` and create one dependency-focused branch.
2. Run `flutter pub outdated --json` and classify direct versus transitive drift. Outdated information is review evidence; it does not authorize an automatic upgrade.
3. For each proposed direct upgrade, read changelog/release notes, platform requirements, breaking changes, security notices, and the installed license.
4. Change `pubspec.yaml` only when the accepted compatibility range needs to change.
5. Run `flutter pub get` intentionally and review the complete `pubspec.lock` diff, including transitive changes.
6. Update `tool/dependency_license_policy.json` for every changed direct resolved version after license review.
7. Run `python3 tool/dependency_governance.py verify` and `python3 tool/test_dependency_governance.py`.
8. Run Analyze, the full Flutter suite, Android build gates, and normal CI before merge.
9. Do not combine unrelated UI/gameplay/economy changes with a dependency-upgrade PR.

## Drift policy

Normal CI reports `flutter pub outdated --json` as a non-blocking informational step. Blocking CI remains based on the committed manifest/lockfile/license contract so upstream package publication cannot make an otherwise unchanged commit fail merely because a newer package exists.

The ENG-006 baseline audit on 2026-08-09 found seven newer versions outside the current dependency constraints, all of them transitive (`hooks`, `intl`, `matcher`, `meta`, `record_use`, `test_api`, and `vector_math`). No direct hosted dependency required a version change for this checkpoint.

## CI commands

```text
flutter pub get
python3 tool/dependency_governance.py verify
python3 tool/test_dependency_governance.py
flutter pub outdated --json
```

The first two Python commands are blocking governance gates. The outdated report is intentionally non-blocking.