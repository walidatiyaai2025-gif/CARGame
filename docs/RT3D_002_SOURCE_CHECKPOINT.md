# RT3D-002 source checkpoint summary

The first 30 tasks are source-controlled readiness work for the native 3D slice. They do not complete RT3D-002.

Delivered:

- fail-closed production renderer admission policy;
- native GPU requirement and WebView/projected fallback exclusion from production admission;
- stable Flutter, Android and minSdk 23 compatibility gates;
- GLB/PBR/lighting/shadow/picking/transform/camera capability gates;
- governed GLB/GLTF production model descriptor contract;
- provenance requirement and local runtime model path policy;
- mandatory vehicle/cargo/environment/target/ground/road first-scene roles;
- multiple-cargo and scene-reference integrity rules;
- bounded camera, lighting and mobile render budgets;
- focused Dart tests;
- machine validator and mutation tests;
- dedicated GitHub Actions contract workflow;
- explicit next-checkpoint and owner-facing APK acceptance boundary.

Still pending under RT3D-002:

- select and admit a real production renderer dependency;
- integrate that renderer behind `Realtime3dScenePort`;
- admit real licensed/provenanced GLB/GLTF model binaries;
- render the native scene in-app;
- prove interaction and mobile performance on the runtime;
- merge green main and promote the exact source to the root retained APK.
