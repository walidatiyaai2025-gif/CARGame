# RT3D-002 renderer candidate scorecard

Use this scorecard before dependency admission. Documentation claims are not sufficient; the integration must pass dependency governance, Android CI, in-app visual evidence, and root-APK promotion before the candidate is accepted as the production path.

## Candidate 1 — Thermion 0.4.1

| Gate | Result |
|---|---|
| Stable Flutter / dependency staging | REJECTED |
| Existing repository verification | REJECTED |
| Decision | Do not weaken existing gates; candidate staging was rolled back. |

The Thermion staging trial failed the existing CARGame verification boundary and was removed. The source-controlled renderer contract remained intact.

## Candidate 2 — three_js 0.3.0

| Gate | Required evidence | Current result |
|---|---|---|
| Native GPU | No WebView/model-viewer gameplay surface | STAGED |
| Stable Flutter | Repository Flutter 3.44.8 dependency resolution | PASSED |
| Android | Normal CARGame Android debug build | PENDING |
| Local GLB | Packaged GLB loads through governed asset path | PENDING |
| PBR/material response | Runtime lit 3D materials | STAGED |
| Lighting | Key + ambient scene lighting | STAGED |
| Shadows | Mobile scene shadows | STAGED |
| Picking | Existing RT3D screen-ray cargo picking drives scene | STAGED |
| Transforms | Existing RT3D drag/snap/return transforms drive mesh | STAGED |
| Camera | Runtime orbit camera | STAGED |
| Licensing | Direct package license review | PASSED — MIT |
| Security | Dependency/security gates | PENDING CI |
| Build | Exact integration head passes normal Flutter CI | PENDING |
| Visual | App exposes `3D VISUAL LAB -> GPU -> NATIVE 3D` | STAGED |
| Root APK | Exact successful main source promoted to retained APK | PENDING |

`three_js` is not promoted to fully accepted production status until the pending build/security/visual handoff gates pass. Production GLB model admission remains the next content gate after this primitive native-runtime checkpoint.
