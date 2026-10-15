# 15 — Verification suite, behavioral parity experiments and performance benchmarks

## 1. Testing is part of the design

The goal is *predictable behavior under combinations*, not screenshot resemblance for a single parameter. Every feature must pass isolated, combined, persistence and performance tests. Use documented ForestPack behavior as a reference where possible and label undocumented cases **[TEST-NEEDED]**. Never claim a controlled external experiment has been executed unless it has actually been run.

## 2. Test pyramid

| Level | What to test | Can run outside Max? |
|---|---|---|
| Unit | RNG, probability curves, triangle math, arc length, masks, hashes, solver | Yes |
| Property | Invariants, monotonic density, deterministic ordering, orthonormal frames | Yes |
| Differential | Incremental vs full build across edit sequences | Yes |
| Integration | Source nodes, Undo, Save/Load, Paint callbacks, render bridge | No |
| Reference behavior | Licensed ForestPack scenes compared against our interpretation | Needs target ForestPack/Max |
| System benchmark | 1M+ instances, multi-scatter, CPU/GPU, renderer export | No or hybrid |
| Real project regression | Existing Cyrus customer scenes and compatibility | No |

## 3. Golden fixture library

Suggested fixtures; each has immutable inputs, expected control states, source version, and results or invariant checks:

```text
F001_flat_plane_image_8x8
F002_density_monotonic
F003_color_id_source_matching
F004_cluster_two_species
F005_path_closed_loop
F006_reference_moved_marker
F007_reference_triangle_area_uniformity
F008_area_order_include_exclude_include
F009_spline_holes_open_band
F010_object_exclusion_resolution
F011_paint_erase_order
F012_paint_long_history
F013_two_stacked_receivers
F014_uv_seam_islands
F015_slope_altitude
F016_source_probability_empty
F017_collision_ties_multithread
F018_collision_incremental_cascade
F019_manual_pin_then_density
F020_effect_move_then_reproject
F021_camera_only_nav
F022_renderer_edge_cutout
F023_animation_samples
F024_save_load_undo
F025_missing_source_restore
```

Every fixture should define `authored inputs`, `algorithm version`, `seed`, `time`, `expected accepted IDs/positions`, `expected warnings`, `snapshot of dependency state` and `performance budgets` where relevant.

## 4. Core mathematical tests

- RNG hash test vectors identical across debug/release builds and 1/16/32 workers.
- Uniform weights and Alias/CDF source sampler statistical chi-square sanity tests (do not impose unrealistically tiny random error).
- Inverse CDF sampler matches target probability curve distribution.
- Barycentric triangle sampling gives uniform expected centroid under many samples.
- Arc-length sampler on known curves returns target distances within tolerance.
- Signed distance from point to circle/line segment/closed polygon matches analytic values.
- Region winding policy handles holes/degenerate/self-intersecting contours predictably.
- Quaternion surface alignment is normalized, orthogonal and stable near parallel axes.
- World/UV-area density conversion behaves as expected for known affine mappings.
- Raster coverage recompiled from authoritative stroke sequence equals incremental working tiles within declared precision.

## 5. Semantic metamorphic tests

These are powerful even without reference output:

| Input transformation | Property expected |
|---|---|
| Change tint only | Placement IDs/transforms unchanged |
| Change viewport density only | Render accepted list unchanged |
| Increase binary/grayscale density for fixed candidates | Pre-collision accepted candidate set monotonic |
| Reorder two noninteracting regions | Final result unchanged |
| Duplicate a source weight set scaled by constant | Relative source probabilities unchanged |
| Move a marker with same stable ID | Reference-generated candidate identity unchanged |
| Change thread count | Accepted IDs and attributes unchanged |
| Undo then Redo an authored stroke | Returns exact persisted authoring state |
| Clear all caches | Full rebuild returns equivalent accepted population |
| Reload scene | Same authored IDs and deterministic results |

Collision acceptance is **not necessarily monotonic** with density under greedy reassignment. Distinguish candidate acceptance from final accepted population in the test specification.

## 6. Differential incremental tests

Pseudocode:

```text
for seed in Seeds:
    doc = CreateRandomValidScatterScene(seed)
    full_before = FullEvaluate(doc)
    for edit in RandomValidEdits:
        doc.Apply(edit)
        incremental = IncrementalEvaluate(doc, dirtyRegions)
        baseline = FullEvaluateFromEmptyCache(doc)
        CompareCanonicalOutputs(incremental, baseline)
```

