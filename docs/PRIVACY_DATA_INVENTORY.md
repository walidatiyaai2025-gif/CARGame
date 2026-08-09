# CARGame Privacy Data Inventory

This document is the human-readable PRIV-001 evidence. The machine-readable source is `docs/privacy/data_inventory.json`, and `tool/verify_privacy_inventory.py` cross-checks that inventory against the current declared persistence keys and dependencies in CI.

## Current privacy posture

CARGame is offline-first. Core progression, economy, settings, transaction-recovery metadata, storage-recovery snapshots, and diagnostics are stored locally on the device. The current production dependency set contains no first-party analytics, account, cloud-save, or remote crash-reporting SDK.

Google Mobile Ads is the only intentional third-party network data processor in the current runtime dependency set. ADS-007 uses Google UMP as the privacy source of truth: consent information is refreshed on launch, required forms are shown before ad startup, and `canRequestAds` gates Mobile Ads initialization plus banner/rewarded/interstitial request paths. No duplicate app-side consent-granted value is persisted.

`ENABLE_DIAGNOSTICS` also exists in `AppBuildConfig`, but current bootstrap installs the local `AppLogger` unconditionally. Diagnostics remain local-only and redacted; ENG-013 owns any future privacy-gated remote crash/non-fatal reporting and the effective build/runtime diagnostics gate.

PRIV-003 adds an explicit first-party local-data boundary: `LocalDataController` can produce a versioned JSON export without network transfer and can clear CARGame-managed SharedPreferences plus local diagnostic logs. Settings exposes both actions under Privacy; destructive reset requires confirmation, serializes concurrent delete attempts, reconstructs fresh progress/settings stores, and returns to the default route so stale in-memory reward/recovery state cannot be written back after deletion.

## Data flow inventory

### Gameplay progress and economy

Source: `lib/core/storage/progress_store.dart`.

Stored locally through SharedPreferences:

- unlocked level and per-level stars;
- coins, hearts, and heart-refill timestamp;
- XP, games/wins/losses, coins earned, perfect wins, combo and streak statistics;
- daily reward and daily mission date/progress/claim state;
- hint, extra-move, and combo-shield inventories;
- selected and unlocked shop themes.

Purpose: core offline gameplay, persistence, rewards, economy, and owned presentation state.

Network transfer: none in first-party code.

Retention: until the user selects **Settings > Privacy > Delete & reset local data**, application data is cleared, or the app is uninstalled.

Deletion: the confirmed in-app reset clears this SharedPreferences state and fresh `ProgressStore` defaults are constructed before returning to the Home route.

### Transaction and migration integrity

Source: `lib/core/storage/progress_store.dart`.

Stored locally through SharedPreferences:

- `pending_shop_purchase_v1` — absolute-state SHOP-002 recovery journal;
- `pending_reward_transaction_v1` — absolute-state REW-007 recovery journal;
- `reward_transaction_ledger_v1` — bounded completed reward transaction IDs used for idempotency;
- `economy_config_version` — ECON-005 schema marker used to prevent incompatible balance logic from loading silently.

Purpose: prevent duplicate debits/grants, recover interrupted writes, and fail closed on incompatible economy schema versions.

Network transfer: none.

Retention: pending journals are removed after successful commit/recovery. The completed reward ledger is bounded to 128 entries. The economy schema marker persists until local data is deleted/reset, application data is cleared, or the app is uninstalled.

Deletion: **Settings > Privacy > Delete & reset local data** clears transaction journals, the completed reward ledger, and economy-version metadata together with the rest of the app-owned SharedPreferences namespace.

### Storage corruption recovery snapshot

Source: `lib/core/storage/recovering_preferences.dart`.

`storage_recovery_backup_v1` stores a versioned local snapshot of current SharedPreferences values immediately before a corrupt value is normalized or removed, plus the snapshot capture timestamp.

Purpose: preserve recoverable local evidence before automatic data repair.

Network transfer: none.

Retention: local until replaced by a later recovery snapshot, deleted/reset in Settings > Privacy, application data is cleared, or the app is uninstalled.

Deletion: the confirmed local reset clears the recovery snapshot; application-data clearing/uninstall remains effective as well.

