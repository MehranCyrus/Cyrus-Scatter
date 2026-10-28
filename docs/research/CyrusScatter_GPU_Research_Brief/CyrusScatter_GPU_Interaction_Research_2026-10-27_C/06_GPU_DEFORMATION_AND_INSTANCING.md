# 06 — GPU deformation, sharing and final geometry

[Contents](00_README.md) · [Parallel data](03_PARALLELISM_AND_DATA_LAYOUT.md) · [Max feasibility](07_MAX_2027_INTEROP_FEASIBILITY.md)

## The first useful GPU experiment

**P.** Feed already validated CPU guide poses into the existing public HLSL/retained display route and evaluate positions and shading frames during drawing. Keep a CPU evaluator for verification, final meshes, bounds and picking. This tests a narrow, reusable boundary before changing collision mathematics or introducing external compute.

A vertex shader evaluates independently bound vertices. It does not discover contacts, resolve multiple obstacles, classify roots, propagate coupled branch mechanics or prove a surface clear. Conversely, a CUDA/OpenCL solver is not necessary just to evaluate a known deformation. Historical vegetation vertex-shader work demonstrates the drawing pattern, but its procedural wind and shallow hierarchy are not the present stateless obstacle fitter. [R19](17_SOURCE_LEDGER.md#r19)

This route is not automatically faster. A static CPU mesh can be uploaded once and drawn many times; shader deformation repeats per visible vertex, view and pass. If the CPU already materializes all vertices for exact validation, that CPU calculation remains. Potential savings are retained unique vertex memory, repeated mesh copies and upload bytes, plus CPU deformation that can genuinely be omitted. Measure all four separately.

## One authoritative evaluation contract

**P.** First expose the existing CPU evaluator's exact binding semantics as a versioned numeric contract. Do not replace it with generic skinning because that is easy to find in a GPU sample. Its outputs must define position, normal, tangent/sign, root-group visibility, parent sockets and fixed-part behavior for a requested completed pose.

For a narrow ribbon proof, a proposed binding is `(source guide, rest span, rest parameter s, rest local offset o, root group)`. Let `c0(s), R0(s)` be the rest centerline/frame and `c1(s), R1(s)` the fitted ones. One possible map is:

\[
o=R_0(s)^T[p_0-c_0(s)],\qquad p_1=c_1(s)+R_1(s)o.
\]

The same rest parameter identifies material along the blade. It must not be recomputed by nearest-guide search at each edit. Any rest-to-current reparameterization is explicitly part of the evaluator. At rest, this map reproduces `p0` within arithmetic error; a rest sentinel may return original position/normal bytes exactly. The formula is a **proposal for a restricted prototype**, not evidence of the current Cyrus implementation.

Frames include authored rest twist. Parallel transport/rotation-minimizing frames can avoid a Frenet frame's inflection singularity, but must be seeded by the authored root material frame and combined with authored twist. Finite rotations need a consistent quaternion sign convention and deterministic near-antiparallel handling. The original RMF method supplies a frame-transport construction, not a plant-binding contract. [R17](17_SOURCE_LEDGER.md#r17)

Parent attachments store an explicit parent material coordinate/socket and local rest frame. Evaluate parents before children. Fixing a child's socket position is distinct from allowing or resisting socket rotation. A fixed root ring, authored fixed part and an independently bendable leaf must retain their own roles; no shader may reinterpret them from current vertex position.

Dual-quaternion or linear-blend skinning is an alternative only if the prepared source uses those weights and its CPU reference agrees. Dual-quaternion blending addresses important rigid-transform blending artifacts, but does not enforce guide length, root constraints or collision clearance. Do not change the deformation method between CPU and GPU in an API comparison. [R18](17_SOURCE_LEDGER.md#r18)

## Normals, tangents and seams

**P.** Preserve rendering topology independently of guide topology. A welded logical plant node can correspond to multiple render vertices across UV seams, material boundaries, hard normals and tangent handedness. Copy bindings to those render vertices without merging their UV/normal channels. Keep per-corner source normals and material IDs when that is what the source provides.

For rigid attachment, rotate the normal/tangent and re-orthogonalize consistently. For a differentiable deformation `f`, the geometrically appropriate normal mapping is `normalize(J_f^{-T} n0)` when the Jacobian is nonsingular. A simple normal rotation is not generally that Jacobian for a bent surface.

For an admitted curvilinear binding `p_j(s,u,v)=c_j(s)+R_j(s)(0,u,v)`, take the first column of `R` as the guide tangent (a material-frame convention independent of scene +Y up, permuted consistently if the source uses another convention), and form derivative bases `B_j=[∂p_j/∂s, ∂p_j/∂u, ∂p_j/∂v]`; then `J=B_1 B_0^{-1}`. This is a mathematical proposal, not a universally available property of arbitrary source bindings. It requires an invertible rest parameterization and reliable derivatives. Near singularities, return an explicit invalid evaluation or use a separately named CPU-approved normal policy.

If current CPU output intentionally uses rotated authored normals, the first GPU proof must match that policy and label its shading approximation; it must not silently replace source custom normals with averaged face normals. Compare position parity, normal angle, tangent orthogonality/handedness and images under normal maps. Derivative-based normals may be a later quality change, isolated from the compute-API experiment.

No normal policy certifies collision. The visible collision audit uses the deformed triangle geometry, including blade edges, broad leaves and fixed parts. Backface rendering, opacity textures and two-sided materials do not decide whether a collision mesh is a closed solid.

CPU validation and GPU parity share one final-surface clearance budget. Reserve a bound for shader/upload/transform deviation inside that budget, or audit the actual delivered positions; two independently passing tolerances must not add into an unreported penetration. [09](09_MEMORY_PRECISION_AND_HARDWARE.md) specifies the combined-error rule.

## Drawing shared geometry with individual poses

| Representation | Storage | Strength | Cost and limitation |
|---|---|---|---|
| CPU-deformed unique vertices | Roughly `D×V×vertex_stride` | Simple established delivery; static drawing amortizes deformation | CPU work, upload and memory for distinct poses |
| Shared vertices + compact pose gather | Shared source plus `Q_D` nodes, maps and masks | Different instance shapes retain source/index sharing | Additional per-vertex lookup/deformation each draw; bounds/picking need matching data |
| GPU compute deformation cache | Shared source plus unique output for selected instances | Reuse computed vertices across several passes | Still `D×V` output memory; compute-to-graphics bridge/fences required |
| Quantized/shared pose variants | Source plus finite pose palette and assignments | Can reuse identical output | A new approximation; local obstacles can make near-identical poses differ in clearance |

Prefer exact identical pose reuse by hash only after comparing full pose/visibility/evaluator keys; hash collision handling is required. Quantizing poses or assigning one representative bend to many plants changes geometry and must be an explicit quality mode with measured error and renewed collision validation. Instance scale/transform affects clearance, so a shared shape variant alone is not a proof for every placement.

Use separate rest/fixed and changed batches where useful. Material IDs divide index ranges; source material references remain immutable. Hidden groups either have filtered index/draw lists or a consistent whole-primitive discard scheme. All vertices of a triangle must agree on its group; a preparation error that mixes hidden and visible groups within a face is rejected or explicitly repaired. Merely moving hidden vertices to one point can leave Wireframe lines, picking artifacts or degenerate-normal problems and needs its own test.

Per-instance ID, transform, pose page and visibility location travel in the supported instance stream. Max 2027 documents the last-buffer instance-stream restriction. Its HLSL material setter offers a buffer-binding route; texture uploads provide another candidate if exact buffer formats/stages fail. These are concrete public API starting points, not an executed shader integration. [M06](17_SOURCE_LEDGER.md#m06) [M07](17_SOURCE_LEDGER.md#m07) [M09](17_SOURCE_LEDGER.md#m09)

Do not place an arbitrary full plant pose in one constant buffer. Feature-level 11 has 4,096 16-byte constant-buffer elements; the hypothetical 451-guide, eight-node, 32-byte-frame pose exceeds that single-buffer size. Chunked structured/typed/texture lookup needs explicit resource and batch limits. [R12](17_SOURCE_LEDGER.md#r12)

## Bounds and picking are part of delivery

**P.** A draw-time-deformed vertex does not automatically expand Max's CPU object bounds. Publish bounds with the same pose revision. For a rigid-frame sweep, bound each guide centerline segment plus the maximum admitted binding offset, include child/fixed geometry and the interpolation overshoot bound, then transform to world space with admitted uniform scale. Cubic curves require a conservative curve bound; endpoint boxes alone can miss interior extrema. Uncertain bounds must be conservatively enlarged or exactly evaluated, not silently culled.

Picking uses the published pose and visibility. Options are a CPU deformed triangle query built for selected/candidate instances, or the documented custom render item's hit-test rendering with exactly the same shader and masks. The documented default hit test identifies a render node, not automatically a stable scatter-instance ID. Add explicit CPU pose-ray/instance-ID mapping or qualify a separate ID pass after batch sorting and compaction. Compare pick IDs/depths against the CPU reference and test that hidden groups cannot be selected through stale geometry. Publish the conservative item-local `SetObjectBox` before culling: `Realize` can be skipped for a culled item, so it cannot reliably repair a stale rest bound. `SetVisibilityGroup` selects render-item viewport categories, not the rooted-group mask. Custom render item bounds and hit-test APIs are documented, but current plugin behavior requires a local probe. [M01](17_SOURCE_LEDGER.md#m01) [M02](17_SOURCE_LEDGER.md#m02)

Wireframe must deform the same vertices with the same pose and show only the same surviving groups. Switching fill/shading does not invalidate contact, prepare sources, or upload unchanged pose pages. Changing camera position can affect drawing/culling only. A separate future display LOD cannot be used as the authoritative collision geometry without a declared approximation contract.

## Renderer, Bake and export

**P.** CPU-readable poses remain the portable completed result. A renderer or Bake request selects a completed `(source revision, pose revision, time, evaluator version, quality)` and materializes the same evaluator into owned geometry. Current static interaction does not require time stepping; unrelated animation times reuse static poses unless a relevant source/placement/collider dependency is time-varying and explicitly supported.

For renderer mesh APIs, respect `GetRenderMesh` ownership/`needDelete` and multiple-mesh transforms where applicable. A viewport HLSL shader is not automatically translated to Arnold, V-Ray, Corona or an exporter; each local plugin/version must pass geometry, materials, normals, time-sampling and ownership tests. [M27](17_SOURCE_LEDGER.md#m27)

GPU-only results cannot be the sole canonical scene representation. If a solver runs on CUDA/OpenCL, read back compact guide poses/status first, then use the CPU evaluator for renderer/Bake geometry, or qualify an explicitly separate renderer procedural adapter. The former has smaller transfer than reading full meshes but still incurs CPU materialization. For animated future modes, materialize requested shutter samples with stable topology and an explicit motion-blur contract; the present study does not deliver that mode.

Bake must be a transaction: snapshot the accepted result, admit total bytes, create outputs in bounded batches, preserve source material/channel semantics, and either complete the requested output or return a clear failure with cleanup. Source assets stay immutable. Distinct deformed instances may become distinct baked meshes; exporting a proxy or mesh is a delivery choice, not a way to hide the unique geometry cost.

## Minimal proof and rejection conditions

The narrow prototype uses the included prepared ribbon control, an authored twisted ribbon, a branched source with one fixed root ring, a broad leaf, and the local supplied 451-guide asset. It exercises two distinct poses plus rest, multiple materials/UV seams, normal maps, hidden groups, Wireframe and picking. GPU and CPU use the same pose bytes and evaluator specification.

Reject this route as the default if pose lookup cannot be expressed through supported public Max inputs, if output parity fails, if correct normals consume unacceptable cost, or if retained CPU meshes deliver better p95 under realistic repeated drawing. Keep it as an optional memory-saving path only if the product accepts its measured tradeoff. A technically successful shader is not itself a performance result.
