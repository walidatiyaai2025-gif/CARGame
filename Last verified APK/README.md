# Last verified APK

This root-level directory is the project's stable handoff location for the newest **successfully verified Android release-mode APK** produced from `main`.

## Contract

- `CARGame-latest-verified.apk` is replaced only after the source commit passes the normal `Flutter CI` workflow and the promotion workflow then passes dependency advisory checks, release-input preflight, release APK compilation, and packaged-artifact security scanning.
- Failed, cancelled, or stale builds must never replace the existing APK.
- `LATEST.txt` records the source commit, workflow runs, generated UTC time, byte size, SHA-256 checksum, signing mode, and distribution status.
- The retained APK uses ephemeral CI signing and has runtime ads disabled. It is intended for installation/QA evidence only.
- It is **not** a production/Play Store signed release. `REL-007` remains subject to real production signing plus install/upgrade/device smoke acceptance.
- Do not manually overwrite the APK or metadata. The `.github/workflows/latest_verified_apk.yml` workflow owns promotion.

Issue #182 tracks this repository rule.
