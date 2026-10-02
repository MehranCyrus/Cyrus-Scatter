# Cyrus Scatter 0.61: viewport performance implementation

**Local performance candidate | 1 October 2026 | 3ds Max 2027.1**

Follow-up: [the 0.62 investigation](Viewport_Performance_Round2_2026-10-01.md) records an additional held-input optimization and the next renderer experiments. This document preserves the 0.61 measurements.

[Max 2027 installer](../dist/CyrusScatter-0.61-Max2027.mzp) · [Installation guide](Max_2027_Installation.md) · [Evidence index](Viewport_Performance_Implementation_2026-10-01/evidence/index.json) · [Original investigation](Viewport_Performance_Investigation_2026-10-01.md)

The first viewport optimization is implemented and tested. In the supplied scene, median navigation-step wall time fell from **88.10 ms to 30.16 ms**, a **65.8% reduction** or approximately **2.92 times the measured step rate**. Both sides use the candidate script; a diagnostic switch selects either the preserved per-instance native drawing loop or the new batch path. The displayed population stays at **6,284 pyramid proxies / 37,704 triangles**, from 52,143 generated placements.

This addresses the main cost identified in the investigation: submitting thousands of small triangle batches during every redraw. Manual mode also benefits because the optimization changes drawing, independently of whether placements are recalculated.

These numbers measure synchronous camera change, redraw and message processing. They are **not GPU-completed frame times or a promise of a particular FPS**. The candidate is ready for the artist's editing and renderer retest; the work below does not establish complete production qualification.

## 1. What changed

### Native proxy drawing

Box, sphere and pyramid previews now prepare their world-space triangles and scalar face shading when the existing native preview cache is built. Navigation reuses this immutable data. The draw function keeps the GraphicsWindow transform at identity and submits source-preserving chunks of at most **4,096 triangles**.

For the saved pyramid preview, this reduces `startTriangles` / `endTriangles` pairs from **6,284 to 44 per draw callback**, a 99.3% reduction. It also removes repeated instance-transform setup and face-normal/shading calculation from the normal redraw path. The triangles themselves are still submitted on every callback: this is CPU-side preparation and batching, not retained GPU instancing.

Preparation preserves the previous source → instance → face ordering, selected placement rows, proxy topology, source colors, solid-color behavior, object offsets, and transformed-edge shading formula. In particular, the normal calculation retains the previous behavior under nonuniform and mirrored scales. The existing render flags and material restoration remain in place.

Additional triangle and batch payload is capped at **16 MiB per cache** and **64 MiB across live caches in a Max process**. Reservation happens before allocation. Cache collection releases the reservation. An oversized cache, process-cap exhaustion, or allocation failure uses the existing draw path and preserves its preview population. These caps cover additional batch payload, not the complete plugin or Max process memory footprint.

The supplied scene needs **1,509,568 bytes (1.44 MiB)** for one set of prepared proxy caches. A diagnostic snapshot observed 3,019,136 process-reserved bytes with more than one cache generation alive; a separate GC test verifies that all reservations return to zero when the owning caches are collected. Old caches may remain live until Max collects them, so the process cap can temporarily select the slower fallback after repeated rebuilds.

Mesh mode continues using the existing source mesh / instance-transform representation. Point Cloud, empty-source markers, and radius drawing retain their existing paths.

### MAXScript redraw work

- Each layer's `previewCache` is requested once per draw callback, and the result is reused for drawing.
- Mouse interaction state is sampled once per callback and passed into those cache requests. Other callers retain the default behavior of querying interaction state themselves.
- Controller icon paths are cached by icon size. The node transform is still read live; changing icon size regenerates its paths.
- Valid surfaces and the enabled-layer preview budget are calculated once per layer traversal and passed to layer synchronization.

Dependency synchronization, CS Edit stack checks, Analyzer revision checks, dirty-state handling, overlap invalidation and Manual refresh rules remain active. There is no new global scene-node registry or persistent layer snapshot that requires a second invalidation system.

The generated script is version **46**, native engine description **0.23**, and installer **0.61**. Class IDs and parameter layouts are unchanged. The package includes the existing 0.60 CPU work already in the workspace.

## 2. Measured results

The candidate ran in an isolated desktop Max session with its own plugin configuration, using a disposable copy of `Test Scene/SaveSelect 2.max`. The normal installed profile and original open Max session were left unchanged. The host is Max 2027.1 (29.1.0.11426), Ryzen 5 5600X, RTX 3090, and approximately 96 GiB RAM. Corona 15 was selected; no production or interactive render was run.

