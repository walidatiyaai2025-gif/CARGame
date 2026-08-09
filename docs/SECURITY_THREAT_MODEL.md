# CARGame Mobile Security Baseline and Threat Model

This document is the human-readable SEC-001 baseline. The machine-readable source is `docs/security/threat_model.json`, and `tool/verify_security_baseline.py` cross-checks it against the current PRIV-001 inventory.

## Security posture

CARGame treats the installed mobile client and device as attacker-controlled. APK/AAB/IPA contents, Dart/native code, bundled resources, public configuration, runtime memory, SharedPreferences, and application-support files can be inspected or modified by a determined user. No privileged security decision may depend on hiding a client value or algorithm.

The product remains offline-first. Google Mobile Ads is the only declared third-party network processor in the current production dependency set. There is no first-party account backend, cloud save, analytics SDK, or remote crash-reporting service.

Current-main truth is intentionally explicit:

- `AdService` request/preload/load/show paths honor `AppBuildConfig.enableAds`, but `MobileAds.instance.initialize()` is still invoked by optional-service bootstrap and is not yet consent-gated. ADS-007 owns that release blocker.
- `ENABLE_DIAGNOSTICS` exists in build configuration, but current bootstrap still installs the local logger unconditionally. Diagnostics remain redacted and local-only; ENG-013 owns effective diagnostics gating and any future remote reporting boundary.

## Trust boundaries

### Mobile client

Untrusted. Shipped configuration is public. Ad unit IDs are identifiers, not credentials. Future privileged actions must be authorized outside the client.

### Local device storage

Untrusted for integrity. SharedPreferences and application-support files may be modified on rooted/jailbroken devices or through backups/debugging. Current local state includes gameplay/progression data, settings, shop/reward transaction journals, reward idempotency state, economy schema metadata, the storage-recovery snapshot, and local diagnostics.

The application must validate persisted values and recover safely instead of assuming local storage is authoritative or tamper-proof.

### Google Mobile Ads

External third-party boundary. The SDK currently initializes during optional-service bootstrap. `AdService` request/load/show operations are separately gated by `ENABLE_ADS`; production consent and regulated-region gating before SDK initialization/requests remain ADS-007 work. Data processing/store disclosure remains governed by PRIV-001 and PRIV-002.

### CI/external secret store

Trusted administrative boundary for release-signing passwords, keystores, production credentials, and store credentials. REL-006 and ENG-010 require secret material to remain outside repository source, Dart defines, logs, issues, screenshots, and distributable artifacts.

### Future backend

Not currently active. When introduced, it becomes the authoritative boundary for authenticated or valuable server-side actions. It must use TLS, server-side authorization, scoped/expiring tokens, and privacy/threat-model review before enabling new data flows.

## Protected assets

- Release signing material — secret; external to repository/client configuration.
- Gameplay/economy state — local integrity data; validated but intentionally not treated as tamper-proof.
- Transaction/reward recovery state — local integrity data; interruption recovery must remain idempotent and fail closed on malformed journals.
- Storage recovery snapshot — potentially sensitive local recovery data because it can contain a pre-repair copy of persisted state.
- Diagnostics — potentially sensitive local data; centrally redacted before persistence/copy.
- Ad unit IDs and other client identifiers — public client configuration, not a security boundary.

## Network baseline

1. Application-owned cleartext networking is not permitted.
2. Future first-party network features must use HTTPS/TLS.
3. Reusable privileged credentials must not exist in the mobile client.
4. Future authenticated clients receive only scoped, expiring credentials and the server performs authorization.
5. Certificate pinning is not required in the current architecture because there is no first-party authenticated backend. Reassess it when such a backend is introduced; do not add brittle pinning without an operational rotation plan.
6. A new SDK/network processor cannot merge without updating PRIV-001 and this threat model where relevant.
7. Google Mobile Ads request gating and SDK bootstrap gating are separate controls; only the request/load/show side is currently governed by `ENABLE_ADS`.

## Threats and controls

### Client extraction

An attacker can decompile or inspect the distributed app. Mitigation is architectural: secrets stay out of the client, release inputs use ENG-010/REL-006 external handling, and future privileged operations cannot rely on obscurity. SEC-003 may increase reverse-engineering cost but is not authorization.

### Local data tampering

Offline progress, economy, settings, transaction journals, reward ledger state, recovery snapshots, and diagnostics can be edited on compromised devices. Current controls target safety and idempotency rather than tamper-proof storage:

- persisted values are validated/normalized on load;
- REL-004 preserves a pre-repair snapshot where possible before supported corruption repair;
- SHOP-002 and REW-007 use validated absolute-state journals to avoid duplicate debit/grant after interruption;
- REW-007 keeps a bounded completed transaction ledger for reward idempotency;
- ECON-005 fails closed on corrupt/future economy schema markers.

Offline single-player state remains non-authoritative for any future server-side value.

### Repackaging and runtime hooking

