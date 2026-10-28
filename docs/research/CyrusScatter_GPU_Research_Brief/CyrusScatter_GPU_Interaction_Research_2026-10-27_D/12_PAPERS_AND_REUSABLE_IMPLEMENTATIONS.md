<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 12 — Papers and reusable implementations

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Adoption principle

Use public papers and repositories to reduce research risk, not to import an entire framework before Cyrus proves a need. The initial product semantics are static rooted fitting and canonical mesh delivery, while most public GPU hair/cloth systems are time-dependent simulations embedded in their own graphics engines.

## Foundational methods

| Source | Relevant idea | Transfer to Cyrus | Limits | Recommendation |
|---|---|---|---|---|
| XPBD, Macklin et al. (2016) | compliant constraints with accumulated multipliers; stiffness less dependent on timestep/iteration count | length, bend, root/socket and contact constraints | iterative convergence still depends on schedule/contact set; dynamic formulation adds state | reimplement small required equations; use paper as reference |
| Discrete Elastic Rods, Bergou et al. (2008) | centerline plus material frame, bending/twist energy and parallel transport | rest frames, twist-aware branches/stems | more state and nonlinear math than simple grass requires | use for advanced comparison/future Animate, not first dependency |
| Position and Orientation Based Cosserat Rods | position/orientation constraints for rods | explicit orientation, stretch/shear, bend/twist | collision and Max mesh binding remain separate | prototype against focused fitter if broad leaves/branches need frames |
| Projective Dynamics (2014) | local projections plus global linear solve | large batches of mostly quadratic deformation constraints | changing contacts and branching matrix/factorization complexity | not first implementation; revisit for large coherent active regions |
| Karras LBVH (2012) | massively parallel hierarchy construction | possible GPU rebuild for dynamic/repacked spatial data | persistent static source/collider BVHs may not need frequent rebuild | use as GPU broad-phase lead only after measured need |
| Position Based Dynamics survey/implementations | geometric constraint patterns | fixtures and CPU reference | general library scope and dynamic semantics | inspect/reuse tests/math patterns, not whole runtime automatically |

## CUDA Samples

**Verified repository/revision:** NVIDIA `cuda-samples`, release `v13.4`; inspected commit `5443602d89ed99aede2e4b7bf329daddeadb320e`.

Useful code locations:

- `cpp/5_Domain_Specific/simpleD3D11/` — external-resource D3D11 buffer update and keyed-mutex synchronization example.
- `cpp/5_Domain_Specific/simpleD3D11Texture/` — creates `ID3D11Device`, registers D3D11 textures with CUDA and renders them.
- `cpp/0_Introduction/simpleCudaGraphs/` — graph construction/replay pattern.
- scan/sort examples and common helper code for standalone experiments.

**Limits:** these samples own their D3D device/resources. They do not establish Max's public ownership contract. Sample helper code is not necessarily production architecture.

**Recommendation:** copy concepts into isolated standalone proofs; do not package the sample tree or claim Nitrous support from it.

## Khronos OpenCL SDK and specifications

**Verified release:** OpenCL SDK `v2026.05.29`, synchronized to OpenCL `3.1.1`, commit `e26922bdf54eaa9fcc31fe1f91d21b8d2bd6970f`, Apache-2.0.

Useful elements:

- headers/loader/examples for a reproducible matched harness;
- official D3D11 sharing extension definitions;
- command-buffer/mutable-dispatch extension capability model;
- ICD loader behavior.

**Limits:** SDK presence does not provide a vendor device; optional extensions and performance vary. Max still must expose compatible D3D resources.

**Recommendation:** implement the same standalone solver schema in OpenCL as the portability comparator. Production adoption depends on measured parity and product hardware policy.

## NVIDIA Warp

**Verified release:** `v1.18.0` (5 Oct 2026), Apache-2.0. Inspected source includes `mesh_query_point`, mesh/BVH code, spatial-query benchmarks and examples.

Potential value:

- rapid Python-authored CUDA/CPU research kernels;
- mesh/BVH experiments and automatic differentiation if later optimization research needs it;
- quick generation of reference datasets.

Risks:

- Python/JIT/runtime footprint and packaging are different from a native Max plugin;
- its mesh-sign/constructor capabilities and GPU architecture must be checked per version;
- embedding Warp does not solve Max graphics interop or renderer/Bake delivery.

**Recommendation:** optional offline/standalone research harness only. Reimplement the selected small native kernels in Cyrus after the algorithm is stable, unless a separate dependency review proves production value.

