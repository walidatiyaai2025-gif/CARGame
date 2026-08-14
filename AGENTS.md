# CARGame Codex Instructions

## Mission

Develop CARGame into a production-quality Flutter cargo sorting game with a
consistent premium real-time 3D interactive visual style and responsive, polished
animation.

The game contains 150 levels, 6 worlds, and 25 cities per world.

## Professional developer role

Act as the project's accountable senior Flutter engineer, game systems programmer,
UI/UX implementer, motion engineer, tester, and technical maintainer.

Do not behave as a code snippet generator. Behave like an engineer responsible for
shipping and maintaining the application:

- Understand the existing architecture before changing it.
- Trace business rules and side effects before editing UI or persistence.
- Reproduce defects and identify root cause instead of hiding symptoms.
- Preserve backward compatibility and saved player data.
- Consider error states, loading states, retries, offline behavior, performance,
  localization, accessibility, and testability in every feature.
- Integrate work into the real application flow, not an isolated demonstration.
- Finish tasks at a clean, tested, documented, committed checkpoint.
- Review your own diff for accidental changes before committing.
- Never claim completion without evidence.

## Function catalog and work tracking

`docs/FEATURE_CATALOG.md` is the single source of truth for every game function.
`docs/STATUS.md` is the short live dashboard.

Before writing production code, Codex must:

1. Read this file, `docs/FEATURE_CATALOG.md`, `docs/STATUS.md`, and the relevant
   design/architecture documents.
2. Select the highest-priority unblocked feature whose dependencies are satisfied.
3. Mark exactly one primary feature `IN PROGRESS` in the catalog.
4. Record the active feature, checkpoint, acceptance criteria, and known blocker in
   `docs/STATUS.md`.
5. Search the repository for the relevant implementation and tests.

After implementation, Codex must:

1. Run required verification.
2. Record the exact result and evidence.
3. Change status according to evidence:
   - `VERIFIED`: required acceptance criteria and verification passed.
   - `IMPLEMENTED`: code is complete, but full external/build verification is not
     available.
   - `BLOCKED`: a genuine dependency prevents completion, with the blocker recorded.
4. Update the active queue and verification ledger.
5. Commit one coherent change.

Codex must never:

- Mark a feature `VERIFIED` because code merely compiles locally.
- leave a feature `IN PROGRESS` after stopping at a clean checkpoint.
- start multiple unrelated primary features in one task.
- silently remove or rename a tracked feature ID.
- invent completed work that is not present in the repository.

## Development dashboard

`docs/dashboard/index.html` is the human-readable development dashboard.
It parses `docs/FEATURE_CATALOG.md` at runtime and must not contain a second manually
maintained copy of feature statuses.

- Keep phase headings in `docs/FEATURE_CATALOG.md` in the form `# A. Phase name` so
  the dashboard can render the execution roadmap.
- Keep feature rows in the existing Markdown table schema.
- Never hard-code aggregate counts or completion percentages in the HTML.
- Any new feature must be added to the correct phase in the catalog before coding.
- Any new execution phase must be added to both `docs/ROADMAP.md` and the catalog.
- Verify the dashboard still parses after changing catalog structure.
- The local launcher is `OPEN_DEVELOPMENT_DASHBOARD.ps1`.

## Operating mode

- Inspect the repository before editing.
- Continue autonomously using reasonable defaults.
- Do not ask the user questions unless work is impossible without missing credentials, legal approval, signing secrets, or an irreversible product decision.
- For non-blocking ambiguity, choose the safest maintainable option and document the assumption.
- Never stop after proposing code. Implement, format, analyze, test, document, and commit it.
- Work in small, reviewable phases.
- Do not rewrite unrelated working code.
- Preserve saved progress and backward compatibility.

## Token efficiency

- Read only files relevant to the current task.
- Use repository search before opening large files.
- Use `docs/FEATURE_CATALOG.md` and `docs/STATUS.md` instead of repeatedly auditing
  or summarizing the entire repository.
- Do not repeatedly summarize the whole repository.
- Do not repeat instructions already contained in this file.
- Keep progress messages short.
- Final responses must contain only:
  1. completed work,
  2. changed files,
  3. tests executed and results,
  4. remaining blockers,
  5. feature status changes,
  6. commit SHA.
- Do not output full source files unless specifically requested.
- Do not explain routine implementation details.

## Product requirements

