# CARGame Memory and Image Budget

PERF-002 defines source-controlled image-memory limits for the Android RC. These limits bound Flutter image-cache retention and manifest-backed decode sizes; they are not a claim about total process RSS or GPU memory on any specific device.

## Global Flutter image cache

`GameImageMemoryPolicy.standard` configures Flutter's shared `ImageCache` during startup with explicit ceilings:

- Maximum cached entries: **96**.
- Maximum cached decoded bytes: **48 MiB**.

The application-owned manifest precache remains separately bounded by the AST-004 LRU policy, whose default completed-entry limit is 24.

## Per-image decode budget

Manifest-backed images use descriptor-native dimensions plus the actual logical render size and device pixel ratio to choose a decode target.

Default limits:

- Maximum decoded bytes per image: **6 MiB**, estimated as width × height × 4 RGBA bytes.
- Maximum decode dimension: **1536 px** on the longest side.
- Layout-free/near-future precache target: **1024 physical px** on the longest side before stricter caps.
- Never upscale above the authored/native descriptor dimensions.
- Preserve source aspect ratio while choosing the decode target.

For display-backed images, `GameAssetView` forwards the resulting physical target through `cacheWidth` and `cacheHeight`. This keeps large authored images close to the pixels actually needed by the screen instead of decoding them at full source resolution.

## Fit behavior

- `contain` and `scaleDown`: choose the scale that fits inside the physical display box.
- `cover`: choose enough pixels to cover the physical display box while preserving source aspect ratio.
- `fitWidth` / `fitHeight`: follow the corresponding physical axis.
- `fill` / `none`: use the larger requested scale but still preserve the source aspect ratio and obey native/dimension/byte caps.
- Missing, zero, negative, or non-finite layout hints fall back to the bounded precache target.

## Precache behavior

Production precache wraps the manifest `AssetImage` in the same resize policy before calling Flutter `precacheImage`. AST-004 test injection retains the original `AssetImage` callback surface so race/LRU/failure regressions remain stable. Production eviction uses the matching resized provider key so bounded precache entries can be removed correctly.

## Safety boundaries

PERF-002 does not change gameplay, economy, persistence, ads, consent/privacy, analytics, navigation identity, package versions, asset provenance, or authored binary assets. Cache/decode state is presentation-only and local.

## Verification boundary

CI can prove deterministic sizing, explicit cache ceilings, bounded decode estimates, source ownership, AST-004 compatibility, and Android build safety. Total process RSS, GPU residency, memory pressure behavior, and low/mid/high device measurements require later physical-device/profile evidence and must not be inferred from these source budgets alone.
