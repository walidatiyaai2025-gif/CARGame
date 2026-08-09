# Security scanning policy

SEC-002 makes dependency, tracked-secret, and generated-artifact checks blocking CI gates. These controls supplement the mobile threat model; they do not replace code review, platform hardening, or release/device verification.

## 1. Tracked secret and signing-material scan

Normal Flutter CI continues to run:

```bash
dart run tool/verify_secret_hygiene.dart
dart run tool/test_secret_hygiene.dart
```

The scanner enumerates Git-tracked files, rejects tracked keystores/private-key material/local secret files, detects high-confidence credential patterns and credential-like assignments, and rejects machine-local user-profile paths. Production signing material and production ad credentials remain external to source control.

## 2. Locked dependency advisory scan

CI restores dependencies with the committed lockfile enforced:

```bash
flutter pub get --enforce-lockfile
python3 tool/verify_dependency_security.py --input-log <captured-pub-output>
```

`pub` is the authoritative advisory source for the resolved Dart/Flutter graph. The verifier fails when active GHSA advisories are reported unless an explicit exception is present in `tool/security_advisory_exceptions.json`.

`pubspec.yaml` must not use `ignored_advisories`, because that would suppress evidence before the repository policy can review it. The separate exception policy is intentionally visible and fail-closed.

### Advisory exception requirements

Each exception must contain exactly scoped review data:

- `id`: GHSA identifier;
- `package`: affected Dart package;
- `reason`: concrete reachability/mitigation rationale;
- `owner`: accountable reviewer/owner;
- `expiresAt`: UTC review expiry date (`YYYY-MM-DD`).

Expired, duplicate, malformed, package-mismatched, or stale exceptions fail CI. The baseline policy contains no exceptions.

## 3. Generated build-artifact scan

After the Debug APK is built and before it is uploaded, CI runs:

```bash
python3 tool/verify_build_artifact_security.py \
  build/app/outputs/flutter-apk/app-debug.apk
```

The scanner opens ZIP/APK entries and rejects forbidden signing/private-key file types, local secret/config files, `secrets/` content, private-key text, high-confidence credential/token patterns, and non-placeholder credential-like assignments.

The scanner deliberately does not scan arbitrary compressed binary bytes as text. It only content-scans bounded UTF-8 text candidates, which avoids random binary false positives. Expected Android signature containers such as `META-INF/*.RSA` are not treated as private signing keys.

## CI failure handling

A security scan failure must be fixed at the source. Do not weaken regexes, rename secrets, add silent ignores, or upload alternate artifacts to bypass a gate. If an upstream advisory is reviewed as non-exploitable, use the narrow time-bounded exception policy and remove the exception as soon as the advisory no longer appears.

## Scope boundaries

SEC-002 verifies repository secret hygiene, locked Dart/Flutter dependency advisories, and generated artifact leakage. It does not claim that release signing, Play integrity, obfuscation, runtime consent, user-data deletion, or production device testing are complete; those remain tracked by their dedicated catalog items.
