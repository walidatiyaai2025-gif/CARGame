# CARGO V2 BUILD INSTRUCTIONS

CARGO_COMMAND_CENTER does not produce the final build. The integration stop point is a QA-gated PR/checkpoint on `cargo-v2` plus runtime evidence where the available environment can capture it.

## Before user merge to main
1. Confirm all intended team PRs are merged into `cargo-v2` by the CAPTAIN after QA evidence.
2. Confirm `docs/PROGRESS_REPORT.md` and `docs/QA_REPORT.md` match the exact `cargo-v2` head.
3. Confirm no unresolved blocker is classified as release-critical.
4. Confirm the visible CARGO V2 checklist items claimed complete have runtime evidence.

## User-controlled integration
1. Review `cargo-v2` versus `main`.
2. Merge `cargo-v2` into `main` when satisfied.
3. Run the repository's governed Flutter verification/build workflow from the resulting exact `main` head.

## Local verification commands
Use the repository's canonical developer workflow in `docs/DEVELOPER_WORKFLOWS.md`. Typical source verification is:

```bash
flutter pub get
flutter analyze
flutter test
```

Do not bypass existing signing, privacy, secret, asset, or release workflow gates.

## Final build ownership
Final APK/AAB production packaging, signing, store submission and `main` release promotion remain outside CARGO_COMMAND_CENTER per project command.
