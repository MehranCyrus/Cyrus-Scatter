# Comparison and ranking

27 October 2026 · Research review only · Folder labels A/B/C/D identify the external reports.

## Decision and assessment method

**For our next implementation, use C as the main guide, A as the detailed reference, B as the alternative-solver and validation companion, and LocalCodex as the source/hardware evidence companion.** External ordering: **C > A > B > D**. The first three are close and complementary. A would be first if the criterion were depth of reference material alone.

The assessment prioritizes correctness, the concrete Max integration path, fit with Cyrus ownership/publication behavior, reproducibility, and usefulness for choosing the next experiment. It does not rank by length, source count, polished prose, or unsupported weighted scores. No blind review or controlled model comparison was performed. Package metadata cannot independently establish which model produced a report.

All external reports distinguish research from production execution. Their proposed acceptance numbers are targets, not achieved speedups. LocalCodex had private source and hardware access that the web researchers did not have, so its executed evidence is assessed separately rather than used to declare an automatic overall winner.

## Report C: best implementation guide

C most effectively turns the problem into small, rejectable engineering experiments. Its [Max integration chapter][C07] names the documented buffer-binding method and flags, specifies a buffer-first proof with texture/constant controls, distinguishes public device access from retained-resource interoperability, and identifies what still requires an actual Max test. The public API findings are substantially corroborated by the installed headers; their existence is not a runtime pass.

C also finds Autodesk's July compiler clarification: the IDE version and the selected MSVC build tools are separate. This avoids an unnecessary toolchain change. Its [solver][C05] and [publication][C08] chapters explain fixed roots, whole-span and visible-surface contact, cumulative dirty edits, and checking the publication baseline before replacing a full pose map. The joint clearance budget in [deformation][C06] prevents CPU contact tolerance and GPU delivery tolerance from independently consuming the same safety allowance.

The [prototype specification][C14] is particularly useful: it connects finite workloads, independent controls, explicit statuses and a small two-instance draw proof to stop/go decisions. The ten included arithmetic/analytic controls reproduced locally, excluding expected Python/platform metadata differences.

**What to add:** A's explicit publication-coverage gates for continuous dragging and its fixed-anatomy high-polygon control. C already measures displayed-result age and coalesced events in [benchmarking][C10]; the improvement is a sharper liveness acceptance rule, not a claim that C omitted latency. No source listing, analytic check or public method description in C establishes a production GPU fitter, renderer parity, or an in-Max sharing path.

## Report A: deepest reference, close second

A gives the richest [solver discussion][A05], including how field approximation, whole-element search, finite constraint iterations, frame reconstruction, and independent validation interact. Its [reuse study][A12] examines newer rod work and actual implementation details rather than treating a hair engine as a plant solver. These are valuable references; individual upstream speed claims still do not predict Cyrus performance.

A is especially strong on [interactive measurement][A10]. It requires displayed generation age and fresh publication coverage, so a renderer presenting an unchanged old pose cannot look like successful interaction. Its proposed 60 Hz profile includes publication progress during sustained input, sufficient accepted samples, and release-to-final latency. Those are proposed gates, not measured results.

A also proposes H01: increase surface tessellation while keeping guide anatomy fixed. This isolates high-polygon deformation, validation and draw costs from the separate guide-solving workload. It is more diagnostic than simply comparing two unrelated plants.

**Correction:** [A04][A04] describes the published Max toolset as the 1944 compiler family. This infers the compiler from the newer IDE version. Autodesk's later setup clarification specifies v14.38 build tools. Preserve the selected 14.38 configuration and check the actual CUDA compiler gate against it. The broader solver/deformation recommendation survives this correction. A's breadth also makes C easier to use as the day-to-day experiment outline.

## Report B: excellent alternatives and reproducible controls

B's [solver chapter][B05] is strong on a finite static fitting profile, positive feasible examples, and why dynamic XPBD terminology alone does not specify our static fitting behavior. Its [benchmark plan][B10] stresses matched geometry, precision, quality and absolute end-to-end latency. Its [reuse chapter][B12] clearly distinguishes observed code, release metadata, inaccessible pinned bodies and unresolved pins. That honesty is useful engineering evidence.

The supplied budget calculator, six adversarial geometry controls, and decision-score sensitivity program all reproduced their recorded semantic outputs. The geometry controls illustrate important counterexamples; they do not execute the complete fitter or prove convergence on arbitrary plants.

**Omission:** the returned package has no mention of `SetBufferParameter` or `BufferUsageTarget`, although its [Max chapter][B07] reviews HLSL material capabilities. Its constants/texture route is a valid fallback, but missing the documented buffer route makes its first Max experiment less direct. It also lacks the July toolset clarification and leaves avoidable uncertainty around the supplied 14.38 build. These omissions put it behind C/A for our immediate integration, not behind them on every solver topic.

## Report D: useful direction, weaker precision

D supports the same sensible staging: preserve a CPU-capable system, prove shared-source shader deformation, and only then evaluate GPU fitting. Its [deformation chapter][D06] covers bounds, picking, seams, normals, hidden rooted groups and renderer materialization. Its scope qualifications are generally responsible.

Three issues reduce confidence in using it as the primary plan:

1. [D07][D07] reports that the inspected API pages do not expose a native D3D11 device. It explicitly qualifies that negative search result, which is good. However, another public Max 2027 interface does expose `GetDevice`; the broader executive implication must be updated. Resource ownership and a supported retained-buffer bridge remain unresolved.
2. Every printed total in its weighted decision table differs from its own weights and ratings. Recalculation is recorded in [the analytic receipt](ANALYTIC_VERIFICATION.json). The broad CPU/shader-leading conclusion survives; the printed numerical precision does not.
3. The 48-byte-per-guide pose estimate in [layout][D03], [interop][D07] and [memory][D09] needs a node count, compression scheme and packet accounting. Its own layout includes variable node payloads. This is an under-specified assumption, not evidence that every possible 48-byte encoding is invalid.

