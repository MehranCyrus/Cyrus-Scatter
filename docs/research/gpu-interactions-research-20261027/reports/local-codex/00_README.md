# GPU acceleration for Cyrus Scatter interactions

**Independent report: Local Codex · 27 October 2026 · research revision 1**

This is our local response to the same assignment sent to the external researchers. It combines current repository inspection, the installed Max 2027 SDK, primary literature, and two executed standalone GPU experiments. It changes no production plugin behavior. It is not a GPU plugin release or Max interoperability qualification.

## Read this first

**Recommendation:** profile the complete edit-to-display path, then prototype CPU collision fitting with GPU vertex deformation through the public Max shader/buffer APIs. Investigate a CUDA fitter only if measured active fitting cost justifies it. CUDA and OpenCL were close on the larger matched deformation kernels in our local probe; copying full geometry back to the CPU dominated those kernels. Neither API has demonstrated superiority for the actual Cyrus fitter.

Read [the decision](01_EXECUTIVE_DECISION.md), [the Max integration findings](07_MAX_2027_INTEROP_FEASIBILITY.md), and [the measured results](10_BENCHMARK_AND_VALIDATION_PLAN.md) before proposing implementation. [The acceptance checklist](18_ACCEPTANCE_CHECKLIST.md) separates completed research from unexecuted product gates.

## Evidence vocabulary

| Mark | Meaning |
|---|---|
| **E** | Executed locally; only the stated fixture/environment is qualified |
| **L** | Local source or installed SDK declaration inspected; not necessarily executed |
| **D** | Verified primary documentation, paper, or pinned upstream source |
| **A** | Analytical estimate, with assumptions stated |
| **P** | Proposed design or experiment; not implemented in the plugin |
| **U** | Unresolved integration or acceptance question |

The current project baseline is **0.87.4.3**, native interaction capability **11**, scene schema **63**. Its historical receipts describe CPU behavior. The working tree contains other work, so HEAD alone does not identify the inspected source. See [local identities](evidence/local_source_identity.json). The whole knowledge corpus was not certified fresh; current conclusions use directly inspected originals.

## Document map

| File | Purpose |
|---|---|
| [01 Executive decision](01_EXECUTIVE_DECISION.md) | What to build first, alternatives, and decision gates |
| [02 Requirements and current system](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md) | Actual CPU pipeline, invariants, and bottlenecks |
| [03 Parallelism and data layout](03_PARALLELISM_AND_DATA_LAYOUT.md) | Work decomposition, sparse buffers, scheduling |
| [04 CUDA, OpenCL, graphics compute](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) | Backend comparison without a predetermined winner |
| [05 Collision and guide solving](05_COLLISION_AND_GUIDE_SOLVING.md) | Contact accuracy, roots, branches, and solver choices |
| [06 Deformation and instancing](06_GPU_DEFORMATION_AND_INSTANCING.md) | Shared sources, per-instance poses, normals, visibility |
| [07 Max 2027 interoperability](07_MAX_2027_INTEROP_FEASIBILITY.md) | Public API evidence and the remaining integration gap |
| [08 Asynchronous publication](08_ASYNC_PUBLICATION_AND_LIFETIMES.md) | Ownership, cancellation, generations, Undo, device loss |
| [09 Memory, precision, hardware](09_MEMORY_PRECISION_AND_HARDWARE.md) | Concrete capacity estimates and coordinate policy |
| [10 Benchmarks and validation](10_BENCHMARK_AND_VALIDATION_PLAN.md) | Actual probe results and full product measurement plan |
| [11 Edge cases](11_EDGE_CASE_AND_FAILURE_MATRIX.md) | Failure matrix and expected recovery |
| [12 Papers and implementations](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md) | What to reuse, exact repository pins, licenses |
| [13 Implementation phases](13_PHASED_IMPLEMENTATION_PLAN.md) | Small experiments with explicit stop/go gates |
| [14 Prototype specifications](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) | Runnable probes and next isolated prototypes |
| [15 Distribution and artist workflow](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) | CPU fallback, packaging, diagnostic UX |
| [16 Open questions](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) | Questions that need local Max execution or product decisions |
| [17 Source ledger](17_SOURCE_LEDGER.md) | Primary URLs, inspected versions, and evidence limits |
| [18 Acceptance](18_ACCEPTANCE_CHECKLIST.md) | Completed research and remaining implementation qualification |

## Included experiments

- [Deformation source](prototype/deformation_probe.cpp), [results](prototype/deformation_results.json), [build/execution identity](prototype/deformation_execution.json).
- [D3D11 sharing source](prototype/interop_probe.cpp), [results](prototype/interop_results.json), [build/execution identity](prototype/interop_execution.json).
- [Reproduction instructions](prototype/README.md) and [local runner](prototype/run_probes.py).

Both ran on this workstation's RTX 3090. The first evaluates a synthetic skinning operation, not Cyrus collision fitting. The second writes standalone owned Direct3D 11 buffers, not Max/Nitrous buffers. No Max process was launched or modified for this research. Product tests listed in later documents remain **not executed** unless expressly identified as a pre-existing receipt.

## Comparing the other reports

External originals belong in `../../external/A`, `B`, and `C`; they are intentionally separate from this independent report. [The comparison protocol](../../comparison/README.md) defines a claim-by-claim review. Agreement between AIs is not evidence of API support or performance. Resolve disagreements using cited declarations, reproducible code, and equivalent benchmarks.

`RESEARCH_METADATA.json` records scope and environment. `MANIFEST.sha256` covers every distributed report, result, and probe source except the manifest itself. The ZIP contains no compiled binaries, commercial model assets, vendor SDK headers, or downloaded engine trees.
