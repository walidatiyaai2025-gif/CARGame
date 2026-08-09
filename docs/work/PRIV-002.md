# PRIV-002 — Privacy policy and Play Data Safety mapping

State: IN PROGRESS  
Issue: #169  
Branch: `agent/priv-002-play-data-safety`  
Started: 2026-08-09

## Goal

Keep the public privacy policy and Google Play Data Safety answers mechanically aligned with the current PRIV-001 data inventory and ADS-007 consent-aware advertising behavior.

## Implementation checkpoint

- Add a publish-ready privacy-policy draft without inventing publisher contact, audience, publication URL, or Play Console evidence.
- Add `docs/privacy/play_data_safety.json` as the machine-readable store-disclosure mapping.
- Map all six current inventory flows exactly once.
- Treat the five local-only flows as on-device-only and keep Google Mobile Ads as the sole off-device SDK flow.
- Use a conservative Google Mobile Ads mapping for approximate location (IP-derived), app interactions, diagnostics, and device/other identifiers, with advertising, analytics, and fraud-prevention/security purposes.
- Add `tool/verify_privacy_disclosures.py` plus focused regressions and run both as blocking Flutter CI gates.

## Acceptance before source-level completion

- Inventory/disclosure flow IDs and processors cannot drift.
- A local-only flow cannot silently become off-device collection/sharing.
- Google Mobile Ads required disclosure types/purposes cannot silently disappear.
- Explicitly absent first-party capabilities must stay synchronized with PRIV-001.
- A draft cannot claim policy publication, Play Console submission, production AdMob review, target-audience confirmation, or real publisher contact.
- A published state must have a stable HTTPS policy URL and all external release evidence completed.

## External evidence before VERIFIED

`PRIV-002` must remain below VERIFIED until the publisher supplies a real privacy contact, confirms target audience/Families applicability, publishes the policy at a stable HTTPS URL, reviews production Google Mobile Ads/UMP behavior, and submits/reviews the matching Play Console Data Safety form.
