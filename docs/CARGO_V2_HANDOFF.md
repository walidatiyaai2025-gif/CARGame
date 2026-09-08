# CARGO V2 AUTONOMOUS CLOSURE HANDOFF

Updated: 2026-09-08 (Kuwait)

## Authority and truth boundary

- Single CARGO V2 integration/closure line: PR #297, branch `cargo-v2-autonomous-closure`, targeting `cargo-v2`.
- The exact live PR #297 head is authoritative; this document records the implementation/evidence basis rather than pretending a documentation commit can hard-code its own resulting SHA.
- Implementation/evidence basis immediately before this documentation reconciliation: `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`.
- `cargo-v2` staging base at that read: `80ab461e5920420a82e924d97ca5a26418fb04fc`.
- `main` is not the CARGO V2 integration target at this stage.
- PR #298 / `cargo-v2-unity-runtime-ci` is the sole Unity runtime/build support PR. It targets #297 and is not a second closure candidate.
- PR #309 / `cargo-v2-worldmap-deploy-cta-polish` is the only current non-support CARGO V2 source PR found in the open-PR sweep. It remains draft and must not be merged without required exact-head/runtime/visual evidence.
- Live GitHub refs, ancestry, exact-head checks, artifacts, and executed runtime evidence override historical prose.

## Convergence completed in this cycle

PR #308 was normal-merged into the authority as `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`. It made integration preview readiness fail closed, wired that validation into the governed Unity build path, and preserved the stronger delivery-recovery persistence invariant.

The runtime support line was then reconciled without force-push. Support commit `7aeff619f1421c1b4d1c1acc481867855d8d1e79` has merge-base exactly `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`, is 0 commits behind that authority basis, and differs from it by exactly one file: `.github/workflows/cargo_v2_unity_runtime.yml`.

No historical gameplay, visual, persistence, reliability, Android-smoke, fleet/economy, mission/data/logic/world-map/runtime-asset or team branch is promoted merely because it still exists. The previous full ancestry/semantic sweep found those implementation lines contained or superseded. Branch deletion is not performed without an explicit repository governance rule authorizing it.

## Exact source/scaffold evidence on the implementation basis

On `cc7cd79b174511b59232d7b4bf8b898dfa5bd9fa`:

- CARGO V2 Hostile State Guard #19 / run `34191496613`: SUCCESS.
- CARGO V2 Player Experience Guard #14 / run `34191496585`: SUCCESS.
- CARGO V2 Unity Scaffold #102 / run `34191496579`: SUCCESS.
- Flutter CI #1312 / run `34191496576`: executing at the evidence read; full test suite and coverage had passed and the job had advanced to its debug-APK build stage. Its final conclusion must be read from GitHub and must not be inferred here.

For PR #309 exact source head `17302145f153f7a5b99dd60bf6da9c07fe1a20ab`:

- WorldMap Deploy CTA Guard #2 / run `34191576245`: SUCCESS.
- Runtime Contract Name Guard #7 / run `34191576251`: SUCCESS.
- Unity Scaffold #103 / run `34191576239`: SUCCESS.
- Flutter CI #1313 / run `34191576249`: executing at the evidence read.

Those are source/scaffold results only. They do not constitute Unity visual/runtime acceptance.

## Current Unity runtime/build evidence

PR #298 support head `7aeff619f1421c1b4d1c1acc481867855d8d1e79` triggered CARGO V2 Unity Runtime Build #9 / run `34191746281` against PR merge candidate `c6fe90150313f9a609db8928d48cab38d46fbd2a`.

Observed execution:

- checkout exact candidate: PASS;
- Unity activation preflight: FAIL-CLOSED;
- Unity import/build: SKIPPED;
- APK verification/evidence: SKIPPED;
- APK upload: SKIPPED;
- diagnostics upload: PASS.

The diagnostic preflight recorded, without exposing secret values:

- `UNITY_LICENSE`: not configured;
- `UNITY_SERIAL`: not configured;
- `UNITY_EMAIL`: not configured;
- `UNITY_PASSWORD`: not configured.

Diagnostic artifact:

- id `10042441917`;
- name `CARGO-V2-Unity-diagnostics-c6fe90150313f9a609db8928d48cab38d46fbd2a`;
- digest `sha256:070e8c1ce015a24ca7e843d10a4ce15d2198c2350ee60de65bfab70fe397a430`.

This is a persistent external activation-configuration blocker, not evidence of a CARGO V2 code regression and not a transient infrastructure failure. Re-running the same gate without a configuration change is not justified as a transient retry.

## Governed Android build contract verified from live source

`Assets/_Project/UI/Editor/SCR_CargoV2Build.cs` sets the production test-build contract at build time:

- product `CARGO V2`, company `WALKA`;
- application identifier `com.walka.cargov2`;
- version `2.0.0`, version code `20000`;
- minimum SDK 23;
- Landscape Left;
- ARM64 only;
- IL2CPP;
- Linear color space;
- APK output (`buildAppBundle=false`);
- `BuildOptions.None` (no development build flag).

`BUILD_CARGO_V2_UNITY.ps1` pins Unity `2022.3.75f1`, runs the governed validation/build methods, rejects non-ARM64 native payloads, and emits SHA-256 evidence only after a real APK exists.

## Remaining hard gates

The final exact candidate still needs genuine executed evidence for:

1. Unity 2022.3.75f1 import and C# compilation.
2. Unity validation and Play Mode startup/navigation.
3. Splash -> Loading -> WorldMap -> deploy -> pickup -> ordered checkpoints -> delivery -> settlement -> next unlock.
4. Persistence/restart/crash recovery and replay/idempotency regressions.
5. Fleet purchase/upgrade runtime acceptance and non-negative economy invariants.
6. Real 3D Resources import, scale/orientation/material/fallback and visual acceptance.
7. Measured current-candidate performance/FPS and memory/runtime stability.
8. ARM64/IL2CPP Unity APK build with recorded SHA-256.
9. APK install/launch and available device/emulator smoke.
10. Final repository convergence and exact-target CI after every integration.

Only after all applicable source/runtime/build/smoke gates are genuinely green and an installable final 3D APK exists may the project enter `FINAL_OWNER_3D_TEST_REQUIRED`.

## Pick-next rule

Re-read live state before every operation. Recover legitimate existing work first, preserve unrelated work, keep PR #298 as the sole runtime-support line, keep PR #309 draft while runtime/visual evidence is absent, and never substitute Flutter/scaffold/static evidence for Unity/device evidence.
