# 01 — Current code audit

**Evidence:** source inspection, 2026-09-28. Cost rankings below are hypotheses until measured. File fingerprints are in [source_snapshot.json](source_snapshot.json); all 97 paths from the existing inventory were readable and their LF-normalized byte counts matched that inventory. Matching sizes alone does not establish identical contents to a historical revision; these new hashes identify the current local snapshot.

## Actual execution path

The generated [AminScatterObject.ms](../../AminScatter/scripts/AminScatterObject.ms) orchestrates native calls. Its `placements` path includes fast/advanced scatter, whole-scale handling, Analyzer area, falloff, filtering, blockers/overlaps, optional final spacing, boundary orientation, CS Edit, and point-source exclusion. Conditional recursive placement work occurs for final processing. Preserve this order.

`refreshPreview` reaches native `aminScatterBuildPreview` or `cyrusBuildGeometryPreview`. Rendering reaches [pflow.ms](../../AminScatter/tools/ui/templates/pflow.ms), which builds Max scene objects after computing placements. Faster native sampling cannot by itself eliminate script marshaling, scene evaluation, drawing, or PFlow creation.

## Findings to instrument

| Area / source | Verified behavior | Candidate action and caveat |
|---|---|---|
| [scatter.cpp](../../AminScatter/src/scatter.cpp), `scatter`, anchor loop | Each anchor finds its closest surface by scanning valid triangles | Consider a shared immutable surface index; preserve original face tie winner and distance arithmetic |
| Same, projected movement | Each moved candidate scans valid triangles again | Include this in the first profile; the research underemphasizes it |
| Same, `Sampler` | Double cumulative areas, `upper_bound`, filtered original triangle indices, sequential RNG | Preserve search semantics, index mapping, and random draw consumption |
| [spacing.inc](../../AminScatter/src/spacing.inc), `SurfaceTree` | A BVH already exists for other projection paths; its traversal/hint can choose different equidistant faces | Reuse only after defining query semantics compatible with each caller |
| Same, `relax` | Reads a point array and grid, writes `next[i]`, swaps each iteration | Good threading candidate after stable neighbor traversal and reduction tests |
| Same, collision cleanup | Accepted points are inserted incrementally into a grid | Preserve ordered acceptance; do not parallelize it as independent rows |
| [final.inc](../../AminScatter/src/final.inc), `bandAt` | Constructs `AreaMask` inside repeated queries | Prepare lazily reusable validation/bounds; `AreaMask` holds a reference, so the cost here is scanning, not copying the entire area |
| Same, final pass | Sequential proposal/acceptance changes points consulted by later work | Keep serial initially; index read-only predicates around it |
| [orientation.inc](../../AminScatter/src/orientation.inc), `outwardAt` | Scans segments; `auto testBand=band` copies the whole band per query; calls `analyzerBand` | Remove the measured copy with an effective-kind parameter; prepare loop metadata once |
| [edge_border.inc](../../AminScatter/src/edge_border.inc) | Repeated containment/clearance scans during row generation | Index distance and containment separately; retain holes, corner rules, masks, RNG, and guard limits |
| [boundary_falloff.inc](../../AminScatter/src/boundary_falloff.inc) | Distance already uses `FallTree`; `areaSide` still scans polygon edges | Measure parity work separately; a distance BVH alone does not accelerate inside/outside classification |
| [preview.cpp](../../AminScatter/src/preview.cpp), build | Equal sample counts per source; stride selection over flattened points; per-source vector pushbacks | Reserve or count/prefix/fill groups without changing selected points or group order |
| Same, draw | Geometry normals/shading recomputed per instance/face on every redraw; triangle submissions remain host calls | Profile shading vs submission; cache bounded immutable shading before considering a new display backend |
| [geometry_preview.inc](../../AminScatter/src/geometry_preview.inc) | Copies source geometry once per rebuild; evenly selects rows; enforces instance and face budgets | Retain these selection semantics and caps; avoid expanding all world-space triangles into a huge cache |
| [cyrus_edit.cpp](../../AminScatter/src/cyrus_edit.cpp), `visible` | Reconstructs visible positions for callers | A visibility cache needs input/activity/row generations in addition to `editRevision` |
| [cyrus_edit_stack.inc](../../AminScatter/src/cyrus_edit_stack.inc), `applyStable` | Replaces input matrices and changes row/activity state without incrementing global edit revision | Invalidate on every dependency update, stack rebuild, restore, load, clone, and deletion |
| PFlow template | Source grouping, scene-node creation, scene diff via repeated `findItem`, cache key construction | Measure grouping and node-diff cost; keep scene ownership/cleanup correct |
| [analyzer.cpp](../../CyrusSurfaceAnalyzer/src/analyzer.cpp) | Raster cells repeatedly scan boundary loops for containment and clearance; thinning has staged updates | Prepare boundary queries and parallelize only independent work with exact tie/order behavior |
| [elements.cpp](../../CyrusSurfaceAnalyzer/src/elements.cpp) | Per-element analysis followed by global ordered spacing and minimum-point overrides | Parallel local analysis may help; merge and global spacing remain ordered |

## Existing optimizations worth preserving

[performance.cjs](../../AminScatter/tools/ui/performance.cjs) already coalesces updates and caches blocker inputs. It retains preview while the mouse is held and uses release/event timers; PFlow also waits for state stability. These delays belong in perceived-latency measurements. The presence of timers does not imply background computation.

`previewBuildMs`, `previewBuildCount`, blocker cache counters, `CyrusPFBuilds`, and Analyzer analysis-run counters provide useful existing signals. They do not account for every nested stage, cache miss reason, or redraw cost.

The Analyzer and scatter have pure native cores. Six scatter CTest cases and one Analyzer CTest case exist. The scatter build already supports `AMIN_BUILD_MAX=OFF`; Analyzer does not yet expose an equivalent option.

## Research corrections that affect implementation

1. `pointCloud()` in the core is not the live native preview construction path. Improving its search loop would not automatically improve viewport rebuilds.
2. `editRevision` alone cannot safely key CS Edit visibility caching.
3. GPU sampling pseudocode in the research differs from the CPU: float vs double CDF, lower-bound style selection vs `upper_bound`, and missing filtered-to-original triangle mapping. Do not copy it into production.
4. Equal seeds do not prove equal output. Face ties, arithmetic order, filtering, compacted indices, and RNG consumption matter.
5. Geometry drawing and PFlow may dominate even after native computation gets faster. Measure their host-side costs independently.
6. The report's timing/speedup/effort estimates are planning guesses. Its exported citation tokens and sandbox ZIP links do not establish accessible evidence or available artifacts.

## Version and generator constraints

`max_bridge.cpp` contains a 2026 SDK assertion. Both installers check Max 2026; registration keys and messages also include 2026. CMake points to 2026 headers/libs. Changing only the assertion would not deliver 2024–2027 support.

The generated script has version 44 and 153 typed persisted parameters in this snapshot. Edit the [generator](../../AminScatter/tools/ui/generate.cjs), its stages, or templates, then regenerate. Native/source hashes and generated-output checks must identify each experiment. See [03](03_Compatibility_and_Regression.md) and [11](11_Platforms_and_Minimum_Requirements.md).
