# Secret and Credential Handling

This document defines the CARGame credential boundary for local development, CI, release signing, diagnostics, and incident response.

## Core rule

No reusable secret belongs in Dart source, Android resources, iOS resources, repository documentation, committed JSON, screenshots, logs, or generated APK/IPA configuration.

Anything shipped to the client must be treated as public. A mobile application cannot safely hide a server API secret from a determined user.

## Configuration versus secrets

The typed build configuration under `lib/core/config/` carries environment selection and public client configuration.

Google Mobile Ads unit IDs are identifiers, not authentication secrets. Debug uses Google's public test IDs. Release IDs are injected at build time so environments remain explicit, but they must not be treated as a security boundary.

Signing passwords, private keys, service-account credentials, backend API secrets, refresh tokens, CI access tokens, and store credentials are secrets and must never be supplied through Dart defines or committed files.

## Approved storage

### Local development

Use developer-local files or environment variables that are excluded by `.gitignore`. Recommended local-only names include:

- `.env.local`
- `dart-defines.local.json`
- `*.credentials.local.json`
- `android/key.properties`
- files inside a local `secrets/` directory

Do not send these files through chat, issue attachments, screenshots, or repository commits.

### GitHub Actions

Store reusable release credentials in GitHub Actions Secrets or an approved external secret manager. Workflows should reference secret names only and must never echo their values.

Prefer short-lived credentials and least-privilege scopes. Separate staging and production credentials.

### Backend services

Any credential that authorizes privileged server actions belongs on the server. The client should receive scoped, expiring tokens only through an authenticated protocol when such services are introduced.

## Logging and diagnostics

`SecretRedactor` sanitizes application diagnostic text before it reaches:

- the in-memory log buffer,
- the persistent application log,
- `debugPrint`,
- runtime error broadcasts,
- the copyable diagnostics surface.

The redactor covers bearer credentials, common credential assignments, sensitive query parameters, private-key blocks, high-confidence standalone provider credential signatures, and user-profile paths. This is defense in depth; callers should still avoid logging credentials in the first place.

## Repository guard

Run before committing:

```powershell
dart run tool/verify_secret_hygiene.dart
```

The guard checks tracked files for high-confidence private-key/token patterns, credential-like assignments, forbidden signing files, local secret bundles, local credential JSON overrides, and user-profile absolute paths.

Focused policy regression:

```powershell
dart run tool/test_secret_hygiene.dart
```

Flutter CI runs both commands before dependency restore and the broader test/build gates. The regression harness verifies safe placeholders/public test IDs and confirms forced-tracked local credential files, environment overrides, signing material, and high-confidence token signatures fail closed.

Intentional redaction test fixtures may use the inline marker `secret-scan: allow`. The marker is for synthetic tests only and must not be used to permit a real credential.

## Rotation procedure

If a secret is suspected to have been exposed:

1. Revoke or rotate it at the provider immediately.
2. Replace the value in the approved secret store.
3. Remove the value from current repository content and artifacts.
4. Determine whether repository history, CI logs, issue attachments, build artifacts, or copied diagnostics contain the value.
5. Purge exposed artifacts where supported and invalidate any derived credentials.
6. Record the incident without reproducing the secret itself.
7. Run the repository secret guard and the full release verification pipeline.

Deleting a secret from the latest commit is not sufficient if it was previously published. Rotation is mandatory.

## Release checklist

Before a production release:

- secret hygiene verification passes;
- no signing material is tracked;
- production credentials are injected only from approved secret storage;
- release logs do not print secret values;
- client configuration contains no privileged server credential;
- environment-specific credentials use least privilege and documented owners;
- any credential changed since the previous release has a verified rotation record.
