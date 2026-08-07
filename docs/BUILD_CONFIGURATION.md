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
| `ADMOB_ANDROID_BANNER_ID` | Google test ID | Android banner unit. |
| `ADMOB_IOS_BANNER_ID` | Google test ID | iOS banner unit. |
| `ADMOB_ANDROID_REWARDED_ID` | Google test ID | Android rewarded unit. |
| `ADMOB_IOS_REWARDED_ID` | Google test ID | iOS rewarded unit. |
| `ADMOB_ANDROID_INTERSTITIAL_ID` | Google test ID | Android interstitial unit. |
| `ADMOB_IOS_INTERSTITIAL_ID` | Google test ID | iOS interstitial unit. |

Ad unit IDs are environment configuration rather than secrets. Credentials, API secrets, signing passwords, private keys, service-account material, and tokens remain owned by `ENG-010` and must never be committed.

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
  --dart-define=ENABLE_DIAGNOSTICS=true
```

## Release

Release builds fail closed when ads are enabled but Google test ad IDs remain configured. Inject production unit IDs from the release environment or CI configuration:

```powershell
flutter build appbundle --release `
  --dart-define=APP_ENV=release `
  --dart-define=ENABLE_DIAGNOSTICS=false `
  --dart-define=ENABLE_ADS=true `
  --dart-define=ADMOB_ANDROID_BANNER_ID=<injected-value> `
  --dart-define=ADMOB_IOS_BANNER_ID=<injected-value> `
  --dart-define=ADMOB_ANDROID_REWARDED_ID=<injected-value> `
  --dart-define=ADMOB_IOS_REWARDED_ID=<injected-value> `
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=<injected-value> `
  --dart-define=ADMOB_IOS_INTERSTITIAL_ID=<injected-value>
```

Do not place real environment values in checked-in scripts. Use CI variables, local untracked environment tooling, or another approved injection mechanism.

## Validation contract

`AppBuildConfig` enforces these invariants before the configuration is accepted:

1. Environment names are typed and unknown names are rejected.
2. When ads are enabled, every required platform/unit ID must be non-empty.
3. Release builds cannot use official Google test ad unit IDs.
4. Ads-disabled builds do not require ad-unit configuration.
5. Production code consumes the typed configuration instead of hard-coded environment branches.

Focused tests live in `test/core/config/app_build_config_test.dart`.
