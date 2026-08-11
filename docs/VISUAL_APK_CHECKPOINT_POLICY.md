# Visual APK Checkpoint Policy

## Purpose

CARGame is now developed as a visually inspectable real-time 3D product. Engineering progress that changes gameplay, world presentation, camera behavior, interaction, animation, cargo, buildings, vehicles, effects, or 3D assets must be visible in an installable APK. Documentation, architecture notes, tests, or invisible plumbing alone are not sufficient evidence for a user-facing 3D checkpoint.

## Mandatory rule

For every user-facing implementation checkpoint, including small increments:

1. Add a reachable visual representation to the actual application flow.
2. Make the changed behavior observable without developer tooling.
3. Keep the representation responsive on supported phone sizes and usable offline.
4. Reuse production domain/application contracts rather than building a disconnected mock.
5. Run Flutter CI including formatting, Analyze, full tests, Debug APK build, artifact security, and upload.
6. Do not call the visual handoff complete until the successful `main` commit is promoted by `.github/workflows/latest_verified_apk.yml` into `Last verified APK/CARGame-latest-verified.apk`.

A pull-request APK artifact is useful verification evidence, but it does not satisfy the final root-APK handoff. The retained root APK remains the single stable installable preview for the user.

## Visual checkpoint surface

Until each real-time 3D subsystem is integrated into its final production scene, the application exposes a `3D VISUAL LAB` route. Temporary lab visualizations are allowed only when they:

- exercise the same production domain/application contracts used by the final renderer;
- are interactive rather than screenshots or static cards;
- clearly distinguish transitional projection/diagnostic rendering from the final native 3D runtime;
- are replaced by the production scene as soon as that subsystem is integrated.

The first lab checkpoint visualizes RT3D cargo picking, ray projection, drag-plane movement, delivery target compatibility, snap/return resolution, target hover feedback, and camera orbit.

## Pull-request evidence

Every user-facing 3D PR must state:

- the in-app entry point;
- what is visually different;
- what the user can interact with;
- the CI run that built the APK;
- the root APK source commit after promotion.

If a change cannot yet be represented visually, it may be tracked as engineering foundation work, but it cannot be presented to the user as a completed visual milestone.
