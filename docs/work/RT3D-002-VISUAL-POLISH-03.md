# RT3D-002 — visual polish slice 03

Issue: #222  
Priority: P0 RELEASE BLOCKER  
Checkpoint: RT3D2-T061 through RT3D2-T080  
Branch: `agent/rt3d-002-visual-polish-slice-03`

## Goal

Make the already-admitted Android Filament scene materially richer and easier to read at a glance without changing gameplay/save/economy truth or introducing external art/licensing dependencies. This checkpoint remains owner-visible: it is not handed off until the exact successful main source is promoted into `Last verified APK/CARGame-latest-verified.apk`.

Runner regeneration checkpoint: PASSED — generated GLB is byte-for-byte aligned with the pinned digest before PR verification.

## 20 visual tasks

- [x] RT3D2-T061: Start from the exact retained-APK main head after native Filament handoff.
- [x] RT3D2-T062: Preserve Google Filament 1.74.0 and the existing native PlatformView bridge.
- [x] RT3D2-T063: Preserve stable cargo/delivery entity names used by `Realtime3dScenePort`.
- [x] RT3D2-T064: Keep the project-owned deterministic GLB workflow and offline loading.
- [x] RT3D2-T065: Add a second crossroad so the yard reads as a small delivery district rather than a flat strip.
- [x] RT3D2-T066: Add curb geometry around the drivable intersection.
- [x] RT3D2-T067: Add repeated high-contrast road stripe nodes for immediate depth/orientation cues.
- [x] RT3D2-T068: Add a dark warehouse loading door.
- [x] RT3D2-T069: Add a colored warehouse loading awning.
- [x] RT3D2-T070: Add visible delivery-pad pylons while keeping existing target nodes authoritative.
- [x] RT3D2-T071: Add a contrasting vehicle windshield material.
- [x] RT3D2-T072: Add four visible wheel nodes to the stylized delivery vehicle.
- [x] RT3D2-T073: Add upper cargo stack nodes to increase warehouse visual density.
- [x] RT3D2-T074: Add three low-cost toy trees using project-generated trunk/crown geometry.
- [x] RT3D2-T075: Add two low-cost street lamps with dedicated emissive-looking color treatment.
- [x] RT3D2-T076: Expand the GLB from 8 to 16 PBR material/mesh variants while remaining well below the 1 MB asset ceiling.
- [x] RT3D2-T077: Keep all added environment geometry non-interactive so gameplay hit/target truth does not drift.
- [x] RT3D2-T078: Pin the new deterministic GLB digest and updated provenance.
- [x] RT3D2-T079: Strengthen the native-slice verifier to require the visible polish nodes/counts.
- [ ] RT3D2-T080: Pass PR CI, merge, exact-main CI, and promote the exact successful source into the retained root APK.

## Expected owner-visible difference

Android `Home -> 3D -> 3D VISUAL LAB` should now show a denser toy-like delivery yard: intersecting roads, road markings/curbs, a readable warehouse entrance, a more recognizable wheeled vehicle, taller cargo stacks, trees, lamps, and existing interactive delivery targets.

## Truth boundary

No backend, economy, persistence, ads, or level-generation behavior changes. No third-party model content is introduced. Physical-device performance observation remains separate evidence; this checkpoint only claims source/build/package and root-APK handoff after those gates actually pass.
