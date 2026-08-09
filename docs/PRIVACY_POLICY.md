# CARGame Privacy Policy

Publication status: DRAFT — NOT YET PUBLISHED

Last updated: August 10, 2026

This privacy policy describes the current CARGame Android application behavior represented by this repository. It is a release draft. It must not be presented as the published policy until the publisher contact, target audience, production advertising configuration, public HTTPS URL, and Google Play Data Safety submission are confirmed.

## Data stored on your device

CARGame is designed to work offline for its core gameplay. The app stores gameplay progress, level stars, coins, hearts, XP, gameplay statistics, daily reward and mission state, booster inventory, selected/unlocked themes, and sound/music/vibration preferences locally on the device.

The app also stores local transaction and recovery metadata used to prevent duplicate purchases or rewards, recover interrupted writes, and repair corrupted local preferences safely. These records remain on the device and are not uploaded by CARGame first-party code.

Local diagnostic logs may contain error messages, stack traces, timestamps, runtime checkpoints, and local file paths. CARGame sanitizes diagnostic text before local persistence or copying. Current first-party diagnostics are local only; there is no remote crash-reporting service in this release.

## Advertising and Google Mobile Ads

CARGame includes Google Mobile Ads for advertising and Google UMP for consent and privacy choices. Advertising is optional to core offline gameplay.

At launch, Google UMP refreshes consent information and can show a consent form where required. CARGame uses the current `canRequestAds` result as the runtime source of truth before initializing or requesting app-owned banner, rewarded, or interstitial ads. The app does not store a second CARGame-specific consent-granted preference. When Google indicates that privacy options are required, the Settings screen can reopen those options.

When advertising is enabled and the current consent/privacy state permits ad requests, the Google Mobile Ads SDK may collect and share data off the device. Google’s current Android disclosure for the Mobile Ads SDK identifies the following automatically handled signals:

- IP address, which may be used to estimate approximate/general location;
- app interactions and product interaction information;
- diagnostic information about app/SDK performance; and
- device and account identifiers, including advertising-related identifiers when available.

Google describes those signals as used for advertising, analytics, and fraud prevention/security purposes. Google also states that data transmitted by its Mobile Ads SDK is encrypted in transit using TLS. Production release owners must re-check the Google Mobile Ads SDK disclosure and the exact production configuration before submitting the Google Play Data Safety form because SDK behavior and optional products can change.

CARGame does not operate a first-party advertising server and does not receive a separate first-party copy of these SDK signals in the current codebase.

## Data we do not collect in first-party code

The current CARGame codebase does not provide or collect:

- account registration;
- email addresses or phone numbers;
- contacts;
- precise location;
- user photo or file uploads;
- first-party analytics events;
- cloud-save/backend account data; or
- remote diagnostic uploads.

If a future release adds one of these capabilities or adds another network SDK, the privacy inventory, this policy, and the Play Data Safety mapping must be updated before release.

## Retention and deletion

Gameplay, settings, transaction/recovery metadata, and local logs remain on the device until they are cleared, replaced by bounded recovery state, the user performs an in-app reset, application data is cleared, or the app is uninstalled, depending on the data type.

CARGame provides first-party local data controls under **Settings > Privacy**. **Copy data export** creates a versioned JSON export containing the current CARGame-managed SharedPreferences snapshot and already-redacted local diagnostic entries, then copies that JSON to the clipboard for an explicit user-controlled action. Creating the JSON export does not send it over the network and does not require a CARGame account or backend.

**Delete & reset local data** requires explicit confirmation and clears CARGame-managed local SharedPreferences, including progression/economy values, settings, pending transaction/reward journals, completed reward transaction IDs, economy-version metadata, and the storage-recovery snapshot. It also clears CARGame local diagnostic logs. The app then constructs fresh progress/settings state and returns to the default game state so deleted reward/recovery values are not retained only in memory.

Android application-data clearing or uninstalling the app also removes CARGame first-party local data.

CARGame does not retain a first-party server copy of Google Mobile Ads data. The in-app first-party local reset does not claim to delete processor-side data retained by Google. Retention of information processed by Google Mobile Ads is governed by Google and the user’s applicable Google/privacy controls, including Google UMP privacy choices where available.

## Security

CARGame keeps core gameplay data local and applies redaction to local diagnostics. Advertising requests are gated by the app’s current privacy eligibility state. For third-party network processing, CARGame relies on the security controls provided by the integrated SDK and platform; the production release owner must verify those controls and the final Data Safety answers before publication.

## Children and target audience

The Google Play target-audience selection and any Families-policy applicability have not yet been confirmed for this release draft. The publisher must make that product decision before publication and must configure advertising, consent behavior, store disclosures, and SDK eligibility consistently with the selected audience.

CARGame’s current first-party code does not create user accounts or intentionally collect names, email addresses, phone numbers, contacts, precise location, or uploaded photos/files.

## Changes to this policy

This policy must be reviewed whenever CARGame changes its persistence model, advertising or consent configuration, third-party SDKs, analytics/crash reporting, account/cloud features, data deletion controls, or Google Play target audience.

## Contact

PUBLISHER CONTACT EMAIL REQUIRED BEFORE PUBLICATION

## Release publication checklist

Before this document can be treated as the published PRIV-002 policy:

1. Replace the contact blocker above with the publisher’s real privacy contact.
2. Confirm the Google Play target audience and any Families-policy requirements.
3. Review the exact production Google Mobile Ads/UMP configuration and current SDK Data Safety guidance.
4. Publish this policy at a stable public HTTPS URL.
5. Submit the matching Google Play Data Safety answers in Play Console.
6. Record the public URL and submission/review evidence in `docs/privacy/play_data_safety.json`.
