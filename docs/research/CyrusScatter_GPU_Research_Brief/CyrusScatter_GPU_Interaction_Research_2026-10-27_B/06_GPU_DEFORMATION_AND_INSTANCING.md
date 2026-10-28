# 06 — GPU deformation, instancing and final geometry delivery

[Index](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Source ledger](17_SOURCE_LEDGER.md)

Researcher A · 2026-10-27 · **Proposed architecture and tests; no shader, renderer or Max execution**

## 1. Accelerate a distinct stage

The fitter decides a guide pose. The deformation evaluator maps prepared source geometry through that pose. The renderer draws/evaluates the resulting surfaces. These are separate computations. Moving the evaluator into a vertex shader does not solve contact, while a GPU contact solver does not automatically deliver a mesh to a renderer.

The project already supplies shared preparation, rooted groups, branch hierarchy, foliage bindings, fixed parts and stable fingerprints **[Provided]**. Preserve those semantics. First reproduce the current CPU evaluator, then investigate storage and execution improvements; do not silently replace source binding or root behavior with a new GPU skinning algorithm **[Proposal]**.

Ordinary `GenerateInstanceData`/`GenerateInstanceRenderItem` describes copies of geometry with instance transforms (and selected per-instance attributes). `InstanceDisplayGeometry` offers broader instance attribute updates, but does not establish arbitrary per-instance guide deformations. A custom HLSL evaluator needs its own pose lookup. [MAX18](17_SOURCE_LEDGER.md#max18) [MAX19](17_SOURCE_LEDGER.md#max19)

## 2. Canonical evaluator contract

**Proposal:** define one versioned numerical evaluator with CPU reference and compatible GPU implementation. The result is identified by `(source fingerprint, binding revision, instance ID, transform revision, pose revision, visibility revision, evaluator version, precision policy)`. This key is independent of whether the sink is viewport, renderer, Bake or export.

Inputs:

- Immutable source positions, topology, UV/corner channels, authored normals/tangents and material slots.
- Persistent guide/node/span IDs mapped to compact runtime indices; reference centreline/frame and attachment data.
- Sparse changed-guide pose records; unchanged guides point to reference data.
- Whole-root-group visibility and descendant propagation, fixed geometry and rigid-part overrides.
- Explicit source-to-instance and Max-to-metres/+Y conversion at the boundary.

Outputs:

- Positions and either precisely defined transferred authored normals or precisely defined recomputed normals; tangent parity specified.
- Unchanged topology/material/UV identity except explicit removal of complete hidden groups in materialized output.
- Conservative bounds, stable picking identity and diagnostic flags.
- No source mutation and no host/GPU pointer in persistent scene state.

For an independently bound blade, a useful **mathematical sketch**, not a claim about current code, is

\[
F(v)=c_1(u)+R_1(u)R_0(u)^T[v-c_0(u)].
\]

Here the prepared binding fixes `(guide ID, span ID, u)` and the material offset; `c0,R0` are reference data, `c1,R1` are the fitted pose. At exact rest use the original source position directly, avoiding reconstruction roundoff. A leaf with a rigid attachment uses its explicit attachment transform; a fixed part bypasses deformation. A branched child inherits the parent attachment before its own local deformation. Joint regions need the existing multi-guide/cage rule where authored; selecting one arbitrary nearest guide can create cracks.

Preserve the meaning of authored twist. Adjacent quaternion signs must be aligned for interpolation; `q` and `-q` represent the same rotation. If the source permits turns beyond the shortest rotation, store a separate unwrapped twist quantity or reject that interpolation mode. Smooth frame interpolation and finite-rotation composition do not by themselves guarantee length, nonintersection or material volume preservation. Those are constraints/validation responsibilities of the fitting and visible-surface stages.

Root position and root orientation remain distinct. Position-only anchoring may rotate the first root span; if the prepared source requires a root ring or full root frame, the evaluator must consume the solver's explicit constraint policy. Do not “repair” root drift by translating only the displayed mesh while leaving the fitted collision geometry elsewhere.

### Normals cannot be an afterthought

**Proposal:** support two explicit policies, selected at preparation and included in the evaluator key:

1. **Transferred authored normals:** where the binding defines a continuous deformation field with a valid Jacobian, apply inverse-transpose `J^-T` to the authored normal and normalize. A local rigid attachment simply rotates its normal. Using only a guide rotation is an approximation when spatially varying deformation introduces shear/curvature; quantify its angular error.
2. **Recomputed geometric normals:** deform positions, compute triangle normals, then accumulate using the original smoothing/corner equivalence policy. Deterministic adjacency lists avoid a nondeterministic floating atomic accumulation if reproducibility is important. Preserve hard boundaries and authored exceptions.

A vertex shader cannot freely scatter contributions to neighboring vertex normals. For recomputation, choose CPU normals, a qualified compute/stream-output path, or a specially prepared local differential representation. If the shader offers only approximate rotated normals, label that viewport mode accordingly and compare against the declared canonical rule. Do not call both results identical merely because positions match.

Max's `MeshNormalSpec` stores explicit normals with per-face-corner indices. Preserve this topology and its explicit flags at materialization; UV splits and normal splits must not alter botanical guide segmentation. [MAX21](17_SOURCE_LEDGER.md#max21)

## 3. Proposed shared-source draw schema

| Buffer | Lifetime / indexing | Contents and policy |
|---|---|---|
| Source vertex/corner streams | Per unique source and material/evaluator layout | Rest position, UVs, corner normal/tangent, compact binding index, rooted-group index. Render-vertex duplication at seams is permitted; binding identity remains logical. |
| Shared index streams | Per source/material subset | Immutable topology. Optional cached visible index pages only for admitted visibility patterns. |
| Binding table | Per prepared source revision | Guide/span lookup, material coordinate/offset, weights or rigid/fixed binding type. |
| Instance stream | Published placement generation | Transform or compact transform representation, instance slot, pose-table base/page, visibility-page index, material/variant selection. Do not encode arbitrary 64-bit stable IDs in a float. |
| Pose table | Sparse retained changed guides | 32-byte node proposal: position plus padding/auxiliary and unit quaternion; 16-byte guide header plus mapping. Missing entries resolve to rest. |
| Visibility | Per affected instance/root group | Independent hide decision; descendants inherit the root-group visibility. Fit failure is not a visibility operation. |
| Diagnostics and bounds | Per published result | Status, accepted key, fit residual summary, conservative local/world bounds and picking IDs. |

Pose data can be supplied through a bounded constant-array prototype or a paged FP32 texture, using documented `HLSLMaterialHandle` array/texture parameters. `TextureHandle` and `RenderEnums.h` expose floating formats and mapping/writing operations; actual vertex-stage indexing, throughput, page limits and update rules require the I2 test. A raw structured buffer or UAV import must not be assumed from these APIs. [MAX08](17_SOURCE_LEDGER.md#max08) [MAX09](17_SOURCE_LEDGER.md#max09) [MAX10](17_SOURCE_LEDGER.md#max10)

**Proposed shader sketch; not compiled:**

```text
instance = instanceStream[drawInstance]
binding  = sourceBindings[sourceVertex.bindingIndex]
if binding.rootGroup is hidden:
    emit consistent clipped primitive result
else if binding is Fixed or referenced guide has no changed pose:
    p,n,t = original source attributes or explicitly fixed transform
else:
    pose = fetchGuidePose(instance.posePage, binding.runtimeGuideIndex)
    p,n,t = CanonicalEvaluator(binding, sourceAttributes, pose)
apply admitted instance transform and declared normal transform
apply host view/projection for this draw only
```

`clipped primitive result` is an implementation gate, not a promise that writing alpha zero is sufficient. All vertices of a primitive must agree on whole-group visibility; preparation must assign consistent face ownership, split mixed-group primitives at authored boundaries, or reject ambiguous visibility. Shaded, shadow, wireframe and picking passes must obey the same decision. Raster clipping, alternate index streams and separate draws have different cost. Measure the chosen mechanism; do not rely on a pixel-alpha path that leaves wireframe or picking visible. Reusing the same evaluator in the hardware hit-test pass avoids selecting the rest position of a bent blade **[Proposal]**. The custom-item API explicitly offers hit testing and may invoke display repeatedly. [MAX16](17_SOURCE_LEDGER.md#max16)

## 4. What remains shared—and what becomes unique

| Representation | Shared work/storage | Per-instance work/storage | Appropriate use |
|---|---|---|---|
| CPU materialized unique mesh | Source prep/topology and potentially UV/material data | Deformed positions/normals, bounds, renderer acceleration | Conservative fallback and final delivery. |
| Vertex-shader pose gather | Source vertices, topology, bindings and shader | Sparse guide poses, visibility, instance transforms; deformation arithmetic repeats for rendered vertices/passes | First GPU prototype when CPU deformation/upload is a measured bottleneck. |
| Compute-cached deformed vertices | Shared source data and kernel | Unique output mesh for each unique pose plus scratch and synchronization | Many render passes or expensive evaluator may justify caching; memory grows with active/retained unique output. |
| Quantized pose variants | A bounded library of complete meshes/poses | Variant index and transform | Optional artist-approved approximate mode only; cluster error and contact revalidation required. |
| Rigid attached foliage prototype | Leaf prototype mesh | Attachment transforms, visibility, possible material override | Preserves real geometry sharing while stems deform. |
| Deforming leaf surfaces | Source template and bindings | Per-leaf pose/control data or deformed output | Cannot promise rigid instancing savings for arbitrary distinct leaf deformations. |

Unique source geometry is not unique instance geometry. If one million detailed clumps each change all 451 guides, sparse pose storage still becomes hundreds of millions of guide records. A shared vertex shader saves output storage but does not remove vertex processing, rasterization, foliage overdraw or renderer acceleration costs. Conversely, one million resident placements with ten changed plants may retain very little changed geometry. Keep these cases separate **[Analysis]**.

Batch by compatible source topology, evaluator mode, material/pass requirements, texture/pose-page bindings and visibility policy. Avoid one draw per blade. Split pages/chunks before API count or allocator limits. Reordering for batching must retain a stable draw-slot-to-instance-ID map. Preserve per-instance material choices without pretending every different material can share one arbitrary shader invocation **[Proposal]**.

A rough memory lower bound is `32Q + 16H` for compact changed-guide poses and headers versus `24Vd` for materialized FP32 positions/normals. Tangents add at least 16 bytes per render vertex if stored as float4; UVs and indices can remain shared if topology is unchanged. Padding, page slack, visibility, renderer copies, staging, old/front/back generations and independent normal/corner streams must be budgeted separately. See the full memory chapter; these are packet definitions, not measured Max allocations.

## 5. Bounds, picking and host invalidation

**Proposal:** culling and picking use the accepted pose revision, never an unrelated latest GPU buffer. Bounds must include leaf width/offsets and fixed/rigid parts, not just guide nodes. A conservative bound from guide span capsules plus attachment envelopes is a useful first level; exact evaluated bounds can tighten it. Include both old and new display bounds during publication damage/invalidation. Transform once through the admitted positive uniform scale and explicit axis/unit boundary.

Retain source streams across normal viewport redraws, camera changes and Wireframe changes. These may select different material/raster states or index streams; they do not invalidate static contact. Upload only changed pose/visibility/transform pages. The public display interface permits separate per-view items and advises avoiding needless updates; callback frequency must not be mistaken for data invalidation. [MAX17](17_SOURCE_LEDGER.md#max17)

The viewport can show the preceding complete pose while a successor is pending, with a stale/pending diagnostic. It cannot read partially written nodes merely because a kernel has been submitted. The completion and lifetime rules in the async chapter apply to every sink.

## 6. Renderer, Bake and export contract

A custom HLSL viewport material is documented for viewport/Quicksilver usage; it is not a renderer-neutral implementation of production shading. The production path must consume canonical geometry/poses through an explicitly qualified adapter. [MAX09](17_SOURCE_LEDGER.md#max09)

Max provides `GeomObject::GetRenderMesh(t,inode,view,needDelete)` and multiple-render-mesh methods. The ownership flag must match reality: a retained cache uses `needDelete=FALSE`, while an intentionally transferred temporary uses `TRUE`. Renderer abort and requested time are part of the contract. Multiple meshes do not guarantee a renderer recognizes shared prototypes or preserves instances. [MAX20](17_SOURCE_LEDGER.md#max20)

**Proposed delivery sequence:**

1. Pin one complete accepted result and evaluator version for the render/Bake/export request.
2. Resolve any necessary refinement under the explicit quality policy before treating it as final. If current inputs have no valid successor, default to a visible error/blocked final update; rendering an earlier accepted result requires an explicit “use last validated result” policy.
3. CPU-materialize from immutable source plus accepted pose, or consume a validated complete GPU readback with the same numerical contract. Never read back a busy front buffer.
4. Build positions, topology, corner normals, UV channels, material indices, bounds and transforms. Apply scene-unit/+Z conversion exactly once.
5. Use renderer/Max standard geometry delivery with clear ownership. Cache by full geometry key; group identical poses only when equivalence is proved or bounded approximation explicitly selected.
6. Bake creates new ordinary geometry and materials/references according to the authored export policy; it does not overwrite prepared source geometry. Export uses the same materialized state and preserves stable provenance where the format permits.

| Sink | Publicly documented foundation | Required local qualification |
|---|---|---|
| Nitrous | Custom render items, public GPU handles, HLSL parameters | Actual shader/evaluator parity, bounds, picking, passes, device reset, no unchanged uploads. |
| Arnold / MAXtoA | Arnold polygon data includes separate position/normal indices, UV arrays and motion keys; Max also has standard render-mesh callbacks | Exact MAXtoA version and consumed interface, material conversion, opacity/cutouts, instance retention, motion/deformation sample behavior. The cited Arnold format page is a general Arnold/Houdini-host example, not a Max plugin test. |
| V-Ray CPU/GPU | No Cyrus-specific adapter evidence supplied | Pin exact V-Ray build; test standard mesh and any particle/prototype route, UVs/normals/materials, CPU/GPU parity, progressive updates and export. |
| Corona | Vendor documents CPU rendering with optional GPU denoising | CPU-readable geometry delivery remains necessary; pin exact Corona build and instancing/material behavior. |
| Bake/export | Canonical CPU materialization is a feasible design independent of viewport shader resources | Exact file format/exporter, unit/axis, topology/normals/material transfer, missing dependencies, and readback failure handling. |

Sources for renderer foundations: [MAX20](17_SOURCE_LEDGER.md#max20), [MAX31](17_SOURCE_LEDGER.md#max31), [MAX32](17_SOURCE_LEDGER.md#max32). Renderer-specific pass results are **Unknown**, not implied by those foundations.

Current static interaction does not acquire a time integrator merely because a renderer asks for subframes. Unrelated animation must reuse unchanged static poses. If animated collider evaluation or wind is later admitted, define separately which authored state is evaluated at each requested time; motion blur cannot be fabricated by interpolation between two stale interactive publications **[Proposal]**.

## 7. Minimal deformation parity experiment

**Not executed.** Prepare four deterministic assets: (D1) one segmented strip with curved rest, (D2) a multi-guide clump with independent rooted groups, (D3) a branch/child plus rigid leaf attachment, and (D4) a broad deforming leaf with UV/normal seams. Include fixed geometry, one hidden group and two materials. Use rest, gentle bend, high bend, quaternion sign reversal and a nearly antiparallel tangent pose; do not ask a collision solver to generate them.

Evaluate CPU and GPU positions/normals/tangents against exactly the same authored bindings and precision policy. Record maximum position error, RMS error, normal/tangent angular error, root/attachment residuals, visibility/topology/material equality and conservative-bound containment. Test both repeated draws with no edits and alternating complete generations. Deliberately corrupt a pose revision and delay completion to prove rejection.

**Proposed initial screen-independent gate:** use the common thresholds in [09](09_MEMORY_PRECISION_AND_HARDWARE.md): position difference at most `max(1e-5 m, 1e-5 × Lref)`, normal difference at most 0.5 degrees, no nonfinite output, exact visibility/material/corner-index identity, and root/attachment errors within their stricter accepted tolerance. Count evaluator deviation in the total visible-contact error budget. These are hypotheses to ratify against source precision and quality, not existing project acceptance limits. The supplied observed 9.145% checked stem-edge change must not be recast as a universal permissible strain.

Follow numeric comparison with deterministic raster captures in shaded, Wireframe and hit-test contexts; captures are proposed local artifacts, not images produced by this research. Verify renderer/Bake results from the same accepted packet before advertising a GPU feature. Only then measure where GPU deformation improves the completed end-to-end path.
