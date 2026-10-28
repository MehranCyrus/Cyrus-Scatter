<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 01 — Executive decision

## Evidence labels

This package uses the following labels consistently:

- **[V] Verified public source** — supported by an official specification, vendor documentation, original paper, or inspected public source repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — copied from the supplied `CURRENT_SYSTEM_CONTEXT.md` or `BRIEF_METADATA.json`; not independently verified against the private repository.
- **[M] Provided measured observation** — a measurement reported by the supplied context. It was not reproduced by researcher A.
- **[E] Executed here** — an operation actually run in the research environment. These are limited to input-hash checks, analytical calculations, document/link validation, manifest generation, and ZIP integrity checks.
- **[A] Analytical estimate** — derived from explicit assumptions or byte-count formulas; not a benchmark.
- **[R] Recommendation / proposed design** — an engineering proposal to be tested.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

A statement may carry more than one label, for example **[P][M]** for a supplied project measurement.


## Decision statement

**[R] Recommended minimum coherent architecture**

> Keep Cyrus's current CPU interaction pipeline as the authoritative solver and validation reference. Add a bounded graphics-shader deformation path that draws shared source geometry from compact per-instance guide poses. Treat CUDA/OpenCL contact fitting as a second, evidence-triggered optimization. Do not make direct CUDA↔Nitrous or OpenCL↔Nitrous resource sharing a production dependency until a public Max 2027 SDK proof passes.

This recommendation is conditional, not ideological:

- If local profiling shows CPU contact fitting and visible-surface refinement dominate even for the real `K` distribution, the next prototype should accelerate those stages.
- If deformation/materialization/upload dominates, shader deformation provides value without replacing the proven contact semantics.
- If Max exposes no supported pose-buffer path, keep CPU materialization and investigate compact buffer uploads through the existing supported handles before any native graphics interop.
- If cross-vendor GPU support becomes a hard product requirement, OpenCL/D3D11 compute or a portable shader path receives more weight.
- If typical `K` remains 1–10 and the supplied ~4.05 ms contact observation is representative at p95, the optimized CPU path may remain the economically correct result.

## Why this order

### 1. Sparse edits are not a million-body solve

**[P]** The supplied system already keeps total resident instances (`N`) separate from affected candidates (`K`): one reported 200-plant fixture found three nearby candidates and fitted six guides, and a 5,000-instance numerical footprint test found one affected neighborhood. The current task is a moved collider with old/new neighborhood invalidation, not an all-scene physics step.

The first decision is therefore not “Can a GPU process one million objects?” It is:

> At what measured `K`, guide/contact density and source complexity does the complete GPU path beat the CPU path after capture, candidate compaction, submission, synchronization, publication, bounds, drawing and final validation?

### 2. The existing viewport already has the lower-risk GPU boundary

**[P]** Cyrus already owns retained custom render items, GPU buffers, HLSL materials and instanced triangle draws. **[V]** Max 2027's public `HLSLMaterialHandle` can bind a `SmartHandle` buffer parameter, and `IVirtualDevice` can draw instanced geometry. **[S05–S07]** This makes shared-source vertex deformation a plausible first proof.

That proof still has unresolved requirements: per-instance pose lookup, buffer update semantics, shader-model limits, culling bounds, hit testing, visibility masks, wireframe consistency and resource invalidation. It is nonetheless narrower than implementing collision BVHs, constrained rods, asynchronous GPU jobs and native D3D interop at once.

### 3. Standalone interop support is not a Max support claim

**[V]** CUDA documents D3D11 resource registration with `cudaGraphicsD3D11RegisterResource`, map/unmap ownership and same-device restrictions. OpenCL's `cl_khr_d3d11_sharing` requires an actual `ID3D11Device*`, creates memory from actual D3D11 resources and mandates acquire/release. NVIDIA's CUDA samples create and own their D3D11 device/resources. **[S10, S14, S21–S22]**

**[U]** The inspected Max 2027 public APIs do not document a native D3D device pointer or compute dispatch. Until the installed headers/samples prove otherwise, an architecture that requires registering Nitrous resources with CUDA/OpenCL is blocked.

