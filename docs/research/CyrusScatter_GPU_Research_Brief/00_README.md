# Cyrus Scatter GPU Interaction Research Package (`2026-10-27`, Researcher `A`)

## 1. Purpose and Scope

This package delivers the complete independent technical investigation requested in `RESEARCH_PROMPT.md`, grounded in the supplied engineering baseline (`CURRENT_SYSTEM_CONTEXT.md`, release **0.87.4.3**, native interaction capability **11**, scene schema **63**, target host **Autodesk 3ds Max 2027 on Windows x64**).

Our objective is to give the local Cyrus Scatter engineering team a **falsifiable, stage-gated architectural decision** on how (and when) to move vegetation collision neighbourhood invalidation, rooted-guide contact fitting, surface refinement, and mesh/normal deformation onto the GPU—comparing **NVIDIA CUDA**, **Khronos OpenCL**, **Direct3D 11 Compute / HLSL Shader Model 5.0 vertex deformation**, **hybrid proxy/field architectures**, and **optimized CPU execution**.

---

## 2. Epistemic Labeling Discipline

Every substantive claim across this document set is tagged with one of five explicit evidence categories:

| Tag | Meaning |
|---|---|
| **[VERIFIED-PUBLIC]** | Independently verified from primary public documentation, specifications, papers, or open-source repositories (cited inline and indexed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md)). |
| **[PROVIDED-FACT]** | Supplied as a baseline project fact in `RESEARCH_PROMPT.md` or `CURRENT_SYSTEM_CONTEXT.md` (not independently inspected in the Cyrus Scatter repository). |
| **[EXECUTED-LOCAL]** | Environment or toolchain fact probed without touching the Cyrus Scatter repository. No production plugin benchmarks or in-Max tests are claimed as executed. |
| **[ANALYTICAL-ESTIMATE]** | First-principles byte-budget, bandwidth, arithmetic, or PCIe transfer calculation with explicit formulas and stated assumptions. |
| **[PROPOSED / UNVERIFIED]** | Proposed architecture, kernel design, or hypothesis requiring local validation via the probes in [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) and prototypes in [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md). |

---

## 3. Document Map

| File | Responsibility |
|---|---|
| [00_README.md](00_README.md) | Package navigation, epistemic tags, and summary of deliverables. |
| [01_EXECUTIVE_DECISION.md](01_EXECUTIVE_DECISION.md) | Conditional architectural recommendation, population taxonomy, weighted API decision matrix, and explicit falsifiers. |
| [02_REQUIREMENTS_AND_CURRENT_SYSTEM.md](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md) | Baseline invariants (`0.87.4.3`), coordinate/scale rules, `Contact gap` vs `Hide margin` (`Inside solid` / `Under collider`), and admissions. |
| [03_PARALLELISM_AND_DATA_LAYOUT.md](03_PARALLELISM_AND_DATA_LAYOUT.md) | Work decomposition across instances/guides/nodes, warp- vs thread-per-guide scheduling, hierarchy handling, SoA schemas, and $N, K, G, V, C, P$ byte/complexity analysis. |
| [04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) | Apples-to-apples comparison of CUDA 12.x/13.x, OpenCL 3.0, and D3D11 Compute (`cs_5_0`) / SM5 vertex shaders on identical NVIDIA hardware, plus cross-vendor portability. |
| [05_COLLISION_AND_GUIDE_SOLVING.md](05_COLLISION_AND_GUIDE_SOLVING.md) | Quasistatic rooted-guide contact algorithms (FTL/XPBD/Cosserat rods), BVH vs SDF trade-offs, foliage envelopes, horizontal footprint indexing, and squeezing/infeasibility rules. |
| [06_GPU_DEFORMATION_AND_INSTANCING.md](06_GPU_DEFORMATION_AND_INSTANCING.md) | Vertex-shader pose-buffer pull skinning vs compute-shader mesh materialization; preserving normals/tangents, UV seams, material IDs, and whole-group visibility masks. |
| [07_MAX_2027_INTEROP_FEASIBILITY.md](07_MAX_2027_INTEROP_FEASIBILITY.md) | Feasibility analysis of `MaxSDK::Graphics` (`IVirtualDevice`, `VertexBufferHandle`, `TextureHandle`, `HLSLMaterialHandle`), D3D11/CUDA interop constraints, LUID matching, fallbacks, and offline renderer (`GetRenderMesh` / `MaxSDK::RenderTimeInstancing`) consistency. |
| [08_ASYNC_PUBLICATION_AND_LIFETIMES.md](08_ASYNC_PUBLICATION_AND_LIFETIMES.md) | Asynchronous drag timeline, epoch/revision tags, pointer coalescing, triple-buffered slots, Undo/Redo safety, TDR/device-loss recovery, and persistence boundaries. |
| [09_MEMORY_PRECISION_AND_HARDWARE.md](09_MEMORY_PRECISION_AND_HARDWARE.md) | FP32 local-frame rebasing vs FP64 reference, numerical invariants, complete VRAM/RAM byte budgets across representative scenes, Windows WDDM Unified Memory limits, and GPU hardware matrix. |
| [10_BENCHMARK_AND_VALIDATION_PLAN.md](10_BENCHMARK_AND_VALIDATION_PLAN.md) | Reproducible core + stress benchmark matrix, 7-stage timing decomposition, p50/p95/p99 latency protocol, and profiler instructions (**not executed** on production code). |
| [11_EDGE_CASE_AND_FAILURE_MATRIX.md](11_EDGE_CASE_AND_FAILURE_MATRIX.md) | Structured matrix mapping 32 geometric, numerical, topological, lifecycle, and hardware failure cases to triggers, hazards, mitigations, tests, and qualification status. |
| [12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md) | Primary-source literature review and open-source repository audit (`NVIDIA/cccl`, `NVIDIA/warp`, `NVIDIA/cuBQL`, `GPUOpen-Effects/TressFX`, `jbikker/tinybvh`, `madmann91/bvh`, `openvdb/nanovdb`, etc.) with licenses and reuse recommendations. |
| [13_PHASED_IMPLEMENTATION_PLAN.md](13_PHASED_IMPLEMENTATION_PLAN.md) | Reordered 6-gate implementation roadmap with inputs/outputs, interfaces, memory budgets, measurable go/no-go criteria, and rollback paths. |
| [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) | Self-contained, reproducible specifications and reference kernel/host sketches (labeled **not executed** in Max) for Gate 1–4 prototypes. |
| [15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) | CUDA EULA Attachment A redistribution, delay-loading `nvcuda.dll`, MSVC `14.38` compatibility, PTX/fatbin caching, CPU fallback, and minimal artist UI/diagnostics. |
| [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) | Exact local repository and 3ds Max 2027 SDK probes required before committing to GPU solver or zero-copy interop work, mapped to blocked decisions. |
| [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md) | Master citation ledger with URLs, versions/dates, licenses, and confidence ratings. |
| [18_ACCEPTANCE_CHECKLIST.md](18_ACCEPTANCE_CHECKLIST.md) | Cross-reference verification table mapping every prompt requirement to its exact section and acceptance criterion. |
| `RESEARCH_METADATA.json` | Machine-readable metadata recording research date, baseline version, environment, execution status, and inventory. |
| `MANIFEST.sha256` | Actual SHA-256 digests of all deliverables in this directory (excluding `MANIFEST.sha256` itself). |
