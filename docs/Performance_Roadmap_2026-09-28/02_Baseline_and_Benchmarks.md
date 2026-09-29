# 02 — Baseline and benchmark design

**Status:** proposed harness and fixtures; no benchmark executable or diagnostic export described below exists yet.

## Three clocks, four result categories

Measure (1) input change to first correct displayed result, including coalescing delay; (2) active computation, split into stages; and (3) steady redraw/navigation with valid caches. Record scatter/editing, viewport, Analyzer, and render preparation separately. Renderer image calculation is a separate timing from Cyrus preparation.

For an operation with nested spans, record parent/child IDs and both inclusive and exclusive time. Never add inclusive parent and child values to estimate total time. Use a monotonic native clock. Do not log every point or allocate strings in inner loops.

## Instrumentation specification — B01

| Boundary | Proposed measurements |
|---|---|
| Generated script orchestration | Event delay, signature calculation, requested vs actual build count, cache hit/miss reason, total `placements`, preview ready, render preparation |
| Native bridge | Mesh evaluation/conversion, settings/array unpack, source sampling, each core call, Matrix3/array packing |
| Scatter | Sampler/index preparation, candidates visited/accepted/emitted, anchor/projected searches, masks/lines, relax iterations, collision/final/orientation/falloff |
| Boundary queries | Index construction, query count, segments/triangles tested, cache reuse |
| Preview | Source extraction, sample selection, transforms/grouping, cache publication, shading, GraphicsWindow submission, drawn points/faces |
| CS Edit | Stack application, fingerprint work, visible-position cache hit/miss, display/hit-test/bounds, undo memory |
| Analyzer | Element splitting, raster, containment/clearance, thinning, path fitting/relaxation, ordered global spacing, output publication |
| PFlow | Key construction, placements, grouping, proxy preparation, scene creation/update, node ownership diff, validation, cleanup |
| Resources | Process private bytes/working set peaks, plugin-owned allocation high-water marks, worker concurrency, GPU buffers/transfers if used |

Export a bounded JSON diagnostic file on request. Include build hashes, scene/fixture hash, exact Max/renderer versions, compiler/flags, seed, units, counts, cache state, thread limit, backend and fallback reason. No automatic network upload. Measure diagnostics enabled/disabled overhead on representative cases; target under 2% for large operations, otherwise sample only the required stages.

## Native fixtures — B02

Create a dedicated optional benchmark target in each project, outside pass/fail timing-sensitive CTest. Existing CTest remains correctness-focused. Proposed scatter fixture axes:

- Requested counts: 1k, 10k, 100k; 1M only as an explicitly enabled stress tier within available memory.
- Valid surface triangles: 2, 10k, 100k; optional 1M stress mesh. Include degenerate faces interleaved with valid faces.
- Sources: 1, 8, 32; unequal weights, transformed sources, density maps, and source exclusions.
- Boundary segments: 4, 100, 1k, 10k; tilted/stacked elements, holes, near-coincident edges, masks.
- Relaxation iterations: off, modest, and configured maximum; candidate rejection ratios low/high; projection off/on; anchors off/on.
- Analyzer resolutions: 48, 192, 384, 768; 1, 10, 100 disconnected elements with bounded total memory.

Avoid a full Cartesian product. One-variable sweeps isolate causes; curated combined cases exercise interactions. Save inputs and exact outputs for correctness. Benchmark generation/loading outside the timed compute scope, with an additional whole-operation timing that includes preparation.

## Max scene kit — B03

Fixtures are to be created during coding because no representative user scenes are available yet. Use built-in geometry first, fixed units/seeds and assets packaged alongside each scene. Record expected source and output counts; equal requested counts do not imply equal emitted counts.

