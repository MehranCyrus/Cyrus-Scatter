# 10 — Benchmark and validation program

[Index](00_README.md) · [Prototype specifications](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) · [Acceptance](18_ACCEPTANCE_CHECKLIST.md)

## Execution status and fair comparisons

**[U/D] All Max, CUDA, OpenCL, HLSL and production CPU benchmark cases below are NOT EXECUTED.** Researcher A executed only the arithmetic, six analytic counterexample oracles and artifact checks recorded in [analysis](analysis/README.md). A compiler existing in the Linux environment does not establish that the Windows plugin or a GPU harness compiled.

Compare CPU reference, CPU+graphics deformation, CUDA and OpenCL on **one identical NVIDIA device** for API performance. Use the same source/guide data, obstacle representation, solver equations/order, constraints, iterations/stopping conditions, precision, error tolerances, visibility, collision coverage, final mesh checks and residency. If CUDA uses a field and OpenCL uses triangle queries, that measures two algorithms, not the APIs. A second cross-vendor experiment answers portability, not the first comparison.

Measure both a matched baseline implementation and an equal optimization-effort variant. Report hours/changes and kernel-layout choices; vendor primitives may be a legitimate engineering advantage, but label their contribution. Include both resident and realistic transfer/validation paths. Do not disable final validation only on the faster lane or count failure as an instant successful solve.

## Fixture families and reproducibility

**[D]** Local engineers generate/export the following canonical fixtures once, then all backends read identical binary arrays. Each file receives an actual SHA-256 when created; this report does not invent fingerprints for unavailable geometry.

| Asset code | Definition | Purpose |
|---|---|---|
| S1 | One rooted segmented blade, 8 nodes, 0.30 m long, 4 mm half-width, analytic rest frame; two-sided render strip | Simple positive controls, exact root/length tests |
| S2 | 32 independent guides, 8 nodes each; deterministic grid roots and modest authored curvature/twist | Uniform warp/workgroup work |
| S3 | **Supplied actual asset only when locally exported:** 451 guides / 22,032 vertices / 27,501 triangles; record actual node/group/seam counts | Product relevance; no substitute source called the same asset |
| S3s | Synthetic 451-guide source, 8 nodes each, roots on 41×11 grid at 8 mm pitch, heights 0.2–0.4 m | Publicly reproducible scaling surrogate; explicitly not S3 |
| S4 | Rooted branching plant, depth 4, mixed 8/16/32-node chains, 24 broad rigid or deformable leaves with explicit bindings | Parent scheduling, width and twist, sparse child contact |
| S5 | 64-node strongly curved guide plus UV-seamed thick strip and fixed root ring | Long-chain divergence, normals and hard frame modes |
| S6 | S3s source geometry copied into 100 distinct source revisions/material assignments | Residency, cache churn and batching costs |

Use seed `0x43595255` plus case index. For a portable generator, specify unsigned 32-bit xorshift `(x ^= x<<13; x ^= x>>17; x ^= x<<5)` with modulo-2³² masking, `u=x/2³²`, stable row-major order, and record the generated arrays. S3s heights use `0.2+0.2u` metres; rest offsets use bounded signed next variates and a documented analytic curve. Freeze the generator version and source hashes; do not rely on an unspecified language RNG. Guides, material frames, render geometry and binding generation are part of the future fixture artifact and must be validated before timings.

For positive controls, independently construct a feasible pose or analytic solution and verify it with the reference collision evaluator. Do not hardcode it as a solver answer. A harness accepting any failure status cannot demonstrate successful fitting. Infeasible and ambiguous fixtures require diagnostic checks, not impossible convergence targets.

## Manageable core matrix

`K` below is a requested placement set; report actual candidate count, affected/hidden/restored groups, `A,Q,P_p,P_s,P_t`, iterations and query work. Keep placement positions deterministic and manipulate collider influence so the intended neighborhoods are independently verified. Cases are not a Cartesian cross product.

