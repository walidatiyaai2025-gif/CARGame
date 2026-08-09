# Build Configuration

CARGame uses compile-time Dart defines for environment-specific behavior. No machine-local absolute paths or production credentials belong in source control.

## Environments

`APP_ENV` accepts exactly:

- `debug` — default; diagnostics enabled by default and official Google test ad unit IDs are allowed.
- `staging` — pre-release verification; explicit selection required and Google test ad IDs remain allowed.
- `release` — production mode; Google test ad IDs are rejected when ads are enabled.

Unknown values fail fast during app configuration.

## Supported defines

| Define | Default | Purpose |
|---|---|---|
| `APP_ENV` | `debug` | Selects debug, staging, or release behavior. |
| `ENABLE_DIAGNOSTICS` | `true` | Enables developer-facing diagnostics policy. |
| `ENABLE_ADS` | `true` | Enables ad loading and presentation. |
| `ENABLE_ANALYTICS` | `false` | Build-time analytics eligibility gate. This flag alone never permits collection; an explicit first-party runtime privacy gate and outward emitter are also required. |
| `ADMOB_ANDROID_BANNER_ID` | Google test ID | Android banner unit. |
| `ADMOB_IOS_BANNER_ID` | Google test ID | iOS banner unit. |
| `ADMOB_ANDROID_REWARDED_ID` | Google test ID | Android rewarded unit. |
| `ADMOB_IOS_REWARDED_ID` | Google test ID | iOS rewarded unit. |
| `ADMOB_ANDROID_INTERSTITIAL_ID` | Google test ID | Android interstitial unit. |
| `ADMOB_IOS_INTERSTITIAL_ID` | Google test ID | iOS interstitial unit. |

Ad unit IDs are environment configuration rather than secrets. Credentials, API secrets, signing passwords, private keys, service-account material, and tokens remain owned by `ENG-010` and must never be committed.

`ENABLE_ANALYTICS` is intentionally different from advertising consent. ENG-012 does not reuse Google UMP `canRequestAds` as a first-party analytics decision. The production composition keeps analytics runtime privacy eligibility deny-all and installs no emitter, so the current application does not collect, persist, queue, or transmit first-party analytics events even if this build define is accidentally enabled.

## Debug

The default command is intentionally safe and requires no local configuration:

```powershell
flutter run --dart-define=APP_ENV=debug
```

Disable ads entirely when testing offline/core UI flows:

```powershell
flutter run `
  --dart-define=APP_ENV=debug `
  --dart-define=ENABLE_ADS=false
```

## Staging

Staging must be explicitly selected:

```powershell
flutter run `
  --dart-define=APP_ENV=staging `
  --dart-define=ENABLE_DIAGNOSTICS=true `
  --dart-define=ENABLE_ANALYTICS=false
```

## Release

Release builds fail closed when ads are enabled but Google test ad IDs remain configured. Inject production unit IDs from the release environment or CI configuration. First-party analytics remains disabled for the current production checkpoint:

```powershell
flutter build appbundle --release `
  --dart-define=APP_ENV=release `
  --dart-define=ENABLE_DIAGNOSTICS=false `
  --dart-define=ENABLE_ADS=true `
  --dart-define=ENABLE_ANALYTICS=false `
  --dart-define=ADMOB_ANDROID_BANNER_ID=<injected-value> `
  --dart-define=ADMOB_IOS_BANNER_ID=<injected-value> `
  --dart-define=ADMOB_ANDROID_REWARDED_ID=<injected-value> `
  --dart-define=ADMOB_IOS_REWARDED_ID=<injected-value> `
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=<injected-value> `
  --dart-define=ADMOB_IOS_INTERSTITIAL_ID=<injected-value>
```

Do not place real environment values in checked-in scripts. Use CI variables, local untracked environment tooling, or another approved injection mechanism.

## Validation contract

`AppBuildConfig` and the ENG-012 analytics boundary enforce these invariants before collection could ever be enabled:

1. Environment names are typed and unknown names are rejected.
2. When ads are enabled, every required platform/unit ID must be non-empty.
3. Release builds cannot use official Google test ad unit IDs.
4. Ads-disabled builds do not require ad-unit configuration.
5. `ENABLE_ANALYTICS` defaults to false and is only the first of multiple analytics eligibility gates.
6. Production analytics requires a separate first-party runtime privacy decision plus an outward emitter; the ENG-012 production composition provides neither.
7. Production code consumes the typed configuration instead of hard-coded environment branches.

Focused configuration tests live in `test/core/config/app_build_config_test.dart` and `test/core/config/analytics_build_config_test.dart`.
