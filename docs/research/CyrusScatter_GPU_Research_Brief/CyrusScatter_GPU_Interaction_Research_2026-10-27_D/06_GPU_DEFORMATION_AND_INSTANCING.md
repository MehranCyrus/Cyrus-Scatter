<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 06 — GPU deformation and instancing

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Product boundary

A pose is not a mesh. Cyrus needs one canonical guide-to-mesh evaluator whose inputs and output semantics are shared by viewport, renderer materialization and Bake/export.

**[R]** Keep the source immutable. Unaffected instances stay on the current transform-only instancing path. Affected instances reference a compact pose; only final output paths that require explicit geometry materialize unique vertices.

## Delivery alternatives

| Delivery | Geometry sharing | Memory / draw impact | Correctness path | Recommendation |
|---|---|---|---|---|
| unique CPU mesh per affected instance | none for changed vertices | `O(KV)` CPU + upload; batching limited | straightforward renderer/Bake | correctness reference/fallback, not interactive default |
| shared source + vertex-shader pose gather | source vertices/indices shared | compact poses; same source can batch | CPU canonical evaluator for validation/final output | **first GPU prototype** |
| compute-deformed vertex buffers | source shared, outputs unique or pooled | `O(KV)` GPU buffers unless transient | possible direct draw only if supported interop | later, after Max proof |
| reusable bent variants | shares each variant | `O(K_variant V)` and quantization | visible approximation | optional distant/quality tier |
| renderer-specific procedural | renderer-dependent | potentially efficient | host/renderer contract required | defer until selected renderer proof |

## Canonical evaluator

Each render vertex has one explicit primary guide/span binding for the initial contract:

```cpp
struct Binding {
    uint32_t guide_id;
    uint16_t span_id;
    uint16_t flags;
    float u;                  // [0,1]
    float3 rest_offset_xyz;   // full rest-frame offset
};
```

For rest span endpoints `(p0,q0)` and `(p1,q1)` and deformed endpoints `(p0',q0')`, `(p1',q1')`:

```text
center(u) = lerp(p0, p1, u)
frame(u)  = normalize(slerp_shortest(q0, q1, u))
vertex    = center(u) + frame(u) · rest_offset_xyz
```

The same formula evaluates rest and deformed geometry. Quaternion sign is normalized for shortest-path interpolation. Ambiguous near-full-turn spans, invalid/nonfinite frames or zero-length spans are rejected during preparation rather than silently collapsed.

For multi-guide smooth bindings in a later level, use a bounded influence list and a formally defined blend (for example dual-quaternion or normalized frame blend), but do not make the first prototype depend on arbitrary skin weights.

## Rest reconstruction gate

Before a source can use GPU deformation:

1. evaluate every vertex through the rest guide/frame binding;
2. compare to supplied source positions with scale-aware tolerance;
3. preserve render-vertex identity, seam duplication, UVs, triangle indices, material IDs and source revision;
4. verify that the declared guide envelope contains bound visible geometry;
5. reject unsupported full-turn/ambiguous frames.

Coincident positions do not authorize welding. UV seams, hard-normal splits and double-sided card vertices remain distinct render vertices.

## Normals and tangents

### Initial supported path

- Transform an authored rest geometric normal/tangent by the local frame deformation if the evaluator is locally rigid enough.
- Re-orthonormalize tangent against normal and preserve handedness.
- For large curvature or nonrigid blending, recompute geometric normals from deformed triangle positions in the CPU reference and compare.

### Deferred

Custom authored normals and renderer-specific tangent bases require a separate fidelity contract. They cannot be assumed correct under arbitrary guide/frame interpolation.

### GPU options

1. **Vertex transform:** cheap; preserves seams but may be inaccurate for strong nonrigid bending.
2. **Compute triangle normal accumulation:** requires UAV/compute path, atomics or two-pass adjacency, and unique output buffers.
3. **Precomputed derivative/Jacobian:** source-specific and more complex; useful only after quality measurement.

**[R]** Start with frame-transformed normals plus an exact CPU geometric-normal comparison on fixtures. Reject/CPU-fallback sources whose error exceeds the declared visual tolerance.

## Visibility and whole rooted groups

Hidden groups are represented by source-level rooted-group IDs and a compact bitset per pose. Attachments inherit root/group visibility. The draw path either:

- uses source-group ranges and indirect/partitioned draws; or
- discards hidden groups in shader only if bounds/picking/render consistency are maintained.

Arbitrary individual triangle deletion is not part of the hiding contract.

## Bounds and culling

A deformed pose requires bounds independent of the rest instance bounds.

Options:

- CPU evaluate guide/envelope bounds, then transform to world; recommended initial path.
- Conservative source maximum-deformation bound; cheap but hurts culling.
- GPU reduction readback; adds synchronization and cannot be the first path without evidence.