### 4. Correct vegetation contact is more than point kernels

A GPU solver must reproduce or deliberately bound:

- fixed root position and root-mode policy;
- whole-segment/capsule contact, not endpoint-only tests;
- parent/child guide ordering and attachments;
- visible blade/foliage envelope, not a clear centerline alone;
- closed-mesh occupancy and stable surface witnesses;
- multiple colliders, infeasible gaps and root-inside cases;
- Contact gap exactly once and independent Hide margin modes;
- last-good-result retention when quality is not achieved.

Moving these rules to a GPU is feasible in principle, but it is not the smallest path to value.

## Architecture options

| ID | Architecture | CPU work | GPU work | Quality boundary | Main risk | Recommendation |
|---|---|---|---|---|---|---|
| A | Optimized CPU fit + CPU deformation | all current numerical work and materialization | retained draw only | current reference | may not scale for large `K`/unique geometry | **Keep as fallback and reference** |
| B | CPU fit + GPU vertex/normal deformation | capture, neighborhood, contact, fit, validation, final materialization on demand | shared-source pose evaluation in HLSL | contact remains CPU exact; viewport pose must match CPU evaluator | Max buffer/indexing/bounds/picking support | **First GPU prototype** |
| C | CPU search + GPU fit + GPU deformation | scene snapshot, candidate list, final validation/publication | contacts, constraints, poses, viewport deformation | requires matched GPU collision and convergence diagnostics | transfers, divergence, interop, incomplete visible-surface checks | **Prototype only after profiling** |
| D | Persistent GPU scene: search + fit + deformation | host capture/revisions/publication | resident scene index, search, contacts, fit, deformation | largest rewrite; dual CPU/render paths still needed | ownership, stale state, VRAM, device loss | **Reject for first delivery** |
| E | Interactive proxy/SDF GPU + exact final CPU refinement | final exact verification/materialization | low-resolution field/proxy interaction | preview explicitly approximate; final must be exact enough | preview/final popping, field errors, build cost | **Conditional for large active regions** |

## Weighted decision matrix

Scores are 1 (poor) to 5 (strong). Weights reflect the current product: static edit response, Max 2027, strong correctness/failure semantics and NVIDIA permitted but not required.

| Criterion | Weight | CPU only | CPU fit + shader deform | CUDA fit + deform | OpenCL fit + deform | Persistent GPU scene |
|---|---:|---:|---:|---:|---:|---:|
| Preserves current contact semantics | 20 | 5 | 5 | 3 | 3 | 2 |
| Max 2027 integration risk | 18 | 5 | 4 | 2 | 2 | 1 |
| Sparse `K` efficiency | 12 | 5 | 4 | 2 | 2 | 2 |
| Large `K` upside | 12 | 2 | 4 | 5 | 5 | 5 |
| Renderer/Bake consistency | 10 | 5 | 4 | 3 | 3 | 2 |
| Failure recovery / last-good | 8 | 5 | 4 | 3 | 3 | 2 |
| Tooling/debuggability | 7 | 4 | 4 | 5 | 3 | 3 |
| Cross-vendor reach | 5 | 5 | 4 | 1 | 5 | 3 |
| Distribution simplicity | 4 | 5 | 5 | 2 | 3 | 2 |
| Future dynamic simulation | 4 | 2 | 3 | 5 | 4 | 5 |
| **Weighted score / 5** | **100** | **4.42** | **4.25** | **3.08** | **3.20** | **2.35** |

The score does **not** claim CPU is always faster. It says CPU/reference plus shader deformation has the best current risk-adjusted sequence. A large-`K` workload distribution and a proven interop path can reverse the result.

## Conditional CUDA versus OpenCL decision

### CUDA is conditionally preferred when all are true

- Product policy accepts an NVIDIA GPU requirement for the optional accelerated backend.
- Target hardware and driver/toolkit are explicitly qualified.
- Same-GPU resource or compact-transfer path is proven in Max.
- GPU fitting is measured to dominate after the shader deformation prototype.
- CUDA's Nsight tooling, graphs, CUB/Thrust/CCCL ecosystem or Warp-based research harness materially shortens implementation/diagnosis.
- CPU fallback remains loadable when CUDA is absent.