### User settings

Source: `lib/core/settings/app_settings_store.dart`.

Stored locally: sound, music, and vibration preferences.

Purpose: remember player-selected presentation preferences.

Network transfer: none.

Retention/deletion: until **Settings > Privacy > Delete & reset local data**, application data is cleared, or the app is uninstalled. After the in-app reset a fresh `AppSettingsStore` uses safe defaults.

### Diagnostics

Source: `lib/core/logging/app_logger.dart`; bootstrap ownership is in `lib/main.dart`.

Possible contents: runtime error messages, stack traces, timestamps, checkpoints, and local file paths. Entries are sanitized by `SecretRedactor` before they enter memory, local file persistence, debug output, runtime error broadcasts, or clipboard-copy diagnostics.

Storage: application-support `logs/app_error.log` plus a bounded in-memory list of at most 300 entries.

Network transfer: none. There is currently no remote crash-reporting or diagnostic-upload SDK.

Current gate truth: local logging is installed during bootstrap. `ENABLE_DIAGNOSTICS` is represented in build configuration but is not currently an effective bootstrap gate; this gap is recorded for ENG-013 rather than hidden by the inventory.

Deletion: `LocalDataController.deleteAllLocalData()` calls `AppLogger.clear()` as part of the confirmed Settings reset. Direct `AppLogger.clear()`, application-data clearing, and uninstall also remain effective.

### First-party local export/reset control

Sources: `lib/core/privacy/local_data_controller.dart`, `lib/features/settings/settings_screen.dart`, and `lib/bootstrap/cargo_sort_app.dart`.

**Copy data export** creates a schema-versioned JSON object containing the current CARGame-managed SharedPreferences snapshot and the already-redacted in-memory diagnostic entries. It declares `networkTransfer: false` and is returned to Settings for an explicit clipboard copy; CARGame does not upload the export and adds no storage/network permission or backend for this action.

**Delete & reset local data** requires an explicit confirmation dialog. The controller clears the CARGame-managed SharedPreferences namespace and local diagnostics. Concurrent delete callers join the same in-flight destructive operation. The app then constructs fresh progress/settings stores and returns the navigator to the first route so stale pre-delete state cannot be re-saved by an old Settings/game route.

This control is first-party local only. It does not claim to export or delete data retained by Google Mobile Ads.

### Advertising

Sources: `lib/main.dart`, `lib/core/ads/ad_consent_controller.dart`, `lib/core/ads/ad_service.dart`, `lib/core/ads/banner_ad_footer.dart`, and `lib/core/config/app_build_config.dart`.

Processor: Google Mobile Ads SDK (`google_mobile_ads`).

Purpose: initialize the advertising SDK and load banner, rewarded, and interstitial advertising.

The app issues standard `AdRequest` objects only when ad loading is enabled. The exact device/network signals processed by the SDK are controlled by the Google Mobile Ads SDK/platform and must be reflected accurately in PRIV-002 / Play Data Safety based on the production SDK configuration.

Current controls and gaps:

- Google UMP consent information is refreshed on launch and any required consent form is presented before ad startup.
- `ConsentInformation.canRequestAds()` is the runtime source of truth for whether the app may initialize/request ads; no cached consent-granted preference is maintained by CARGame.
- `AdService` and `BannerAdFooter` refuse request/load/show operations unless both `ENABLE_ADS` and current consent state permit requests, and loaded app-owned ads are disposed when eligibility is revoked.
- Settings keeps a publisher-rendered privacy entry; when Google reports privacy options are required, the user can re-open the privacy options form and runtime eligibility updates without restarting.
- Release builds reject Google test ad-unit IDs.
- No first-party server receives ad identifiers or ad telemetry, and first-party analytics remains absent/disabled until ENG-012 adds a separately privacy-gated design.
- The first-party local reset does not claim to delete processor-side Google data; Google/UMP privacy controls remain separate.

## Explicitly absent in the current codebase

No application feature currently collects or stores account registration data, email addresses, phone numbers, contacts, precise location, user photos/files, first-party analytics events, cloud-save accounts, or remote diagnostic uploads.