Attackers can patch unofficial builds. REL-006 keeps release signing keys outside source control and documents external signing/key-management procedure. Official distribution relies on platform signature identity. Client integrity checks must never replace future server-side authorization; SEC-003 owns additional obfuscation/integrity hardening.

### Network interception

All future application-owned networking must use TLS. Third-party SDK endpoint security is partly controlled by providers. Any future authenticated first-party API must use scoped tokens and server-side authorization.

### Secret leakage

Secrets may leak through source, CI, logs, screenshots, diagnostics, or artifacts. ENG-010 provides source-control guards, redaction, approved secret-storage rules, and rotation procedures. REL-006 keeps Android release signing inputs external and validates them through redacted preflight. Pattern redaction is defense in depth, so callers must still avoid logging credentials. SEC-002 remains the dependency/secret/artifact scanning follow-up.

### Diagnostic and privacy leakage

Diagnostics may contain paths, exception text, tokens, or other sensitive values. Current logs remain local-only and use `SecretRedactor` before memory, file, debug output, runtime broadcast, or clipboard copy. No remote crash-reporting SDK exists.

`ENABLE_DIAGNOSTICS` is not currently an effective bootstrap gate for the local logger. That gap is explicitly owned by ENG-013 and must not be represented as already fixed.

### Dependency and supply-chain risk

Dependencies can introduce vulnerable code or unexpected data collection. Current CI validates secret hygiene, privacy inventory, the security baseline, assets, formatting, analysis, tests, and debug packaging. PRIV-001 also fails closed on selected analytics/cloud/crash SDK additions until privacy review. Automated vulnerability/license scanning and broader dependency governance remain SEC-002/ENG-006.

### Malicious or malformed state/input

Persisted values, transaction/reward journal payloads, economy schema metadata, asset/config metadata, route actions, repeated taps, and missing assets can produce unsafe transitions. Current typed registries, persistence validation/recovery, absolute-state journals, economy-version checks, navigation/gameplay race guards, and bounded asset fallbacks reduce that risk. Future external/deep-link/network inputs require dedicated validation as introduced.

### Advertising boundary and consent

Google Mobile Ads is explicitly external and is the only current PRIV-001 network processor. `AdService` blocks request/preload/load/show operations when ads are disabled, and release configuration rejects Google test ad-unit IDs.

However, SDK bootstrap still calls `MobileAds.instance.initialize()` independently of the request gate. Production consent and regulated-region handling before initialization/requests are therefore not complete until ADS-007 is VERIFIED. PRIV-002 must map the final production behavior into policy/store disclosures.

## Secure storage rules

- Do not place signing keys, passwords, refresh tokens, private keys, service-account data, backend API secrets, or store credentials in SharedPreferences or Dart source.
- SharedPreferences is acceptable only for non-secret local game state, preferences, transaction/migration metadata, and recovery state that is validated as untrusted input.
- Recovery snapshots may contain local game state and must remain local; do not upload them as diagnostics without a separate privacy/security gate.
- If future account/session tokens are introduced, use platform-backed secure storage and document lifecycle/rotation; do not silently reuse SharedPreferences.
- Release credentials belong in approved local/CI secret stores governed by ENG-010 and REL-006.

## Tamper assumptions

The game must continue to handle malformed local state safely, but it does not claim offline client state is tamper-proof. Any future competitive, purchased, or remotely valuable entitlement must be validated by an authoritative backend before it can affect server-side value.

## Current privacy/security gap parity

SEC-001 mirrors security-relevant PRIV-001 gaps so the two inventories cannot describe different runtime controls:

- `ad-sdk-bootstrap-consent` — ADS-007: SDK initialization is not yet production-consent gated.
- `diagnostics-build-gate` — ENG-013: `ENABLE_DIAGNOSTICS` is not yet an effective local logger bootstrap gate.

PRIV-003 in-app reset/export/deletion is a privacy/product control rather than a separate client trust boundary; it remains explicit in PRIV-001 and is not claimed complete by SEC-001.

## Security logging and incident response

- Never reproduce exposed secrets in tickets or evidence.
- Rotate credentials after suspected exposure; deleting the latest source line is insufficient.
- Keep diagnostic redaction before persistence/copy.
- Security-relevant build failures remain blocking rather than converted to warnings.
- Recovery/transaction evidence must not be treated as secret or tamper-proof merely because it is stored locally.

## Follow-up ownership

- SEC-002: dependency, secret, and artifact security scans.
- SEC-003: obfuscation, integrity, and release hardening.
- ADS-007: production ad consent/privacy controls before SDK initialization/requests.
- ENG-013: effective diagnostics gate and any future remote crash/non-fatal reporting.
- PRIV-002: policy and Play Data Safety mapping.
- TEST-011: privacy/consent/security verification.

REL-004 storage recovery, REL-006 signing/key-management, and ENG-010 secret handling are already VERIFIED inputs to this baseline; they are no longer listed as unfinished controls.

SEC-001 defines the current baseline and assumptions; it does not claim downstream gates complete.