| Case / seed suffix | N | Target K | Source | Relevant colliders / global | Focus |
|---|---:|---:|---|---|---|
| B01 / 1 | 1k | 1 | S1 | 1 / 1 | Clear/exact rest and small-launch overhead |
| B02 / 2 | 10k | 10 | S2 | 1 / 128 | Sparse CPU index and compact updates |
| B03 / 3 | 100k | 10 | S3s | 1 / 1k | Sparse resident population growth |
| B04 / 4 | 1M | 10 | S3s | 1 / 16,384 | Current admission boundary; horizontal footprint locality |
| B05 / 5 | 1k | 100 | S2 | 8 / 128 | Simultaneous contacts, middle crossover |
| B06 / 6 | 10k | 1k | S3s | 1 / 1k | Many guide solves, regular work |
| B07 / 7 | 100k | 10k | S3s | 8 / 16,384 | Large active region, admitted chunking and peak memory |
| B08 / 8 | 10k | 100 | S4 | 8 / 128 | Branch hierarchy and broad leaves |
| B09 / 9 | 10k | 100 | S5 | 64 / 1k | Long-chain divergence and query pressure |
| B10 / 10 | 10k | 1k | S6 | 8 / 1k | Distinct source cache, materials and shader batching |
| B11 / 11 | 200 | measured neighborhood | S3 | 1 / 1 | Reproduce supplied fixture only after actual asset/log acquisition |
| B12 / 12 | 1k | all | S1 | 1 / 1 | Small all-active baseline |
| B13 / 13 | 1M | all, if admitted | S1 | 1 / 1 | Million simple blades; separate from detailed clumps |
| B14 / 14 | 100k | 1 | S3s | 1 / 1k | Sweep retained `R=0,1k,10k,100k` subject to admission; map-copy/publication scaling |
| B15 / 15 | 10k | 100→0 | S3s | 1 / 1k | Collider leave/delete/Undo restores rest |
| B16 / 16 | 10k | 1k | S4 | 8 / 128 | Renderer contention, final delivery and failure retention |

B07/B13 must pass resource admission first. If rejected, report requested/estimated/available bytes and the rejection; do not run an unsafe reduced test under the original case name. Beyond 1M is a future-capability stress only, not current product support.

### Targeted stress extensions

Run the [11](11_EDGE_CASE_AND_FAILURE_MATRIX.md) correctness cases once per backend/precision before large timing sweeps. Then extend only the suspected bottleneck: 4/8/16/32/64-node distributions; 1/8/64 relevant colliders; zero versus many distinct posed guides; near-all hidden rooted groups; analytic versus convex/mesh/field obstacles; cold field/BLAS construction; changing source and collider topology; low/large gap; multiple moving colliders; far-away coordinates; small scales; CPU fallback; low VRAM; stale completions; adapter recreation. Avoid an exhaustive expensive cross product.

## Per-case record and run protocol

**[D] Required manifest:** case/seed/generator commit; all asset and settings hashes; Max patch/plugin build/SDK/compiler/CRT; Windows/driver; CPU/GPU model and architecture/VRAM; display and compute LUID/UUID; power/thermal state; resolution/viewports/refresh/VSync; exact camera/frustum and visible instance/vertex counts; frozen LOD/cull policy and material/pass state; renderer state; scene units and frame conversion; transforms; counts and admission budgets; precision/FMA/fast-math flags; solver objective/order/caps; cold/warm cache keys; publication policy; active output status and exact validation thresholds. Resident `N` is not visible draw count. Keep off-host compute-harness results distinct from in-Max presentation results.

For each admitted case, first validate correctness and report all failures. Then run a cold launch/process session separately, including context creation, module load/JIT, source upload and cache construction. For warm timing, use 50 warm-up requests followed by 500 measured requests across five fixed drag trajectories; repeat in five fresh sessions. These counts are a proposed initial protocol, not a statistical guarantee. Randomize backend run order; log warm-up stabilization and thermal throttling. For p99 decision-making, pool only genuinely comparable samples and report sample count plus bootstrap/session uncertainty, or increase the run count if the tail is unstable.

Freeze five timestamped transform traces before comparison: slow linear entry/exit, fast linear entry/exit, circular translation, stationary-centre rotation/uniform-scale change, and teleports with leave/delete restoration. Save each trace and its SHA-256, initial snapshot, sampling rate and exact timestamps; every backend receives those same files. These traces are specified here but not generated or executed. Keep coalescing and input rate the same. Count discarded/superseded requests and age of visible accepted result; measuring only accepted outputs can otherwise conceal severe latency or starvation.

## Measure the full critical path

