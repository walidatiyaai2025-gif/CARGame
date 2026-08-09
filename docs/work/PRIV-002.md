# PRIV-002 — Privacy policy and Play Data Safety mapping

State: IMPLEMENTED  
Issue: #169  
Pull request: #170  
Branch: `agent/priv-002-play-data-safety`  
Started: 2026-08-09

## Goal

Keep the public privacy policy and Google Play Data Safety answers mechanically aligned with the current PRIV-001 data inventory and ADS-007 consent-aware advertising behavior.

## Implemented scope

- Added a publish-ready privacy-policy draft without inventing publisher contact, audience, publication URL, or Play Console evidence.
- Added `docs/privacy/play_data_safety.json` as the machine-readable store-disclosure mapping.
- Mapped all six current inventory flows exactly once.
- Treats the five local-only flows as on-device-only and keeps Google Mobile Ads as the sole off-device SDK flow.
- Uses a conservative Google Mobile Ads mapping for approximate location (IP-derived), app interactions, diagnostics, and device/other identifiers, with advertising, analytics, and fraud-prevention/security purposes.
- Added `tool/verify_privacy_disclosures.py` plus 12 focused regressions and runs both as blocking Flutter CI gates.

## Source acceptance

- Inventory/disclosure flow IDs and processors cannot drift.
- A local-only flow cannot silently become off-device collection/sharing.
- Google Mobile Ads required disclosure types/purposes cannot silently disappear.
- Explicitly absent first-party capabilities stay synchronized with PRIV-001.
- A draft cannot claim policy publication, Play Console submission, production AdMob review, target-audience confirmation, or real publisher contact.
- A published state must have a stable HTTPS policy URL and all external release evidence completed.

## Verification evidence

- Pre-push pure-Python probe: 12/12 privacy-disclosure regressions passed and the six-flow repository-shape contract passed.
- Flutter CI #746 / run `31335858470` passed the PRIV-001 inventory gate, new Play Data Safety validator, 12 disclosure-policy regressions, security baseline, dependency/security/CI contracts, formatting/whitespace, Analyze, focused Flutter checks, the full Flutter test suite, Debug APK build, artifact security scan, and upload on head `1da1ce6e57d9fc29b30a514360a847078820a7dc`.
- Debug artifact #9044388801 is 80,608,681 bytes with SHA-256 `03e81188e97a1b9ab867d18c48894603f7586bd5d0963014516de35e8b8e868a`.

## External evidence before VERIFIED

`PRIV-002` remains IMPLEMENTED rather than VERIFIED until the publisher supplies a real privacy contact, confirms target audience/Families applicability, publishes the policy at a stable HTTPS URL, reviews production Google Mobile Ads/UMP behavior, and submits/reviews the matching Play Console Data Safety form.
