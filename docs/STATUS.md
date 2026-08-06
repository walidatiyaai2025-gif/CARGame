# CARGame Live Project Status

This document is the short operational dashboard. Detailed tracking lives in `docs/FEATURE_CATALOG.md`; counts and percentages are calculated dynamically by the Developer Portal.

## Project objective

Build a production-quality Flutter cargo sorting game with 150 levels, 6 worlds, unified premium 3D visuals, responsive living motion, offline-first progress, Arabic/English support, measurable quality, privacy/security/legal readiness, and Android store release operations.

## Current work

| Field | Value |
|---|---|
| Current phase | A — Engineering foundation and baseline stabilization |
| Active primary feature | `ENG-002` Stable Android build toolchain |
| Active coupled feature | `REL-001` Dynamic ADB/device scripts |
| Status | IN PROGRESS |
| Branch | main |
| Planning audit | Completed; production coverage expanded and phases normalized to A–S |
| Next checkpoint | Finish repository-wide dynamic-device/build verification, then record the systematic baseline under `ENG-001` |

## Planning coverage audit — 2026-08-07

- Required phase count: **19** (`A` through `S`).
- Registered task count after audit: **190**.
- Status distribution at audit time: **54 IMPLEMENTED**, **3 READY**, **2 IN PROGRESS**, **131 PLANNED**, **0 VERIFIED**, **0 BLOCKED**.
- No task was promoted to `IMPLEMENTED` or `VERIFIED` by this audit.
- Existing implementation statuses remain preliminary until verified against acceptance evidence.
- Phase `O` is now Localization, `P` Accessibility, `Q` Performance/Reliability, `R` Testing/Quality Gates, and `S` Release/Privacy/Security/Legal/Store Readiness.

## Coverage added or strengthened

1. Environment/flavor configuration, secret handling, clean-machine developer tooling, dependency licensing, analytics schema, privacy-gated crash reporting, and offline service isolation.
2. Complete UI loading/empty/error/retry states, animation lifecycle/interruption safety, asset provenance/licensing, and asset CI validation.
3. Deep-link safety, onboarding/resume, world/level content versioning, gameplay interruption recovery, deterministic anti-spam state machine, and level authoring compatibility.
4. Reward/economy ledgers, idempotency/reconciliation, probability disclosure, versioned balance rules, optional cloud/billing boundaries, live configuration, notifications, clock-abuse safeguards, and social readiness.
5. Ad quality/no-fill behavior, audio rights/loudness/accessibility, locale formatting/translation QA, full accessibility scope, network/battery/app-size budgets, runtime/storage recovery.
6. Integration, compatibility, privacy/security, dashboard-parser, smoke/soak quality gates.
7. Privacy inventory/data safety/deletion, threat model/scans/hardening, legal notices/content rights, signing/key management, store assets/tracks, production monitoring/rollback, disaster recovery/archive, and final go/no-go.

## Phase overview

| Phase | Tasks | Current evidence state |
|---|---:|---|
| A Engineering foundation | 14 | 3 implemented, 1 ready, 1 in progress; governance and service boundaries added. |
| B Shared 3D design system | 9 | 3 implemented; shared states and accessibility requirements expanded. |
| C Motion and living interface | 10 | 1 ready; lifecycle/interruption safety added. |
| D 3D asset pipeline | 12 | 1 ready; provenance, rights, and CI validation added. |
| E Home and navigation | 10 | 7 implemented; onboarding/resume and external-entry safety added. |
| F Worlds/cities/map | 8 | 5 implemented; content migration/versioning added. |
| G Mission briefing/loadout | 6 | 4 implemented; accessible mission summary added. |
| H Core gameplay | 16 | 10 implemented; interruption recovery and deterministic anti-spam added. |
| I Level design/content | 8 | 2 implemented; schema/version compatibility added. |
| J Results/rewards | 8 | 5 implemented; transaction ledger, reconciliation, and odds rules added. |
| K Economy/progress/shop | 13 | 8 implemented; versioned balance and future sync/billing boundaries added. |
| L Retention/live content | 10 | 2 implemented; live config, notifications, clock safeguards, social readiness added. |
| M Ads/monetization | 9 | 1 implemented; analytics/quality/no-fill requirements added. |
| N Audio/haptics | 7 | Planned; licensing, loudness, and accessibility added. |
| O Localization | 6 | 2 implemented; locale formatting and translation QA added. |
| P Accessibility | 5 | Planned as a dedicated phase. |
| Q Performance/reliability | 11 | 2 implemented, 1 in progress; network/battery/app size/runtime/storage recovery added. |
| R Testing/quality gates | 12 | Planned; integration, device, parser, privacy/security, smoke/soak gates added. |
| S Release/privacy/security/legal/store | 16 | Planned as a complete production and operations gate. |

## Verification ledger

| Date | Scope | Verification | Result | Commit |
|---|---|---|---|---|
| 2026-08-07 | Planning coverage audit | Confirmed 19 phase headings A–S, 190 unique feature IDs, valid catalog table schema, and dashboard-compatible statuses. No production commands were required because the task changed documentation only. | PASSED — static catalog/dashboard parser compatibility | Planning audit commit sequence ending at current HEAD |
| Not recorded | Production baseline | A systematic format/analyze/test/build baseline has not yet been recorded under the new workflow. | Pending | - |

## Known high-priority risks

1. Two related tasks remain `IN PROGRESS`; the workflow should normally converge them to a clean status before starting unrelated production work.
2. Emulator/ADB instability and recurring Kotlin cache failures still require multi-machine verification.
3. Fifty-four features are marked `IMPLEMENTED` but none are `VERIFIED`; systematic regression evidence is required.
4. Current 3D presentation is primarily procedural Flutter styling; production assets, provenance, memory budgets, and commercial rights remain open.
5. Privacy, security, analytics, crash reporting, licensing, signing, store disclosures, monitoring, and rollback are now tracked but not implemented.

## Next ready work

1. Finish `ENG-002` and `REL-001` with repository-wide script audit and device/build evidence.
2. Complete `ENG-001` baseline audit and capture format/analyze/test/debug-build results.
3. Implement `MOT-001` shared motion tokens and lifecycle-safe primitives.
4. Implement `AST-001` taxonomy plus `AST-011` provenance rules before producing large asset packs.
5. Implement `TEST-001` economy/progress tests and `PRIV-001` before enabling analytics, personalized ads, cloud, or notification data flows.

## Last update

- Completed the full global-production planning coverage audit.
- Expanded the catalog to 190 measurable tasks across all mandatory phases A–S.
- Updated phase definitions, roadmap sequencing, implementation governance, and live status.
- No production feature implementation or evidence status was invented or promoted.
