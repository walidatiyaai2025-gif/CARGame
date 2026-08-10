# TEST-011 — Privacy, consent, and security release evidence

Repository status: IN PROGRESS
External UMP regulated-device verification: PENDING
Final feature status ceiling: IMPLEMENTED until the external evidence below is captured.

## Purpose

TEST-011 is the release-level evidence boundary for CARGame privacy, consent, local-data controls, diagnostics/analytics privacy, secret handling, dependency security, network-processor declarations, and packaged APK scanning. It consolidates existing source-controlled protections and makes their continued presence mechanically enforceable.

This checkpoint does not invent production Google UMP configuration, production AdMob identifiers, production signing material, regulated-region observations, or device behavior. CI proves repository-owned behavior only. TEST-011 MUST NOT be marked VERIFIED while `External UMP regulated-device verification` is PENDING.

## Repository-verifiable matrix

| Area | Source of truth | Required repository evidence | Current repository posture |
|---|---|---|---|
| UMP consent refresh | `lib/core/ads/ad_consent_controller.dart` | `requestConsentInfoUpdate`, required-form handling, live `canRequestAds` snapshot | Implemented and covered by focused tests |
| Ad request gate | `lib/main.dart`, `lib/core/ads/ad_service.dart`, `lib/core/ads/banner_ad_footer.dart` | Mobile Ads initialization plus banner/rewarded/interstitial load/show paths remain behind current consent eligibility | Implemented fail-closed |
| Privacy options | UMP gateway + Settings | Publisher-rendered privacy entry re-opens `showPrivacyOptionsForm` only when required and updates eligibility without restart | Implemented and widget-tested |
| Offline core | bootstrap / optional services | Local progress/settings become usable before consent/ad startup; UMP or Mobile Ads failure cannot block play | Implemented and preserved |
| Privacy inventory | `docs/privacy/data_inventory.json`, `docs/PRIVACY_DATA_INVENTORY.md` | Every declared persisted key family is inventoried; Google Mobile Ads is the only intentional off-device processor | CI-blocking inventory gate |
| Play Data Safety | `docs/privacy/play_data_safety.json` | Disclosure mapping stays synchronized with the inventory and current runtime processors | CI-blocking disclosure gate |
| First-party analytics | ENG-012 boundary | `ENABLE_ANALYTICS` defaults off; runtime privacy is fail-closed; no outward emitter/processor/queue/transport exists | Disabled by default |
| Remote diagnostics | ENG-013 boundary | `ENABLE_REMOTE_DIAGNOSTICS` defaults off; runtime privacy is deny-all; no remote emitter/processor/queue/upload exists | Disabled by default |
| Local export | `LocalDataController` | Schema-versioned first-party JSON export, redacted diagnostics, explicit `networkTransfer: false` | Implemented and tested |
| Local deletion | `LocalDataController` + Settings/app shell | Confirmed destructive action clears SharedPreferences + diagnostics, serializes concurrent deletes, rehydrates safe stores, removes stale route state | Implemented and tested |
| Redaction | `SecretRedactor` / diagnostics gates | Secrets and sensitive local paths are redacted before retained/copied diagnostic output | CI protected |
| Secrets | `tool/verify_secret_hygiene.dart` | Tracked source is scanned and release secrets stay external | CI blocking |
| Dependencies | `tool/verify_dependency_security.py` | Lockfile restore, advisory scan, bounded explicit exception policy | CI blocking |
| Network/security model | `docs/SECURITY_THREAT_MODEL.md` + validator | Runtime processor/trust-boundary truth matches inventory/disclosures | CI blocking |
| APK artifact | `tool/verify_build_artifact_security.py` | Every normal CI Debug APK is scanned before upload | CI blocking |

## Consent and ad-request invariants

