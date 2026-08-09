# Android Signing and Key-Management Procedure

This procedure is the operational source for CARGame Android production signing. It covers the **upload key used to sign release artifacts before Play Console upload** and the release configuration required by `BUILD_RC.ps1`.

It does not contain production credentials. Never commit a keystore, password, production AdMob identifier, or secret-bearing `android/key.properties` file.

## 1. Supported signing inputs

The Gradle release configuration and `VERIFY_RELEASE_INPUTS.ps1` use the same precedence for each signing field:

1. non-empty environment variable;
2. otherwise the matching value from ignored `android/key.properties`.

| Purpose | Environment variable | `android/key.properties` key |
|---|---|---|
| Keystore path | `ANDROID_KEYSTORE_PATH` | `storeFile` |
| Keystore password | `ANDROID_KEYSTORE_PASSWORD` | `storePassword` |
| Upload-key alias | `ANDROID_KEY_ALIAS` | `keyAlias` |
| Upload-key password | `ANDROID_KEY_PASSWORD` | `keyPassword` |

Use one method consistently where possible. Mixed configuration is supported because environment variables override individual file values, but it is harder to audit and should be limited to controlled migration/recovery scenarios.

### Keystore path rule

Use an **absolute path** for production signing. Gradle resolves a relative `storeFile` from the `android/app` module, which is easy to misunderstand across Windows, Linux, local workstations, and CI runners. The preflight intentionally matches Gradle's resolution behavior, but absolute paths are the operational standard.

## 2. Production AdMob inputs

Every Android RC build requires the production Android AdMob application ID:

- `AndroidAdMobAppId` parameter to `BUILD_RC.ps1`;
- passed internally to Gradle as `ADMOB_ANDROID_APP_ID`.

When runtime ads are enabled with `-EnableAds`, the builder also requires:

- `AndroidBannerId`;
- `AndroidRewardedId`;
- `AndroidInterstitialId`.

The preflight rejects Google's official test application/ad-unit IDs and rejects malformed IDs. It reports only whether values are configured; it never prints the supplied production IDs.

## 3. Create the upload keystore

Generate the upload key on a trusted administration workstation. Use a current JDK `keytool` and strong, unique secrets stored in the approved password manager.

Example command template:

```powershell
keytool -genkeypair `
  -v `
  -keystore "C:\Secure\CARGame\cargame-upload.jks" `
  -alias "cargame-upload" `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

`keytool` should prompt interactively for passwords. Do not put real passwords on a command line, in PowerShell history, source files, tickets, chat, email, CI logs, or screenshots.

Record the following metadata separately from the secret values:

- application/package: `com.walka.cargosort`;
- key purpose: Android Play upload key;
- alias name;
- creation date;
- owner/custodian;
- backup locations;
- Play Console registration date/status;
- approved users/automation identities.

## 4. Local workstation configuration

Preferred local file method:

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Set `storeFile` to the absolute keystore path.
3. Fill the password and alias values locally.
4. Confirm `android/key.properties` remains ignored by Git.
5. Run the safe preflight before any RC build.

```powershell
.\VERIFY_RELEASE_INPUTS.ps1 `
  -AndroidAdMobAppId '<production-admob-app-id>'
```

For an ads-enabled build:

```powershell
.\VERIFY_RELEASE_INPUTS.ps1 `
  -AndroidAdMobAppId '<production-admob-app-id>' `
  -EnableAds `
  -AndroidBannerId '<production-banner-id>' `
  -AndroidRewardedId '<production-rewarded-id>' `
  -AndroidInterstitialId '<production-interstitial-id>'
