# Parallelism, dependencies, and buffer layout

**Status: P — proposed layouts and scheduling; E — a narrower deformation surrogate was executed.**

## Define the populations

Use `N` for resident placements, `K` for affected plants after neighborhood filtering, `G` for affected guides, `Q` for guide nodes, `P` for candidate collider pairs, `V` for vertices actually deformed/drawn, and `T` for triangles checked. Report all of them. “One million objects” is not a useful workload definition without this decomposition.

A GPU runs many independent arithmetic tasks in groups. It does not allow arbitrary dependent branches to update simultaneously without coordination. Independent blades provide abundant parallel work; a parent-child stem hierarchy requires the child's attachment to use a coherent parent result. Irregular collision traversal can also make neighboring threads spend very different amounts of time working.

## Where parallel work fits

| Stage | Candidate decomposition | Dependency/cost to respect |
|---|---|---|
| Broad-phase plant query | Query per moved collider; compact unique plants | Small K may favor existing CPU index |
| Collider pair generation | Plant/collider pair tests | Never allocate N × obstacle count |
| Root exclusion | Root-group samples against admitted shapes | Exact mode and consistent mask ownership |
| Guide contact | Lane/thread per span or coherent guide subgroup | Whole spans, not only endpoint samples |
| Guide fitting | Subgroup per guide, or plant workgroup | Sequential corrections, parent levels, solver divergence |
| Frame reconstruction | Guide chain scan/transport | Root frame and twist continuity |
| Leaf/stem deformation | Thread per vertex | Mostly regular gathers; excellent initial target |
| Surface validation | Vertex/triangle candidates | Independent evaluator, thin features, conservative bounds |
| Bounds and status | Segmented reductions by stable owner | Deterministic validity, explicit incomplete work |

GPU BVH traversal benefits from coherent query order; fewer arithmetic operations alone need not produce faster traversal. This motivates benchmarking source/shape buckets and spatial ordering rather than assuming a uniform grid wins. [Karras, GPU traversal](https://developer.nvidia.com/blog/thinking-parallel-part-ii-tree-traversal-gpu/).

## Proposed immutable source bundle

Each preparation revision owns a numeric bundle containing:

- Local rest positions, normals/tangents, UV/material and original-face correspondence.
- Guide-node offsets/counts, rest lengths, parent guide/span/material parameter, root-group ID, anchor masks, and rest frames.
- Per-vertex binding kind: fixed, deforming stem, or rigid foliage attachment; guide/span/material parameter and rest offset.
- Per-root-group face mapping, optional guide-to-face adjacency, and conservative rest/reachable bounds.
- Collider acceleration structure or admitted proxy/SDF plus geometry revision, error bounds, and units.

Use integer offsets into flat arrays, never host pointers, `shared_ptr`, STL objects, Max nodes, or opaque engine addresses inside device buffers. Add explicit format/version fields, element counts, checked offsets and byte charges. Hash the serialized preparation identity; do not use a transient scene node handle as the content key.

## Proposed instance and active bundles

An illustrative 64-byte instance record can hold a rebased positive-uniform transform, source table index, stable numeric lookup, flags, and pose indirection. This is a design budget, not the current C++ `Instance` size. Full stable identities and source revisions remain owned on the CPU; a GPU numeric slot must be generation-checked before it maps back to one.

For active work use structure-of-arrays or small aligned records:

```text
ActivePlant: stableSlot[], sourceId[], pairBegin[], pairEnd[], posePage[]
ActiveGuide: plantSlot[], guideId[], nodeBegin[], nodeCount[], parentLevel[]
PoseNode:   position.xyz / packed auxiliary, orientation.xyzw
Status:     outcome[], complete[], iterations[], maxResidual[], overflow[]
Visibility: per-root bitsets + explicit authored hiding mode
```

The exact pose wire format must match `posePoint` semantics. A quaternion plus translation is 32 bytes with aligned float4 fields, but current rest-to-pose reconstruction may need different data. Do not commit to this estimate before the CPU/GPU deformation parity test.

Use 64-bit host byte arithmetic and checked multiplication even if per-dispatch indices fit 32 bits. Split oversized dispatches with explicit base offsets; do not let a 32-bit `N * V` wrap into a smaller allocation.

## Scheduling choices

**One thread per plant** is simple but poor for heterogeneous plants: one lane can traverse hundreds of guides while adjacent lanes finish tiny grasses. **One subgroup per guide** gives cooperating lanes for short node chains and contact tests, but underutilizes long leaf meshes and does not solve branch ordering. **One workgroup per plant** supports shared memory, yet a large tree can exceed local-memory/register budgets. Bucket by node count and contact mode; keep exceptional complex cases separate.

A first guide fitter can process parent-depth levels in separate launches. Within a level, independent guides run concurrently. A guide may perform sequential local corrections inside its subgroup. This preserves a clear dependency graph at the cost of launch barriers. For large depths, compare persistent work queues or graph coloring only after measuring the simpler version.

Jacobi-style updates read one iterate and write another, exposing parallelism but changing finite-iteration behavior. Gauss-Seidel uses fresh corrections and can converge differently, with more dependency. Graph coloring can avoid write conflicts, but shared branch attachments and contact constraints determine the graph. Changing update order requires quality requalification; it is not merely a backend port.

## Compaction and deterministic identities

Flag candidates, prefix-scan into bounded lists, sort by stable instance/guide/pair IDs where required, and run kernels over those compact lists. A device overflow counter invalidates the successor; silently dropping excess entries is forbidden. Atomics may build temporary lists, but deterministic sorting and explicit tie-breaking are needed before persistent publication.

Keep old and new neighborhoods so that departing colliders restore rest state. GPU visibility culling must not remove plants from the authoritative interaction set: an offscreen plant may become visible immediately after a camera move. Visibility is an output/draw optimization; contact relevance is a separate input relation.

## Sparse updates must remain sparse in storage

Allocate pose pages only for changed guides or affected plants. An absent page means the immutable rest definition, not an uninitialized pose. Retiring the last change releases the page after readers finish. A two-level indirection avoids rewriting every instance record when pose pages move, but its extra shader reads must be benchmarked.

Do not hide a dense per-instance guide table inside a “sparse” design. At 451 guides, a 4-byte lookup table already costs 1,804 bytes per posed instance before node data. Prefer source-shared guide metadata plus active-instance indirection and compact guide patches; compare dense pages for genuinely dense active plants. [Memory estimates](09_MEMORY_PRECISION_AND_HARDWARE.md) quantify the difference.

## A useful experimental lesson

The first local CUDA version used less explicit vector alignment than the OpenCL `float4` version. Correcting matching 16-byte float4/8-byte index-pair layout and inlining changed the relative result substantially. Final source includes static size assertions. This is evidence that layout/compiler choices can dominate an API-brand comparison. It is not evidence that either final kernel is optimally tuned.