1. Google UMP is the advertising privacy source of truth; CARGame does not persist a duplicate consent-granted preference.
2. `ConsentInformation.instance.requestConsentInfoUpdate` runs before ad eligibility is consumed.
3. `ConsentForm.loadAndShowConsentFormIfRequired` handles a required form before Mobile Ads startup.
4. `ConsentInformation.instance.canRequestAds()` supplies current request eligibility.
5. The default consent state is fail-closed. Unexpected gateway failure also returns to fail-closed state.
6. Mobile Ads SDK initialization occurs only after consent eligibility permits requests.
7. `AdService` requires both build-time ads enablement and the current `AdRequestGate.canRequestAds` value before rewarded/interstitial preload, load, or show.
8. `BannerAdFooter` applies the same build/platform/current-consent gate before creating/loading a banner.
9. When eligibility is revoked, app-owned loaded rewarded/interstitial/banner objects are disposed rather than retained for later display.
10. Settings only renders the UMP privacy-options action when Google reports it is required; using it refreshes runtime eligibility without restart.
11. Google UMP advertising eligibility is not reused as first-party analytics permission.
12. UMP/Mobile Ads failure is optional-service failure: core offline play remains available.

## Local export/deletion invariants

- Export is versioned, first-party local, explicitly zero-network, and includes only CARGame-managed local preferences plus already-redacted local diagnostics.
- Third-party Google data is not claimed as included in the first-party export.
- Destructive reset requires explicit user confirmation in Settings.
- Concurrent delete callers join one safe destructive boundary.
- Reset clears CARGame-managed SharedPreferences, transaction/reward/recovery metadata, and local diagnostic logs.
- Fresh `ProgressStore` and `AppSettingsStore` instances are loaded after reset and stale pre-delete routes are removed so old state cannot be re-persisted.
- The app does not claim that its local reset deletes processor-side Google Mobile Ads data.

## Analytics and diagnostics privacy invariants

- First-party analytics collection remains disabled by default and has an independent runtime privacy gate.
- No first-party analytics emitter, processor, persistence queue, or transport is installed in the current production composition.
- UMP ad consent must never be treated as analytics consent.
- Local diagnostics remain separately gated, bounded, and redacted.
- Remote diagnostics remain disabled by default and production runtime privacy remains deny-all with no remote emitter/upload path.
- Any future telemetry SDK, processor, persistence queue, or network transport requires an inventory/disclosure/security update before merge.

## Security and CI invariants

Normal Flutter CI must keep all of these blocking gates:

- tracked secret hygiene plus its regression suite;
- privacy data inventory;
- analytics privacy contract;
- crash-reporting privacy contract;
- Play Data Safety disclosures plus disclosure regressions;
- security baseline/trust-boundary parity;
- TEST-007, TEST-008, TEST-010, AST-004, PERF-001, and PERF-002 contracts;
- dependency advisory scan after lockfile-enforced package restore plus scanner regressions;
- TEST-011 repository validator and its mutation regressions;
- focused TEST-011 consent/privacy/security/local-data Flutter matrix;
- Analyze, complete Flutter suite, TEST-008 coverage gate;
- Debug APK build, packaged-artifact security scan, and artifact upload.

## External evidence still required for VERIFIED

The following is deliberately outside repository CI and remains PENDING:

1. Confirm the production AdMob application is using the intended externally supplied production application/ad-unit identifiers; do not commit those values to source control.
2. In the production AdMob **Privacy & messaging** configuration, confirm the intended Google UMP message is published for the app and required regulatory regions. Preserve an operator screenshot/export or change record outside source control if policy requires it.
3. Use a physical Android device with the production-integrated candidate and a regulated-region condition (actual regulated region or Google's documented test-geography/test-device mechanism as appropriate for pre-release validation).
4. From a clean install/reset consent state, record that consent information refresh occurs and a required form is displayed when Google requires one.
5. Record that CARGame makes no app-owned ad request before `canRequestAds` is true, and that eligible banner/rewarded/interstitial paths function only after UMP permits requests.
6. Open **Settings > Privacy** when Google reports privacy options are required, change the available privacy choice, and record that request eligibility updates without app restart; if eligibility becomes false, confirm already loaded app-owned ads are disposed/not shown.
7. Exercise no-network/UMP-error behavior and record that Home/core play remains available and no retry loop blocks the user.
8. Cross-check the Play Console Data safety submission and published privacy policy against the exact production SDK/configuration used by that candidate.
9. Attach the device/build/version, region/test-geography method, timestamp, screenshots/logs, and reviewer/owner to the release evidence location.

Until all applicable external items are evidenced, TEST-011 remains IMPLEMENTED rather than VERIFIED. CI success alone is intentionally insufficient.
