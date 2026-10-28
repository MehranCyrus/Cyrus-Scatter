# 10 — Benchmark and validation program

[Contents](00_README.md) · [Numerical gates](09_MEMORY_PRECISION_AND_HARDWARE.md) · [Prototype specifications](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)

**Status.** The GPU/CPU-production/Max benchmark below is **proposed and not executed**. Only the small Python arithmetic/analytic controls in [optional](optional/README.md) ran here. The supplied 4.05 ms native-stage observation is S, not a new result or a baseline distribution.

## 1. Freeze inputs before timing

Create a versioned case bundle containing prepared source arrays, collider assets, exact placements/transforms, ordered edit events, settings, expected exclusions, reference output or invariant expectations, and hashes. Hash geometry bytes **and** topology, guide/parent/binding data, source overrides, units and evaluator policy. Retain source and transformed geometry hashes separately. A file name or triangle count is not a fingerprint.

The following source families keep the core matrix manageable:

| Asset ID | Reproducible definition | Fingerprint status |
|---|---|---|
| R8 | Included original ribbon: 8 nodes at `(0,0.1j,0)`, 16 vertices at x=±0.01 m, 14 triangles, first ring fixed | Geometry and hash present in [executed checks](optional/executed_checks.json) |
| R33 | Same 0.7 m ribbon, 33 nodes at y=`0.7j/32`, 66 vertices, 64 triangles; separate authored twist profile | Recipe specified; generated prepared/binding hash must be recorded before comparing backends |
| G451 | Coordinator's actual 451-guide, 22,032-vertex, 27,501-triangle source | Private bytes unavailable; local capture and exact node/parent counts required. Do not substitute another grass and keep this name |
| BR63 | Synthetic binary branch forest with 63 guides, depths 0–5, eight nodes/guide; authored parent sockets, fixed root ring | Proposed generator fixture; freeze its geometry/bindings and hash locally |
| LEAF | Broad quad spanning a sphere although its supporting guide is clear; UV-seam duplicate and custom-normal variants | Analytic hazard present in X05; full prepared render fixture to freeze locally |
| HP | One library high-poly asset, with explicit preparation/classification and at least one broad-leaf/fixed-part group | Local asset choice, counts and fingerprint pending; no invented public-asset benchmark |

All fixtures use metres, internal +Y up, positive uniform scales `{0.1,1,10}` as separate correctness variants, identity unless the case says otherwise, and a double host translation origin initially zero. Use a specified counter-based deterministic random generator or export the final arrays so CPU/CUDA/OpenCL see identical bytes. Record generator algorithm/version, not just seed. Included analytic controls use literal arrays and do not depend on a random library.

**Placement recipe — P.** Put the requested active population in a fixed 10 m × 10 m test patch with stable IDs and exported transforms. Put inactive placements in distant non-overlapping tiles, retaining the same active patch while varying N. Export the complete resulting candidate lists from the CPU reference. `K_requested` is a target, not an assertion: record observed `K,H,Q,P,V_A,T_A`, hidden groups and changed descendants for every event. If observed work differs across backends, stop the comparison and resolve it first.

For B02–B04, freeze one active-patch and edit-trace byte sequence/hash and reuse it unchanged. The different per-row seed controls inactive placement only; it must not change that common active workload. For every claimed large-fitting bin, freeze nontrivial CPU-reference work expectations for changed guides, `H/Q/P/V_A`, iterations and visibility. A large candidate count consisting only of clear or wholly hidden plants does not qualify as large contact-fitting coverage. Cases whose intended geometry cannot realize the requested work are relabeled with observed work, not presented as the planned stress population.

## 2. Core matrix: 18 cases, not a Cartesian explosion

Every row runs CPU A0 and shader A1 where available. A2 CUDA/OpenCL is added only after its correctness gate; A3/A4 are separate algorithm/quality experiments. Seeds are `20261027 + row number` and are stored explicitly in [case manifest](optional/benchmark_cases.json). Memory-inadmissible rows record a rejection, not an attempted allocation.