The main perspective viewport was **953 × 750**, in the saved two-viewport layout with edged faces enabled. The Nitrous API reports `Realistic`; the visible viewport menu says `Standard`. Geometry degradation was disabled consistently during measurement and restored afterward.

Each condition has **three repeats, eight warm-up steps and 60 measured steps per repeat**. The second repeat reverses condition order. All 900 measured steps are retained; no outliers are removed.

| Condition | Median step | P95 step | Median scatter callback total per step |
| --- | ---: | ---: | ---: |
| Preserved native instance loop, 0.61 script | 88.10 ms | 139.97 ms | 68.88 ms |
| Candidate, Real-time | **30.16 ms** | **49.28 ms** | **11.34 ms** |
| Candidate, duplicate cache-call control | 30.90 ms | 49.43 ms | 15.15 ms |
| Candidate, Manual | 37.38 ms | 53.42 ms | 10.03 ms |
| Scatter callback disabled | 12.10 ms | 18.91 ms | 0 ms |

There were **zero preview rebuilds, Analyzer runs or PFlow builds during every measured trial**. Counts and per-layer identities remained stable, and no preview errors were reported. A measured step usually invokes each drawing callback twice, so its callback total is not the duration of a single invocation.

The duplicate-cache control restores the previous callback ordering and independent interaction polls while retaining the candidate's icon and synchronization changes. It supports removing redundant calls, but does not isolate every script optimization or represent a complete 0.60 build. The large gain is attributable to native batching.

The earlier full 0.60 investigation measured 90.52 ms in Real-time and 88.98 ms in Manual. Those are historical reference measurements; the paired native comparison above is the cleaner attribution test.

Repeat medians vary: Real-time was 27.05 / 43.07 / 26.93 ms; Manual was 39.57 / 25.65 / 39.22 ms. The similar callback cost and absence of rebuilds do not support treating the aggregate difference as evidence that Manual intrinsically draws slower. Desktop scheduling, redraw and message processing contribute to the overall time. The Real-time result meets the initial 35 ms median / 55 ms P95 step targets; the Manual aggregate misses the median target. Neither result reaches the callback-disabled baseline.

Actual mouse-pan input also exercised the mouse-held path. Two held callbacks per condition measured **39.07 / 35.39 ms** for the previous native loop and **5.01 / 5.13 ms** for batching, with unchanged cache counts and rebuild counters. This is corroboration with a very small sample, not an independent FPS benchmark. The final reverse-pan screenshot capture failed with `no monitor found for window`; the callback samples and subsequent restoration were recorded successfully.

## 3. Correctness and verification

| Check | Result and scope |
| --- | --- |
| Native build and CTest | Release x64 Max 2027 SDK build; all eight Scatter suites and one Analyzer suite passed. |
| General Max smoke test | Native/script loading, placements and previews, CS Edit, Analyzer, save/reopen passed. |
| Existing CPU performance fixture | Source filtering/transforms, layer preview/render, empty/point sources, serial/worker parity and queued notification behavior passed. |
| Proxy geometry parity | Exact ordered triangle positions, scalar shading and source colors for all three proxy shapes, including mirrored/nonuniform/sheared transforms and source offsets. |
| Supplied scene parity | All **37,704** prepared triangle rows exactly match independently evaluated previous draw data. |
| Selection and budgets | Deterministic selected-row ordering, source groups, 4,096-face chunk boundaries, empty caches and placeholder/empty-source policies passed. |
| Memory and fallback | Per-cache and process caps, preserved output counts under fallback, Mesh fallback and release to zero after GC passed. |
| Script lifecycle | Unchanged redraw does not rebuild; icon resize, Manual refresh, mouse-held deferral, post-drag rebuild, layer enable, clone, placement round trip and save/reopen passed. |
| Generated script and package | Regeneration is byte-identical; ZIP integrity and every manifest hash checked; packaged native/script payload matches tested files. |

Visual pairs cover box, sphere and pyramid in solid and source-color modes. For manageable captures, box/pyramid use 2,000 instances per layer and sphere uses 250. The saved pyramid/source-color pair was visually inspected. The image files are **not pixel-identical**: after excluding the menu/statistics area, changed-pixel counts range from 754 to 5,876 out of 581,330 pixels; the largest mean absolute channel difference is 0.112 on a 0–255 scale. Geometry, shade and color data are exact; rasterization differences are consistent with changing where transforms are applied, but that explanation is an inference rather than a GPU-level proof. Keep large-coordinate and other-driver visual checks in wider qualification.

