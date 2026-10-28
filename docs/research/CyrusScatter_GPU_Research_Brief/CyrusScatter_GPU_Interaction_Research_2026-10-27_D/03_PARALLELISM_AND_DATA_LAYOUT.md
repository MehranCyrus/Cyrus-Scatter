<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 03 — Parallelism and data layout

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## The central execution fact

**[P]** The scene may contain up to one million admitted instances, but a drag request is local: only plants in the union of the collider's old and new neighborhoods are candidates. The correct top-level algorithm is therefore sparse compaction, not an `N`-wide solver launch.

```text
changed collider revisions
        ↓
old/new spatial query
        ↓
compact stable-ID candidate list K
        ↓
group by source and complexity
        ↓
classify roots / select active guides
        ↓
contact + fit active guide spans
        ↓
validate complete visible result
        ↓
stage compact poses and visibility
        ↓
publish newest complete generation
```

See [diagrams/01_stage_dataflow.mmd](diagrams/01_stage_dataflow.mmd).

## Work decomposition

| Granularity | Parallel opportunity | Dependency / divergence hazard | Recommended use |
|---|---|---|---|
| Instance | Different affected plants are independent for one-way fixed-collider response | source sizes and contact counts vary widely | primary outer compaction and batching unit |
| Rooted group | roots and their attachments can often be solved independently | shared parent branch or common surface refinement couples groups | good CPU task / GPU work item after ownership classification |
| Guide | independent blades are highly parallel | branches depend on parent frames; broad foliage can share constraints | warp/subgroup-per-guide or one guide per small block |
| Span / segment | contact tests are parallel | constraint solve updates adjacent nodes | parallel contact generation; level/color/Jacobi solve |
| Node | simple integration/projection is parallel | one thread per node produces irregular memory and synchronization | use within a guide block, not as the only global mapping |
| Collider pair | broad/narrow tests are independent | duplicate contacts and reduction order | compact pairs, sort/group by plant, reduce deterministically |
| Triangle | exact visible validation is parallel | reduction to per-triangle/per-plant diagnostics | tiled BVH traversal or triangle batches |
| Render vertex | canonical guide-to-mesh evaluation is independent | pose gather and normal/tangent reconstruction | ideal vertex shader or compute kernel work |
| Parent depth | branches at one depth can update after parents | deep/uneven trees produce low occupancy | level schedule for hierarchical plants |

## Recommended scheduling hierarchy

### Sparse front end

1. **CPU host snapshot** records changed transforms and revisions.
2. **CPU spatial query** produces candidate plant IDs from old and new collider bounds.
3. Candidates are sorted by stable ID and grouped by source revision.
4. A first classification pass emits counts for active rooted groups, guides, spans and pairs.
5. Prefix scans allocate compact output ranges without per-request heap allocation.

This front end should remain CPU-first until a measured `N`-wide query cost justifies persistent GPU broad phase. It already avoids touching most resident instances and is responsible for semantic invalidation and source ownership.

### GPU/parallel mapping options

| Work size | Mapping | Why |
|---:|---|---|
| very short guide, few spans | one warp/subgroup per several guides | avoids underfilled blocks |
| medium guide | one warp/subgroup per guide | neighbor communication through shuffle/shared memory |
| long or branching guide | one block/workgroup per rooted group | local reductions and iterative constraints stay resident |
| heterogeneous plant | queue of `(plant, guideRange, complexityClass)` | prevents one very complex plant from stalling an entire launch |
| exact visible mesh | one thread per triangle/vertex after source grouping | coherent source reads and deterministic reduction buffers |

A single thread per whole plant is rejected because one 451-guide plant and one two-guide plant have radically different work. A single global thread per node is also incomplete because constraints require neighbor/parent coordination and per-plant convergence state.

## Constraint update strategies

### Jacobi-style

Each iteration reads positions/frames from generation `t` and writes independent corrections to a separate buffer, followed by a deterministic reduction or averaging pass.

