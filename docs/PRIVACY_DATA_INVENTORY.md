# CARGame Privacy Data Inventory

This document is the human-readable PRIV-001 evidence. The machine-readable source is `docs/privacy/data_inventory.json`.

## Current privacy posture

CARGame is offline-first. Core progression, economy, settings, and diagnostics are stored locally on the device. The current dependency set contains no first-party analytics, account, cloud-save, or remote crash-reporting SDK.

The only intentional third-party network data processor in the current runtime dependency set is Google Mobile Ads. Ad requests can be disabled globally with `ENABLE_ADS=false`. Production consent behavior remains owned by ADS-007 and store disclosure/policy mapping remains owned by PRIV-002.

## Data flow inventory

### Gameplay progress and economy

Source: `lib/core/storage/progress_store.dart`.

Stored locally through SharedPreferences: unlocked level, per-level stars, coins, hearts and refill timestamp, XP, win/loss and combo statistics, daily reward/mission state, booster inventory, selected/unlocked themes, and related progression counters.

Purpose: core offline gameplay, persistence, rewards, and economy integrity.

Network transfer: none in first-party code.

Retention: until application data is cleared/uninstalled or a product reset/delete path removes it. A user-facing deletion/export/reset workflow remains tracked by PRIV-003.

### User settings

Source: `lib/core/settings/app_settings_store.dart`.

Stored locally: sound, music, and vibration preferences.

Purpose: remember player-selected presentation preferences.

Network transfer: none.

### Diagnostics

Source: `lib/core/logging/app_logger.dart`.

Possible contents: runtime error messages, stack traces, timestamps, checkpoints, and local file paths. Entries are sanitized by `SecretRedactor` before they enter memory, local file persistence, debug output, runtime error broadcasts, or clipboard-copy diagnostics.

Storage: application-support `logs/app_error.log` plus a bounded in-memory list of at most 300 entries.

Network transfer: none. There is currently no remote crash-reporting or diagnostic-upload SDK.

Deletion: `AppLogger.clear()`, clearing application data, or uninstalling.

### Advertising

Sources: `lib/core/ads/ad_service.dart` and `lib/core/config/app_build_config.dart`.

Processor: Google Mobile Ads SDK (`google_mobile_ads`).

Purpose: banner, rewarded, and interstitial advertising.

The app issues standard `AdRequest` objects only when ads are enabled. The exact device/network signals processed by the SDK are controlled by the Google Mobile Ads SDK/platform and must be reflected accurately in PRIV-002 / Play Data Safety based on the production SDK configuration.

Current controls:

- `ENABLE_ADS=false` disables ad loading/showing.
- Release builds reject Google test ad-unit IDs.
- No first-party server receives ad identifiers or ad telemetry in the current codebase.
- Production consent and regulated-region handling are not claimed complete here; ADS-007 owns that gate.

## Explicitly absent in the current codebase

No application feature currently collects or stores account registration data, email addresses, phone numbers, contacts, precise location, user photos/files, first-party analytics events, cloud-save accounts, or remote diagnostic uploads.

## Data minimization rules

1. Offline core play must remain functional without analytics, cloud services, or ads.
2. Any new SDK that transmits user/device data requires an inventory update before merge.
3. Any new persisted user datum requires purpose, retention, deletion/reset path, and source ownership in the inventory.
4. Diagnostics must be redacted before persistence or copying and must not be remotely uploaded without a separate privacy-gated feature.
5. Production ad consent must fail closed where consent is required; PRIV-001 does not substitute for ADS-007.
6. Build-time IDs/configuration are not treated as user data, but secrets and credentials remain governed by ENG-010.

## Retention and deletion gaps

The app currently relies on OS-level app-data clearing/uninstall for complete local progress/settings deletion. Diagnostics additionally expose `AppLogger.clear()`. A consolidated in-app reset/export/delete experience is intentionally tracked by PRIV-003 and must reuse the inventory in this document.

## Processor map

- Local device / SharedPreferences — first-party local-only gameplay and settings state.
- Local application-support directory — first-party local-only diagnostic log file.
- Google Mobile Ads — third-party advertising processor when `ENABLE_ADS=true`.

No other network data processor is declared by the current production dependency set.

## Follow-up gates

- ADS-007: production consent and privacy controls for ads.
- PRIV-002: privacy policy and Play Data Safety/store disclosure mapping.
- PRIV-003: user reset/export/deletion readiness.
- ENG-012: analytics remains disabled until a privacy-gated schema and consent path exist.
- ENG-013: remote crash reporting remains absent until privacy-gated diagnostics are implemented.
- TEST-011: release privacy/consent/security verification.
