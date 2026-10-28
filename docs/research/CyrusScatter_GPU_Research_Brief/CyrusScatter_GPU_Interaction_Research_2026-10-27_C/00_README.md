# Cyrus Scatter GPU Interaction Research — researcher A

**Date:** 27 October 2026, Asia/Tehran. **Baseline supplied by coordinator:** Cyrus Scatter 0.87.4.3, native interaction capability 11, scene schema 63, Windows x64 / 3ds Max 2027.

## Start here

**Recommendation:** retain CPU neighborhood selection and the qualified static fitter first; prototype shared-source HLSL deformation driven by sparse completed guide poses. Investigate the public Max 2027 native D3D11 hook in parallel. Consider CUDA fitting for measured large active work, with an algorithm-matched OpenCL comparator and a CPU fallback. Direct resource sharing and end-to-end speedup are not established by this research.

Read [01 — Executive decision](01_EXECUTIVE_DECISION.md), then [07 — Max feasibility](07_MAX_2027_INTEROP_FEASIBILITY.md), [13 — Implementation gates](13_PHASED_IMPLEMENTATION_PLAN.md), and [16 — Local probes](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md). The complete set below answers the supplied assignment; it is not a production implementation or a repeat of the earlier vegetation/tree literature report.

## Evidence legend

| Label | Meaning | Example |
|---|---|---|
| **S — supplied** | Project statement/test observation in the attached context; not independently reproduced | The one observed 4.05 ms native contact evaluation |
| **V — verified public** | Current/historical primary documentation or inspected source, with version/location | Max2027 `ID3D11GraphicsWindow::GetDevice` declaration |
| **X — executed here** | A check actually run in this environment | Ten Python arithmetic/analytic controls, input hashes, link/archive checks |
| **E — estimate/derivation** | Mathematical calculation with explicit assumptions; not measured allocation or latency | 122.672 GB for one million hypothetical fully posed detailed clumps |
| **P — proposal/hypothesis** | Recommended design, prototype, threshold or workflow awaiting validation | 20% paired p95 adoption margin |
| **U — unresolved** | Precise question requiring local SDK, code, device or host evidence | Retained-buffer native sharing/retirement route inside actual Nitrous callbacks |

These labels also appear in full words. Algorithm/design chapters default to P where stated. A documented API capability does not qualify a working host integration. Public-source file downloads and paper inspection are research activity, not execution of their implementations.

## Complete document set

| File | Purpose |
|---|---|
| [01_EXECUTIVE_DECISION.md](01_EXECUTIVE_DECISION.md) | Conditional recommendation, populations and falsifiers |
| [02_REQUIREMENTS_AND_CURRENT_SYSTEM.md](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md) | Supplied baseline, limits and notation |
| [03_PARALLELISM_AND_DATA_LAYOUT.md](03_PARALLELISM_AND_DATA_LAYOUT.md) | Stage graph, scheduling, schemas, sparse work and complexity |
| [04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) | Five architectures, matched APIs and weighted sensitivity matrix |
| [05_COLLISION_AND_GUIDE_SOLVING.md](05_COLLISION_AND_GUIDE_SOLVING.md) | Static formulation, whole-surface contacts, fields and bounds |
| [06_GPU_DEFORMATION_AND_INSTANCING.md](06_GPU_DEFORMATION_AND_INSTANCING.md) | Evaluator, normals/seams, sharing, bounds/picking and final geometry |
| [07_MAX_2027_INTEROP_FEASIBILITY.md](07_MAX_2027_INTEROP_FEASIBILITY.md) | Exact public APIs, native hook, ownership and separate proof layers |
| [08_ASYNC_PUBLICATION_AND_LIFETIMES.md](08_ASYNC_PUBLICATION_AND_LIFETIMES.md) | Revision-safe coalescing, publication, retirement and recovery |
| [09_MEMORY_PRECISION_AND_HARDWARE.md](09_MEMORY_PRECISION_AND_HARDWARE.md) | Byte budgets, FP precision, tolerances and hardware practicality |
| [10_BENCHMARK_AND_VALIDATION_PLAN.md](10_BENCHMARK_AND_VALIDATION_PLAN.md) | Core cases, frozen inputs, timings, presentation and adoption |
| [11_EDGE_CASE_AND_FAILURE_MATRIX.md](11_EDGE_CASE_AND_FAILURE_MATRIX.md) | Trigger/hazard/mitigation/test/status cases |
| [12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md) | Original work, actual source paths, pins and licensing boundaries |
| [13_PHASED_IMPLEMENTATION_PLAN.md](13_PHASED_IMPLEMENTATION_PLAN.md) | Ownership, interfaces, budgets and staged go/no-go gates |
| [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) | Small P0–P5 experiments and interface sketch |
| [15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) | Optional backend startup, AOT/JIT/cache, notices and artist controls |
| [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) | Exact local source/SDK/host probes and blocked decisions |
| [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md) | Primary URLs, revisions/dates, inspection scope and evidence limits |
| [18_ACCEPTANCE_CHECKLIST.md](18_ACCEPTANCE_CHECKLIST.md) | Delivered research versus unexecuted product gates |

Machine-readable [RESEARCH_METADATA.json](RESEARCH_METADATA.json) records environment, input identity, execution scope and inventory. [MANIFEST.sha256](MANIFEST.sha256) contains actual hashes of all included files except itself. [ARTIFACT_VERIFICATION.json](ARTIFACT_VERIFICATION.json) records structure/link/archive checks. Diagrams use Mermaid inside Markdown; the prose remains usable in readers without Mermaid support.

## Optional original analytic checks

[optional/README.md](optional/README.md) explains the small runnable program, output and proposed benchmark manifest. It has no third-party runtime dependency. The included R8 geometry and sphere-control hashes can seed standalone prototype fixtures. G451 and private library assets are not supplied here; their actual fingerprints are explicit local prerequisites, never invented.

```bash
python optional/research_checks.py --output optional/executed_checks.json
python optional/verify_package.py .
```

The recorded run used Python 3.12.14 on Linux x86_64 and passed ten checks. No GPU device, NVCC, OpenCL inspection tool, Windows/Max installation or production repository was exposed. A C++ compiler was available, but no C++/CUDA/OpenCL/Max prototype was compiled; research and design were the authorized task.

## Important reading cautions

Eight nodes per guide, 32-byte pose frames and a 16 GB/s transfer rate are named analytical assumptions, not observations about the supplied asset or machine. Hardware specification memory is not free VRAM. Current source/release metadata occasionally disagree; those disagreements are preserved in the relevant chapters rather than collapsed into a fictitious qualified version. The report does not select the production renderer because it was not specified.

Original third-party papers, source trees, binaries and proprietary assets are not packaged. The ZIP contains the complete Markdown research, metadata, hashes and small original Python checks. No production code was modified and no results from earlier chats or bundled historical harnesses are claimed as new validation.
