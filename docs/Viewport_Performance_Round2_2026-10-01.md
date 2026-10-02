# Further viewport improvements in Cyrus Scatter 0.62

**Local test candidate for 3ds Max 2027.1, 1 October 2026**

There is further performance headroom after the first viewport optimization. This second investigation found and removed repeated layer synchronization during held mouse input. The resulting **0.62 candidate reduces scatter callback time by 33.1% and total navigation-step wall time by 9.1% in the controlled comparison**. It preserves the displayed population and uses the same native renderer as 0.61. A larger improvement needs a different viewport display implementation; exploratory measurements support investigating it, but that renderer is not ready to ship.

[0.62 installer](../dist/CyrusScatter-0.62-Max2027.mzp) · [Installation guide](Max_2027_Installation.md) · [Evidence index](Viewport_Performance_Round2_2026-10-01/evidence/index.json) · [First implementation](Viewport_Performance_Implementation_2026-10-01.md)

## Interpreting the remaining FPS gap

The artist reports about **20 FPS before the first change, 80 FPS afterward, and 150–160 FPS with the scatter removed**. These are artist observations, separate from the instrumented measurements below. At 80 FPS a frame takes 12.5 ms; at 160 FPS it takes 6.25 ms. Using 160 FPS as a comparison baseline gives approximately 6.25 ms of additional work to investigate.

| Illustrative target | Total frame budget | Extra time above a 160 FPS baseline | Reduction needed in the current extra time |
| --- | ---: | ---: | ---: |
| 80 FPS | 12.50 ms | 6.25 ms | Current observation |
| 100 FPS | 10.00 ms | 3.75 ms | 40% |
| 120 FPS | 8.33 ms | 2.08 ms | 67% |
| 140 FPS | 7.14 ms | 0.89 ms | 86% |

These calculations explain why the next increase is harder; they are not forecasts. The scene without scatter has no scatter display cost. Approaching that speed requires removing most of the remaining submission and script overhead, while the GPU still has additional geometry to draw.

## What the second profile found

The supplied scene generates 52,143 placements and displays **6,284 proxies containing 37,704 triangles**. The first optimization reduced submission batches from 6,284 to 44 and cached transformed triangle data. It still submits those triangles through the immediate drawing callback on every redraw.

Stage timing identified another substantial cost: `layerEntries()` synchronizes surfaces, shared settings, CS Edit state, Analyzer revisions and overlap dependencies even when navigation will reuse the completed preview. The instrumented 0.61 callback spent a median **2.48 ms** in layer synchronization with normal input and **2.30 ms** with the held-input predicate forced true. Native triangle submission took approximately **2.41 ms** and **2.25 ms**, respectively. Discovery, icons and other script work make up the remainder. Individual stage medians should not be added to infer a measured total.

The held-input profile bypasses the real mouse-state query, so its 0.008 ms interaction stage is not a measurement of that query. Full stage samples and their derived summary are in [the profile evidence](Viewport_Performance_Round2_2026-10-01/evidence/profile/stage-summary.json).

## What 0.62 changes

`viewportLayerEntries held` uses the live controller and layer enable flags during held input and returns the existing layer objects directly. The existing `previewCache interactionHeld:true` path continues to display each layer's last completed preview. This avoids dependency synchronization whose output cannot be used during that held redraw.

On a redraw after release, the function calls the complete existing `layerEntries()` path. Surface synchronization, CS Edit checks, Analyzer revisions and overlap invalidation resume there. No persistent list of layers, additional geometry cache, timer or new dependency registry was introduced. Node visibility and controller/layer enable flags remain live. Controller-owned display settings changed during held input synchronize after release, consistently with displaying the completed preview during interaction.

The implementation lives in [the guarded generator stage](../AminScatter/tools/ui/viewport-performance.cjs); the generated scripted class advances to version 47. [The second-round text diff](Viewport_Performance_Round2_2026-10-01/evidence/change-from-061.diff) normalizes line endings and compares against the workspace snapshot taken immediately before this change, preserving the earlier CPU and viewport work. The original bytes are retained in the accompanying ZIP and hashes.