### OpenCL is preferred or retained when one of these is true

- AMD/Intel support is a product requirement.
- A public Max D3D11 device/resource path is available and the target OpenCL runtimes expose `cl_khr_d3d11_sharing`.
- Matched NVIDIA measurements are similar enough that portability outweighs CUDA tooling.
- A D3D11 compute implementation can reuse HLSL and supported resource ownership more cleanly than either CUDA or OpenCL.

### Neither API should be selected yet when

- `K` is usually tiny;
- CPU capture/publication/snapshot copy dominates;
- Max does not expose the required supported resources;
- final CPU validation/materialization erases the gain;
- interactive quality requires exact mesh checks that remain serial/CPU;
- GPU device loss or missing runtime would make the plugin fail to load.

## Workload sensitivity

| Workload | Likely best starting path | Reason |
|---|---|---|
| `N=1M`, `K=1–10`, few changed guides | CPU fit; compact pose upload; shader deform | dispatch and synchronization can exceed arithmetic; resident `N` need not be touched |
| `K=100–1k`, shared sources, many changed guides | CPU/GPU crossover experiment | enough active work to amortize launch; pose storage remains manageable |
| `K=10k`, mostly shared sources | GPU fit/deform becomes plausible | large parallel population; VRAM and final validation become central |
| millions of vertices changing, few source types | shader/compute deformation | avoid CPU unique mesh expansion and full uploads |
| thousands of detailed clumps with hundreds of guides | GPU may help, but memory/contact divergence dominate | needs compact active-guide state, batching and source grouping |
| full-scene, all-active, many unique sources | likely offline or bounded quality mode | economically and physically different from local drag; must be admitted explicitly |

## Required quality tiers

### Final / publishable

- CPU reference or GPU result independently validated against the declared geometry.
- Root and attachment invariants pass.
- Visible-surface clearance meets tolerance, not merely guide clearance.
- No stale revisions.
- Renderer/Bake materialization path exists.
- Failure preserves last complete result.

### Interactive approximation

Allowed only if visibly labelled and bounded:

- simplified collider proxy or narrow-band SDF;
- reduced iterations or affected-guide subset selected by geometry, never arbitrary deletion;
- conservative clearance;
- no claim of final contact quality;
- exact final Update/refinement before publish/render/Bake.

## Falsifiers

The recommendation changes if one of these is observed:

1. **CPU fit dominates:** p95 CPU guide/contact/refinement exceeds the interaction budget at modest `K` while deformation/upload is minor. Then move directly to a narrow GPU fitter prototype.
2. **Shader deformation blocked:** Max cannot bind enough structured pose data, cannot index per instance safely, or cannot provide correct bounds/picking. Then keep CPU materialization and investigate supported stream-output/UAV or compact CPU uploads.
3. **Interop proven:** installed Max 2027 headers/samples expose a supported native D3D path and the in-Max proof survives device recreation, multi-adapter systems and mixed viewports. Then direct compute-written buffers receive higher priority.
4. **Typical `K` remains tiny:** production traces show `K≤10` at p99 and current CPU fits within target. Then a GPU solver is rejected; only deformation may remain useful.
5. **Final validation dominates:** exact visible-surface refinement/materialization costs more than the proposed GPU solve. Then accelerate or redesign the validator/materializer before the solver.
6. **OpenCL parity plus portability:** matched NVIDIA results and tool effort are comparable, and cross-vendor support is commercially important. Then OpenCL or D3D11 compute can outrank CUDA.
7. **CUDA tooling materially wins:** graphs, libraries and profiling reduce total integration time and p95 latency without unsupported interop. Then CUDA becomes the supported optional backend.

## Immediate next action

Run the six prototypes in [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md), beginning with CPU stage instrumentation and the Max buffer/shader proof. Do not implement a production GPU solver before P0, P1 and the renderer/Bake materialization proof have measurable pass results.
