# CARGame Mobile Security Baseline and Threat Model

This document is the human-readable SEC-001 baseline. The machine-readable source is `docs/security/threat_model.json`.

## Security posture

CARGame treats the installed mobile client and device as attacker-controlled. APK/AAB/IPA contents, Dart/native code, runtime memory, local preferences, public identifiers, and UI logic can be inspected or modified by a determined user. No privileged security decision may depend on hiding a value or algorithm in the client.

The current product is offline-first. The only declared third-party network processor in the production dependency set is Google Mobile Ads. There is no first-party account backend, cloud save, analytics SDK, or remote crash-reporting service today.

## Trust boundaries

### Mobile client

Untrusted. Shipped configuration is public. Ad unit IDs are identifiers, not credentials. Future privileged actions must be authorized outside the client.

### Local device storage

Untrusted for integrity. SharedPreferences and application-support files may be modified on rooted/jailbroken devices or through backups/debugging. The app must validate persisted values and recover safely instead of assuming local storage is authoritative.

### Google Mobile Ads

External third-party boundary. Ad network requests exist only when ads are enabled. Data processing and production consent/store disclosure are governed by the privacy inventory, ADS-007, and PRIV-002.

### CI/external secret store

Trusted administrative boundary for future release-signing passwords, keys, service credentials, and store credentials. Secret values must never be copied into source, Dart defines, logs, issues, screenshots, or build artifacts.

### Future backend

Not currently active. When introduced, it becomes the authoritative security boundary for authenticated or valuable server-side actions. It must use TLS, server-side authorization, scoped/expiring tokens, and a privacy-inventory update before enabling new data flows.

## Protected assets

- Release signing material: secret; never committed or shipped as plaintext configuration.
- Gameplay/economy state: local integrity data; validated, but not considered tamper-proof.
- Diagnostics: potentially sensitive local data; centrally redacted before persistence/copy.
- Ad unit IDs and other client identifiers: public configuration, not a security boundary.

## Network baseline

1. Application-owned cleartext networking is not permitted.
2. Future first-party network features must use HTTPS/TLS.
3. Reusable privileged credentials must not exist in the mobile client.
4. Future authenticated clients receive only scoped, expiring credentials and the server performs authorization.
5. Certificate pinning is not required in the current architecture because there is no first-party authenticated backend. Reassess it when such a backend is introduced; do not add brittle pinning without an operational rotation plan.
6. A new SDK/network processor cannot be merged without updating `docs/privacy/data_inventory.json` and the threat model where relevant.

## Threats and controls

### Client extraction

An attacker can decompile or inspect the distributed app. Mitigation is architectural: secrets stay out of the client and server-authorized operations cannot rely on obscurity. Obfuscation may increase reverse-engineering cost later under SEC-003 but is not treated as authorization.

### Local data tampering

Offline progress, coins, boosters, settings, and other local state can be edited on compromised devices. Current mitigations include clamping/validation and tested mutation invariants. Offline single-player progress remains intentionally non-authoritative for any future server rewards.

### Repackaging and runtime hooking

Attackers can patch unofficial builds. Official release signing establishes distribution identity; signing keys remain outside the repository. Platform integrity/obfuscation hardening remains SEC-003. Client integrity checks must never replace server-side authorization.

### Network interception

All future application-owned networking must use TLS. Third-party SDK endpoints are partly controlled by their providers. Any future authenticated first-party API must use scoped tokens and server-side authorization.

### Secret leakage

Secrets may leak through source, CI, logs, screenshots, or diagnostics. ENG-010 provides source-control guards, redaction, approved secret-storage rules, and mandatory rotation after suspected exposure. Pattern redaction is defense in depth, so callers must still avoid logging credentials.

### Diagnostic and privacy leakage

Diagnostics may contain paths, exception text, tokens, or other sensitive values. Current logs remain local-only and use `SecretRedactor` before memory, file, debug output, runtime broadcast, or clipboard copy. Remote crash reporting remains disabled until ENG-013/PRIV-001 gates permit it.

### Dependency and supply-chain risk

Dependencies can introduce vulnerable code or unexpected data collection. Current CI validates secret hygiene, privacy inventory, assets, formatting, analysis, tests, and debug builds. Automated vulnerability/license scanning remains SEC-002/ENG-006.

### Malicious or malformed state/input

Persisted values, manifest metadata, route actions, repeated taps, and missing assets can produce unsafe state transitions. Current typed registries, progress clamps, navigation/gameplay race guards, and asset fallbacks reduce this risk. External/deep-link inputs must receive dedicated validation as they are introduced.

### Advertising boundary and consent

Google Mobile Ads is explicitly external and can be disabled through configuration. PRIV-001 records the processor. Production consent and regulated-region handling remain a blocking ADS-007 responsibility and must be accurately mapped in PRIV-002.

## Secure storage rules

- Do not place signing keys, passwords, refresh tokens, private keys, service-account data, backend API secrets, or store credentials in SharedPreferences or Dart source.
- SharedPreferences is acceptable only for non-secret local game state and preferences.
- If future account/session tokens are introduced, choose platform-backed secure storage and document lifecycle/rotation; do not silently reuse SharedPreferences.
- Release credentials belong in approved local/CI secret stores described by `docs/SECRET_HANDLING.md`.

## Tamper assumptions

The game must continue to handle malformed local state safely, but it does not claim offline client state is tamper-proof. Any future competitive, purchased, or remotely valuable entitlement must be validated by an authoritative backend before it can affect server-side value.

## Security logging and incident response

- Never reproduce exposed secrets in tickets or evidence.
- Rotate credentials after suspected exposure; deleting the latest source line is insufficient.
- Keep diagnostic redaction enabled before persistence/copy.
- Security-relevant build failures must remain blocking rather than converted to warnings.

## Follow-up ownership

- SEC-002: dependency, secret, and artifact scans.
- SEC-003: obfuscation, integrity, and release hardening.
- REL-006: release signing/key-management procedure.
- REL-004: storage corruption backup/recovery.
- ADS-007: ad consent/privacy controls.
- PRIV-002: policy and Play Data Safety mapping.
- TEST-011: privacy/consent/security verification.

SEC-001 defines the baseline and assumptions; it does not claim those follow-up gates complete.
