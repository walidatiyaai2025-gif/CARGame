# ECON-005 — Versioned economy configuration and balance rules

Status: VERIFIED  
Tracking: issue #122 / RC-001 #79

## Audit findings

- Release-critical economy values were distributed across `ProgressStore`, `GameScreen`, and `ShopScreen` instead of one authoritative schema.
- `ProgressStore` owned starting wallet/resource defaults, heart cap/refill cadence, starter boosters, XP level step, mission thresholds, daily/mission rewards, and milestone/world bonuses.
- `GameScreen` owned the level coin reward formula, XP reward formula, and the 10-coin hint fallback sink.
- `ShopScreen` owned heart, booster, and theme prices/quantities; theme prices were embedded in UI offer data and purchase APIs accepted caller-provided prices.
- Existing v1 behavior had to remain numerically identical; ECON-005 is centralization/versioning/validation, not a rebalance.
- `SHOP-002` and `REW-007` already provide transaction durability. ECON-005 feeds them authoritative values without weakening their recovery/idempotency guarantees.

## Implementation direction

- Added an immutable typed economy configuration with explicit schema version `1` and the current shipped values.
- Centralized starter values, caps/refill cadence, mission thresholds, XP step, reward formulas, milestone/world grants, daily grants, gameplay sinks, and shop catalog pricing/quantities.
- Validates non-negative amounts, valid caps/ranges, stable unique shop IDs, and deterministic/non-negative formula outputs.
- Gameplay, progress/reward, and shop paths consume config values while preserving public behavior where compatibility matters.
- Added persisted `economy_config_version`; v1 adoption is idempotent and does not rewrite existing balances or entitlements.
- Shop IDs are authoritative lookup keys so price/quantity truth no longer comes from presentation data.

## Migration policy

- Legacy saves without `economy_config_version` are adopted as v1 by writing only the version marker; wallet, hearts, boosters, themes, progression, and reward state are not rewritten.
- Re-loading the same v1 marker is a no-op.
- A save stamped with a future economy schema fails closed before reward/shop recovery so an older build cannot silently apply stale prices or reward formulas.
- Future positive versions below the runtime schema require an explicit registered migration before the runtime may advance the marker; implicit balance rewrites are forbidden.

## Review hardening

- A present non-positive `economy_config_version` is treated as corrupted metadata and fails closed; only an absent marker is considered a legacy v1 save.
- Configured heart purchases debit coins and grant hearts inside the existing SHOP-002 absolute-state purchase journal, including atomic refill-timestamp clearing when the cap is reached.
- The v1 schema keeps non-negative price validation semantics; shipped balance values are unchanged.
- Focused review-hardening run `31296816764` passed Analyze plus ECON-005, ProgressStore, SHOP-002, and REW-007 regression suites before producing the clean implementation head.

## Verification evidence

- Implementation PR #124 final clean head: `05217d3a1134b21ff014a58864615683db3ccb22`.
- Flutter CI #647 / run `31296918681` passed secret/privacy/security gates, formatting, whitespace integrity, Analyze, optional-service checks, the full Flutter test suite, Debug APK build, and artifact upload.
- Debug artifact `cargame-debug-apk` #9033326885 is 80,544,514 bytes with SHA-256 `bbca79f780b9effc07a93ecc8a5a0b0dd73b523e6706531fe292127165d2872a`.
- PR #124 squash-merged to `main` as `2091cf35ff9b4a261fa76f9d90975735711c58e3`.
- Existing REW-007 and SHOP-002 interruption/idempotency coverage remained green through the final full CI gate.
- Reconciliation runs on a separate docs-only PR so the implementation evidence and tracking evidence remain independently auditable.
