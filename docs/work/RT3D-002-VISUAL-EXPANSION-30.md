# RT3D-002 — Native Filament visual expansion 30

Issue: #222  
Priority: P0 VISUAL DELIVERY  
Checkpoint: RT3D2-T081 through RT3D2-T110  
Branch: `agent/rt3d-002-visual-expansion-30`

## Goal

Deliver 30 owner-visible improvements in the actual Native Filament scene. No numbered task is documentation-only; every task adds geometry/material detail that must be visible through `Home -> 3D -> 3D VISUAL LAB` in the retained root APK before handoff is complete.

## 30 visual tasks

- [x] RT3D2-T081: Add a second sorting-depot building to expand the delivery district.
- [x] RT3D2-T082: Add a separate depot roof cap for stronger silhouette/readability.
- [x] RT3D2-T083: Add a dark depot loading door.
- [x] RT3D2-T084: Add a bright depot sign panel.
- [x] RT3D2-T085: Add a separate office building on the opposite side of the yard.
- [x] RT3D2-T086: Add an office roof cap.
- [x] RT3D2-T087: Add four visible office window panels.
- [x] RT3D2-T088: Add a west sidewalk ribbon.
- [x] RT3D2-T089: Add an east sidewalk ribbon.
- [x] RT3D2-T090: Add a north sidewalk ribbon.
- [x] RT3D2-T091: Add a six-bar north zebra crossing.
- [x] RT3D2-T092: Add a six-bar south zebra crossing.
- [x] RT3D2-T093: Add a dedicated parking slab.
- [x] RT3D2-T094: Add five parking-bay divider stripes.
- [x] RT3D2-T095: Add four orange hazard-cone blocks at the loading edge.
- [x] RT3D2-T096: Add four protective bollards around the delivery lane.
- [x] RT3D2-T097: Add a traffic-light pole.
- [x] RT3D2-T098: Add a high-contrast traffic-light head.
- [x] RT3D2-T099: Add the left checkpoint-arch post.
- [x] RT3D2-T100: Add the right checkpoint-arch post.
- [x] RT3D2-T101: Add the checkpoint-arch top beam.
- [x] RT3D2-T102: Add three more toy trees around the expanded district.
- [x] RT3D2-T103: Add four hedge blocks around the office.
- [x] RT3D2-T104: Add a visible street bench.
- [x] RT3D2-T105: Add a visible trash bin.
- [x] RT3D2-T106: Add two more street lamps in the expanded area.
- [x] RT3D2-T107: Add two visible vehicle headlights.
- [x] RT3D2-T108: Add two visible vehicle taillights.
- [x] RT3D2-T109: Add vehicle roof beacon, rear bumper, and cargo rack details.
- [x] RT3D2-T110: Add four corner markers to each delivery target for instant target readability.

## Asset/result contract

- Project-owned deterministic GLB revision: `visual expansion v3`.
- Expected GLB SHA-256: `5de93589908d375446567cd84aa84dcba496a705538cec37c098f82440b480b2`.
- Expected GLB byte length: `19712`.
- Generator output: 124 visible nodes and 25 PBR material/mesh variants.
- Stable gameplay entity IDs remain unchanged (`cargo.demo.*`, `delivery.*`, `vehicle.player`).
- Google Filament 1.74.0 and the current Android PlatformView bridge remain unchanged.
- No third-party model content is introduced.

## Owner-visible result

The scene should read as a small toy delivery district rather than a sparse yard: two work buildings, sidewalks, zebra crossings, parking, safety props, a checkpoint, street furniture/landscaping, more vehicle detail, and clearer target zones.

## Handoff boundary

Source/PR CI is not enough. Completion requires: PR gates -> merge -> exact-main Flutter CI -> governed `Last verified APK` promotion -> `LATEST.txt` source SHA matches the merged visual-expansion commit. Physical-device FPS remains separate evidence and is not invented here.