| Architecture | D prints | Recalculated from D's table |
|---|---:|---:|
| CPU only | 4.42 | 4.45 |
| CPU fit + shader deformation | 4.25 | 4.20 |
| CUDA fit + deformation | 3.08 | 3.02 |
| OpenCL fit + deformation | 3.20 | 3.08 |
| Persistent GPU scene | 2.35 | 2.42 |

These are D's subjective decision weights, not measured performance scores. Recomputing them does not turn them into an objective comparison.

## LocalCodex: strongest executed component evidence

LocalCodex is narrower in literature coverage but contributes something the external reports cannot: actual current-source/SDK inspection and recorded CUDA/OpenCL execution on an RTX 3090. Its [deformation result][LDEFORM] and [owned-buffer sharing result][LINTEROP] are present with matching prototype source identities.

| Synthetic output vertices | CUDA device p50, ms | OpenCL device p50, ms | CUDA pageable round trip p50, ms | OpenCL pageable round trip p50, ms |
|---:|---:|---:|---:|---:|
| 4,096 | 0.00512 | 0.00512 | 0.1270 | 0.2344 |
| 65,536 | 0.01536 | 0.008064 | 0.2831 | 0.2503 |
| 1,048,576 | 0.045056 | 0.040960 | 2.9257 | 3.1801 |
| 4,194,304 | 0.134144 | 0.138240 | 12.8788 | 12.8412 |

These results show why full vertex transfer deserves attention and why this test cannot select CUDA over OpenCL. They do not show real Cyrus input-to-present latency. There are only 20 samples per case, fixed run ordering, simple synthetic quaternion/translation data and no plant contact solve, normal evaluation or Max draw. The synthetic interpolation is not a qualification of the current shortest-SLERP evaluator. Its CPU comparator is not the production CPU scheduler.

The standalone D3D11 control wrote 1,024 float4 values through both APIs and checked staging readback. OpenCL used `cl_nv_d3d11_sharing`; the KHR variant was not advertised. This is useful capability evidence for this driver, not a result on Max-owned resources or every NVIDIA/OpenCL installation.

The original local report also benefits from C's newer compiler citation and fuller numerical/lifetime contracts. Its value is as a measurement companion, with its own limits retained. No hardware benchmark was rerun for this review.

## Reconcile memory assumptions before comparing numbers

Many apparent disagreements are different layouts. Using one explicit illustration—451 guides, eight pose nodes per guide, 32 bytes per node and a 16-byte guide header—gives:

```text
full pose per plant = 451 × (8 × 32 + 16) = 122,672 bytes
six changed guides = 6 × (8 × 32 + 16) = 1,632 bytes
1,000 full poses   = 122.672 MB
1,000,000 poses    = 122.672 GB
```

These decimal totals exclude packet headers, hidden masks, instance transforms, old/new generations, CPU shadows, contacts, scratch and allocator overhead. Eight nodes are an estimate, not a measured property of every 451-guide plant. One million fully posed plants is radically different from one million resident transforms with a small active neighborhood.

For the same 22,032 output vertices, 24/32/40 bytes per vertex gives 528,768 / 705,024 / 881,280 bytes. Position plus normal, padded streams and tangent-inclusive streams are different storage contracts; that difference is not arithmetic failure. Actual render-corner duplication at seams can increase counts further.

## What we should carry forward

Use C's structure, import A's detailed solver and liveness gates, use B's feasible/counterexample controls, and retain LocalCodex's actual capability evidence. Correct D rather than discard its useful cross-checks. Do not splice five proposed type systems or dependency lists into production.

The next decision is deliberately smaller than adopting CUDA: **measure the current CPU critical path and prove compact-pose shader deformation through public Max APIs on two differently posed instances of one source.** Only after that proof should a matched GPU fitter experiment determine whether solving, rather than CPU refinement/upload/draw, offers the next worthwhile gain. See [consolidated findings](CONSOLIDATED_FINDINGS.md) for the gates.

[A04]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_A/04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md
[A05]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_A/05_COLLISION_AND_GUIDE_SOLVING.md
[A10]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_A/10_BENCHMARK_AND_VALIDATION_PLAN.md
[A12]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_A/12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md
[B05]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_B/05_COLLISION_AND_GUIDE_SOLVING.md
[B07]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_B/07_MAX_2027_INTEROP_FEASIBILITY.md
[B10]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_B/10_BENCHMARK_AND_VALIDATION_PLAN.md
[B12]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_B/12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md
[C05]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_C/05_COLLISION_AND_GUIDE_SOLVING.md
[C06]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_C/06_GPU_DEFORMATION_AND_INSTANCING.md
[C07]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_C/07_MAX_2027_INTEROP_FEASIBILITY.md
[C08]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_C/08_ASYNC_PUBLICATION_AND_LIFETIMES.md
[C10]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_C/10_BENCHMARK_AND_VALIDATION_PLAN.md
[C14]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_C/14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md
[D03]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_D/03_PARALLELISM_AND_DATA_LAYOUT.md
[D06]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_D/06_GPU_DEFORMATION_AND_INSTANCING.md
[D07]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_D/07_MAX_2027_INTEROP_FEASIBILITY.md
[D09]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_D/09_MEMORY_PRECISION_AND_HARDWARE.md
[LDEFORM]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_LocalCodex/reports/local-codex/prototype/deformation_results.json
[LINTEROP]: ../CyrusScatter_GPU_Interaction_Research_2026-10-27_LocalCodex/reports/local-codex/prototype/interop_results.json
