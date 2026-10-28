# 01 — Executive decision

[Contents](00_README.md) · [API matrix](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) · [Implementation gates](13_PHASED_IMPLEMENTATION_PLAN.md)

## Recommendation

**Proposal. Approve a narrow CPU-fit → compact-pose → supported-HLSL deformation prototype, accompanied by CPU critical-path instrumentation and a small Max 2027 interoperability proof. Do not begin with a full GPU physics engine or a resident million-instance GPU solver.**

Keep the present CPU fitter and complete visible-surface validator as the correctness reference. Preserve source preparation, fixed anchors, authored parent/leaf bindings, stateless rest restoration and separate exclusion semantics. The first optimization should test whether shared-source drawing from sparse guide poses reduces materialization, unique geometry storage and uploads at acceptable draw cost. It requires no CUDA/OpenCL collision solver and may be useful even when direct compute/graphics sharing is unavailable.

If a large active neighborhood makes contact fitting the measured bottleneck, build **CUDA as the first experimental compute backend**, with a matched OpenCL implementation on the **same NVIDIA GPU**. This prioritizes reusable scan/sort infrastructure and diagnostics, not an unsupported claim of faster CUDA arithmetic. A qualified D3D11 compute path can become preferable if it reduces the host resource/synchronization burden. Keep the CPU plugin functional with optional acceleration absent. The weighted matrix in [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) explicitly changes winner when host integration or cross-vendor priorities change.

## What the evidence establishes

| Evidence class | Finding | Decision consequence |
|---|---|---|
| **S — supplied** | One 200-plant scene produced three nearby candidates, six fitted guides, 62 hidden groups and about 4.05 ms native contact evaluation in one run | This is a sparse workload. It cannot establish a GPU crossover, presented latency or million-plant throughput |
| **V — public SDK** | Max 2027 exposes retained streams/HLSL parameters and also `ID3D11GraphicsWindow::GetDevice()` returning `ID3D11Device*` | A blanket claim that Max has no public native D3D device hook is incorrect; there is a concrete probe |
| **U — host integration** | A documented device getter does not establish a retained-buffer bridge, legal compute submission, ownership or retirement in Cyrus's actual Nitrous callbacks | Prove the complete resource lifecycle before relying on zero-copy or direct D3D11 compute |
| **V — source inspection** | Public CUDA/OpenCL samples own their graphics resources; current TressFX code uses dynamic strand and sampled-vertex contact assumptions | Useful building blocks, not ready Max/static-vegetation adapters |
| **X — this assignment** | Ten Python arithmetic/analytic controls passed; supplied hashes and document/archive checks were performed | Reproducible narrow evidence only; no GPU, Max, production fitter or renderer benchmark |
| **E — explicit arithmetic** | Dense all-instance guide/mesh state can dwarf shared source geometry | Admit resident, retained and active memory separately; do not hide multiplication behind instancing |

