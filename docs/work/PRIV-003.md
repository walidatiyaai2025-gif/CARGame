# PRIV-003 — User data export/deletion readiness

State: VERIFIED  
Issue: #171  
PR: #172  
Branch: `agent/priv-003-local-data-controls`  
Started: 2026-08-10  
Verified: 2026-08-10

## Goal

Give the player an explicit in-app path to export and delete CARGame first-party local data without introducing a backend, network transfer, new storage permission, or a false claim about Google processor-side deletion.

## Verified implementation

- `LocalDataController` exports schema-versioned JSON containing the app-owned SharedPreferences snapshot and already-redacted local diagnostics.
- Export is returned to the caller only; Settings exposes an explicit copy-to-clipboard action and no CARGame network upload path.
- Local deletion clears the full app-owned SharedPreferences namespace, including transaction journals, completed reward ledger, economy metadata, storage-recovery backup, progression/economy/settings state, and local diagnostic logs.
- Concurrent delete attempts join one in-flight operation.
- After deletion, the app shell constructs fresh `ProgressStore` and `AppSettingsStore` instances and returns the navigator to its first route so stale private reward/recovery state cannot survive only in memory or be re-saved from an old route.
- Settings Privacy exposes export and destructive reset controls with an explicit confirmation dialog and makes clear that Google Mobile Ads processor-side data is outside the first-party delete operation.
- PRIV-001 inventory, the PRIV-002 policy/Play mapping, and the disclosure validator now require the in-app local deletion mechanism and reject reintroduction of the completed `in-app-data-controls` gap.
- Flutter CI includes dedicated controller and Settings local-data regression gates before the full suite.

## Verification evidence

- Flutter CI #768 / run `31338337454` passed privacy inventory, Play Data Safety validation, 15 disclosure-policy regressions, security/dependency/dashboard/assets gates, formatting, whitespace, Analyze, focused `LocalDataController` tests, focused Settings local-data tests, optional-service and GameButton checks, the full Flutter suite, Debug APK build, artifact security scan, and upload on implementation head `64da8aeaefaefe60fb57d765bc0c7d26521e0c83`.
- Debug artifact #9045113026 is 80,619,639 bytes with SHA-256 `6c101a90e89053b48836dd48be72b76ceb9290401ae3643310ad46730b653ddf`.
- The first-party remote deletion portion is not applicable to the current product because CARGame has no first-party account, backend, cloud-save, or remote diagnostic-upload data path. Those capabilities remain explicitly absent and adding any of them requires a new privacy inventory flow before merge.

## Acceptance result

- Versioned zero-network export: PASSED.
- SharedPreferences/reward/recovery/settings deletion: PASSED.
- Local diagnostics deletion: PASSED.
- Safe default rehydration after reset: PASSED.
- Confirmation and duplicate/concurrent destructive-action guards: PASSED.
- UMP/Google processor boundary preserved: PASSED.
- Full repository verification and Debug APK security: PASSED.

## Non-goals

- CARGame currently has no first-party account/backend/cloud-save data to delete remotely.
- The app does not claim to delete data retained by Google Mobile Ads; UMP/privacy options continue to own Google advertising privacy choices.
