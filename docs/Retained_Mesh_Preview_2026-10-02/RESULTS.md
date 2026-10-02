# Mesh preview: implementation and qualification results

2 October 2026. Scatter **0.64 candidate**, native engine **0.25**. Accepted runtime evidence: isolated Max 2027 `run02`. The user's open artist session was not used for these fixtures, and the source scene was not saved or replaced.

The severe Mesh slowdown was primarily repeated CPU display work, rather than the placement calculation or triangle count alone. The old path transformed, shaded and submitted every displayed triangle on every redraw. The new path keeps each source group's geometry and accepted instance matrices in graphics buffers, and uses Autodesk's public instanced drawing interface. The same preview cache supplies both paths; geometry budgets and accepted instances are unchanged.

## Measured result

The unit below is **milliseconds per synchronous camera/redraw step**, measured around `viewport.setTM`, `completeRedraw` and posted-message processing. It is **not** a measurement of presented FPS, completed GPU time or mouse-to-photon latency. Smaller is better.

| Case | Accepted preview triangles | Old Mesh median | Retained Mesh median | Preview off median | Samples per arm |
| --- | ---: | ---: | ---: | ---: | ---: |
| Artist scene, 200,000 faces/layer | 842,324 | 278.07 ms | **15.34 ms** | 14.73 ms | 60 |
| Artist scene, 2,000,000 faces/layer | 9,955,989 | 3,163.39 ms | **16.94 ms** | 15.45 ms | 45 |
| Synthetic 200 dense cone instances | 870,400 | 220.03 ms | **7.47 ms** | 7.76 ms | 90 |
| Artist scene, 20,000,000 faces/layer | 61,696,972 | Not run | **34.07 ms** | Not run | 90 retained only |

The artist settings retain the 2,000-instances-per-layer limit. The face limit applies **per layer**, so total accepted triangles exceed one layer's limit. Counts above come from the native preview snapshot, not Max's viewport polygon overlay. The 61.7-million-triangle case is a retained-only stress sweep, not a paired speedup comparison.

The ordinary native-Max control for the same 200 cone instances took **10.18 ms median**. Its source topology, instance count and transforms were checked against the Cyrus fixture, including a triangle in world coordinates. Native Max uses different material/lighting code, so this is geometry parity, not identical shading. Small differences between retained and preview-off measurements are noise; these data do not show that adding geometry makes Max faster, or that Cyrus is universally faster than native Max.

| Case and arm | p95 | Maximum |
| --- | ---: | ---: |
| Artist 200k, old | 296.65 ms | 303.19 ms |
| Artist 200k, retained | 24.53 ms | 33.44 ms |
| Artist 200k, off | 28.82 ms | 32.13 ms |
| Artist 2M, old | 3,446.78 ms | 3,470.26 ms |
| Artist 2M, retained | 25.49 ms | 44.01 ms |
| Artist 2M, off | 27.29 ms | 48.43 ms |
| Synthetic, old | 237.67 ms | 247.19 ms |
| Synthetic, retained | 14.58 ms | 32.45 ms |
| Synthetic, native Max | 17.30 ms | 27.74 ms |
| Synthetic, off | 12.72 ms | 20.74 ms |
| Artist 20M, retained | 51.03 ms | 82.91 ms |

The paired tests assert unchanged cache-build counts, generation revision, explicit-upload count, failure count and fingerprint during navigation. The stress test asserts unchanged generation, uploads, failures and fingerprint; it does not independently assert the cache-build counter. Draw counters increase in both. These counters describe calls made by the plugin, not hidden driver work or GPU completion.

Increasing the artist preview from 2M to 20M faces/layer and completing its first update/redraw took **1,296.87 ms**. This was an edit in an already warm process, not a fresh-process startup measurement. Fast navigation does not eliminate mesh extraction, shader initialization or upload costs after an edit.

## Test conditions and evidence quality

- Host: 3ds Max 2027.1, version tuple `[29000,70,0,29,1,0,11426,2027,".1"]`, isolated PID 32228. The loaded Scatter and Edit module paths and hashes were verified.
- Hardware: Ryzen 5 5600X, GeForce RTX 3090; driver and memory details are in `evidence/environment.json`.
- Viewport: 1,302 × 750 pixels, default shading (`smoothhighlights`); adaptive geometry degradation disabled. Artist camera transform was preserved when changing to a single viewport. This does not qualify every viewport shading mode, resolution or camera route.
- Four warmup camera steps precede each timed paired arm. Old/off/retained order alternates between repetitions. Native control runs after those arms. Geometry changes, GC and warmups are outside the timed region. No compiler or other benchmark ran concurrently.
- The original artist process remained open and idle. These are controlled scripted redraw sweeps, not a foreground interactive input-latency capture or a frame-present trace.
- The artist scene was loaded from `Test Scene/SaveSelect 2.max`, 185,442,040 bytes, SHA-256 `c131c90b88abd7aad16a944170a4740f1c7e7f5f2f5412276627eb54d230c38c`. This is the scene revision for this loop; older reports have different historical hashes.

**Rejected evidence:** preliminary `run01` artist timings had the camera reset by a layout change, leaving the foliage outside the view. They were discarded. The final recipe captures the scene before timing, and the accepted initial, retained and legacy captures were visually inspected. The earlier 5,000-native-node experiment is exploratory: it has substantial scene/callback overhead and is not used for the headline comparison. Its cause needs separate profiling before optimization.

## Appearance, geometry and lifecycle

Captured image pairs show the same accepted content. They are not bitwise identical: GPU shader arithmetic and rasterization produce small edge/color differences. On the complete captured viewport:

