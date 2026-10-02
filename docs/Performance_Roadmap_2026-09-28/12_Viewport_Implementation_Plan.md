# 12 — Viewport and editing implementation plan

**Goal:** faster preview rebuilds and smoother navigation at the same visible workload, while preserving editing and render output. Track input-to-preview latency separately from steady redraw frame time.

## Production path and current limits

[preview.cpp](../../AminScatter/src/preview.cpp) constructs and draws the native cache. [geometry_preview.inc](../../AminScatter/src/geometry_preview.inc) extracts source geometry/proxies and selects placement rows. The script's `refreshPreview` selects the path. Core `pointCloud()` is not the production native builder.

The native point budget currently allows 1–500,000 points. Geometry accepts up to 100,000 requested shown instances and 20,000,000 faces; these are validation ceilings, not recommended interactive settings. Source geometry is cached once per rebuild and instanced during drawing. Replacing it with expanded world-space triangles could increase memory dramatically.

## V01 — Point preview preparation

1. Time source sample extraction, row unpacking, sample selection, transform/group construction and publication separately.
2. Preserve equal samples per source, original flattening and `ceil(total/budget)` stride. Selection can yield fewer than the budget; do not change the pattern to fill the budget differently.
3. Count selected samples per source, reserve or allocate exact group sizes, compute stable offsets, and fill deterministically. Compare the extra count pass with simple reservation; keep the faster measured option.
4. Extract a host-independent numeric transform kernel with explicit layout/math tests. Keep Max value unpack/publication on the host thread.
5. Parallelize selected independent transforms through T02 when count exceeds the measured crossover. Reuse this kernel's contract for G02.

**Verify:** zero samples, empty output, multiple/sparse sources, mirrored and nonuniform transforms, large coordinates, all point budgets, exact selected flattened indices, source group order/color. Measure total build time and temporary allocations, not only multiply operations.

## V02 — Geometry draw cost

**Measured priority update, 2026-10-01:** the [saved-scene navigation investigation](../Viewport_Performance_Investigation_2026-10-01.md) found zero redraw-induced rebuilds and 6,284 per-instance triangle batches per callback. A world-space batching prototype retaining the original script plumbing reduced median navigation-step wall time from 90.52 ms to 31.56 ms, while still executing the existing face-shading loop. Prioritize bounded proxy batching, then repeated script work and retained display integration. The shade-cache proposal below remains a supporting experiment. Prototype visual parity and production integration are not yet qualified; do not apply expanded geometry without a memory budget, especially in Mesh mode.

The current draw loop recomputes transformed normals and a fixed-light shading value per face and instance on every redraw, then submits triangles through GraphicsWindow. Measure CPU shading and host submission separately.

First candidate: cache the scalar shading factor per selected instance/face when source geometry or instance transforms change. Colors can be applied separately so selection/solid-color changes do not rebuild geometry. Account for negative and nonuniform scale; a simple normal transform may not reproduce the current cross-product result.

Bound cache bytes and invalidate on source geometry, transforms, selected rows, mode, face budget, or shading-rule change. Do not allocate the full theoretical face ceiling per layer without checking the global cache budget. Compare shade-only storage against recomputation on small scenes; discard oversized caches or use CPU recomputation as fallback.

Keep host drawing on the main thread. Preserve render flags/material restoration, Z behavior, solid/source colors and existing visibility semantics. Do not change renderer data or placement order to improve viewport timings.

**Verify:** fixed camera screenshots, selection/picking, all proxy shapes, full mesh, point placeholders, budget-skipped instances, many layers, idle redraw and cache invalidation. V02 passes only with matched visible counts.

## E01 — CS Edit visible-position cache

**Files:** [cyrus_edit.cpp](../../AminScatter/src/cyrus_edit.cpp), [cyrus_edit_stack.inc](../../AminScatter/src/cyrus_edit_stack.inc), [cyrus_edit_storage.inc](../../AminScatter/src/cyrus_edit_storage.inc).

Cache visible positions and their stable `(layer,row)` mapping on the modifier instance. A modifier-local generation must change when input transforms/sources, row membership/deltas/deletion, layer activity/validity, stack application, reset, load, clone, undo or redo changes. `editRevision` is insufficient because `applyStable` and active-layer changes can update dependencies without it.

Keep selection styling separate when geometry/membership is unchanged. Hit-test indices and `SelectSubComponent` must resolve through the same visible ordering. Define whether cache data is rebuilt before a selection event if an input changed since hit testing; never let a stale index select another row.

Store no borrowed pointers into vectors that can be replaced by undo/stack updates. Profile undo snapshots, which currently copy layer state, before considering a separate undo-memory optimization. Do not change persistence format as part of the visibility cache.

**Verify:** markers, bounds, hit tests and selected instance remain aligned after every invalidation case, including changes that do not bump the global edit revision. Repeated selection-only redraw should reuse positions where safe.

## Event and cache policy

Preserve the existing lazy/coalesced update behavior until the baseline explains its delays. Instrument time waiting for release/event timers separately from active work. Cache keys must include actual geometry/time/settings dependencies, not merely viewport mode or node handles.

Changing display mode, color or camera should not invalidate unrelated placement, Analyzer or render caches. A surface/source/seed change must invalidate the dependent result. Test these relationships explicitly rather than broadening every notification into a full rebuild.

If a faster compute stage exposes MAXScript unpack/packing as the next dominant cost, use C04's evaluation-owned data reuse. Do not carry GC-owned arrays to worker threads.

## If drawing remains dominant

Open a separate prototype for supported Max display caching/instancing APIs across 2024–2027. First establish an API/lifetime compatibility matrix from the installed SDK samples. Requirements: same placement selection, bounds, hit testing, colors, device-loss recovery, reset/unload cleanup and memory limits.

Do not commit to Direct3D/OpenCL interop or an entire new renderer without a measured submission bottleneck. GPU point transforms and GPU display instancing solve different costs and have different host integration requirements.

## Test release deliverables

Provide V01/V02/E01 scene recipes, baseline/candidate cache/build counters, frame-time traces at fixed viewport size, before/after screenshots and memory peaks. Use [08](08_Manual_Test_Runbook.md). Record results independently for rebuild, navigation and selection so a faster rebuild cannot hide slower every-frame drawing.