**Advantages:** parallel, race-free, easy double buffering.  
**Costs:** more iterations and memory traffic; simultaneous contacts can converge slowly.

### Colored / level Gauss–Seidel

Partition constraints so no two in a color write the same node. Process colors sequentially; constraints inside a color run in parallel. Parent-depth levels are a related schedule for branches.

**Advantages:** better convergence than pure Jacobi.  
**Costs:** preprocessing, sequential color barriers, poor occupancy for small colors, topology-specific schedules.

### Serial per-guide Gauss–Seidel

A warp or block owns one guide and performs ordered span constraints in local/shared memory.

**Advantages:** predictable convergence and few global barriers.  
**Costs:** guide-length divergence and limited parallelism when `K×G` is small.

**[R] Baseline:** parallelize plants/rooted groups and contact generation; keep each short guide's constrained fit ordered inside a warp/block. Use level scheduling for branch parents. Compare with Jacobi only in the standalone prototype rather than committing to one universal solver.

## Deterministic ordering

Deterministic scene identity does not require bitwise CPU/GPU floating-point equality.

- Candidate IDs are sorted by `(layerID, placementID, sourceRevision)`.
- Active guides are emitted in source guide order.
- Contact witnesses are reduced with a stable key `(guideID, spanID, colliderID, featureID)` and an explicit tie rule.
- Per-request diagnostics use fixed output slots, not unordered atomic append order.
- Publication merges by stable ID after the request revision is revalidated.
- Numerical acceptance uses tolerances and invariant checks; it does not compare raw bit patterns.

## Proposed immutable source schema

```cpp
struct SourceHeader {
    uint64_t source_id;
    uint64_t source_revision;
    uint32_t guide_count;
    uint32_t span_count;
    uint32_t vertex_count;
    uint32_t triangle_count;
    float3   local_bounds_min;
    float3   local_bounds_max;
};

struct GuideRange {
    uint32_t first_node;
    uint16_t node_count;
    uint16_t parent_guide;      // 0xffff for root
    uint16_t parent_socket;
    uint16_t flags;
};

struct GuideNodeSOA {
    float *rest_x, *rest_y, *rest_z;
    float *rest_qx, *rest_qy, *rest_qz, *rest_qw;
    float *radius;
    float *arc_length;
};

struct VertexBinding {
    uint32_t guide_id;
    uint16_t span_id;
    uint16_t flags;
    float    u;
    float3   rest_offset_xyz;
};
```

**[R]** Use SoA for numerical kernels and an AoSoA tile (for example 32 or 64 nodes) where kernels repeatedly load all fields. Preserve a source-level canonical order and maintain a remap table if a GPU-optimized order differs.

## Proposed request and active-work schema

```cpp
struct RequestKey {
    uint64_t scene_epoch;
    uint64_t owner_revision;
    uint64_t placement_revision;
    uint64_t source_set_revision;
    uint64_t collider_geometry_revision;
    uint64_t collider_transform_revision;
    uint64_t interaction_settings_revision;
    uint64_t request_serial;
};

struct ActivePlant {
    uint64_t placement_id;
    uint32_t source_slot;
    uint32_t first_active_guide;
    uint32_t active_guide_count;
    uint32_t first_pair;
    uint16_t pair_count;
    uint16_t flags;
    float4x3 local_from_world;
};

struct ActiveGuide {
    uint32_t plant_slot;
    uint32_t guide_id;
    uint32_t first_span;
    uint16_t span_count;
    uint16_t parent_depth;
};

struct CandidatePair {
    uint32_t plant_slot;
    uint32_t collider_slot;
    uint32_t local_shape_slot;
    uint32_t flags;
};
```

## Compact pose output