Both native modules are byte-for-byte identical to the tested 0.61 package. Its proxy batching limits and render behavior remain in force. Manual mode benefits during held navigation because the removed work occurs before drawing, independently of whether placement recalculation is allowed.

## Controlled comparison results

The candidate comparison ran **720 measured navigation steps**: four conditions, three repeats, 60 steps per repeat and eight warmup steps per condition. Repeat two reversed condition order. It ran in an isolated Max 2027.1 session on a disposable copy of `SaveSelect 2.max`, with a 953 × 750 active viewport and adaptive geometry degradation disabled during measurement. The artist's original Max session and the previous candidate session remained open; these are paired desktop measurements with background variability.

Both callbacks ran on the same 0.62 class and native binaries. The retained 0.61 callback uses the unchanged full layer traversal; the 0.62 callback selects the new held-input path. For the held conditions, both sides received the same forced-true interaction predicate. **This matrix uses scripted camera changes, not actual mouse gestures.**

| Condition | Median step wall time | P95 step wall time | Median total scatter callback time per step |
| --- | ---: | ---: | ---: |
| 0.61 callback, normal predicate | 34.99 ms | 77.27 ms | 13.61 ms |
| 0.62 callback, normal predicate | 34.65 ms | 68.26 ms | 13.53 ms |
| 0.61 callback, simulated held input | 34.49 ms | 63.93 ms | 11.76 ms |
| 0.62 callback, simulated held input | 31.34 ms | 54.05 ms | 7.87 ms |

The held conditions have two scatter callbacks per measured step. The normal conditions have a median of two, occasionally three. Callback totals in this table therefore differ from the per-callback profile above. Held navigation removes **33.1% of measured scatter callback time** and **9.1% of total step wall time**. The normal path shows no meaningful improvement, as expected. Held step medians improved in all three repeats.

All measured trials recorded **zero preview rebuilds, zero Analyzer runs and zero PFlow builds**, with stable populations and no recorded layer errors. [Raw frames, case metadata and summary](Viewport_Performance_Round2_2026-10-01/evidence/candidate-matrix/summary.json) are retained, including long outliers.

The harness measures synchronous camera changes, redraw and Windows message processing. It has no GPU completion fence and does not measure presented frame rate. Do not convert its numbers into a promise that the artist's 80 FPS becomes a particular new FPS, or compare absolute times against a different session's earlier run.

## Actual mouse input and visual checks

Four real pan strokes per version recorded one held scatter callback per stroke. The median fell from **5.92 ms to 4.13 ms**, a 30.3% reduction; populations and counters remained unchanged. This small, sequential sample verifies that actual mouse input selects the intended path. It is supporting smoke evidence, not a statistically powered FPS benchmark. The [gesture summary](Viewport_Performance_Round2_2026-10-01/evidence/gesture-summary.json) records coordinates, ordering and sample sizes.

Same-camera viewport images preserve the proxy arrangement and visible appearance. Below the statistics overlay, 485 of 581,330 pixels differ, or **0.0834%**, with a maximum difference of 6 out of 255 in a color channel. Thus the captures are close but not pixel-identical. Geometry and native shading code are unchanged. [Comparison data](Viewport_Performance_Round2_2026-10-01/evidence/image-comparison.json), [0.61 capture](Viewport_Performance_Round2_2026-10-01/evidence/images/held-061.png) and [0.62 capture](Viewport_Performance_Round2_2026-10-01/evidence/images/held-062.png) are available for inspection. The statistics overlay is excluded from the geometry comparison because its FPS text changes.

## The next larger renderer improvement

A separate experiment exported the existing proxy triangles and baked face colors into six ordinary Max mesh nodes, allowing Max's normal scene display to retain them. This preserved the 37,704 triangles and their positions, but produced visibly brighter colors. A material or color-pipeline difference is a hypothesis; its cause was not established. These nodes were diagnostic, nonrenderable objects and were removed by reloading the disposable scene before candidate validation.

In a separate **1,260-step exploratory matrix**, median step times were:

