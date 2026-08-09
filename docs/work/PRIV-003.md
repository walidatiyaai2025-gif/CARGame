# PRIV-003 — User data export/deletion readiness

State: IN PROGRESS  
Issue: #171  
Branch: `agent/priv-003-local-data-controls`  
Started: 2026-08-10

## Goal

Give the player an explicit in-app path to export and delete CARGame first-party local data without introducing a backend, network transfer, new storage permission, or a false claim about Google processor-side deletion.

## Implementation checkpoint

- `LocalDataController` exports versioned JSON containing the app-owned SharedPreferences snapshot and already-redacted local diagnostics.
- Export is returned to the caller only; Settings currently exposes an explicit copy-to-clipboard action and no network upload path.
- Local deletion clears the full app-owned SharedPreferences namespace, including transaction journals/reward ledger/storage-recovery backup, and clears local diagnostic logs.
- Concurrent delete attempts join one in-flight operation.
- After deletion, the app shell constructs fresh `ProgressStore` and `AppSettingsStore` instances before continuing so stale private reward/recovery state cannot survive only in memory.
- Settings Privacy exposes export and destructive reset controls with an explicit confirmation dialog and makes clear that Google Mobile Ads processor-side data is outside the first-party delete operation.

## Acceptance before source completion

- Export is valid versioned JSON and explicitly declares no network transfer.
- Export includes current first-party SharedPreferences state and redacted local diagnostics only.
- Destructive reset clears progress/economy/settings/transaction/recovery state and diagnostics.
- Fresh stores after reset use safe defaults and do not retain the previous reward ledger or recovery snapshot.
- Delete requires user confirmation and duplicate/concurrent destructive actions are guarded.
- Existing Google UMP privacy-choice behavior remains unchanged.
- Focused tests, Analyze, full Flutter tests, Debug APK build, privacy/security gates and artifact scan pass.

## Non-goals

- CARGame currently has no first-party account/backend/cloud-save data to delete remotely.
- The app does not claim to delete data retained by Google Mobile Ads; UMP/privacy options continue to own Google advertising privacy choices.