| Case | N | Requested K | Source / contacts | Purpose and required output |
|---|---:|---:|---|---|
| B01 | 1k | 1 | R8; one sphere | Tiny-edit routing and launch/host overhead |
| B02 | 10k | 10 | R8; one sphere | Small active set |
| B03 | 100k | 10 | Same active R8 patch | Locality while resident scene grows |
| B04 | 1M | 10 | Same active R8 patch | Resident admission/index/publish cost; not all-active claim |
| B05 | 10k | 1 | G451; one closed stone | Real-source sparse guide count and audit cost |
| B06 | 10k | 10 | G451; same stone family | Local crossover neighborhood |
| B07 | 100k | 100 | G451; one collider/plant | Guide and validation growth |
| B08 | 100k | 1k | G451; eight relevant colliders | Broad active patch and competing contacts |
| B09 | 1M | 10k | G451; eight relevant colliders | Large active set, admission before allocation |
| B10 | 10k | 100 | G451; 64 relevant colliders | Contact count/scratch/divergence stress |
| B11 | 1M | 10 | R8; 16,384 global colliders, at most eight relevant | Global versus local C; one collider moved |
| B12 | 100k | 1k | R33; one sphere/box mix | Long-chain dependency and frame transport |
| B13 | 10k | 100 | BR63; eight colliders | Parent-depth scheduling, child contacts and socket errors |
| B14 | 10k | 100 | LEAF; two close obstacles | Clear guides with colliding visible leaf faces |
| B15 | 10k | 100 | Eight distinct sources including HP; one collider each | Source diversity, cache and material/normal streams |
| B16 | 1M | 1M | R8; all-active field of simple proxies | Millions of simple blades, memory permitting |
| B17 | 10k | 10k | G451; broad-area edit | Many complex clumps all active; report actual feasibility |
| B18 | 1M | 1M | G451 | Admission arithmetic/rejection control; no interactive feasibility assumption |

Run four semantic phases for each eligible row: rest/clear; drag into contact; hold unchanged; move away and verify rest restoration. Keep one moving collider in the primary trace. Add a batch-motion trace for B08/B11 after primary comparisons, not every row. Use 0, 1 mm and 10 mm Contact gap and independently varied Hide margin/modes in the correctness suite; performance core freezes one exact setting per case.

Stress extensions, run only to answer a remaining risk: many retained unique poses with tiny new K; warm/cold source/BVH/SDF caches; first kernel/shader compile; source/collider topology edits; sparse versus dense hidden groups; nearly infeasible gaps; fast endpoint teleports; rotation/uniform scale edits; large-world/small-feature coordinates; device loss, cancellation and stale revisions; GPU renderer contention; unsupported devices. N above 1M is explicitly a future admission test, never current product support.

## 3. Build and environment record

For each run capture CPU model/core policy, RAM, Windows build/power state, GPU exact SKU/VRAM, active display adapter LUID and CUDA/OpenCL identity, driver, display count/resolution/refresh/VRR, Max full build, plugin commit/configuration, renderer version/status, toolkit/compiler version, actual CRT flags, kernel targets, and all precision/optimization options.

Record `cl /Bv`, `nvcc --version`, actual OpenCL platform/device/version/extensions, `nsys --version`, and each tool's help output with the run artifact. These are instructions for the local team, not commands executed here. Match CPU worker policy, algorithm, source/quality profile, active work and stopping criteria across backend comparisons. Distinguish scalar/parallel CPU configurations and CUB-assisted versus hand-written primitive variants. Report tuning effort/configurations tested; do not benchmark an optimized algorithm against a deliberately poor port.

**P.** Warm up 100 completed edits after source/JIT preparation; then collect at least 1,000 event samples over three independent sessions per selected core row. Randomize paired backend order. A row that is too slow or memory-heavy records the actual count and reason; it is not silently omitted. For p99 decisions use at least 10,000 event samples in the chosen adoption/crossover bins and report tail uncertainty/session variability. Cold startup/first-use costs are ten separate fresh-process/cache-controlled observations, not folded into warm medians.

A held-input trace is reproducible algorithm load, but is not physical input latency. Also run a recorded host drag trace under native input delivery, and use physical high-speed camera/photodiode instrumentation for a smaller acceptance subset if input-to-photon is a product claim. Do not assign zero latency to coalesced/dropped requests: record them separately, update age, and time to latest completed publication.

## 4. Measure completed work and publication age

| Stage | Proposed instrumentation | Report |
|---|---|---|
| Input/capture/invalidation | Host QPC timestamps plus request/revision ID | Event received, capture duration, dirty-set union, map-copy bytes/time |
| Neighborhood/packing | CPU ranges and work counters | Search, sorting, candidate counts, serialization and admission |
| Fit/contact/refine | CPU ranges or device events on ordered queues | Completed solve time, iterations, pair/triangle visits, residual/failure |
| Deformation | Separate CPU evaluator and shader/compute measurement | Position/normal work, vertex count and repeated draw passes |
| Transfers | Device-event or API completion markers plus byte counters | Actual HtoD/DtoH, source cold uploads, pose packets, hidden staging copies |
| Synchronization/publication | QPC, fence/event IDs, dependency records | Queue wait, validation wait, host commit, graphics-ready time |
| Draw/presentation | PresentMon/ETW plus pose revision marker | Presented frame intervals, dropped frames, first displayed frame containing revision |
| Memory/recovery | Cyrus allocation ledger plus OS/driver budget | Peak live/scratch/retired/staging bytes, total process/VRAM, error recovery |