| Display experiment | Median step wall time | Interpretation |
| --- | ---: | --- |
| 0.61 display | 39.21 ms | Reference within this matrix |
| Retained ordinary meshes with full script synchronization | 30.77 ms | Faster, but brightness differs |
| Retained ordinary meshes plus direct held-input layer traversal | 23.69 ms | Supports further investigation; brightness still differs |
| Scatter callback disabled and diagnostic meshes hidden | 18.76 ms | Control with no scatter preview drawn |

These exploratory results do not qualify a renderer and are not the 0.62 release comparison. Two additional attempts using `Mesh::render` and legacy hardware draw meshes from a redraw callback produced no visible proxies; hardware creation counters stayed zero. Their apparently fast timings are **invalid performance wins**. The [probe source and recipes](Viewport_Performance_Round2_2026-10-01/recipes/probe/probe.cpp), failed-path images and all trials are retained to prevent repeating or misinterpreting those experiments. No probe binary or retained-node experiment is included in the installer.

The recommended next implementation is a native viewport display component driven by completed scatter preview data. It should prepare reusable Nitrous render items when the preview changes and let navigation reuse their buffers. Autodesk documents preparation and render-item lifetime through [IObjectDisplay2](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html) and its [Nitrous plugin display interfaces](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/plug-in_display_interface.html). The Max 2027 headers and runtime must govern implementation; the overview is from the 2024 documentation.

Implement this in the following order:

1. **Retain the existing proxy geometry first.** Preserve world-space triangles, face shading, source and solid colors, depth behavior and display visibility before introducing instancing. Prove camera navigation causes no buffer rebuild or upload.
2. **Establish ownership and invalidation.** Release resources on cache replacement, controller deletion, scene reset and device changes; update on settings, source, surface and time changes. Respect Manual and held-input behavior, multiple views, Undo/Redo, clones and scene reopening.
3. **Match visual output.** Resolve the observed brightness difference and test box, sphere, pyramid, mirrored/nonuniform scales, missing sources and relevant viewport modes. Keep a bounded fallback for unsupported cases.
4. **Measure total navigation cost again.** Keep display counts and quality fixed, record repeatable real navigation alongside callback timings, and collect GPU-completed or presented-frame evidence before publishing FPS claims. Test resource release, a large scene and the project's 32 GB RAM floor.
5. **Then consider prototype instancing and culling.** They can reduce memory/submission work, but transformed normals, per-source colors and bounds require explicit parity tests. Evaluate controller discovery and remaining script synchronization using the new profile before adding more caching.

Async scatter calculation or more CPU workers target editing and rebuild latency. They do not address the steady navigation trials here, which performed no rebuilds. Lower proxy budgets remain a user-controlled quality tradeoff, not the basis of this optimization.

## Validation and handoff

Fresh Max batch runs passed `test_viewport_performance.py`, `test_max2027.py` and `test_compute_performance.py`. The viewport fixture now changes a surface while held, checks the old preview is preserved, verifies the new surface is consumed after release, and checks Undo/Redo return the exact old/new triangle. It also checks live controller/layer visibility. Existing tests cover proxy parity, chunking, memory limits/fallback, cache collection, Manual refresh, clone and save/reopen. [The new fixture](../tools/tests/viewport_performance_smoke.ms) and copied result logs accompany the evidence. The prior native CTest results remain applicable to the unchanged native payload; they were not rerun as a new native build in this round.

The generated script is reproducible. ZIP integrity, every package manifest hash, script/source equality and native equality against 0.61 passed. Package SHA-256 is `5f0f7a99ac88ca118345fb79a67539213f0d64ea8d137ed3820cd757cbbcff49`; [verification details](Viewport_Performance_Round2_2026-10-01/evidence/package-verification.json) include individual payload hashes.

The isolated `round2-test.max` session remains open with 0.62, normal production redraw callbacks, event handlers enabled, the original camera and adaptive-degradation setting restored, and benchmark command timers disposed. The original scene hash and installed profile script hash are unchanged. The prior 0.61 installer is preserved. Install 0.62 through **Scripting > Run Script**, then restart Max to use it in your normal session; see the installation guide.

Full artist editing/CS Edit coverage, Corona production and interactive rendering, other Max versions, the missing-Corona-source Point Cloud issue and 32 GB hardware qualification remain open. This round establishes the scoped navigation improvement and the next measured engineering direction, not complete product qualification.