```cpp
struct PoseHeader {
    uint64_t placement_id;
    uint32_t first_changed_guide;
    uint16_t changed_guide_count;
    uint16_t hidden_word_count;
    uint32_t diagnostic_slot;
};

struct ChangedGuidePose {
    uint32_t guide_id;
    uint32_t first_node_pose;
    uint16_t node_count;
    uint16_t flags;
};

struct NodePose {
    float3 position_local;
    uint32_t packed_quaternion; // optional only after measured error qualification
};
```

Do not allocate `N×G` pose state. Store only changed guides for `K` plants, plus a hidden-root mask and sparse rigid-part changes. Rest guides are implicit through the immutable source.

## Stage-by-stage complexity

Let `Q` be spatial-query output before exact candidate pruning.

| Stage | Expected work | Storage |
|---|---:|---:|
| old/new neighborhood query | approximately `O(log N + Q)` for tree, or touched cells for grid | resident instance bounds `O(N)` |
| stable compaction/grouping | `O(Q)` plus sort `O(K log K)` or radix `O(K)` | `O(K)` |
| collider leaf collection | `O(P)` after instance-space reuse | `O(C + P)` |
| contact generation | analytic `O(KGS C_local)`; mesh `O(KGS log T + hits)` | contacts `O(P_contact)` |
| iterative fit | `O(K G_active S I)` | two guide buffers for Jacobi or one local buffer for ordered guide solve |
| visible refinement | roughly `O(K V_active log T)` or triangle-BVH overlap work | exact diagnostics/scratch |
| pose publication | `O(changed guides + hidden words)` | retained compact poses `O(Kp×changed)` |
| CPU mesh materialization | `O(K V)` | potentially `O(KV)` unique vertices |
| shader deformation | `O(K V_visible)` only when drawn | shared source + pose buffers |

The formulas expose two different scalability limits: the solver scales with active guides/spans, while final unique mesh delivery scales with vertices. A fast guide solver cannot compensate for materializing thousands of high-poly unique plants.

## Analytical byte counts

**[A]** These are lower bounds, excluding allocator alignment, indices, materials, BVHs, staging, diagnostics and history.

| Data | Formula | Supplied 451-guide / 22,032-vertex source |
|---|---:|---:|
| instance transform | `48N` B | 1M = 45.78 MiB |
| instance bounds/identity estimate | `32N` B | 1M = 30.52 MiB |
| full guide pose at 48 B/guide | `48KG` B | 21.14 KiB/plant; 1k = 20.65 MiB; 10k = 206.45 MiB |
| hidden-root bitset | `ceil(G/8)K` | 57 B/plant; 10k = 0.54 MiB |
| positions + normals | `24KV` B | 0.504 MiB/plant; 1k = 504.27 MiB; 10k = 4.92 GiB |
| positions + normal + tangent | `40KV` B | 0.840 MiB/plant; 10k = 8.21 GiB |

These numbers are why shared-source shader deformation is the first GPU target and why a full unique vertex buffer for every affected high-detail clump is not a scalable default.

## Data residency policy

1. Upload immutable prepared source geometry, bindings and guide rest data once per source revision.
2. Cache collider geometry/BVH or proxy once per collider geometry revision; update transforms separately.
3. Upload compact changed-transform and candidate data for a request.
4. Keep scratch pools keyed by capacity class; never allocate a new heap for every pointer event.
5. Publish compact poses; do not read back full deformed meshes during dragging.
6. Materialize exact CPU geometry only for validation gates that require it, renderer requests, Bake/export, or fallback.
7. Retire old buffers only after the associated graphics/compute fence and publication generation are complete.

## Crossover rule

No fixed `K` threshold is proposed. The runtime route must be chosen from measured distributions:

```text
if GPU unavailable or request unsupported:
    CPU reference
else if active_work < measured_crossover[source_class, quality]:
    CPU fit + optional shader deformation
else:
    GPU candidate path
```

The crossover table is valid only for the qualified hardware/driver/build/quality configuration and must include dispatch, synchronization, transfer and final validation—not only kernel time.