| Stage | Measurement | Exclusions / traps |
|---|---|---|
| Host capture, invalidation, map copy, neighborhood | QPC/ETW markers and counts per generation | Do not attribute all host time to collision |
| Preparation/BLAS/field residency | Cold and dirty-asset timers, bytes and cache hit/miss | Not charged to every warm drag unless actually rebuilt |
| Solve and visible refinement | CPU wall/worker time; completed GPU event time per stage; exact residuals | Submission duration is not completed device execution |
| Deformation/normals/tangents | CPU evaluator time or per-pass GPU timing | Multiple viewport/material/shadow passes can repeat work |
| Transfers | Actual uploaded/read bytes and completed event intervals | Async API return time is not transfer duration |
| Synchronization/publication | Queue wait, fences, host marshaling, accepted/retired version counts | Do not double-count overlap by simply summing all stage times |
| Drawing/presentation | Presented-frame intervals, result generation shown, correct viewport swap chain | Max process may contain multiple windows/swap chains |
| End-to-end | Input/collider-edit generation timestamp → first displayed frame showing that complete generation | CUDA event time or raw Present frequency alone is insufficient |
| Resources/recovery | CPU live allocations/RSS, GPU budgets/commits, retired/staging peak, cold/recovery latency | Nominal free VRAM and average allocations hide peaks |

**[V]** Windows QPC is the native interval clock; custom ETW/TraceLogging events can associate application stages with OS traces. Nsight Systems provides CUDA/NVTX and Windows WDDM tracing; the current retrieved release is 2026.5.1 (documentation updated 9 September 2026). Nsight Compute 2026.3.1 is suited to focused kernel analysis, but replay/metric collection alters execution; it is not the uninstrumented drag-latency run. [SYS04](17_SOURCE_LEDGER.md#sys04) [SYS05](17_SOURCE_LEDGER.md#sys05) [SYS06](17_SOURCE_LEDGER.md#sys06) [SYS07](17_SOURCE_LEDGER.md#sys07) [SYS10](17_SOURCE_LEDGER.md#sys10) [SYS11](17_SOURCE_LEDGER.md#sys11)

**[V/D]** PresentMon v2.6.0 provides a version-qualified ETW presentation tool candidate. Its console documentation distinguishes displayed frames, swap chains, input and instrumented timing metrics. Use its CSV data with Cyrus generation markers; do not assume a generic click metric identifies a particular collider deformation. In Max, qualify the mapping from draw/generation marker to displayed viewport frame. If supported host instrumentation cannot establish it, use an external high-speed visual/input measurement for physical input-to-photon and label software estimates accordingly. [SYS08](17_SOURCE_LEDGER.md#sys08) [SYS09](17_SOURCE_LEDGER.md#sys09)

Example commands are **unexecuted collection recipes**, to be checked against the installed pinned binaries:

```powershell
PresentMon-2.6.0-x64.exe --process_name 3dsmax.exe --timed 60 --output_file presents.csv --qpc_time --write_display_metadata
nsys profile --trace=cuda,nvtx,wddm --wddm-memory-trace=true --duration=30 --output=cyrus_gpu_trace .\CyrusGpuHarness.exe --case B06
ncu --set basic --kernel-name regex:fit --launch-count 10 .\CyrusGpuHarness.exe --case B06
```

The harness executable above is a **proposed name**, not a delivered binary. PresentMon installed filename/options and Nsight privileges/features must be checked with `--help`; output absence is recorded, not filled with guessed measurements. Use GUI attach/launch where needed for Max. Do not call `cudaDeviceReset()` on a host-shared context merely to flush profiling data.

Report p50/p95/p99, worst spike, update throughput, presented FPS, accepted-result age, convergence/failure/overflow rate, all residual maxima and confidence intervals. Keep incomplete/approximate results in separate categories. Identify the overlapping critical path on a timeline; a 2 ms solver can still produce a slow edit if validation or presentation waits dominate.

## Proposed go/no-go criteria and crossover

**[D]** First gate correctness: zero false accepted results in adversarial fixtures; all known-feasible synthetic controls meet declared constraints; exact rest/whole-group visibility/identity preservation; bounded work/memory; zero stale publications. A GPU result that runs faster by weakening these gates fails.

For a route to become automatic, propose a meaningful warm end-to-end p95 improvement of at least 20% **and** 2 ms over the qualified CPU route for the selected workload class, with no worse p99 beyond a pre-agreed margin, no new false acceptances, and admitted peak memory. These are product decision thresholds, not measured speedups. The measured crossover is the smallest stable workload feature region satisfying that rule in repeated sessions. Publish its data; do not substitute a universal `K=100` guess.

30/60/120 Hz correspond to 33.33/16.67/8.33 ms display periods. Choose a target tier before testing. A provisional 60 Hz sparse-edit target can require p95 newest-result input-to-present within two periods (33.33 ms), while sustaining presented frames within the one-period draw budget; this does not mean every 60 Hz frame contains a new fit. Large edits may use explicit pending/final-quality states. If surface verification dominates, report that fact and optimize it instead of claiming an API victory from kernel timing.