| Pair | Mean absolute RGB-channel difference, 0–255 | Pixels with any channel differing by more than 8 |
| --- | ---: | ---: |
| Artist 200k | 0.0230 | 0.0566% |
| Artist 2M | 0.1041 | 0.5483% |
| Transform fixture, default shading | 0.0040 | 0.0088% |
| Transform fixture, wireframe | 0.0089 | 0.0102% |
| Synthetic dense cones | 0.0272 | 0.1007% |

Full-image statistics are descriptive, not a substitute for visual review or a universal quality threshold. Both default-shaded and wireframe captures retain the old Mesh preview's filled, two-sided, fixed-shading behavior. This change does not add renderer materials, UV textures or native edged-face rendering to the preview.

The runtime fixtures passed:

- **Mesh reuse:** 5,000 simple cone instances, 320,000 triangles, one retained source group; 90 camera steps without geometry uploads or cache rebuilds.
- **Updates:** Manual mode holds until refresh; explicit refresh and automatic updates publish the new generation. Source geometry and parameter undo/redo invalidate the appropriate display data.
- **Modes and visibility:** Mesh/Point Cloud/Proxy transitions, preview visibility, layer enable, controller hiding/unhiding, solid color and source-group color. No stale drawing after a mode change.
- **Ownership:** cloned controllers have independent transient owners; deletion cleans them up; four viewports reuse buffers; GC preserves live shared snapshots.
- **Persistence:** save/open strips and reconstructs transient helpers; the clean scene's dirty flag stays clean; helpers remain nonrenderable and cannot convert into render geometry.
- **Transform and occlusion cases:** identity, mirrored nonuniform scale, shear, a singular flattened transform, source pivot offset, degenerate triangle, placeholder point, and an ordinary Max object occluding Mesh. Moving the preview offscreen and back preserves the retained path.
- **Point regression:** 500,000 cached points, all prior lifecycle checks, 128 MiB process-cap rejection, unsupported-source diagnostics and recovery, no disabled-preview redraw loop.
- **Placement/render transport:** exact fixture placement fingerprint `12831264586494362244` stayed unchanged; PFlow transport evaluated all 5,000 fixture instances. This is not a production renderer/IPR qualification.

All **nine Scatter native suites passed for each SDK build**: Max 2026 and Max 2027, 18 suite executions total. Analyzer was unchanged and was not rebuilt/retested for this loop. Max 2026 has compile/native-test evidence but **no installed Max 2026 runtime test**.

## Memory behavior

| Case | Accepted Mesh instances | Local source triangles with instances | Source groups | Explicit graphics-buffer payload |
| --- | ---: | ---: | ---: | ---: |
| Artist 200k | 332 | 232,210 | 32 | 25,094,616 bytes |
| Artist 2M | 1,500 | 2,339,673 | 40 | 252,756,684 bytes |
| Artist 20M | 5,421 | 3,963,776 | 43 | 428,348,016 bytes |
| Synthetic dense cones | 200 | 4,352 | 1 | 479,616 bytes |

The reservation is `108 × source triangles + 48 × instances` bytes per source group. It excludes snapshot memory, SDK system copies, temporary streams and driver overhead; it is not a measurement of resident VRAM. Sources are shared within a group, not globally across controllers/layers.

The Mesh memory fixture deliberately exceeded both limits. Four copies of a 170,396,484-byte cache were rejected at the **512 MiB generation cap**. At the **1 GiB process cap**, two further owners with two copies each were accepted, then four attempts rejected; peak accounted payload was 934,342,620 bytes. Cleanup returned exactly to the 252,756,684-byte baseline. The original fallback cache still contained 1,910,581 triangles. Those helper owners were hidden: this validates reservation rejection and cleanup, not a real GPU out-of-memory or device-loss event. Late cumulative failure counters include these intentional rejection tests.

## Deliverable and remaining qualification

Packages are in `dist/retained-mesh-0.64/`. Install the matching MZP through **Scripting → Run Script**, restart Max, and select the existing **Mesh** display mode. The 2027 package contains the exact tested script/native files. No package was installed into the artist session during testing.

| Package | SHA-256 | Qualification |
| --- | --- | --- |
| `CyrusScatter-0.64-Max2027.mzp` | `44139c3a779e3b684baecbd6c8ca931a4d0c84962bdbce5103f7e38f5576e3d8` | Build, native suites and isolated Max runtime |
| `CyrusScatter-0.64-Max2026.mzp` | `7ef2255bb3d4b785685db26413760eb3eb7e27ad029ccde96eb4c10b2f475c75` | Build and native suites; runtime pending |

The native fallback is retained. `CyrusRetainedMeshDrawing false` selects the old path for a session comparison; `true` restores instancing. Rejected generations preserve the CPU cache and report fallback status. Do not use the slow legacy toggle on extremely dense previews without allowing it time to finish.

Next qualification should cover Max 2026, a second GPU/vendor, device reset/loss, and foreground interactive frame timing. Future optimization should target measured costs: spatial grouping/culling, source sharing across layers, or the controller lookup callback on scenes with many ordinary nodes. The current implementation culls source-group items, not individual plants; it does not promise cost-free drawing of arbitrary geometry.

The [implementation guide](README.md) records the SDK contract and primary Autodesk/Microsoft sources. [Reproduction instructions](../../tools/performance/mesh_integration/README.md) describe the isolated harness. The curated [evidence index](evidence/README.md) and [hash manifest](evidence/manifest.json) cover accepted receipts, original image pairs, raw timing CSVs, exact recipes and build logs. No scene assets, DLLs or SDK redistributables are included in that evidence folder.
