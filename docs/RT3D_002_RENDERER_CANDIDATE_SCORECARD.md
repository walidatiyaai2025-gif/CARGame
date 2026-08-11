# RT3D-002 renderer candidate scorecard

Use this scorecard for each renderer candidate before dependency admission. A candidate is not accepted from documentation claims alone; the selected integration must still pass dependency governance, CI and the in-app interaction checkpoint.

| Gate | Required evidence | Result |
|---|---|---|
| Native GPU | Renderer does not depend on a WebView/model-viewer gameplay surface | PENDING |
| Stable Flutter | Compatible with the repository stable Flutter baseline | PENDING |
| Android | Android runtime support with required minSdk <= 23 | PENDING |
| Local GLB | Loads packaged local GLB assets | PENDING |
| PBR | Material pipeline supports PBR response | PENDING |
| Lighting | Dynamic/key + ambient scene lighting | PENDING |
| Shadows | Mobile-capable scene shadows | PENDING |
| Picking | Screen/ray or equivalent object picking | PENDING |
| Transforms | Mutable world transforms for drag/snap/return | PENDING |
| Camera | Runtime orbit/follow camera control | PENDING |
| Licensing | Package license passes repository dependency policy | PENDING |
| Security | No prohibited network/secret/runtime behavior | PENDING |
| Build | Exact integration head passes normal Flutter CI | PENDING |
| Visual | Real app scene exercises vehicle/cargo/environment interaction | PENDING |

No candidate is selected by this template. All results remain PENDING until repository-backed evidence exists.