The dedicated test is [viewport_performance_smoke.ms](../tools/tests/viewport_performance_smoke.ms), run by [test_viewport_performance.py](../tools/test_viewport_performance.py). Logs, raw samples, images, recipes and binary/package identities are preserved with the [evidence index](Viewport_Performance_Implementation_2026-10-01/evidence/index.json).

## 4. Code ownership and diagnostics

| File | Responsibility |
| --- | --- |
| [preview_batches.inc](../AminScatter/src/preview_batches.inc) | Batch data structures, memory reservations, shading preparation and caps. |
| [preview.cpp](../AminScatter/src/preview.cpp) | Cache preparation, batched drawing, preserved fallback, diagnostics. |
| [geometry_preview.inc](../AminScatter/src/geometry_preview.inc) | Prepare batches after existing geometry selection completes. |
| [viewport-performance.cjs](../AminScatter/tools/ui/viewport-performance.cjs) | Guarded source-generation transformations for redraw optimizations. |
| [generate.cjs](../AminScatter/tools/ui/generate.cjs) | Runs the viewport stage after the existing CPU performance stage. |
| [build_max.py](../tools/build_max.py) | Produces version 0.61 installers with hashed payloads. |

Do not edit the generated MAXScript alone. Update its owning generator stage, regenerate and verify compilation. The new stage requires unique anchors so source drift fails loudly.

Diagnostic primitives are session-local and do not change scene serialization:

```maxscript
cyrusPreviewBatchDrawing()       -- current drawing switch; defaults to true
cyrusPreviewBatchDrawing false   -- use preserved native loop, same cache data
cyrusPreviewBatchDrawing true    -- restore candidate drawing
cyrusPreviewDrawStats cache
cyrusPreviewTriangles cache true 100000
```

`cyrusPreviewDrawStats` returns `[mode, old batch count, prepared batch count, prepared faces, cache bytes, process bytes, cache cap, process cap]` as Integer64 values. Cast these bounded values to `integer` before passing them to the current monitor's JSON helper, whose generic string formatting otherwise emits MAXScript `L` suffixes. Triangle export is diagnostic-only, capped at 100,000 rows, and never used by normal redraw. `true` exports prepared data; `false` independently evaluates the old geometry/transform formula.

## 5. Install and continue qualification

1. Save work in the normal Max session.
2. Run [CyrusScatter-0.61-Max2027.mzp](../dist/CyrusScatter-0.61-Max2027.mzp) through **Scripting > Run Script**.
3. Restart Max to load the new native module. The current isolated test session already has the candidate, but does not upgrade the normal profile.
4. Reopen a test copy and compare navigation with the same proxy shape, viewport size and display budgets.
5. Retest normal selection, Modify editing, CS Edit, surface changes, Undo/Redo, save/reopen, then Corona production and IR workflows. The new automated lifecycle fixture does not qualify every interactive operation.

Surface Analyzer 0.14 is unchanged. If it is already installed, this viewport update does not require reinstalling it. For a pre-viewport comparison, the [0.60 installer](../dist/CyrusScatter-0.60-Max2027.mzp) is preserved. Compare using the original test copy; backward reopening of candidate-saved files is not qualified.

The original scene's SHA-256 is verified unchanged. Test instrumentation is removed, normal candidate callbacks and camera are restored, and command timers are disposed. The disposable candidate scene remains open separately. Existing workspace CPU changes were preserved; a pre-viewport source backup is retained at `build/viewport-optimization-2026-10-01/before-viewport-changes.zip`.

## 6. Remaining performance work

1. **Retained Nitrous geometry / instancing:** remove repeated per-triangle submission, particularly for Mesh and sphere previews. This is the next larger architectural experiment; this release still submits triangles every redraw.
2. **Reduce remaining script and redraw overhead:** profile controller traversal, layer synchronization, radius and Analyzer drawing after batching. Replace checks only with explicit, tested invalidation rules; preserve Manual, source updates, Undo and CS Edit behavior.
3. **Qualify cache rebuilding and heavier scenes:** measure prepare time, multiple controllers, large coordinates, repeated edits, 32 GB systems and other supported hosts/drivers. Full source geometry evaluation during cache rebuild is unchanged.
4. **Separate missing-source robustness:** the investigation's Point Cloud failure involving missing Corona source assets is not fixed here. This candidate preserves existing source policy and does not conceal it by reducing the displayed population.

The change substantially reduces the confirmed bottleneck in this scene. Remaining drawing and host overhead still leave a measurable gap to the callback-disabled control, so there is further useful work after this candidate's artist retest.
