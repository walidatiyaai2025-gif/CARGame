# RT3D-003 — Current-main cinematic polish refresh

Issue: #227
Priority: P0 VISUAL

## Baseline

- Refresh branch starts from exact current `main` after GAME-017 + WORLD-009.
- Preserve Filament 1.74.0, native PlatformView architecture, interaction entity IDs, world coordinates, gameplay, save/economy, ads/privacy, and cargo target truth.
- Port only the isolated deterministic cinematic GLB generator work from the stale RT3D-003 branch, regenerate the project-owned GLB, and verify zero-diff determinism before adding camera/runtime changes.

## Current checkpoint

- Cinematic GLB generator is now based on current main.
- Regenerated project-owned GLB is pinned to SHA-256 `b727b594612452a9a3723aa64423ee5d18a9b90567aba191d9a035bf888de157`.
- Validator/provenance migration is being applied so the RT3D contract verifies the new emissive materials, vehicle detail, road arrows, traffic signals, pallet/skyline dressing and delivery rims instead of the stale RT3D-002 node set.

## Next gates

1. Regenerated GLB and generator contract.
2. Native bloom and deterministic camera presets.
3. HUD/semantics and reduced-motion behavior.
4. Focused validator + full Flutter CI + Android APK security.
5. Exact-main merge and retained Last verified APK evidence.
