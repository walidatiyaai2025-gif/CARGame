# ECON-005 — Versioned economy configuration and balance rules

Status: IN PROGRESS
Tracking: issue #122 / RC-001 #79

## Audit findings

- Release-critical balance values are split across `ProgressStore`, `GameScreen`, and `ShopScreen`.
- Starting coins, heart cap/refill, starter boosters, XP level step, mission thresholds, daily rewards, milestone/world rewards, level reward/XP formulas, hint fallback cost, booster quantities/prices, heart prices, and theme prices have no single schema version.
- `purchaseTheme()` and `purchaseBooster()` currently accept caller-provided prices/quantities, so presentation code can accidentally become an economy authority.
- Heart purchases currently debit coins and grant hearts in separate operations rather than through the existing SHOP-002 purchase journal.

## Invariants

- Version 1 must produce the exact shipped values and formulas. No rebalance is permitted in ECON-005.
- REW-007 reward idempotency/recovery and SHOP-002 purchase recovery remain authoritative transaction boundaries.
- Existing wallets, progression, inventories, themes, and reward ledgers must load without destructive rewrites.
- Future economy versions require an explicit, idempotent migration; a newer saved schema must fail closed rather than be silently downgraded.

## Implementation

- Add immutable, validated `EconomyConfig` v1 with stable shop IDs and current balance/formula values.
- Make `ProgressStore` consume config-derived defaults, caps, thresholds, bonuses, daily rewards, and authoritative shop offers.
- Persist `economy_config_version` non-destructively for migration/reconciliation metadata only.
- Move gameplay reward/XP/hint/extra-move quantities and shop display/pricing to the same configuration.
- Make heart purchases atomic through the SHOP-002 journal.
- Keep legacy optional purchase arguments compile-compatible but ignore them for pricing/quantity authority.

## Verification target

- Config parity and fail-closed validation tests.
- Authoritative-price spoof regression tests.
- Heart purchase atomic/recovery tests.
- Legacy save + economy-version migration/idempotency tests.
- Existing REW-007 and SHOP-002 recovery regressions remain green.
- Formatting, Analyze, full Flutter suite, Debug APK build, and artifact upload.
