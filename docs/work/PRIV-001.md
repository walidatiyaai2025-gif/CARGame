# PRIV-001 — Privacy inventory, consent, and data minimization

Status: VERIFIED  
Tracking: issue #32 / RC-001 #79  
Historical implementation: PR #33 / merge `0720c343f334acd9f2094115d427c301c6cf015e`  
Current-main refresh: PR #126 / merge `dd076dd383d6c3cd0dd33986f980e8b4f012b38b`

## Why this task was reopened

PR #33 introduced the human-readable and machine-readable privacy inventory plus the CI validation gate. The feature later drifted from current source because subsequent release-hardening work added local persistence that was not explicitly enumerated by the original inventory:

- SHOP-002: `pending_shop_purchase_v1` transaction journal.
- REL-004: `storage_recovery_backup_v1` pre-repair snapshot.
- REW-007: `pending_reward_transaction_v1` and bounded `reward_transaction_ledger_v1`.
- ECON-005: `economy_config_version` and config-driven atomic heart purchase state.

No new production network dependency is present in `pubspec.yaml`; Google Mobile Ads remains the only declared network data processor. Analytics, cloud sync, account registration, and remote diagnostic upload remain absent.

## Current-main result

- The machine inventory covers all 33 current SharedPreferences key/prefix families owned by `ProgressStore`, `AppSettingsStore`, and `RecoveringPreferences`.
- Durable player progress, transaction/migration integrity metadata, storage-recovery snapshots, settings, diagnostics, and ad SDK processing are documented as separate flows where their retention/processor semantics differ.
- `tool/verify_privacy_inventory.py` now extracts current persistence declarations and fails CI on missing, stale, or duplicate inventory coverage.
- Network processor/dependency checks remain fail-closed for selected unreviewed analytics/cloud/crash SDK additions.
- Runtime gaps are documented truthfully instead of treated as completed controls:
  - ADS-007 owns production consent/regulated-region gating before Google Mobile Ads SDK initialization/requests. `AdService` request/load/show calls honor `ENABLE_ADS=false`, but current bootstrap still initializes `MobileAds`.
  - ENG-013 owns effective diagnostics gating and any future remote crash reporting. `ENABLE_DIAGNOSTICS` exists but current bootstrap installs the local redacted logger unconditionally.
  - PRIV-003 owns consolidated in-app reset/export/deletion controls; complete local deletion currently relies on OS application-data clearing/uninstall, while diagnostics also expose `AppLogger.clear()`.
  - PRIV-002 owns published privacy policy and Play Data Safety/store disclosure mapping.

## Verification evidence

- Final implementation head: `659a78ce00b6fc3f95e7213bf1c04ceaa680cd55`.
- Flutter CI #651 / run `31299285194`: SUCCESS.
- Strengthened privacy inventory drift gate: SUCCESS.
- Security baseline cross-check: SUCCESS.
- Dynamic Android targets, secret hygiene/policy, formatting, whitespace, Analyze, optional-service isolation, animated GameButton tests, full Flutter suite, Debug APK build, and artifact upload: SUCCESS.
- Debug artifact `cargame-debug-apk` #9034063433: 80,544,514 bytes.
- Artifact SHA-256: `6fc839b195551ffcdbb0bd30b69bb9f29124aa5b9f5277ab8aa981d3508f4f9c`.
- PR #126 squash-merged to `main` as `dd076dd383d6c3cd0dd33986f980e8b4f012b38b`.
- This reconciliation PR is documentation/tracking only and receives its own current-head CI before issue closure.
