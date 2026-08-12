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

## Candidate trial record

### Thermion staging trial — rejected for this checkpoint

The active branch briefly staged `thermion_flutter ^0.4.1` and `vector_math ^2.2.0` as a renderer-candidate dependency trial. The lockfile resolved, but the exact staged head did not pass the repository's existing verification boundary:

- normal Flutter CI run `31536669561` failed at `Verify dynamic Android targets` before the rest of the release gates could execute;
- focused RT3D-002 run `31536669464` passed the machine contract, mutation tests, formatting and package restore, then failed at the focused Flutter domain-test step;
- the dependency staging was therefore rolled back rather than weakening existing CI to accommodate an unproven renderer candidate;
- temporary dependency-resolution and rollback helper workflows were removed after use.

This is a rejection of the staged integration state, not a blanket claim about what a future differently integrated or differently versioned renderer can or cannot support. A future candidate must start from the green baseline and pass the same gates without suppressing them.

No production renderer is selected by this checkpoint. Remaining candidate results stay PENDING until repository-backed evidence exists.