The published bound must contain every visible deformed vertex. Use an independent CPU audit in qualification.

## Picking and hit testing

Max custom render-item hit testing is distinct from display. A shader-only surface is not automatically pickable.

**[R] Initial behavior:**

- selection remains placement/instance level;
- CPU evaluate compact guide/envelope or a bounded deformed proxy for hit testing;
- use exact materialized mesh only for detailed edit tools that require it;
- verify hit positions against displayed geometry in Max.

## Batching

Group draw items by:

```text
(source revision, material variant, deformation shader variant,
 visibility layout class, pose buffer generation)
```

One source vertex/index buffer is reused. Per-instance data contains transform, pose offset/count, hidden-mask offset and stable ID. Do not group instances with incompatible source revisions or unsupported bindings.

A candidate per-instance record:

```cpp
struct DrawInstance {
    float4x3 world_from_source;
    uint32_t pose_header_index;
    uint32_t hidden_mask_offset;
    uint32_t stable_id_low;
    uint32_t flags;
};
```

## Pose lookup in shader

```hlsl
StructuredBuffer<DrawInstance> gInstances;
StructuredBuffer<PoseHeader>   gPoseHeaders;
StructuredBuffer<ChangedGuide> gChangedGuides;
StructuredBuffer<NodePose>     gNodePoses;
StructuredBuffer<Binding>      gBindings;

VSOut VS(uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
{
    DrawInstance inst = gInstances[instanceID];
    Binding b = gBindings[vertexID];
    PoseSample pose = FindChangedOrRestPose(inst.pose_header_index, b.guide_id);
    float3 p = EvaluateBinding(b, pose);
    float3 n = EvaluateNormal(vertexID, b, pose);
    return TransformAndShade(inst.world_from_source, p, n);
}
```

The sparse changed-guide lookup must be bounded. Options include a per-pose sorted range plus binary search, a compact per-active-pose remap table, or a small source-guide-indexed table only for currently drawn affected instances. Benchmark the gather pattern; do not allocate `N×G` globally.

## CPU/GPU consistency

Use shared golden fixtures and one specification, not duplicated undocumented behavior.

- same rest/deformed frame interpolation;
- same coordinate conversion and uniform scale;
- same hidden groups;
- same source revision and binding identity;
- CPU reference in double/local high precision;
- GPU FP32 local evaluation;
- compare world/local positions, normals, bounds and triangle clearance with scale-aware tolerances.

Capture the worst vertex, triangle, guide and instance IDs. A visually plausible screenshot is not sufficient.

## Renderer, Bake and export

The initial production contract should be:

1. Viewport may use shared-source shader deformation after qualification.
2. At render/Bake/export request, the host obtains the latest complete pose generation.
3. CPU canonical evaluator materializes explicit vertices, geometric normals/tangents under the selected policy, topology, UVs and materials.
4. The independent visible validator runs or uses a previously certified immutable result.
5. Renderer/Bake receives the explicit mesh/proxy representation supported by that output path.

GPU-only buffers are transient and not serialized as scene truth.

## Variants

Quantize poses only as an optional quality tier:

- key by source revision, obstacle-relative direction/distance class and quality settings;
- record maximum vertex/normal/contact error against exact pose;
- use hysteresis to avoid switching pops;
- bound cache count and memory;
- invalidate on source/evaluator/settings revision;
- never use a variant whose visible clearance certificate fails.

Variants are useful for distant mass deformation, not a substitute for exact hero contact.

## Source immutability and invalidation

| Change | Invalidate |
|---|---|
| source positions/topology | preparation, bindings, source GPU buffers, all poses, bounds, materializations |
| UV/material only | corresponding streams/material grouping; geometry binding only if vertex identity/topology changes |
| guide/root/parent edit | guide preparation, bindings/poses and dependent attachments |
| envelope edit | contact certification and all affected poses |
| shader/evaluator revision | GPU cache and consistency certification |
| collider transform | old/new affected requests only |
| collider geometry | collider BVH/field and affected requests |
| camera/style/wireframe | draw state only; no solve/reupload of unchanged poses |

## Minimum Max viewport proof

The P1 proof must establish:

- a `SmartHandle`/supported buffer can carry multiple source guides and per-instance pose offsets;
- `SV_InstanceID` and `SV_VertexID` indexing is correct across batches;
- update does not recreate immutable source buffers;
- mixed shaded/wireframe viewports retain data;
- bounds and culling remain correct;
- hit testing uses the declared CPU/proxy path;
- device recreation invalidates and rebuilds transient resources safely;
- no native/private D3D extraction is used.

Failure of this proof does not reject GPU solving; it changes delivery to compact pose readback plus CPU/host-supported upload/materialization.