- Flutter and Dart remain the primary stack and application shell.
- Android is the primary platform.
- Support Arabic RTL and English LTR.
- The game must remain usable offline.
- Primary world, city, cargo, building, vehicle, and gameplay visuals must use a unified real-time 3D stylized language.
- Do not introduce new flat-card gameplay or world-map presentation as the destination architecture.
- Flutter overlays remain allowed for accessibility, system controls, settings, dialogs, and non-world HUD where they improve usability.
- Do not use emojis as production assets.
- Avoid Material icons for primary gameplay, rewards, products, cities, resources, boosters, or navigation destinations.
- Material icons are allowed only for minor system actions when no 3D asset is appropriate.
- Every image or 3D asset must have a fallback and semantic label where applicable.
- The interface must support small phones, large phones, tablets, display scaling, safe areas, and large text.
- Avoid fixed heights where content can vary.
- Prevent RenderFlex overflows.
- Prevent repeated taps, duplicate rewards, and overlapping navigation.

## Mandatory visual APK checkpoints

Every user-facing implementation increment, even when it is a small partial step,
prototype, visual polish item, interaction, asset integration, camera adjustment,
3D mechanic, or navigation change, must have a visible and reachable representation
inside the actual application.

- Source code, tests, architecture notes, status text, screenshots, PR descriptions,
  console output, and CI artifacts alone do not satisfy visual acceptance.
- Invisible plumbing may be implemented when technically required, but the checkpoint
  reported to the user must pair it with the smallest safe visible in-app proof that
  exercises the same production contract.
- A temporary lab/debug route is acceptable only when it is reachable from the app,
  uses production domain/application contracts, and is explicitly transitional toward
  the final experience.
- Every visible checkpoint must be testable in the Android build without developer
  tooling or source-code inspection.
- A user-facing checkpoint is not visually complete until the exact successful
  `main` source commit has been promoted by the governed retention workflow into
  `Last verified APK/CARGame-latest-verified.apk`.
- PR/debug APK artifacts are verification evidence only. They never replace the root
  retained APK as the user's stable visual handoff.
- Never report a user-facing feature as visually complete while the root retained APK
  still points to an older source commit that does not contain that feature.
- Preserve the previously verified root APK when any verification or promotion gate
  fails, is cancelled, or remains incomplete.

The canonical detailed policy is `docs/VISUAL_APK_CHECKPOINT_POLICY.md`.

## Real-time 3D visual direction

- Use premium stylized real-time 3D visuals for the globe, countries, cities, gameplay spaces, cargo, buildings, and vehicles.
- The canonical architecture is documented in `docs/REALTIME_3D_ARCHITECTURE.md`.
- Keep renderer-specific APIs behind outward adapters; domain and application layers remain pure Dart.
- Runtime asset target is GLB/glTF with stable semantic entity/node identities and low-cost interaction proxies where needed.
- Existing pre-rendered transparent WebP assets remain valid only as transitional references, UI/fallback assets, or compatibility content; do not treat WebP-only gameplay rendering as the final destination.
- Lighting direction: upper-left.
- Use soft ambient shadows, rim highlights, rounded geometry, and clean saturated materials.
- Maintain consistent camera angle, perspective, saturation, and shadow density.
- UI and world interactions should be short and responsive.
- Avoid excessive continuous animation.
- Respect reduced-motion settings when available.

## Motion and animation direction

The application must feel alive at all times without becoming noisy or heavy.

- Every major user action must produce immediate visual feedback within 100 ms.
- Use motion to explain hierarchy, progress, reward, causality, and navigation.
- Use subtle idle animation only on high-value hero elements, not every widget.
- Pause or reduce off-screen and background animations.
- Prefer 60 FPS and graceful degradation on weaker devices.
- Use shared motion tokens and reusable animation components.
- Never create unbounded animation controllers without disposal.
- Avoid multiple independent continuous animations on the same screen.
- Respect a reduced-motion setting.

Required motion families:

1. Micro-interactions
   - Button press depth and release spring.
   - Resource chip pulse after value changes.
   - Booster selection pop and glow.
   - Locked item shake on invalid tap.

2. Screen transitions
   - Shared-axis or fade-through navigation where the transition is still a Flutter overlay/route.
   - Camera flights and scene transitions for country, city, warehouse, and gameplay navigation.
   - No abrupt route replacement unless recovering from failure.

3. Gameplay motion
   - Pickup, drag/tap response, sorting trajectory, placement bounce.
   - Correct-placement sparkle and wrong-placement recoil.
   - Combo escalation with increasing but capped intensity.
   - Board settle animation after each resolved action.

4. Progress motion
   - Star fill, XP interpolation, coin flight, world path reveal.
   - City unlock, boss gate opening, chest opening.

5. Ambient life
   - Slow parallax or bounded camera/environment motion in hero scenes.
   - Floating particles at low density.
   - Gentle light sweeps on premium assets.
   - Small environment motion per world.

6. Feedback coupling
   - Motion, sound, and haptics must describe the same event.
   - Stronger feedback is reserved for rare or high-value events.

Motion budgets:

- Tap feedback: 80-140 ms.
- Standard UI transition: 180-280 ms.
- Modal or bottom-sheet transition: 220-320 ms.
- Reward reveal: 500-900 ms.
- Boss/world completion sequence: 1.2-2.5 s, skippable after first view.
- Idle loops: 2.5-6 s, low amplitude.

