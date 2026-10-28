# 18 — Acceptance checklist

[Index](00_README.md) · [Phased plan](13_PHASED_IMPLEMENTATION_PLAN.md) · [Execution record](analysis/EXECUTED_CHECKS.md)

## Research-package acceptance

The rows marked complete refer to this research deliverable only. They do not qualify an implementation.

| Requirement | Evidence / disposition |
|---|---|
| Researcher ID A and exact baseline | Complete: title/metadata;0.87.4.3, capability11, schema63 |
| Supplied context remains provided, not independently verified | Complete: [02](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md), byte-identical inputs and hashes |
| Current primary sources and version/date limitations | Complete: [17](17_SOURCE_LEDGER.md), including current versus historical and pin versus source-body distinctions |
| Verified/provided/executed/analytical/proposed/unknown separation | Complete: [00](00_README.md), chapter labels and metadata |
| Four populations kept separate | Complete: [02](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md), [03](03_PARALLELISM_AND_DATA_LAYOUT.md), [09](09_MEMORY_PRECISION_AND_HARDWARE.md) |
| Five architectures and CUDA/OpenCL/D3D comparison | Complete: [01](01_EXECUTIVE_DECISION.md), [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md); scores explicitly judgments |
| Whole-span contact, visible geometry, root position/frame distinction | Complete: [05](05_COLLISION_AND_GUIDE_SOLVING.md), [06](06_GPU_DEFORMATION_AND_INSTANCING.md) |
| Concrete Max2027 interfaces and interop proof | Complete research: [07](07_MAX_2027_INTEROP_FEASIBILITY.md); host execution remains open |
| Async lifetime, stale-result suppression and bounded memory | Complete proposed design: [08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md) |
| Numerical/hardware/memory practicality | Complete: [09](09_MEMORY_PRECISION_AND_HARDWARE.md), reproducible arithmetic |
| Manageable benchmark matrix and full latency measurement | Complete specification: [10](10_BENCHMARK_AND_VALIDATION_PLAN.md); no performance results invented |
| Trigger/behavior/hazard/mitigation/test/status failure matrix | Complete: 46 rows in [11](11_EDGE_CASE_AND_FAILURE_MATRIX.md) |
| Papers, implementation paths, versions and licenses | Complete scoped review: [12](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md); inaccessible bodies explicitly identified |
| Implementable gates, minimal prototypes and artist workflow | Complete proposals: [13](13_PHASED_IMPLEMENTATION_PLAN.md), [14](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md), [15](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) |
| Exact local source/SDK probes | Complete: 28 probes in [16](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) |
| Named Markdown set, metadata, actual hashes and real ZIP | Package checks recorded in [analysis/EXECUTED_CHECKS.md](analysis/EXECUTED_CHECKS.md); manifest excludes itself |

## Implementation gates — all NOT EXECUTED here

| Gate | Required pass before enabling the lane | Status |
|---|---|---|
| CPU baseline | Real source snapshot, scoped reference, all required correctness fixtures; actual bottleneck trace | Not executed |
| Standalone compute | Matched arithmetic/constraints, complete errors/status, bounded memory/query work | Not executed |
| Standalone graphics sharing | Exact device/resource descriptions, exclusive ownership, completion, reset/teardown | Not executed |
| Supported in-Max acquisition | Public interface in actual callback and documented lifetime; no private pointer cast | Not executed |
| Supported shader deformation | Canonical positions/normals/tangents, UV seams/materials/groups, bounds and picking | Not executed |
| Contact fitting | Known-feasible controls converge; no false clear for whole-span/inside/width/multi-contact cases | Not executed |
| Root modes | PositionOnly independently qualified; ClampFrame/SoftFrame separately implemented/tested or Unsupported | Not executed |
| Final visible geometry | Complete reference audit, including occupancy and triangle/width cases; evaluator error included | Not executed |
| Async publication | Zero stale/partial publication under Undo/Redo/delete/source/unit/reset races; owned lifetimes | Not executed |
| Performance crossover | Complete-path repeated p50/p95/p99, quality/failure parity, cold/transfer/present costs | Not executed |
| Sparse scale | N up to current1M admission with smallK and measuredR; no dense hiddenN×G orN×V assumption | Not executed |
| Large active scale | K/A/Q/P and all simultaneous memory admitted; oversized jobs fail legibly | Not executed |
| Device/resource failures | Allocation/query/driver/device loss and long-reader backpressure recover without partial results | Not executed |
| Renderer/Bake/export | Exact target builds, complete accepted-state parity, normal/material/units/instance semantics | Not executed |
| Distribution | Optional import graph, exact DLL/license/CRT inventory, no-runtime clean startup, cache bounds | Not executed |

## Coverage of every assignment section

| Assignment section | Primary location |
|---|---|
| 1 Decision/populations | 01,02,09 |
| 2 Supplied baseline | 02,inputs,metadata |
| 3 Evidence discipline | 00,17,analysis,metadata |
| 4 Parallel execution/dataflow | 03 |
| 5 Architectures | 01,06,08 |
| 6 CUDA/OpenCL/graphics | 01,04,15 |
| 7 Collision/guide solving | 05,11,14 |
| 8 Max2027 feasibility | 07,06,16 |
| 9 Asynchrony/reliability | 08,11,15 |
| 10 Precision/memory/hardware | 09 |
| 11 Benchmark plan | 10,14 |
| 12 Papers/reusable code | 12,17 |
| 13 Recommendation/gates/distribution | 01,13,14,15,16 |
| 14 Files/metadata/ZIP | 00,metadata,manifest,analysis/package checks |

## Release claim rule

Ship only a lane whose exact quality, host/API, device/driver, compiler/runtime, renderer and workload envelope passed. “Candidate converged” is not “visible mesh validated”; “standalone interop works” is not “supported inside Max”; “one million resident” is not “one million detailed clumps deform every edit.” Keep these distinctions in engineering logs and artist diagnostics.
