# PRIV-001 — Privacy inventory, consent, and data minimization

Status: IN PROGRESS  
Tracking: issue #32 / RC-001 #79  
Historical implementation: PR #33 / merge `0720c343f334acd9f2094115d427c301c6cf015e`

## Why this task is reopened

PR #33 introduced the human-readable and machine-readable privacy inventory plus the CI validation gate. The feature later drifted from current source because subsequent release-hardening work added local persistence that is not explicitly enumerated by the original inventory:

- SHOP-002: `pending_shop_purchase_v1` transaction journal.
- REL-004: `storage_recovery_backup_v1` pre-repair snapshot.
- REW-007: `pending_reward_transaction_v1` and bounded `reward_transaction_ledger_v1`.
- ECON-005: `economy_config_version` and config-driven atomic heart purchase state.

No new production network dependency is present in `pubspec.yaml`; Google Mobile Ads remains the only declared network data processor. Analytics, cloud sync, account registration, and remote diagnostics remain absent.

## Current-main audit scope

- Reconcile every current SharedPreferences key family owned by `ProgressStore`, `AppSettingsStore`, and `RecoveringPreferences` with the machine-readable inventory.
- Split durable player progress from transaction/recovery metadata where retention semantics differ.
- Keep diagnostics and Google Mobile Ads processing mapped to actual runtime/build controls.
- Strengthen `tool/verify_privacy_inventory.py` so un-inventoried persistence keys fail CI instead of silently drifting.
- Preserve the explicit follow-up boundaries: ADS-007 owns regulated-region ad consent; PRIV-002 owns policy/Play Data Safety mapping; PRIV-003 owns user-facing reset/export/deletion UX.

## Acceptance

- Every currently persisted key family is covered by a documented local data flow with purpose, processor, storage, consent basis, retention, deletion path, and source.
- The validator mechanically compares current storage-key declarations with inventory coverage.
- No undocumented network data dependency is introduced.
- Existing privacy/security/secret gates, Analyze, full Flutter tests, Debug APK build, and artifact upload remain green.
- Catalog/status are reconciled to VERIFIED only after current-head CI evidence exists.
