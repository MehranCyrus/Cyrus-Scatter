# 13 — Phased implementation plan

[Contents](00_README.md) · [Prototype specifications](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) · [Benchmarks](10_BENCHMARK_AND_VALIDATION_PLAN.md) · [Acceptance](18_ACCEPTANCE_CHECKLIST.md)

**P — proposed implementation gates; not executed.** These are engineering decisions and exit conditions, not a delivered plugin, schedule estimate or commitment to a compute API. Keep the production CPU route available throughout. The first recommended acceleration experiment is **CPU fitting plus supported HLSL deformation from compact CPU guide poses**. Investigate native graphics access in parallel, without making successful zero-copy interoperability a prerequisite for that experiment.

## Gate structure and ownership

| Gate | Lead responsibility | Main prototype | Decision produced |
|---|---|---|---|
| G0 — Reference and bottlenecks | Numerical core and measurement owner | P0 | Which stages and active populations justify acceleration? |
| G1 — Max data feasibility | Max display/SDK owner | P1/P2 | Supported pose-to-shader route; native bridge status |
| G2 — Deformation parity | Evaluator and display owner | P1 | Whether shared-source shader evaluation meets quality and cost requirements |
| G3 — Bounded GPU fitting | Numerical/compute owner | P3 | Whether a GPU static fitter merits adoption; which backend |
| G4 — Scale and routing | Performance/memory owner | P0/P3 | Admitted scene classes, crossover policy and memory caps |
| G5 — Product qualification | Host lifecycle, renderer and release owners | P4/P5 | A releasable optional capability with reliable CPU recovery |

Owners are responsibilities to assign locally, not named contributors or claims about the existing team. Each gate stores exact inputs, executable revisions, settings, hardware, completed measurements and failure logs. A blocked gate records which decision remains unknown. It does not become a pass through an architecture argument.

## G0 — Freeze the reference and measure the complete edit

**Inputs:** the supplied 0.87.4.3 baseline, privately available prepared sources, synthetic correctness fixtures, and deterministic collider edit traces. **Outputs:** a versioned numerical snapshot/evaluator contract, fixture fingerprints, full-stage telemetry and baseline latency distributions. The numerical owner defines complete-success versus incomplete/unsupported states; the host owner timestamps capture and publication.

**Interfaces and budget:** P0 adds bounded counters around capture/invalidation, neighborhood lookup, retained-map copying, fitting, surface refinement, deformation, transfers, publication and drawing. Counters must distinguish `N`, `K`, affected guides/nodes, candidate pairs and retained changed poses. Reserve logging memory; no per-contact unbounded event stream. Keep source capture and publication on approved host callbacks.

**Go/no-go:** freeze correctness tolerances before tuning; all admitted controls pass, deliberate failures preserve the previous result, and stage timings reconcile with a completed event-to-present trace. Identify whether solving, mesh materialization, upload, map copying or drawing actually dominates. If the supplied small neighborhood is already CPU-efficient and no costly stage is demonstrated, retain CPU as its route. The 4.05 ms supplied observation is not this baseline campaign.

**Rollback and unresolved checks:** remove instrumentation independently of the evaluator. Local source inspection must resolve the probes in [16](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md), including actual binding semantics, guide-node counts and successor-copy costs. Missing evidence blocks performance conclusions, not the CPU product.

## G1 — Prove supported Max data delivery

**Inputs:** a shared ribbon, two known CPU poses, stable instance IDs and the installed Max 2027 SDK/build environment. **Outputs:** an in-Max shader-input proof and a written interop capability record. The display owner implements P1; the SDK owner runs P2's native-device and ownership probes separately.

**Interfaces and budget:** use public retained buffers/textures, material parameters and the supported instance stream. Begin with the bounded I2a packet in [07](07_MAX_2027_INTEROP_FEASIBILITY.md), admitting all buffers before creation. P2 separates I0 standalone compute, I1 standalone sharing, I2a supported Max shader input, I2b supported native bridge, and I3 final geometry. Device pointers alone do not satisfy I2b.

**Go/no-go:** I2a must display deliberately different poses, preserve exact visibility/material identities, publish conservative bounds before culling, and return correct stable instance picks after sorting. Camera/F3/selection changes cause zero new static solves and zero unchanged-pose uploads. I2b additionally needs a documented resource-consumption path, adapter match, synchronization and retirement ownership. No private pointer extraction is an acceptable substitute.

**Rollback and unresolved checks:** if I2b fails, select compact readback plus supported Max upload. If I2a fails, retain CPU deformation. Exact SDK callback/thread/resource restrictions and the production renderer remain local questions. This gate is feasible without building a full GPU solver.

## G2 — Establish one deformation evaluator on CPU and GPU

**Inputs:** the frozen CPU evaluator, identical prepared bindings/poses, twisted ribbons, broad leaves, branch sockets, fixed root rings and the local 451-guide source. **Outputs:** a qualified shader evaluator and measured memory/upload/draw tradeoffs. The evaluator owner controls semantics; the display owner controls retained delivery.

**Interfaces and budget:** use the [06](06_GPU_DEFORMATION_AND_INSTANCING.md) contract for positions, normals, tangents, seams, materials, hidden groups, bounds and picking. CPU-readable completed poses remain canonical. Shared source vertices and sparse pose pages replace unique viewport geometry only where measured beneficial. Account for repeated shader evaluation in every view/pass and any CPU surface audit that still materializes vertices.

