# Issue #182 — Latest verified APK retention

## Goal

Keep `Last verified APK/` at repository root as a stable handoff location for the newest successfully verified Android release-mode APK produced from `main`.

## Implementation

- `Flutter CI` remains the source verification gate.
- `.github/workflows/latest_verified_apk.yml` listens only for successful `Flutter CI` completions from `main` push commits.
- It restores the locked dependency graph, checks dependency advisories, generates localization, runs the release-input preflight regression, creates an ephemeral CI signing key, validates release inputs, builds the release APK with runtime ads disabled, and scans the packaged APK for sensitive-artifact leakage.
- Promotion is fail-closed: immediately before writing the retained artifact, the workflow verifies that `main` still equals the source SHA. Stale, failed, or cancelled work leaves the previous APK untouched.
- The promoted file is `Last verified APK/CARGame-latest-verified.apk` and generated metadata is `Last verified APK/LATEST.txt`.
- The retained APK is installable QA/release-mode evidence only. It does not satisfy production signing or Play Store release acceptance.

## Tracking

This is an out-of-band release-infrastructure request while `TEST-003` remains the sole primary `IN PROGRESS` catalog feature. `REL-007` remains `PLANNED` until production signing and install/launch/upgrade/device smoke acceptance are complete.

## Verification

- Workflow YAML parsed locally with PyYAML.
- Embedded Bash steps passed `bash -n` syntax validation.
- Repository CI and the first automatic APK promotion must pass after merge before the retained binary itself is claimed as available.
