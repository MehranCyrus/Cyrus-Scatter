<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 00 — Package guide

**Researcher:** A  
**Research date:** 27 October 2026  
**Decision target:** GPU computation for Cyrus Scatter vegetation interaction  
**Baseline used as provided context:** Cyrus Scatter `0.87.4.3`, native interaction capability `11`, scene schema `63`, 3ds Max 2027 / Windows x64.

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


## What this package answers

This package evaluates whether Cyrus should keep the current CPU architecture, move only deformation to graphics shaders, move guide/contact fitting to CUDA or OpenCL, place the entire interaction pipeline on a persistent GPU scene, or use a quality-tiered hybrid. It treats the following as separate populations:

| Symbol | Population |
|---|---|
| `N` | Total resident scatter instances in an interaction layout |
| `K` | Affected instances in the current edit request |
| `G` | Guides per affected instance |
| `S` | Segments per guide |
| `V` | Render vertices per source |
| `C` | Relevant colliders per plant |
| `P` | Candidate contact pairs |
| `I` | Solver iterations |
| `Kp` | Retained unique poses or deformation variants |

The package does **not** infer that a one-million-instance admission means one million complex plants can bend interactively. It does not treat graphics instancing as free per-instance deformation storage, and it does not treat the existence of CUDA/OpenCL/D3D interop in standalone applications as proof that Nitrous exposes equivalent supported resources.

## Concise decision

**[R] Do not begin with a full CUDA or OpenCL solver.** First prove the end-to-end bottleneck and the Max 2027 data path. The highest-value first GPU prototype is:

1. Keep current CPU neighborhood search, root classification, guide fitting, and independent visible-surface validation as the correctness reference.
2. Publish compact per-instance guide poses and visibility masks.
3. Deform shared source vertices and normals in the existing Max custom HLSL viewport path, if a bounded `SmartHandle`/shader-buffer probe proves the required indexing, update and lifetime behavior.
4. Materialize the same pose on CPU for final renderer, Bake and export requests until a renderer-specific path is independently qualified.
5. Only after this prototype shows that deformation/upload/drawing is a material part of input-to-present latency should Cyrus invest in GPU contact/guide fitting.
6. If GPU fitting is justified, compare CUDA and OpenCL on the same NVIDIA GPU with the same kernels, inputs, precision, quality, memory residency and tuning budget. CUDA is the conditional favorite for an NVIDIA-prioritized product because of tooling, graphs and ecosystem—not because an API name guarantees faster kernels.

See [01_EXECUTIVE_DECISION.md](01_EXECUTIVE_DECISION.md).

## Highest-risk unresolved question

**[U] Does the installed Max 2027 public SDK provide a supported way to create, update, bind and synchronize the required pose buffers—or to obtain compatible native D3D resources—without private APIs or taking ownership of Nitrous?**

The inspected public `IVirtualDevice`, `HLSLMaterialHandle`, `DrawContext` and `ICustomRenderItem` pages document retained render handles, custom HLSL parameters, instanced draw, stream output and UAV binding, but they do not document a native D3D device pointer or compute dispatch. **[S04–S07]** This must be resolved by the interop proof in [07_MAX_2027_INTEROP_FEASIBILITY.md](07_MAX_2027_INTEROP_FEASIBILITY.md) before a full solver investment.

## Document map

| File | Purpose |
|---|---|
| [01_EXECUTIVE_DECISION.md](01_EXECUTIVE_DECISION.md) | Conditional recommendation, weighted matrix, sensitivity and falsifiers |
| [02_REQUIREMENTS_AND_CURRENT_SYSTEM.md](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md) | Normalized requirements and supplied baseline |
| [03_PARALLELISM_AND_DATA_LAYOUT.md](03_PARALLELISM_AND_DATA_LAYOUT.md) | Work decomposition, schemas, complexity and byte counts |
| [04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) | Matched API comparison and graphics-compute baseline |
| [05_COLLISION_AND_GUIDE_SOLVING.md](05_COLLISION_AND_GUIDE_SOLVING.md) | Collision representations, static fitter and rod methods |
| [06_GPU_DEFORMATION_AND_INSTANCING.md](06_GPU_DEFORMATION_AND_INSTANCING.md) | Shared-source deformation, normals, bounds, picking and output |
| [07_MAX_2027_INTEROP_FEASIBILITY.md](07_MAX_2027_INTEROP_FEASIBILITY.md) | Public SDK evidence and early proof specification |
| [08_ASYNC_PUBLICATION_AND_LIFETIMES.md](08_ASYNC_PUBLICATION_AND_LIFETIMES.md) | Revisioned requests, buffering, cancellation and recovery |
| [09_MEMORY_PRECISION_AND_HARDWARE.md](09_MEMORY_PRECISION_AND_HARDWARE.md) | Memory lower bounds, precision policy and hardware qualification |
| [10_BENCHMARK_AND_VALIDATION_PLAN.md](10_BENCHMARK_AND_VALIDATION_PLAN.md) | Fair benchmark matrix and measurements |
| [11_EDGE_CASE_AND_FAILURE_MATRIX.md](11_EDGE_CASE_AND_FAILURE_MATRIX.md) | Required trigger/behavior/hazard/test/status matrix |
| [12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md) | Primary papers and inspected code paths |
| [13_PHASED_IMPLEMENTATION_PLAN.md](13_PHASED_IMPLEMENTATION_PLAN.md) | Staged gates, entry/exit criteria and rollback |
| [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) | Reproducible isolated prototypes |
| [15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) | Runtime absence, fallback, caching and artist-facing behavior |
| [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) | Precise local source/SDK/host probes |
| [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md) | Versioned primary-source register |
| [18_ACCEPTANCE_CHECKLIST.md](18_ACCEPTANCE_CHECKLIST.md) | Release-independent go/no-go checklist |
| `RESEARCH_METADATA.json` | Machine-readable execution boundary and inventory |
| `MANIFEST.sha256` | SHA-256 of every package member except itself |

## Execution status

**[E] Executed in this environment**

- Verified all four supplied input hashes against `MANIFEST.sha256`.
- Inspected current primary documentation and public repository source/metadata.
- Calculated analytical storage lower bounds from the supplied 451-guide / 22,032-vertex fixture.
- Generated and parsed all JSON.
- Validated relative Markdown links and required file inventory.
- Computed the return manifest and tested ZIP CRC/integrity.

**Not executed**

- No 3ds Max installation or SDK headers/samples were available.
- No NVIDIA GPU, CUDA runtime, OpenCL device runtime or D3D device was available.
- No Cyrus repository, private test fixture, renderer or viewport was executed.
- No CUDA/OpenCL/HLSL prototype was compiled.
- No timing, FPS, pointer latency, GPU memory peak or visual result is claimed.

## Package use

Start with the executive decision, then run the local probes in this order:

1. [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md — P0/P1](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)
2. [07_MAX_2027_INTEROP_FEASIBILITY.md](07_MAX_2027_INTEROP_FEASIBILITY.md)
3. [10_BENCHMARK_AND_VALIDATION_PLAN.md](10_BENCHMARK_AND_VALIDATION_PLAN.md)
4. [13_PHASED_IMPLEMENTATION_PLAN.md](13_PHASED_IMPLEMENTATION_PLAN.md)

Do not authorize a production GPU backend until the interop, correctness, lifetime, renderer/Bake, distribution and failure-retention gates in [18_ACCEPTANCE_CHECKLIST.md](18_ACCEPTANCE_CHECKLIST.md) pass.