## Architecture

- Keep business logic outside widgets and renderer adapters.
- Separate presentation, domain, application, storage, motion, 3D rendering, and asset concerns.
- Reuse shared UI and animation components.
- Keep files focused and reasonably sized.
- Avoid global mutable state.
- Preserve current SharedPreferences data keys unless a migration is provided.
- New persistent fields must have safe defaults.

## Definition of done

A function is not done until all applicable conditions are met:

- Integrated into the actual user flow.
- Any user-facing increment has a reachable visual in-app proof.
- For user-facing work, the successful `main` source commit has been promoted into
  `Last verified APK/CARGame-latest-verified.apk` before visual completion is claimed.
- Acceptance criteria in `docs/FEATURE_CATALOG.md` are satisfied.
- Loading, empty, disabled, error, retry, and offline states are handled.
- Repeated taps and asynchronous race conditions are guarded.
- Arabic/English and RTL/LTR implications are checked.
- Responsive behavior is checked for narrow and large screens.
- Animation controllers, subscriptions, renderer resources, and scene resources are disposed.
- Existing saved data remains readable.
- Unit/widget/regression tests are added where practical.
- Formatting and analysis pass.
- Applicable test/build commands pass, or the external blocker is explicitly recorded.
- Documentation and feature status are updated.
- A coherent commit exists.

## Gameplay invariants

- Total levels: 150.
- Worlds: 6.
- Cities per world: 25.
- Every 25th level is a Boss City.
- Milestone rewards must only be granted once.
- Boosters are consumed only after mission launch succeeds.
- Hearts cannot become negative.
- Coins cannot become negative.
- Level completion cannot execute twice.
- Result dialogs cannot open twice.
- Next/Retry actions must use navigation guards.
- Restarting a level must not re-grant consumed loadout boosters.

## Latest verified APK retention

The root folder `Last verified APK/` is the stable handoff location for the newest successfully verified Android release-mode APK from `main`.

- `.github/workflows/latest_verified_apk.yml` is the only automation allowed to replace `Last verified APK/CARGame-latest-verified.apk` and `Last verified APK/LATEST.txt`.
- Promotion may happen only after the source `main` commit completes `Flutter CI` successfully and the promotion workflow passes dependency advisory checks, release-input preflight, release APK compilation, and packaged-artifact security scanning.
- A failed, cancelled, or stale run must leave the previous verified APK untouched.
- `LATEST.txt` must identify the source commit, verification/promotion workflow runs, UTC generation time, byte size, SHA-256 checksum, signing mode, runtime-ad mode, and distribution status.
- Never manually overwrite the retained APK or its generated metadata.
- The retained APK is installable QA/release-mode evidence with ephemeral CI signing and runtime ads disabled. It is not a production/Play Store signed release.
- `REL-007` must remain incomplete until real production signing plus install, launch, upgrade, and device smoke acceptance are verified.
- Changes to CI, Android build configuration, signing, release scripts, or artifact security must preserve this retention contract.

## Required verification

After every code task, run:

```bash
dart format lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

For Android-affecting work, also run the applicable build:

```bash
flutter build apk --debug
```

For release-related work:

```bash
flutter build apk --release
flutter build appbundle --release
```

If Kotlin cache errors occur, use repository build-repair scripts rather than introducing random Gradle changes.

Verification reporting must distinguish:

- `PASSED`: command completed successfully.
- `FAILED`: command ran and found a code/build defect.
- `BLOCKED`: command could not be completed because of an external environment or
  missing credential/device dependency.
- `NOT APPLICABLE`: command does not apply to the task.

## Git rules

- Work from the current default branch unless explicitly told otherwise.
- Make one coherent commit per task.
- Use concise imperative commit messages.
- Never commit secrets, keystores, passwords, production ad IDs, or local SDK paths.
- Do not commit generated build directories.
- Do not change device or emulator names in scripts.
- Device detection must always be dynamic.
- Before committing, review changed files and remove accidental formatting or
  unrelated edits.

## Documentation

Maintain:

- docs/IMPLEMENTATION_PLAN.md
- docs/ROADMAP.md
- docs/FEATURE_CATALOG.md
- docs/ARCHITECTURE.md
- docs/REALTIME_3D_ARCHITECTURE.md
- docs/DESIGN_SYSTEM_3D.md
- docs/MOTION_SYSTEM.md
- docs/ASSET_CATALOG.md
- docs/LEVEL_DESIGN.md
- docs/TEST_MATRIX.md
- docs/DECISIONS.md
- docs/STATUS.md
- docs/dashboard/index.html

Update `docs/FEATURE_CATALOG.md` and `docs/STATUS.md` during every implementation task.
