# CARGame Codex Instructions

## Mission

Develop CARGame into a production-quality Flutter cargo sorting game with a
consistent premium 3D-rendered visual style and responsive, polished animation.

The game contains 150 levels, 6 worlds, and 25 cities per world.

## Operating mode

- Inspect the repository before editing.
- Continue autonomously using reasonable defaults.
- Do not ask the user questions unless work is impossible without missing credentials, legal approval, signing secrets, or an irreversible product decision.
- For non-blocking ambiguity, choose the safest maintainable option and document the assumption.
- Never stop after proposing code. Implement, format, analyze, test, and commit it.
- Work in small, reviewable phases.
- Do not rewrite unrelated working code.
- Preserve saved progress and backward compatibility.

## Token efficiency

- Read only files relevant to the current task.
- Use repository search before opening large files.
- Do not repeatedly summarize the whole repository.
- Do not repeat instructions already contained in this file.
- Keep progress messages short.
- Final responses must contain only:
  1. completed work,
  2. changed files,
  3. tests executed and results,
  4. remaining blockers,
  5. commit SHA.
- Do not output full source files unless specifically requested.
- Do not explain routine implementation details.

## Product requirements

- Flutter and Dart remain the primary stack.
- Android is the primary platform.
- Support Arabic RTL and English LTR.
- The game must remain usable offline.
- All primary visual elements must use a unified 3D-rendered style.
- Do not use emojis as production assets.
- Avoid Material icons for primary gameplay, rewards, products, cities, resources, boosters, or navigation destinations.
- Material icons are allowed only for minor system actions when no 3D asset is appropriate.
- Every image asset must have a fallback and semantic label.
- The interface must support small phones, large phones, tablets, display scaling, safe areas, and large text.
- Avoid fixed heights where content can vary.
- Prevent RenderFlex overflows.
- Prevent repeated taps, duplicate rewards, and overlapping navigation.

## 3D visual direction

- Use premium stylized 3D-rendered visuals, not a real-time 3D engine.
- Lighting direction: upper-left.
- Use soft ambient shadows, rim highlights, rounded geometry, and clean saturated materials.
- Maintain consistent camera angle, perspective, saturation, and shadow density.
- Prefer transparent WebP assets.
- UI animations should be short and responsive.
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
   - Shared-axis or fade-through navigation.
   - Hero transitions for city, chest, reward, and selected product.
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
   - Slow parallax in hero backgrounds.
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

- Keep business logic outside widgets.
- Separate presentation, domain, application, storage, motion, and asset concerns.
- Reuse shared UI and animation components.
- Keep files focused and reasonably sized.
- Avoid global mutable state.
- Preserve current SharedPreferences data keys unless a migration is provided.
- New persistent fields must have safe defaults.

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

## Git rules

- Work from the current default branch unless explicitly told otherwise.
- Make one coherent commit per task.
- Use concise imperative commit messages.
- Never commit secrets, keystores, passwords, production ad IDs, or local SDK paths.
- Do not commit generated build directories.
- Do not change device or emulator names in scripts.
- Device detection must always be dynamic.

## Documentation

Maintain:

- docs/IMPLEMENTATION_PLAN.md
- docs/ROADMAP.md
- docs/ARCHITECTURE.md
- docs/DESIGN_SYSTEM_3D.md
- docs/MOTION_SYSTEM.md
- docs/ASSET_CATALOG.md
- docs/LEVEL_DESIGN.md
- docs/TEST_MATRIX.md
- docs/DECISIONS.md
- docs/STATUS.md

Update docs/STATUS.md after every completed phase.