Compare sorted stable IDs, source IDs, transforms within epsilon, surface bindings, rejection reasons where deterministic, and manual edits. Include changes to Areas order, source dimensions, collision radius, dense paint, linked scatter occupancy and Effect position.

If comparison fails, the optimization must be disabled or expanded until correct; don't "fix" tests by loosening tolerance around missing instances.

## 7. ForestPack reference-behavior test plan

Reference tests are **not yet executed**. Install/run a licensed compatible version of ForestPack, create tiny controlled `.max` scenes and capture:

- Screen recording or screenshots of relevant settings.
- Exact 3ds Max version, ForestPack version, renderer, unit setup.
- Candidate/accepted counts where Forest exposes them.
- Instance positions/source assignment (where accessible through legitimate export or visual markers).
- A/B difference after changing one control.
- Document source URL and conflict if documentation differs.

**High-information tests**:

1. Image map with precisely known active pixel grid, no transforms or collisions.
2. Same map with threshold/grayscale density sweep and fixed seed.
3. Include–Exclude–Include stack reversed.
4. Two sources with different collision radii, source probabilities changed.
5. Source-selected transform map vs Probability Map.
6. Random translation crossing a spline boundary.
7. Point/Size/Edge boundary of a large flower clump.
8. Paint–Spline–Paint conversion of a shape with holes.
9. Multiple stacked surfaces, Randomize Stacked off/on.
10. Effect that moves item laterally and reprojects it to receiver.

Use tests to determine behavior, **not** to obtain/disassemble proprietary binaries or code.

## 8. Performance instrumentation requirements

Record per update:

`sceneRevision`, `scatterId`, `changeType`, `cold/warm`, `threadCount`, `candidateCount`, `areaRejectCount`, `sourceEmptyCount`, `collisionPairTests`, `collisionRejectCount`, `acceptedCount`, `dirtyTiles`, `reusedTiles`, `surfaceQueries`, `memoryPeak`, `GPUUploadBytes`, and stage times.

Sampling should be lightweight and optional in production; debug builds can capture detailed traces. Tag cache misses with reason (geometry, transform, area, seed, camera, time, renderer).

## 9. Proposed benchmark scenes

| Benchmark | Construction | Questions |
|---|---|---|
| B1 High-density lawn | 1M accepted grass instances on flat and deformed surfaces | Source memory, candidate gen, collision cost, GPU point preview |
| B2 Shared landscape | 10 distinct scatters on same 1M-face terrain | Surface cache memory reuse and invalidation |
| B3 Paint stress | 1,000 strokes, overlapping adds/erasures, dense coverage | P50/P95 input latency, memory vs history, tile rebuild correctness |
| B4 Path urban layout | Hundreds of splines, 10k path placements | Arc sampling, editing, reference reactivity |
| B5 Mixed per-source sizes | Grass, bushes, trees, rocks at dense candidate level | Collision broadphase and rejection stability |
| B6 Complex area stack | 50 mixed include/exclude/linked areas | Ordered stack correctness, field cache throughput |
| B7 Large multi-camera shot | Camera orbit/flythrough, LOD and culling | Popping, stale camera regeneration, render-preparation time |
| B8 Render matrix | Same scene Arnold/Corona/V-Ray | Instance count, shading parity, memory, animation support |
| B9 History/persistence | Repeated undo, save/load, clone/merge | Referential integrity, orphan handling |
| B10 Effects | Tint-only vs position-writing procedural modifiers | Dirty-stage precision and compute overhead |

Define versions of scene assets and a fixed test machine. Include cold startup and warm interactive conditions; report median, P95, max and memory peak. Compare 1, 4, 8, 16+ threads to find saturation rather than always using all logical cores.

## 10. Acceptance policy

At each milestone: all unit tests green; no invalid host-thread access; no stale publication after cancel; referenced fixture outputs match; performance regression thresholds compared with last known good build; save/load/Undo smoke tests; renderer fallback warnings accurate. Record known unsupported combinations in the release notes.

## 11. Test report template

```markdown
# Test FP-AREA-004
Version: ForestPack X / Max Y / renderer Z / Cyrus commit SHA
Evidence: [FP-DOC] + [Observed] + [CYRUS-DESIGN]
Inputs: 1 flat receiver, 3 spline regions, fixed seed 101
Operation: Include A, Exclude B, Include C; reorder B/C
Expected: exact include/exclude contribution behavior
Actual: counts, source IDs, positions, screenshots
Deviation: count/geometry/order, documented difference
Result: Pass / Fail / Inconclusive
Next action: fix logic / revise spec / investigate version
```

Test IDs should be referenced from the feature catalog, not held in separate notes that become stale.
