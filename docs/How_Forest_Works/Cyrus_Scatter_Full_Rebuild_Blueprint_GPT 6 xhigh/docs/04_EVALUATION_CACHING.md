# 04 — Evaluation graph, dirty propagation, spatial partitioning and scheduling

## 1. The central correctness contract

Given the same authored document, host scene snapshot, clock time, renderer-independent settings and algorithm version, a **full rebuild** is the reference answer. Incremental rebuilds must produce an equivalent semantic result. Equivalent means accepted identities and attributes meet declared deterministic/tolerance rules; viewport sample ordering need not be byte-identical.

Caches are optimizations, not alternate definitions of the result.

## 2. Dirty dependencies are typed and directional

Possible stages:

```text
HostSnapshot ──> SurfaceBVH ──> SurfaceSample
           ├──> Splines/AreaMask/DistanceFields ─┐
           ├──> Sources/Bounds ──────────────────┤
           └──> TexmapFieldSnapshot ─────────────┤
GeneratorParameters -> CandidateReservoir ──────┤
AreaStackOrder/Fields ---------------------------> Eligibility
Candidate + Eligibility + SourceWeights --------> SourceChoice
SourceChoice + SourceBounds + Transforms --------> ItemBounds
Items + Bounds + Constraints -------------------> OccupancySolution
Accepted + ManualOverrides ---------------------> AuthoredFinalItems
FinalItems -> ViewportBuffer / Picking / RenderStream / Bake
```

Stage keys include `schemaVersion`, `algorithmVersion`, `inputContentHash`, relevant `time`, coordinate mode, source revisions and stable seed. Only include fields actually read by the stage. For example, viewport point size must not enter candidate cache keys.

### Proposed change impact table

| Change | Initial invalidation | Cascading invalidation | Should remain reusable |
|---|---|---|---|
| Source tint | Material attributes | Relevant viewport/render shading data | Placement, surface queries, collision |
| Source replacement | Source bounds, source handle | Transform size, collision, render stream | Image/map candidate coordinates |
| Global density | Candidate acceptance/eligible set | Source selection, occupancy, final items | Terrain BVH, source meshes |
| Area reorder | Region-stack evaluation | Eligibility, constraints, final | Distribution reservoir, surface BVH |
| Paint dab | Paint mask tiles | Affected candidate set, collision propagation | Other tiles and stable source library |
| Receiver vertex deformation | Surface geometry/BVH refit (if valid) | Local surface samples, slope, bounds | Unrelated receivers and sources |
| UV edit | UV sampler | UV-bound distributions/fields | XY-only fields (unless configured otherwise) |
| Source probability | Source-choice field | Bounds/collision/LOD | Candidate positions, basic region coverage |
| Collision radius | Occupancy | Accepted final list | Placement and surfaces |
| Camera movement | Camera filters/LOD | Possibly population if camera-driven Effects/density | Camera-independent generation |
| Seed | Random channels | Their dependent stages | Source geometry and static surface data |
| Preview quality | Viewport sampling | GPU buffers only | Final accepted list |

## 3. Job orchestration

A small state machine is enough initially:

`CLEAN → DIRTY → QUEUED → BUILDING → READY_TO_PUBLISH → CLEAN`.

A new change while `BUILDING` marks a newer revision and **cancels or supersedes** the old job. The old snapshot stays displayed until a newer valid result is published. Publication checks all consumed revision tokens, not merely a single UI counter if data can change through independent pathways.

```cpp
void OnAuthoredEdit(Edit e) {
    ApplyUndoableChange(e); // main thread
    Revision r = document.Revision();
    DirtySet dirty = graph.Propagate(e.AffectedResources());
    scheduler.Enqueue(BuildRequest{CopySnapshots(dirty), r, dirty});
}

void OnWorkerCompleted(BuildResult result) {
    // Dispatch to proper host/UI thread before interacting with 3ds Max.
    if (!result.revisions.Match(CurrentRevisions())) return; // stale
    PublishImmutableBuffers(result); // atomic pointer/version swap
}
```

Add cancellation checkpoints at candidate batches, tile boundaries and heavy field builds. Avoid taking locks per instance. Don't publish partially inconsistent buffers unless explicitly operating in progressive-preview mode with clearly marked partial quality.

## 4. Spatial tiling strategy

Use tiles for caching and spatial queries, **not as a mandate that all algorithms be independent per tile**. A local spatial coordinate may be defined by scatter/receiver in XY; UV mode uses island-aware parameter-space tiles and possibly world-space acceleration too. Potential world-space tile dimensions must be benchmarked, not guessed as universal.

