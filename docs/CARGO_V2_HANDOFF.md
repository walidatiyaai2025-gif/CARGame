# CARGO V2 AUTONOMOUS CLOSURE HANDOFF

Updated: 2026-09-07 (Kuwait)

## Authority

- Authoritative integration/closure line: PR #297, branch `cargo-v2-autonomous-closure`, targeting `cargo-v2`.
- PR #298, branch `cargo-v2-unity-runtime-ci`, is the Unity runtime/build support gate for PR #297. It is not a second closure candidate.
- `main` remains outside the CARGO V2 integration step until the governed `cargo-v2` acceptance path is complete.
- Live GitHub refs, exact-head CI, artifacts, and executed runtime evidence override stale prose or historical PR descriptions.

## Reconciliation completed on 2026-09-07

The historical stacked CARGO V2 PRs #256, #257, #259, #265, #267, #268, #269, #271, #273, #275, #277, #279, #281, #283, #285, and #287 were individually compared against the PR #297 integration head. Each compared head was an exact ancestor of the closure line (`behind_by=0` with its own head as merge base), so those stale Draft PRs were closed as contained/superseded without creating duplicate merges or discarding commits.

PR #300 (`cargo-v2-company-transaction-recovery`) was reviewed on exact head `cf727f9b826f5a9b7af5e9a3cb11c4a3888ef2a6`, had all three applicable checks green, and was normal-merged into PR #297. The resulting pre-documentation reconciliation head was `7aa3e0642d645d257b1c1539442bc4d73aea0562`.

## Exact executed evidence at the pre-documentation reconciliation head

On `7aa3e0642d645d257b1c1539442bc4d73aea0562`:

- `CARGO V2 Unity Scaffold` run #28 / `34159261431`: SUCCESS.
- `Flutter CI` run #1232 / `34159261418`: SUCCESS.
- The scaffold workflow verifies the source-controlled Unity project/build scaffold and source-side recovery/verifier contracts. It does not constitute Unity Editor execution, Play Mode, Android build, install, launch, device smoke, FPS, or visual acceptance.

## Unity runtime/build support gate

PR #298 exact support head `080673f6b90b66a5cba2eafbb81709dddcd8db37` executed `CARGO V2 Unity Runtime Build` run #3 / `34157646725`.

The run failed closed during activation preflight before Unity started because all repository activation inputs observed by the job were absent:

- `UNITY_LICENSE`: not configured;
- `UNITY_SERIAL`: not configured;
- `UNITY_EMAIL`: not configured;
- `UNITY_PASSWORD`: not configured.

Therefore that run provides no Unity compile/import, Play Mode, APK, install/launch, device, FPS, or visual evidence. No credentials are invented or committed.

Diagnostic artifact from that execution:

- artifact id: `10031509477`;
- name: `CARGO-V2-Unity-diagnostics-5decf061b0402971a87cc32c140b4f6ae619c05d`;
- digest: `sha256:c0e862aa1669dc388223c11e6f6dd29e86da90f25ac5fc4dac6da4fd4610f493`.

## Integrated product scope already present on PR #297

The authoritative line contains the assembled CARGO V2 source chain for:

- Unity 2022.3.75f1 project scaffold and Android ARM64/IL2CPP build tooling;
- Splash and Loading presentation;
- 20-mission Cairo/Dubai WorldMap, selection, locking, persistence, touch input, and deploy flow;
- source-controlled 3D truck, Mission, and WorldMap OBJ/MTL assets with runtime `Resources` paths and fallbacks;
- playable truck driving, cargo pickup, ordered checkpoints, delivery, timer, damage, recovery, retry, pause, and abandon;
- active-delivery crash/restart recovery with run identity and corrupt-state quarantine;
- mission completion handoff, idempotent reward settlement, company progression, fleet purchase/selection, and upgrades;
- deterministic Android APK verifier and SHA-256 evidence contract.

## Remaining gates before final owner test

All of the following require genuine executed evidence on the final exact candidate; none may be inferred from source or scaffold CI:

1. Unity 2022.3.75f1 import and C# compilation.
2. Unity validation commands and Play Mode startup/navigation.
3. Full gameplay loop: WorldMap -> deploy -> pickup -> checkpoints 1/2/3 -> delivery -> settlement -> next unlock.
4. Persistence/restart/crash recovery and replay/idempotency regressions.
5. Fleet purchase/upgrade runtime behavior and non-negative economy invariants.
6. Real 3D Resources import, scale, orientation, materials, fallback behavior, and visual acceptance.
7. Android ARM64/IL2CPP APK build on the exact candidate with recorded SHA-256.
8. APK install and launch smoke, then device/emulator runtime smoke where available.
9. Performance/FPS evidence measured from an executed current candidate.
10. Repository convergence: all required checks green on the exact target head before governed integration.

Only after every automated/source/runtime/build gate above is green and an installable final 3D test APK exists may the project enter `FINAL_OWNER_3D_TEST_REQUIRED`.

## Pick-next rule

Before each new unit, re-read live PRs/branches/checks and recover legitimate existing work first. Do not duplicate PR #298 while it remains the active Unity-runtime support line. If activation remains unavailable, continue independent source-controlled verification, regression hardening, Android smoke automation, evidence reconciliation, and convergence work that does not require secrets; then re-check the runtime gate.