**Go/no-go:** all [09](09_MEMORY_PRECISION_AND_HARDWARE.md) per-fixture numerical and visible-surface gates pass under the same normal policy; exact identity/visibility checks pass. No picking or culling uses stale rest geometry. For latency adoption, apply [03](03_PARALLELISM_AND_DATA_LAYOUT.md)'s proposed margin: at least 20% lower p95 for the eligible active-work bin, reproduced across three sessions, with no added correctness failures. A memory-saving-only result may justify an explicitly separate option, not a claimed latency win.

**Rollback:** keep CPU-deformed retained meshes as a switchable route. Reject shader deployment when supported pose lookup, normal parity or renderer-independent CPU reconstruction cannot be established. Do not proceed to a solver merely to rescue an unsuccessful deformation proof.

## G3 — Compare a narrow static GPU fit fairly

**Inputs:** G0 identifies a large-active-work solving bottleneck; G1 establishes delivery or fallback. **Outputs:** P3's bounded primitive/guide solver, matched CPU/CUDA/OpenCL traces, and an API decision with explicit rejected profiles. Compute and numerical owners jointly own correctness.

**Interfaces and budget:** first support prepared finite guides, positive uniform scales and analytic sphere/box controls, then admit closed meshes only after complete containment/contact tests. Keep Contact gap and Hide margin independent. Use count/scan/fill with caps on traversal, pairs, contacts, iterations and scratch. Affected groups receive complete coverage; overflow returns incomplete. CPU-readable compact poses and diagnostics are read back for authoritative validation even if a direct graphics bridge is available.

**Go/no-go:** compare the same NVIDIA device, inputs, algorithm, precision and converged quality with equivalent transfer policies. The adversarial suite must pass whole-span crossings, fully contained geometry, infeasible roots, broad leaves and multiple obstacles. A warm start must preserve the static result contract. Adopt only eligible bins meeting the same 20% p95 margin; otherwise optimize CPU or stop. Kernel-only superiority is insufficient.

**Rollback:** route whole jobs to the reference fitter and preserve preceding complete results. Custom contact engineering, full-surface refinement cost or absent public interop can make this gate economically unattractive; those are valid rejection outcomes.

## G4 — Separate sparse scale from simultaneous work

**Inputs:** qualified candidates from G2/G3 and the manageable core matrix in [10](10_BENCHMARK_AND_VALIDATION_PLAN.md). **Outputs:** routing features, crossover with hysteresis, memory admission tables and supported workload descriptions.

**Interfaces and budget:** the performance owner measures sparse `N` growth independently from active `K`, guide/vertex counts, relevant colliders and accumulated retained poses. [09](09_MEMORY_PRECISION_AND_HARDWARE.md) supplies lower bounds; actual accounting includes CPU mirrors, renderer copies, scratch, staging, queued generations and leases. Reject impractical all-active detailed-clump configurations before allocation. Measure cold preparation/JIT and active GPU-render contention separately.

**Go/no-go:** stable p50/p95/p99, worst spikes, failure rates and errors are recorded for repeated sessions. Routing must include transfers, validation and publication; no fixed threshold based only on total instance count. Memory remains within declared caps during admission, peak execution and recovery. Unsupported devices reach the CPU route without loading failures.

**Rollback:** reduce admitted batch sizes or revert affected workload bins to CPU. No memory-saving response may silently drop guides, hide failed plants or publish partial contact sets. Hardware purchase/support recommendations remain conditional on these observations.

## G5 — Qualify asynchronous and final delivery behavior

**Inputs:** numerical backend and delivery candidates, exact host/renderer/runtime versions, fault-injection traces. **Outputs:** a releasable optional capability, recovery diagnostics, installer matrix and final acceptance record. Begin P4's scheduling envelope around the CPU evaluator before G3; complete device-specific qualification here.

**Interfaces and budget:** [08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md)'s tokens include the base publication sequence and relevant dependencies. Coalescing preserves all dirty identities since the last validated publication. Bound pending/in-flight generations and retirement memory; never recycle buffers on cancellation alone. P5 materializes canonical CPU poses through the same evaluator for renderer/Bake/export, with transactional ownership and source immutability.

**Go/no-go:** the race suite produces zero stale publications or use-after-free across Undo/Redo, two-collider coalescing, deletion, source/unit replacement, reset and shutdown. Inject device loss, allocation failure and incomplete queries; retain or reconstruct the last complete CPU result. Final geometry, channels, stable picks and transforms pass exact-version renderer/Bake checks. Driver/runtime absence leaves the CPU plugin loadable. Complete [18](18_ACCEPTANCE_CHECKLIST.md); an unexecuted item remains open.

**Rollback:** disable the optional backend by capability/profile, rebuild retained display data through supported host paths, and report why the previous result remains. Never require disabling TDR or accepting corrupt geometry to finish qualification.

## Prototype cross-reference and stopping rule

| Prototype | Purpose |
|---|---|
| P0 | CPU stage and event-to-present telemetry |
| P1 | Supported HLSL ribbon/pose deformation and parity |
| P2 | I0–I3 compute, sharing, in-Max and final-delivery proofs |
| P3 | Matched bounded static-fit comparison |
| P4 | Asynchronous race, cancellation and recovery campaign |
| P5 | Production renderer, Bake and export consistency |

Stop at the cheapest architecture that meets the measured target. Passing G2 does not obligate G3; passing a standalone compute proof does not pass Max; and reducing solve time does not pass the product when final validation or presentation still determines drag latency.