```

A successful preflight reports only configuration state, signing source, keystore presence, and whether ads are enabled. Secret values and production IDs are redacted by design.

## 5. CI / controlled automation configuration

Do not commit `key.properties` or a keystore for production CI.

Provision the keystore through the CI platform's protected secret/file mechanism, then expose an ephemeral local file path as `ANDROID_KEYSTORE_PATH`. Configure the other three signing values as protected secrets. Restrict production signing jobs to the protected release environment/branch and authorized release operators.

Before invoking Flutter/Gradle, run:

```powershell
.\VERIFY_RELEASE_INPUTS.ps1 -AndroidAdMobAppId '<injected-production-app-id>'
```

The repository's `Android Release Packaging Smoke` workflow is intentionally separate. It generates a one-day ephemeral test keystore and uses a synthetic compile-only AdMob application ID with runtime ads disabled. Those binaries are **non-distributable** and never replace the production signing flow.

## 6. Production release handoff checklist

The release owner must have all of the following before starting `REL-007` / `REL-008` candidate generation:

- exact source commit/tag to release;
- approved version name and version code;
- production Android AdMob application ID;
- production Banner/Rewarded/Interstitial IDs when ads are enabled;
- upload keystore from the approved secure location;
- keystore password in the approved secret store;
- upload-key alias;
- upload-key password in the approved secret store;
- successful `VERIFY_RELEASE_INPUTS.ps1` result;
- green Flutter CI on the candidate source;
- release notes / test scope;
- target Android device/API matrix for install/update smoke.

Build APK:

```powershell
.\BUILD_RC.ps1 -AndroidAdMobAppId '<production-admob-app-id>'
```

Build AAB:

```powershell
.\BUILD_RC.ps1 -BuildAppBundle -AndroidAdMobAppId '<production-admob-app-id>'
```

Add `-EnableAds` and the three production unit IDs only when the candidate is meant to exercise production ad configuration.

## 7. Ownership and access control

- Assign one primary release-key custodian and at least one authorized backup custodian.
- Grant access only to people/automation identities that must sign releases.
- Store passwords in the approved password manager/secret vault, not beside the keystore.
- Do not share signing material through email, chat, issue attachments, shared plaintext drives, or repository secrets visible to untrusted pull requests.
- Review authorized access after staffing/role changes and before major releases.
- Record access/rotation events in the organization's release/security audit system, not in this repository if they contain sensitive details.

## 8. Backup and recovery

Maintain at least two encrypted backup copies of the upload keystore in separate controlled locations. A backup is not considered valid until an authorized custodian has verified that it can be restored and inspected with the expected alias without exposing passwords in logs.

Recommended separation:

- primary encrypted secrets/keys vault;
- secondary encrypted disaster-recovery vault or offline protected copy.

Never rely on a developer laptop as the only copy.

If the local upload key is lost or suspected compromised:

1. stop production signing with the affected key;
2. notify the release/security owner;
3. verify whether a protected backup can be restored safely;
4. if not recoverable or if compromise is suspected, follow the Play Console upload-key reset/replacement process for the application;
5. generate/register the replacement upload key through the approved process;
6. revoke/delete obsolete local copies where appropriate;
7. update the secret vault, access inventory, CI configuration, and release evidence;
8. run preflight and a controlled candidate validation before resuming releases.

The Play app-signing key and the local upload key are different responsibilities when Play App Signing is used. Do not treat loss of the upload key as permission to create an untracked replacement and continue publishing without Play Console registration.

## 9. Planned rotation / replacement

Rotate or replace the upload key only with an approved release/security change. Before rotation:

- create and back up the replacement securely;
- record non-secret metadata and ownership;
- register/approve it through the applicable Play Console process;
- update CI/local secure configuration;
- verify preflight and signing on a controlled candidate;
- retain or destroy the old key according to the approved retention policy and incident requirements.

Never overwrite the only known-good keystore during rotation.

## 10. Verification commands

Contract test for the safe preflight:

```powershell
pwsh -NoProfile -File .\tool\test_release_input_preflight.ps1
```

Safe release-input check:

```powershell
.\VERIFY_RELEASE_INPUTS.ps1 -AndroidAdMobAppId '<production-admob-app-id>'
```

The preflight validates configuration only; it does not prove that a production candidate installs, upgrades, launches, or is accepted by Play. Those requirements remain under `REL-007`, `REL-008`, `TEST-009`, and `TEST-012`.