## PositionBasedDynamics repository

**Verified repository:** `InteractiveComputerGraphics/PositionBasedDynamics`, MIT, inspected commit `10a70bc146a97873dc3c8fef372f5217e010542e`.

Relevant paths:

- `PositionBasedDynamics/PositionBasedElasticRods.h/.cpp`
- `Demos/CosseratRodsDemo/`
- `Simulation/Constraints.cpp`
- SDF/distance-field demos and collision code.

Value:

- executable reference for Cosserat stretch/shear and bend/twist constraints;
- CPU fixtures and implementation comparison;
- evidence that rod math alone is only one layer of a larger simulation system.

Limits:

- broad library dependency and dynamic simulation architecture;
- no Cyrus asset preparation, stable-ID publication, visible-ribbon validation, Max lifecycle or renderer output.

**Recommendation:** inspect equations/tests; avoid adopting the entire library for first static fitting.

## TressFX

**Verified repository:** `GPUOpen-Effects/TressFX`, MIT; latest tagged release `v4.1.0` (2020), inspected public code commit `ba0bdacdfb964e38522fda812bf23169bc5fa603`.

Relevant paths:

- `src/TressFX/TressFXSimulation.cpp`
- `src/Shaders/TressFXSimulation.hlsl`
- dispatch stages such as integration/global constraints, velocity shock propagation, local shape constraints, length/wind/collision.

Transferable lessons:

- strand-level and vertex-level dispatch separation;
- grouping constraints into multiple passes;
- GPU-resident strand state and HLSL compute scheduling;
- need for authored/exported strand structure.

Limits:

- time-dependent hair simulation rather than quasistatic vegetation fitting;
- engine-owned D3D12/Vulkan context, not Max Nitrous;
- older release/toolchain and hair-specific rendering;
- no exact visible card/leaf triangle certificate or Max renderer/Bake path.

**Recommendation:** reuse scheduling concepts and test ideas; do not adopt as production dependency.

## CUDA versus OpenCL reusable primitives

| Need | CUDA candidate | OpenCL candidate | Adoption |
|---|---|---|---|
| prefix scan/compaction | CUB/CCCL | custom/SDK example or selected library | use mature primitive after deterministic key/output audit |
| radix sort | CUB/Thrust/CCCL | custom/vendor/third-party | sort stable IDs/pairs only when measured |
| graph replay | CUDA Graphs | command-buffer extension where supported | optional optimization after correctness |
| mesh BVH query | custom/Warp research | custom OpenCL | shared algorithm specification; backend-specific implementation |
| profiling | Nsight Systems/Compute | event profiling/vendor tools | both plus host/presentation instrumentation |

Do not count library kernel speed without its allocation, synchronization and licensing/deployment context.

## Rigid-body engines

Jolt/PhysX-style rigid collision infrastructure can supply shape definitions, BVHs, broad phase and queries, but a rooted vegetation system still needs:

- source guide preparation and bindings;
- root/parent constraints;
- whole-segment and visible-envelope contact;
- quasistatic success/failure semantics;
- compact pose state;
- canonical viewport/render/Bake evaluation;
- Max/thread/lifetime integration.

A general “GPU rigid bodies” feature is not evidence for this rooted deformable workload.

## License summary, not legal advice

| Component | Public license evidence | Distribution note |
|---|---|---|
| CUDA Samples | BSD-style source headers in inspected sample | retain notices/conditions when reusing code; toolkit/runtime EULA separately applies |
| OpenCL SDK | Apache-2.0 | retain license/NOTICE obligations as applicable |
| NVIDIA Warp | Apache-2.0 | large runtime/dependency review still required |
| PositionBasedDynamics | MIT | attribution/license; dependency graph review |
| TressFX | MIT | attribution/license; old engine integrations not directly usable |
| papers | publication copyright | reimplement ideas/equations; do not redistribute papers as code assets |

The local release process must separately review NVIDIA runtime redistributables, OpenCL loader/runtime packaging, installer signing and third-party notices.

## Selected reuse strategy

1. **Specifications/papers:** authoritative equations and numerical fixtures.
2. **CUDA Samples/OpenCL SDK:** standalone interop and matched backend harnesses.
3. **PositionBasedDynamics:** CPU rod reference and adversarial tests.
4. **TressFX:** GPU pass decomposition and HLSL scheduling reference.
5. **Warp:** optional rapid research/BVH harness.
6. **Production Cyrus:** focused native implementation after gates; no large dependency until measured benefit and distribution review.
