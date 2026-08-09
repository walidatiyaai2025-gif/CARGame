# ECON-005 — Versioned economy configuration and balance rules

Status: IN PROGRESS  
Tracking: issue #122 / RC-001 #79

## Audit findings

- Release-critical economy values are currently distributed across `ProgressStore`, `GameScreen`, and `ShopScreen` instead of one authoritative schema.
- `ProgressStore` owns starting wallet/resource defaults, heart cap/refill cadence, starter boosters, XP level step, mission thresholds, daily/mission rewards, and milestone/world bonuses.
- `GameScreen` owns the level coin reward formula, XP reward formula, and the 10-coin hint fallback sink.
- `ShopScreen` owns heart, booster, and theme prices/quantities; theme prices are embedded in UI offer data and purchase APIs currently accept caller-provided prices.
- Existing v1 behavior must remain numerically identical; ECON-005 is centralization/versioning/validation, not a rebalance.
- `SHOP-002` and `REW-007` already provide transaction durability. ECON-005 must feed them authoritative values without weakening their recovery/idempotency guarantees.

## Implementation direction

- Add an immutable typed economy configuration with explicit schema version `1` and the current shipped values.
- Centralize starter values, caps/refill cadence, mission thresholds, XP step, reward formulas, milestone/world grants, daily grants, gameplay sinks, and shop catalog pricing/quantities.
- Validate non-negative amounts, valid caps/ranges, stable unique shop IDs, and deterministic/non-negative formula outputs.
- Make gameplay, progress/reward, and shop paths consume config values while preserving their public behavior where compatibility matters.
- Add a persisted economy-config version/migration marker only where it adds deterministic save migration; v1 migration must be idempotent and must not rewrite existing balances or entitlements.
- Treat shop IDs as authoritative lookup keys so price/quantity truth no longer comes from presentation data.

## Verification required

- Focused v1 parity tests for current rewards, prices, starter values, caps, thresholds, and formulas.
- Validation regressions for malformed/unsafe configurations and duplicate/unknown shop IDs.
- Legacy-save/migration tests prove v1 is non-destructive and repeatable.
- Existing REW-007 and SHOP-002 recovery/idempotency suites remain green.
- Formatting, Analyze, full Flutter suite, Debug APK build, and artifact upload.
- Catalog/status reconciliation after merge.

## Migration policy

- Legacy saves without `economy_config_version` are adopted as v1 by writing only the version marker; wallet, hearts, boosters, themes, progression, and reward state are not rewritten.
- Re-loading the same v1 marker is a no-op.
- A save stamped with a future economy schema fails closed before reward/shop recovery so an older build cannot silently apply stale prices or reward formulas.
- Future positive versions below the runtime schema require an explicit registered migration before the runtime may advance the marker; implicit balance rewrites are forbidden.

## Review hardening

- A present non-positive `economy_config_version` is treated as corrupted metadata and fails closed; only an absent marker is considered a legacy v1 save.
- Configured heart purchases now debit coins and grant hearts inside the existing SHOP-002 absolute-state purchase journal, including atomic refill-timestamp clearing when the cap is reached.
- The v1 schema keeps non-negative price validation semantics; shipped balance values are unchanged.
- Focused review-hardening run `31296816764` passed Analyze plus ECON-005, ProgressStore, SHOP-002, and REW-007 regression suites before producing the clean implementation head.