The SDK hook and HLSL binding facts are supported by current 2027 declarations. Their practical in-host use remains unexecuted. [M06](17_SOURCE_LEDGER.md#m06) [M10](17_SOURCE_LEDGER.md#m10) [M03](17_SOURCE_LEDGER.md#m03)

## Four very different populations

1. **One million resident instances, a few changed plants.** Keep the CPU spatial index, immutable source cache and sparse changed poses. Avoid scanning/uploading all instances per pointer event. Profile retained-map copying and publication as well as contact math.
2. **Thousands of affected guides/plants.** Candidate for GPU fitting after measured crossover. Group work by guide length, branch depth and contact representation; use bounded pair lists and explicit synchronization.
3. **Millions of changing blades or vertices.** Candidate for parallel deformation and compact pose lookup. Vertex counts, material passes, surface verification and renderer copies still cost work and bytes.
4. **Millions of detailed clumps, hundreds of guides each.** Reject the naïve all-active representation as an interactive workstation target. Under the explicit eight-node hypothesis, one million copies of the supplied 451-guide source need about **122.672 GB of pose/header data**, before generation copies, contacts and rendering; unique float position/normal/tangent streams add **881.28 GB**. These are storage estimates, not allocation measurements. [09](09_MEMORY_PRECISION_AND_HARDWARE.md)

A million simple one-guide blades is not equivalent to the fourth case. Neither admission count nor shared source meshes prove that all their vertices can be deformed, verified and presented at a desired rate.

## Recommended sequence and stop conditions

| Priority | Concrete next result | Stop/reverse if |
|---|---|---|
| 1. P0 telemetry | Replayed CPU reference with stage costs and `N,K,D,H,Q,P,V_A` counts | Capture, retained-map copying or publication dominates; optimize that boundary first |
| 2. P1 deformation | One shared ribbon with rest/two distinct poses, correct normals, hidden groups, bounds and instance picking in public Max HLSL | Supported pose inputs fail, parity fails, or repeated draw work outweighs saved CPU/upload memory |
| Parallel P2 interop | Standalone compute, standalone sharing, supported in-Max bridge and renderer delivery treated as separate proofs | Private casts, undocumented ownership or host-context takeover would be required; select staged fallback |
| 3. P3 narrow fitting | Same static equations, analytic contacts and quality on CPU/CUDA/OpenCL; canonical CPU-readable poses | Complete readback/validation/upload route has no worthwhile crossover or requires lower quality |
| 4. Large-scale cases | Sparse N sweep separately from large-K/all-active sweep | Memory or worst-case query work exceeds admission; reject honestly instead of dropping guides |
| 5. Release qualification | Async revision safety, Undo/deletion/reset, recovery, renderer/Bake and absent-driver startup | Any stale/partial publication, source mutation, ownership bug or final-geometry mismatch remains |

**P.** Use a 20% paired end-to-end p95 improvement over three sessions as an initial adoption margin in the workload bins routed to a new backend, with unchanged quality and bounded memory. It is a proposed business/engineering gate, not an observed speedup or a universal requirement. Exact crossover and hardware minimum are unresolved until measured.

## The highest-risk unknown

**Can the actual Max 2027 retained drawing path safely consume a plugin-owned compute-written resource through public interfaces, with a documented device/context lifetime, completion and device-recreation protocol?**

`GetVertexBuffer(length,FVF)` is not an established unwrap of a `VertexBufferHandle`, and `SmartHandle::GetPointer()` is not a documented native D3D resource pointer. The native hook makes the investigation concrete; it does not answer it. A complete failure of direct sharing need not end GPU research: compact pose readback plus public HLSL uploads remains an option, but both transfers, CPU validation and publication must be included in the latency comparison. [07](07_MAX_2027_INTEROP_FEASIBILITY.md)

In the proposed authoritative design, **CPU-readable completed poses remain required even with direct sharing**. Sharing may remove a second display upload or full-mesh copy; it does not automatically remove the pose readback required by CPU validation, persistence and final geometry.

## Numerical and product boundaries

Root position anchoring and root orientation stiffness stay separate. Contact gap is added once to the bending metric; Hide margin controls a separate complete group-exclusion rule. Missing SDF data, no nearby surface hit, overflow, nonfinite input, nonconvergence and cancellation never become a clear result. Endpoints outside are insufficient for whole-segment clearance, and guide clearance is insufficient for broad leaves.

A proxy/field preview must have an explicit approximation/error contract and refinement status. It may not solve only convenient blades and hide the rest. A visible fixed root can make the requested fit infeasible; retain the prior complete publication and explain the conflict. A GPU path preserves the existing static operation rather than introducing history-dependent wind, inertia or settling.

Async work uses owned snapshots, stable IDs, relevant dependency revisions, a base publication sequence and bounded in-flight resources. Coalescing keeps dirty edits since the last validated publication. Draw/style changes reuse the accepted result. These are new engineering obligations, not properties established by the current synchronous executor. [08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md)

## Current-version findings to retain in procurement/build decisions

The inspected NVIDIA archive lists CUDA 13.4.3, while the live detailed release notes identify 13.4 Update 2; record that mismatch rather than invent a qualified installed version. Current OpenCL unified specification is v3.1.2, but published features are not a driver capability inventory. Autodesk's newer IDE baseline must not obscure its explicit v14.38 build-tools guidance. These facts justify exact local installer/header/driver and compiler records, not a requirement to buy the latest GPU. [C01](17_SOURCE_LEDGER.md#c01) [C02](17_SOURCE_LEDGER.md#c02) [C06](17_SOURCE_LEDGER.md#c06) [M29](17_SOURCE_LEDGER.md#m29)

The implementable next assignment is P0 + P1, with P2's read-only native-device/resource investigation in parallel. The remaining documents provide the data schema, completeness rules, failure matrix, runnable arithmetic controls and measurable gates required to decide whether to proceed to GPU fitting.
