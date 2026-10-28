# Cyrus Scatter GPU Interaction Research — Researcher A

**Research date: 27 October 2026 · Target: Cyrus Scatter 0.87.4.3 / capability 11 / scene schema 63 · 3ds Max 2027 / Windows x64**

This is a research and architecture package, not a production implementation. It answers the supplied [research assignment](inputs/RESEARCH_PROMPT.md) using the supplied [system context](inputs/CURRENT_SYSTEM_CONTEXT.md) as project facts and independently consulted current primary sources for public capabilities.

## Decision in one paragraph

Retain the CPU reference and sparse-neighborhood route. First test **CPU fitting with shared-source GPU deformation through supported HLSL inputs**, alongside a small Max graphics-interface probe. Only add an optional GPU fitter if a matched, complete-pipeline benchmark shows a worthwhile benefit for large active work. CUDA is the initial NVIDIA prototype candidate for tooling and reusable primitives; OpenCL and D3D11 compute remain serious alternatives. There is no demonstrated CUDA speed advantage, GPU capacity figure or in-Max compute-sharing pass in this package. The full weighted decision and falsifiers are in [01](01_EXECUTIVE_DECISION.md).

## Evidence labels

| Label | Meaning | What it does not mean |
|---|---|---|
| **V — Verified public evidence** | Current official documentation, original paper or explicitly described public source inspection | Executed behavior in Cyrus/Max, or inspection of inaccessible pinned file bodies |
| **P — Provided project fact** | Supplied coordinator context, including local observations and path pointers | Independent repository access or repetition of its 61 tests/host campaign |
| **X — Executed here** | Standard-library arithmetic/oracle scripts and package checks identified in the execution record | GPU, CUDA/OpenCL compilation, shader, solver, Max, renderer or installer execution |
| **E — Estimate / analytical deduction** | Equations and byte counts with stated assumptions | Measured bandwidth, timings, scalability or benchmark speedup |
| **D — Design proposal / hypothesis** | Suggested architecture, numerical profile, budget, UI or acceptance target | Existing support or a proved convergence/capacity guarantee |
| **U — Unresolved / Not executed** | Requires installed SDK, source, hardware or host validation | Evidence that an API is impossible or a scene has no feasible fit |

Some chapters also spell these labels out as “Provided,” “Proposal,” “Analysis,” or “Unknown.” Context and qualification remain the same. A paper's or vendor's reported result is identified as report-local evidence; it is not included in Researcher A's execution record.

## Reading order

Start with [01 Decision](01_EXECUTIVE_DECISION.md), [07 Max feasibility](07_MAX_2027_INTEROP_FEASIBILITY.md), [13 Gates](13_PHASED_IMPLEMENTATION_PLAN.md), and [16 Exact local probes](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md). Engineers can then follow their module's chapter. The source ledger includes dates/versions, precise locations, claims, limitations, licensing observations and inspection confidence.

| File | Main question answered |
|---|---|
| [01_EXECUTIVE_DECISION.md](01_EXECUTIVE_DECISION.md) | Which architecture/API should be prototyped, with weights, sensitivities and rejection conditions? |
| [02_REQUIREMENTS_AND_CURRENT_SYSTEM.md](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md) | What must stay true, and what do the supplied observations actually establish? |
| [03_PARALLELISM_AND_DATA_LAYOUT.md](03_PARALLELISM_AND_DATA_LAYOUT.md) | How are instances/guides/spans/vertices scheduled and stored without hidden dense expansion? |
| [04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) | What do current APIs/toolchains offer, and how should they be fairly compared? |
| [05_COLLISION_AND_GUIDE_SOLVING.md](05_COLLISION_AND_GUIDE_SOLVING.md) | How can static rooted contact preserve lengths, frames, width and final surface correctness? |
| [06_GPU_DEFORMATION_AND_INSTANCING.md](06_GPU_DEFORMATION_AND_INSTANCING.md) | How does one evaluator reach draw, normals, materials, picking, render and Bake? |
| [07_MAX_2027_INTEROP_FEASIBILITY.md](07_MAX_2027_INTEROP_FEASIBILITY.md) | Which exact public interfaces exist, and what remains to prove in Nitrous? |
| [08_ASYNC_PUBLICATION_AND_LIFETIMES.md](08_ASYNC_PUBLICATION_AND_LIFETIMES.md) | Who owns in-flight data, stale results, readers, retirement and failure recovery? |
| [09_MEMORY_PRECISION_AND_HARDWARE.md](09_MEMORY_PRECISION_AND_HARDWARE.md) | What do realistic byte/precision budgets allow and rule out? |
| [10_BENCHMARK_AND_VALIDATION_PLAN.md](10_BENCHMARK_AND_VALIDATION_PLAN.md) | How do we measure fair total latency, correctness, crossover and memory? |
| [11_EDGE_CASE_AND_FAILURE_MATRIX.md](11_EDGE_CASE_AND_FAILURE_MATRIX.md) | What happens in 46 adversarial geometry/lifecycle cases? |
| [12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md) | Which algorithms and inspected code paths transfer, under what limitations/licenses? |
| [13_PHASED_IMPLEMENTATION_PLAN.md](13_PHASED_IMPLEMENTATION_PLAN.md) | What are the ordered owners, outputs, budgets and stop criteria? |
| [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) | What precisely should the local team build first and how can it fail qualification? |
| [15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) | How does an optional backend deploy safely and remain simple for artists? |
| [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) | Which 28 exact code/SDK/host probes close the remaining decisions? |
| [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md) | What primary evidence supports the conclusions? |
| [18_ACCEPTANCE_CHECKLIST.md](18_ACCEPTANCE_CHECKLIST.md) | What is completed research evidence versus an unexecuted implementation gate? |
| [RESEARCH_METADATA.json](RESEARCH_METADATA.json) | Research identity/time, baseline, tools, executed/unexecuted work and inventory |
| [MANIFEST.sha256](MANIFEST.sha256) | Actual SHA-256 of every included file except the manifest itself |

## Reproducibility and package checks

The [analysis folder](analysis/README.md) contains small Python scripts, their actual arithmetic/oracle outputs and execution notes. They require only Python 3's standard library. No third-party code trees, vendor binaries, proprietary plant assets, benchmark traces or renderer images are bundled. The input brief/context copies are unchanged and retain their own supplied manifest.

From the extracted document directory:

```sh
python3 analysis/calculate_budgets.py
python3 analysis/check_adversarial_geometry.py
python3 analysis/check_decision_scores.py
python3 analysis/verify_package.py .
```

The final verifier checks included file hashes, relative links/anchors and inventory. Archive-member safety, integrity and manifest parity were also checked during packaging. Exact observations and limitations are recorded in [EXECUTED_CHECKS.md](analysis/EXECUTED_CHECKS.md). Mermaid diagrams are plain Markdown source; a viewer with Mermaid support renders them, while the surrounding prose/tables remain complete without it.

## Main limitations

No production checkout, installed Max, Windows toolchain, qualified GPU, nvcc or OpenCL device was available. Some pinned GitHub file bodies were inaccessible even though release/commit identities were verified; the ledger distinguishes those from readable rolling source or exact commit diffs. The intended production renderer and actual artist hardware remain unspecified. Software documentation reflects retrieval on the research date and may change; exact installed combinations still need qualification.

The highest-risk unresolved question is the **supported Max 2027 data/resource ownership and synchronization path**, including final geometry delivery. This report identifies a real public native D3D11 candidate rather than assuming absence, and specifies a small proof rather than assuming success.