## Data minimization rules

1. Offline core play must remain functional without analytics, cloud services, or successful ad service startup.
2. Any new SDK that transmits user/device data requires an inventory update before merge.
3. Any new persisted key family requires purpose, retention, deletion/reset path, processor, consent basis, and source ownership in the inventory.
4. CI extracts `*Key`/`*Prefix` SharedPreferences declarations from the current persistence sources and fails if the inventory omits a key or documents a stale key.
5. Diagnostics must be redacted before persistence or copying and must not be remotely uploaded without a separate privacy-gated feature.
6. Google UMP must remain the source of truth before Mobile Ads initialization/requests; app-owned ad paths must remain fail-closed behind current `canRequestAds` state and must not cache a duplicate consent-granted value.
7. First-party local export must remain user-driven and zero-network; a future remote export/sync path requires a new privacy inventory flow before merge.
8. First-party local deletion must continue to clear transaction/reward/recovery metadata and local diagnostics and must not imply deletion of third-party processor-side data.
9. Build-time IDs/configuration are not treated as user data, but secrets and credentials remain governed by ENG-010.

## Known privacy gaps and owners

- **ENG-013 — diagnostics gate:** `ENABLE_DIAGNOSTICS` exists but is not currently wired to suppress bootstrap installation of the local logger. Remote crash reporting remains absent.

The previous PRIV-003 in-app data-controls gap is closed by the source-controlled local export/delete/reset implementation. No account/backend/cloud-save deletion gap exists because those first-party remote data paths are absent.

## Retention and deletion posture

Complete first-party local deletion is available through **Settings > Privacy > Delete & reset local data**, Android application-data clearing, or uninstall. The in-app reset covers gameplay/progress/economy, settings, transaction/reward/economy-integrity metadata, the storage-recovery snapshot, and local diagnostic logs, then rehydrates safe default stores.

A versioned **JSON export** is available through **Settings > Privacy > Copy data export**. It includes CARGame-managed SharedPreferences state and redacted local diagnostics and is copied locally without CARGame network transmission.

Google Mobile Ads processor-side retention remains outside the first-party local reset and must be represented separately in PRIV-002/store disclosures.

## Processor map

- Local device / SharedPreferences — first-party local-only gameplay, settings, transaction/migration integrity metadata, and storage-recovery snapshot state.
- Local application-support directory — first-party local-only diagnostic log file.
- Google Mobile Ads — third-party advertising processor initialized only when UMP eligibility permits ad requests.

No other network data processor is declared by the current production dependency set.

## Mechanical drift protection

`tool/verify_privacy_inventory.py` currently enforces:

- required privacy flows and fields;
- unique processor, flow, and storage-key ownership;
- source-file existence;
- network-flow/processor consistency;
- network processor dependency declaration;
- declared local/network dependency presence in `pubspec.yaml`;
- fail-closed detection for known analytics/cloud/crash SDK additions that require privacy review;
- exact coverage of persisted `*Key`/`*Prefix` declarations in `ProgressStore`, `AppSettingsStore`, and `RecoveringPreferences`;
- offline-first, analytics-disabled, and cloud-sync-disabled principles.

`tool/verify_privacy_disclosures.py` additionally requires the local deletion mechanism to remain available, rejects reintroduction of the completed `in-app-data-controls` gap, and verifies the source anchors for `LocalDataController` plus Settings export/delete/confirmation controls.

This keeps PRIV-001/PRIV-002/PRIV-003 aligned with current source instead of relying on a one-time prose audit.

## Follow-up gates

- ADS-007: UMP consent and re-openable privacy controls now gate ad SDK initialization/requests; automated verification must remain green and production UMP evidence is still external.
- PRIV-002: privacy policy and Play Data Safety/store disclosure mapping remain IMPLEMENTED pending publication/store evidence.
- PRIV-003: first-party local reset/export/deletion readiness is source-complete and subject to repository verification evidence.
- ENG-012: analytics remains disabled until a privacy-gated schema and consent path exist.
- ENG-013: effective diagnostics gating and any future privacy-gated remote crash reporting.
- TEST-011: release privacy/consent/security verification.
