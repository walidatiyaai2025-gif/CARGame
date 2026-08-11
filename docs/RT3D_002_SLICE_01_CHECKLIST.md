# RT3D-002 Slice 01 visual readiness checklist

This checklist is intentionally narrower than the full RT3D-002 release blocker. It defines the evidence required before the first native scene may replace the projected visual lab as the owner-facing checkpoint.

## Renderer

- production renderer passes `Realtime3dRendererAdmissionPolicy`;
- renderer integration is behind `Realtime3dScenePort`;
- renderer works on the repository stable Flutter channel;
- Android minSdk remains 23 unless an explicit owner-approved compatibility decision changes it;
- object picking, transforms, camera control, PBR lighting and shadows are exercised in-app.

## Models

- vehicle model is local and admitted;
- at least one cargo model is local and admitted, instantiated as multiple cargo nodes;
- warehouse/environment model is local and admitted;
- delivery-target model is local and admitted;
- ground and road geometry are present;
- every binary has real provenance/licensing evidence and passes asset/security admission.

## Interaction

- the existing RT3D cargo controller performs pick -> drag -> compatible snap;
- wrong target returns cargo safely;
- missed drop returns cargo safely;
- renderer errors do not corrupt gameplay state;
- reduced-motion mode keeps interactions deterministic without decorative travel animation dependence.

## Mobile visual budget

- scene is inside the source-controlled triangle/draw-call/texture ceilings;
- expensive lighting/shadow choices have a bounded lower-quality fallback;
- no physical-device FPS, GPU-memory or thermal claim is recorded without an actual measured run.

## Owner-facing handoff

- scene is reachable from normal application navigation;
- normal Flutter CI is green for the exact final head;
- focused RT3D-002 CI is green for the exact final head;
- merged main is green;
- the exact successful main source is promoted to `Last verified APK/CARGame-latest-verified.apk`;
- the retained APK is the artifact used for visual review.