| ID | Scene / operation | Main purpose |
|---|---|---|
| S01 | Plane, one simple source, 1k/10k/100k instances | Baseline marshaling and ordinary scatter |
| S02 | Dense uneven surface, projected movement, anchors | Triangle search scaling and face-tie correctness |
| S03 | Dense include/exclude loops, holes, edge rows, facing/falloff | Boundary algorithms and identity stability |
| S04 | Relax/final/collision enabled; multiple interacting layers | Ordered acceptance and combined CPU cost |
| S05 | Analyzer corridors, rings, branches, tilted and nearby elements | Raster/path work and global spacing |
| V01 | Point display at 10k/100k/500k point budgets | Construction vs steady redraw |
| V02 | Box/sphere/pyramid/full geometry; fixed face budget | Geometry construction, shading and draw calls |
| E01 | Large CS Edit stack, selection, transforms, undo/redo | Cache invalidation and stable edits |
| R01 | Many layers and sources, repeated render starts | PFlow build/grouping and cache reuse |
| R02 | Interactive rendering while parameters/sources change | Coalescing, contention and stale data |
| L01 | Save/open/reset/merge/clone/delete after edits/rendering | Lifecycle cleanup and cache ownership |
| M01 | Combined large scene on a real 32 GB machine | Peak memory, bounded scratch and graceful failure |

Create version-native fixtures for each Max release. Do not assume a newer `.max` file opens in an older host. Preserve scene builders and validate their outputs per version.

## Measurement protocol

1. Freeze a reference build before changes. Record raw SHA-256 for binaries, native inputs, generator inputs and generated script. Freeze machine power mode, viewport size/mode, Max version, renderer/settings, and background workload.
2. Capture both original baseline and candidate with identical instrumentation. Use Release builds for timing; run correctness with checks active as well. Verify test assertions are actually active in Release (`assert` may be disabled by `NDEBUG`).
3. **Cold:** restart Max for each of five runs; label process-cold separately from GPU kernel-cache-cold. Record all five values and median. A five-sample p95 is not a reliable tail estimate.
4. **Warm recompute:** three untimed warmups, then 30 measured operations which actually invalidate the intended stage. Restore fixture state between runs. Record median, nearest-rank p95, min/max, failures and raw samples.
5. **Warm cache:** 30 unchanged requests/redraw operations. Confirm counters prove a hit; do not report this as recomputation speed.
6. Alternate baseline/candidate session order. Repeat the comparison in a second session if a change approaches the decision threshold. Preserve slow valid samples; annotate interrupted runs rather than deleting inconvenient results.
7. For navigation, use the same camera path/duration and report frame-time median/p95. Capture screenshots at fixed frames to check display parity.
8. Run renderer contention cases separately from idle cases. Avoid changing renderer thread settings mid-comparison.

Stage speedup = baseline median / candidate median. Time reduction = 1 - candidate / baseline. Report both with workload and units; never extrapolate a kernel result to whole-scene performance.

## Proposed acceptance defaults

Freeze these before an experiment; they are engineering decision thresholds, not promised gains.

| Gate | Default |
|---|---|
| Correctness | All relevant [03](03_Compatibility_and_Regression.md) checks pass before accepting timings |
| Useful improvement | At least 25% median reduction in a preselected user-visible operation, or document a smaller improvement with material absolute time saved |
| Regression | Investigate any median/p95 increase greater than `max(5% of baseline, 2 ms)` on a required case |
| Memory | Investigate peak increase greater than `max(10% of baseline, 64 MiB)`; always obey the 32 GB workload envelope |
| Stability | No crashes, stale publication, wrong edits, duplicate render objects, or unbounded memory growth |
| Threading | Compare serial optimized vs 1/2/4/6/8/12 threads as hardware allows; select the smallest useful limit |
| GPU | Compare optimized CPU vs total GPU path, including transfers and packing; see [06](06_GPU_OpenCL_Feasibility.md) |

An isolated stage improvement is valuable evidence but does not satisfy a whole-operation claim. Use the measured fraction `f` and stage speedup `s` to estimate the upper bound `1 / ((1-f) + f/s)` before investing in a large rewrite.

## Build verification available today

From the project root, after an appropriate compiler is installed, the existing scatter core can be configured without Max:

```powershell
cmake -S AminScatter -B build/perf-core-baseline -G "Visual Studio 17 2022" -A x64 -DAMIN_BUILD_MAX=OFF
cmake --build build/perf-core-baseline --config Release
ctest --test-dir build/perf-core-baseline -C Release --output-on-failure
```

These are existing CMake interfaces, not a claim that this machine can run them now. Analyzer core-only configuration, benchmark targets, scene builders, backend switches, and JSON export are future deliverables. Host plugin commands must use the pinned per-version SDK/toolchain from [11](11_Platforms_and_Minimum_Requirements.md).