For each tile retain: world bounds, coordinate-space bounds, candidate range and stable IDs, area field revisions, receiver hashes, occupancy halo, final instance buffer, performance counters, publish generation and LRU state.

### Dirty area expansion

For a paint dab of radius `r`, falloff max `f`, random-placement max displacement `j`, collision support max `c`, and effect reach `e`, a conservative first bound is:

`dirtyBounds = dabBounds expanded by (f + j + c + e)`

This is only safe if all influences have finite, known support. Expressions that sample arbitrary external objects, long paths or unbounded effects can require larger regions or global rebuilds.

### Cross-tile collision halo

Each occupancy tile queries neighboring accepted/candidate items overlapping its enlarged bounds. Stable candidate priority must not depend on evaluation-thread ordering. Use one consistent owner rule for cross-tile items and avoid duplicate acceptance.

## 5. Why greedy collisions can propagate beyond one tile

Suppose A and B overlap; A wins. A is removed by painting. Then B becomes accepted. B may collide with C, previously accepted. This can cause a chain of changes beyond the original brush radius. An algorithm that reevaluates only directly touched tiles is **incorrect** if its final accepted state differs from the full solution.

Three possible strategies:

1. **Full rebuild for collision-affected scatters:** correct baseline, simpler, use while prototypes mature.
2. **Dependency tracking:** for each accepted/rejected candidate, record conflict edges and winner priority; propagate changes until stable. Need graph-memory budget and cycle-free priority semantics.
3. **Spatially bounded independent solver:** define tiles/patches whose winner rules cannot be changed from outside or include boundary buffer partitions; sacrifices some global maximality to guarantee bounded invalidation. Must make seams visually acceptable.

Recommended first implementation: deterministic global priority + full fallback; add differential-tested incremental solver only after profiling proves necessary.

## 6. Deterministic work scheduling

Parallelize independent stages and candidate chunks, but do **not** let iteration order choose collision winners accidentally.

Use a deterministic per-candidate rank `(priorityHash, stableCandidateId)`; stable sorts or conflict-solver policies define decisions. Random sampling uses keyed RNG channels. For floating ties, define an epsilon and canonical ID tie break.

Memory/performance note: large global sorts may dominate; compare block sorting, spatial-cell queues and tile-local determinism. Measure on actual data.

## 7. Data cache types and eviction

| Cache | Key | Reusable by | Safe eviction |
|---|---|---|---|
| Receiver BVH | node+geometry/topology revision+time | Multiple scatters | Yes; reprepare |
| UV lookup | receiver+UV channel/revision | UV distributions/fields | Yes |
| Spline arc table | path UUID+geometry transform revision+tolerance | Path generators and distances | Yes |
| Object occupancy mask | object+projection axis+world resolution+revision | Area queries | Yes |
| Painted compiled tiles | paint UUID+stroke revision+tile+resolution | Area/distance queries | Yes; strokes survive |
| Candidate reservoir | generator+space/seed/algorithm version+tile | Density/source changes | Yes |
| Accepted snapshot | all evaluated input keys | Viewport/render/export | Yes, if recomputable |
| Source animation sample | source+frame+renderer capabilities | Many instances and time frames | Bounded LRU |
| GPU preview | final-instance revision+quality+device | Viewports | Drop on device loss |

Store per-cache memory, hit/miss, build time, outstanding job count, and eviction count in diagnostics.

## 8. Hashing and validity

**Revision != content hash.** Revisions are fast invalidation counters. Content hashes help reuse immutable derived data if equivalent inputs return after Undo. Hashes must include algorithm version and coordinate interpretation. Do not hash raw `struct` padding or pointer addresses. Snapshot scene nodes in canonical deterministic order. For very large meshes, topology and vertex revision counters may be preferable to repeated full hashes if host change notifications are reliable.

## 9. Preview while painting

Design two latency budgets:

- **Brush feedback:** cursor, overlay coverage, erase indication; independent of scatter rebuild, updated as often as possible.
- **Population preview:** background worker or bounded synchronous update; stale results discarded.

During continuous strokes, accumulate dirty bounds and use throttling/coalescing. Commit a final authoritative reevaluation when the stroke ends. Support explicit "Fast draft preview" if background collision/Effects are expensive; indicate quality differences.

## 10. Benchmark correctness protocol

For every incremental path, run seeds 1..N across random edit sequences: build full, apply edit incrementally, build fresh full, sort by stable IDs, compare counts, transforms, sources and rejection reasons. Include cross-boundary placements, dense occupancy, overlapping Areas, effect-driven movement, large source radii, stacked receivers, undo/replay, cancel mid-job and camera movement.

Do not promote the incremental solver to production until tests pass. See `15_TESTS_BENCHMARKS.md`.