QPC is the Windows native high-resolution interval clock; record its frequency and use a consistent time domain. Device-event timestamps do not automatically share QPC's epoch. Calibrate/correlate trace domains or use the profiler's documented correlation rather than subtracting unrelated raw clocks. [R05](17_SOURCE_LEDGER.md#r05)

Use CUDA events for ordered device work and completed transfer scopes, or profiling-enabled OpenCL queue events (`QUEUED/SUBMIT/START/END` as supported). CPU command submission time is not GPU completion. A span covering multiple streams needs explicit dependency/completion coverage; one stream's event does not measure unrelated in-flight work.

**Critical path.** For one event, measure `first_present_containing_revision − event_received`. Show the dependency timeline: CPU capture → candidate work → transfers → solve → CPU validation → publication → drawing → presentation. For pipelined events, some stages overlap; do not sum overlapping durations, nor report only the shortest kernel as total latency. Also report the age of the most recent displayed validated result during dragging, including when new inputs are coalesced.

## 5. Tooling and presentation proof

PresentMon **2.6.0**, released 21 September 2026, commit `e13fce6acdb55a808fd8318175a56863e532d95f`, is an inspected primary reference. Its console documentation exposes process filtering, CSV, QPC timing and display metadata. Use the installed version's `--help` to freeze accepted flags, and identify the correct viewport swapchain/display rather than aggregating all Max windows. [R06](17_SOURCE_LEDGER.md#r06) [R07](17_SOURCE_LEDGER.md#r07)

**Proposed command shape, not executed:**

```powershell
PresentMon-2.6.0-x64.exe --process_name 3dsmax.exe --output_file present.csv --qpc_time --write_display_metadata
```

PresentMon's click/input metrics cannot be assumed to identify the particular collider revision caused by every drag/mouse-move. Add a small opt-in viewport revision marker or a documented trace-to-frame mapping, then verify the first displayed frame carrying that result. Call this **input-received-to-present** unless physical input and display scanout/photon measurement are actually included.

Nsight Systems can correlate CPU ranges, CUDA, DirectX and WDDM activity. The live release page inspected here labels 2026.5.1, while CUDA 13.4 Update 2 bundles 2026.3.2.476; do not conflate them. Save the installed version/trace mode. A proposed targeted diagnostic invocation is:

```powershell
nsys profile --trace=cuda,nvtx,dx11,wddm --wddm-memory-trace=true --capture-range=nvtx --nvtx-capture=drag@Cyrus --capture-range-end=stop --kill=none --output=cyrus_trace "C:\Path\To\3dsmax.exe"
```

Prepare the scene and finish warmup before opening the registered NVTX string `drag` in domain `Cyrus`; close it after a bounded 20-second prepared drag trace and its final completion. This readiness gate avoids capturing only Max startup. Validate installed options/permissions; `--kill=none` prevents profiler-session termination from killing the target. Use a dedicated test session and separate diagnostic tracing from final latency runs. [R08](17_SOURCE_LEDGER.md#r08) [R09](17_SOURCE_LEDGER.md#r09)

Nsight Compute may replay kernels and save/restore memory while collecting counters; its diagnostic timings are not an unbiased host-drag measurement. Use narrow standalone kernels for occupancy, register/spill, bandwidth and divergence diagnosis. Run separately unprofiled or lightly instrumented end-to-end measurements. [R10](17_SOURCE_LEDGER.md#r10)

GPUView from Windows Performance Toolkit gives CPU/GPU scheduling, context/flip queues and ETW diagnostics. Capture a short trace with its documented `Log.cmd` start/stop workflow and inspect lost events. Use it to explain queue contention, not as an automatic collider-to-photon mapper. [R11](17_SOURCE_LEDGER.md#r11)

## 6. Acceptance and reporting

For every backend/case report p50/p95/p99, maximum, event/sample count, cold spikes, published/dropped/coalesced/stale counts, convergence and failure rate, all quality errors, completed transfer bytes/time, CPU/VRAM peaks and recovery outcome. Keep failed attempts in the workload accounting; a fast result obtained by dropping difficult plants is a failure, not a speedup.

Targets of 30/60/120 Hz correspond to **33.33/16.67/8.33 ms per presented frame** (E). They are end-to-end budgets shared with the rest of Max. Pick a product target before tuning and report both frame pacing and update age; an asynchronously smooth viewport may still show a stale plant response.

**P adoption gate:** all correctness/status/lifetime tests pass, the admitted memory budget holds, and the candidate improves paired end-to-end p95 by at least 20% in its routed workload bins over three sessions without a material p99/recovery regression. Report confidence/session variation and the actual absolute latency. For sparse edits, require no statistically or practically material regression versus routing directly to CPU. The 20% margin is an engineering proposal, not a result or universal economic threshold.

Choose/reject the backend based on the measured critical path and total maintenance burden. If CPU validation, host map copying, readback/re-upload or drawing dominates, stop broadening solver investment and fix that boundary. An API race cannot be won by changing quality, algorithm, active populations or transfer policy unnoticed.
