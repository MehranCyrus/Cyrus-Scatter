# 04 — CUDA, OpenCL and graphics compute

[Contents](00_README.md) · [Max feasibility gate](07_MAX_2027_INTEROP_FEASIBILITY.md) · [Measurement protocol](10_BENCHMARK_AND_VALIDATION_PLAN.md) · [Distribution](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md)

**Decision — proposal, not a benchmark:** prototype CPU fitting plus supported HLSL deformation first. If large active neighborhoods make guide/contact fitting the measured bottleneck, use CUDA as the first **compute research implementation**, with an algorithm-matched OpenCL comparator on the same NVIDIA GPU. Keep the CPU implementation deployable. Prefer CUDA initially for reusable primitives and diagnosis, not because an API name guarantees faster kernels. A supported, efficient D3D11 compute-to-Nitrous path could reverse the compute choice.

## 1. Version and evidence boundaries

| Item checked on 27 October 2026 | Verified finding | Consequence |
|---|---|---|
| [CUDA archive](https://developer.nvidia.com/cuda-toolkit-archive) | Lists 13.4.3, October 2026, as latest. The separately opened live release notes identify **13.4 Update 2**, components 13.4.92 and CCCL 3.4.3. The attempted versioned 13.4.3 release-notes URL did not open. | Record this documentation mismatch. Do not claim that 13.4.3 was installed, compiled, or qualified. A local prototype must pin an actual installer and its matching documentation. [C01](17_SOURCE_LEDGER.md#c01), [C02](17_SOURCE_LEDGER.md#c02) |
| CUDA driver compatibility | 13.x limited-feature minor compatibility starts at branch R580; 13.4's corresponding branch is R615. New features and PTX can require newer drivers. | “R580+” alone is not a complete deployment guarantee. Test the selected AOT binary, driver and interoperability route together. [C02](17_SOURCE_LEDGER.md#c02), [C04](17_SOURCE_LEDGER.md#c04) |
| CUDA Windows toolchain | The 13.4 table lists MSVC 193x / VS2022 with native x64 C++20. | Supplied tools 14.38 correspond to compiler 19.38 and fit that family, but a build still must pass Max SDK and CUDA checks. Do not substitute a newer compiler because CUDA accepts it. [C03](17_SOURCE_LEDGER.md#c03) |
| Max toolchain | SDK table lists VS2022 IDE 17.14.13, v143, C++20 and Windows SDK 10.0.19041.0. Autodesk's 31 July 2026 clarification specifically pins v14.38 / 17.8 build tools, independently of the IDE. | Use the existing pinned compiler for the host boundary; inspect SDK project properties and record `/MD` or other CRT settings rather than guessing them. [C25](17_SOURCE_LEDGER.md#c25), [C26](17_SOURCE_LEDGER.md#c26) |
| OpenCL specification | The old “3.0-unified” URL redirects to **v3.1.2**, 17 September 2026, commit `219be24fc8947c68ee45b4d25b55a92b8f799f29`. | Specification publication does not establish installed NVIDIA, AMD or Intel driver support. Query the actual platform. [C06](17_SOURCE_LEDGER.md#c06) |
| OpenCL capabilities | OpenCL 3.0 makes many 2.x capabilities optional; 3.1 adds required subgroups and SPIR-V 1.0–1.4. Command buffers remain extension APIs. | Keep a plain workgroup implementation; enable subgroup, IL and command-buffer paths only under a recorded capability profile. [C06](17_SOURCE_LEDGER.md#c06), [C07](17_SOURCE_LEDGER.md#c07) |
| Graphics baseline | Supplied Cyrus shaders are SM5.0. D3D11 `cs_5_0` supports compute dispatch, UAVs and group synchronization; doubles require a capability check. HLSL wave intrinsics were introduced with SM6. | Existing SM5 drawing does not imply compute dispatch access, nor authorize SM6, D3D12 or Vulkan. [C14](17_SOURCE_LEDGER.md#c14), [C15](17_SOURCE_LEDGER.md#c15) |

All GPU execution, Windows compilation and Max checks in this chapter are **not executed**. Selected upstream source and license files were retrieved and inspected. That is source evidence, not a working Cyrus backend.

## 2. Choose the work boundary before the language

| Alternative | CPU work | GPU work and transfers | Synchronization / quality / cost |
|---|---|---|---|
| **A0: optimized CPU** | Capture, neighborhood, root classification, guide fit, visible-surface checks, materialization | Upload changed display geometry; shared rest geometry remains resident | Current semantic reference. Profile sparse map copying, scheduling, materialization and publication before moving arithmetic. CPU time and geometry upload may dominate at larger K. |
| **A1: CPU fit + vertex-shader deformation** | Same fit and verification; produce compact complete guide poses, visibility and conservative bounds | Upload only changed poses/masks; vertex shader reads shared rest vertices and pose lookup | First recommended experiment. No CUDA/OpenCL solver needed. Vertex/normal evaluator must match CPU and deliver renderer/Bake through a CPU path. Repeated passes may repeat vertex work; arbitrary pose-resource binding remains a Max gate. |
| **A2: CPU search + GPU fit/deform** | Host capture, stable candidate list, authoritative revisions, admission, complete visible-surface validation or conservative coverage with selective exact refinement | Upload K transforms and compact pair lists; solve active guides; read compact poses for CPU validation/canonical publication; draw through shared resources **if qualified**, otherwise upload through public Max handles | Favored compute experiment when active work is large. Potentially useful even without zero-copy if compact readback wins. Transfers, validator and host publication can erase solver savings. |
| **A3: resident GPU search + fit/deform** | Host deltas, source preparation, commit decisions, CPU fallback | Resident N-instance index and source data; upload changed collider/transforms; GPU compaction, pairs, solve and deformation | Reserve for measured CPU broad-phase bottlenecks or broad edits. More persistent memory, index mutation, overflow and asynchronous lifetime engineering. A local edit must not rebuild an N-instance structure. |
| **A4: GPU proxy/field preview + exact refinement** | Prepare admitted proxies/fields; exact surface qualification and final publication | Coarse fitting from shared proxy/SDF data, then pose readback or interop | Explicit approximation policy required. Every affected group is represented; proxy misses or incomplete checks cannot become “complete.” A final exact successor may differ visually. Rejected as an invisible quality downgrade. |

These are proposed architecture boundaries. Choosing A2 does not require A3, and choosing A1 does not require either compute API. A0 remains valuable for K near one even when N is one million. Conversely, N=one million detailed plants all active implies millions of unique guide states; shared source geometry does not eliminate that state.

## 3. Comparable computational mechanisms

| Mechanism | CUDA | OpenCL | D3D11 compute / SM5 |
|---|---|---|---|
| Kernels | C++ device kernels with explicit block/grid decomposition | OpenCL C kernels; device/language capability inventory | HLSL `cs_5_0`, dispatched through a qualified D3D context |
| Within a guide | Warp shuffles/reductions or block shared memory | Subgroup operations when supported; local-memory workgroup fallback | Group-shared memory and barriers; do not use SM6 wave operations in SM5 code |
| Between guide levels | Separate kernels or an explicitly synchronized task scheme | Separate enqueues/events or command-buffer dependencies | Separate dispatches and resource-state/use ordering |
| Stable work lists | CUB integer scan/radix sort; query scratch size and pool it | Implement or adopt a pinned scan/sort; workgroup primitives are not a device-wide scan | Additional HLSL scan/sort implementation; complexity is part of the choice |
| Repeated launches | Streams and CUDA Graphs | Command queues/events; `cl_khr_command_buffer` when present | Dispatch calls; no assumption of a public Max command-list injection path |
| Allocation | Persistent buffers, explicit arenas, optional stream-ordered pools | Persistent `cl_mem` arenas and offset allocation; query size/alignment limits | Reusable buffers/views if public ownership permits |
| Diagnosis | Nsight Systems/Compute, Compute Sanitizer, platform debugger | Event profiling plus vendor tools; support must be checked per vendor/backend | D3D debug/graphics tooling plus host traces; Max support is separate |

The table describes API mechanisms, not observed comparative speed. CUDA Graphs separate definition/instantiation from replay; they reduce repeated submission work but do not remove data dependencies. Prefer a bounded set of graph shapes by bucket/capacity, updating data and supported parameters, over one graph per plant. First measure ordinary launches: a graph cache adds its own memory and lifecycle cost. [C08](17_SOURCE_LEDGER.md#c08)

The inspected CUB `DeviceRadixSort` is stable and `DeviceScan` exposes temporary-storage sizing. Its floating-point scan documentation explicitly warns about pseudo-associative nondeterminism. Use integral counts for compaction and stable keys such as `(instance_id, guide_id, collider_id, feature_id)` for publication. Fixing those keys does not make iterative floating-point solutions bitwise identical. [C10](17_SOURCE_LEDGER.md#c10)

A CUDA pool does not replace admission. Cross-stream users must finish before a stream-ordered free; pool release thresholds control caching rather than impose a hard application memory limit. A proposed Cyrus pool tracks committed, live, retired and scratch bytes explicitly. Prefer preallocated scratch for each admitted bucket before optimizing allocation calls. [C09](17_SOURCE_LEDGER.md#c09)

**Scheduling proposal:** start with one workgroup/block per short independent guide, several guides per block when occupancy measurements justify it, and level barriers for branches. A block per 451-guide plant risks excessive imbalance and shared-memory demand; one thread per plant serializes its contacts. Bucket by chain length, branch depth, collider count and contact workload. Treat “NVIDIA warp = 32 lanes” as a backend detail, not the portable guide schema. For D3D11, the documented 1,024-thread group maximum is a ceiling, not a recommendation. [C14](17_SOURCE_LEDGER.md#c14)

## 4. Arithmetic must be matched before comparing speed

**Proposed reference profile:** CPU double world transforms and classification; translation into a bounded local frame before GPU conversion; FP32 local iterative pose state; explicitly selected double refinement for ambiguous contacts; normalized finite quaternions; bounded reductions. The mixed profile needs its own error envelope in [09](09_MEMORY_PRECISION_AND_HARDWARE.md). A double-precision audit of the final visible surface remains distinct from a float render buffer.

For the initial controlled comparison, use the same operation ordering where practical and record contraction, denormal, division and square-root policies. CUDA `--use_fast_math` changes flush-to-zero, division, square-root and FMA settings. Do not compare this profile against strict OpenCL math and attribute the difference to CUDA. Record explicit NVCC flags, OpenCL build options and HLSL flags in every result. [C16](17_SOURCE_LEDGER.md#c16)

Test at least two separately named arithmetic profiles:

1. **Controlled:** FP32 local, ordinary math, no broad fast-math mode; choose and record whether multiplication/addition contraction is allowed. Avoid floating atomic accumulation by fixed reduction or coloring where feasible.
2. **Qualified optimized:** allow selected fused or approximate operations only after running the same contact/root/strain/normal fixtures and reporting error changes. An API-specific faster but lower-quality method is a different experiment.

FMA, reassociation and different reduction trees can change answers even for individually IEEE-compliant operations. FMA is not intrinsically less accurate; exact bitwise parity can require sacrificing useful optimizations without establishing geometric correctness. Report stable identities, repeated-run reproducibility, geometric invariants and visual acceptance separately. [C17](17_SOURCE_LEDGER.md#c17)

FP64 hardware throughput and memory differ sharply by device family; “workstation” does not promise datacenter-style FP64. Select mixed precision from accuracy evidence and actual device measurements, not CUDA-core counts. FP16 is rejected for collision classification/root coordinates in the initial profile. Compression of display-only pose data is a separate bounded-error experiment.

## 5. Fair CUDA–OpenCL comparison on one NVIDIA GPU

**Specification; not executed.** Port one frozen algorithm, not two unrelated demos:

- Same prepared-source snapshot, stable ID order, root masks, guide lengths/hierarchy, collider triangles/proxies, transforms, Contact gap, Hide margin, stopping tests and iteration cap.
- Same active lists and primitive/refinement workload. Start with CPU-provided candidates so an acceleration-structure change cannot confound the API comparison.
- Same precision and contraction profile, measured penetration/strain limits and accepted result count. Count incomplete and failed jobs; exclude neither from latency nor quality reporting.
- Same resident immutable inputs, warm-up policy, transfer policy and maximum queued work. Compare kernel-only, resident pipeline, and full host boundary separately.
- Give both backends comparable tuning effort: at least thread/node, subgroup/guide and workgroup/guide buckets; report chosen local sizes, shared/local memory, occupancy or equivalent evidence, register spill and divergence indicators.
- Include plain launch/queue mode first, then graph/command-buffer mode only if both are available. A missing OpenCL extension is a deployment finding, not a fabricated zero-time comparison.
- Use the same GPU, driver, power policy, display load and renderer state. Randomize paired run order, repeat warm and cold runs, and capture completed transfers and end-to-end presentation. CUB versus a simple portable scan is an **ecosystem configuration** comparison; also isolate kernels to show what causes any gain.

A proposed dispatch policy uses measured predictors `(active_nodes, spans, collision_pairs, candidate_triangles, source_complexity, branch_depth, readback_bytes)` rather than K alone. Fit a conservative crossover from paired p95 measurements. Use hysteresis around the threshold and keep the CPU route for tiny edits. No numerical crossover has been measured here. The supplied 4.05 ms contact run cannot provide one.

CUDA's tooling advantage is concrete but limited: Compute Sanitizer checks memory, shared-memory hazards, initialization and synchronization; it does not prove solid classification or surface clearance. Run its tools against the standalone fixture harness before Max qualification. Use current tool versions recorded locally; the CUDA 13.4 toolkit's bundled Nsight version need not equal the latest standalone profiler. [C27](17_SOURCE_LEDGER.md#c27), [C02](17_SOURCE_LEDGER.md#c02)

## 6. Graphics interoperability changes the economics

CUDA supports both direct graphics registration/map/unmap and external-memory/semaphore imports. A registered resource cannot be simultaneously used by graphics while mapped for CUDA. This is a resource ownership constraint, not an optional performance hint. [C18](17_SOURCE_LEDGER.md#c18)

The inspected CUDA 13.4 `simpleD3D11` sample is particularly instructive: it creates its own D3D11 device/swapchain and shared keyed-mutex vertex buffer, then imports external memory and a keyed-mutex semaphore. It is **not** evidence that a Max `VertexBufferHandle` accepts those resources. Its infinite wait is unsuitable as Cyrus's host responsiveness policy. OpenCL-SDK's external-memory sample instead owns Vulkan resources, also outside Nitrous. [C11](17_SOURCE_LEDGER.md#c11), [C12](17_SOURCE_LEDGER.md#c12)

The public Max 2027 investigation in [07](07_MAX_2027_INTEROP_FEASIBILITY.md) includes a documented native D3D11 interface; this prevents a blanket statement that Max exposes no native device anywhere. What still needs proof is safe acquisition, same-device identity, the intended retained-item resource bridge, synchronization and device recreation. D3D11 compute may avoid an extra runtime and interop layer **if that whole path qualifies**. D3D12/Vulkan require additional host-supported evidence and are not proposed replacements for the viewport.

**Authoritative result rule:** in this proposed architecture, CPU-readable compact poses remain required for CPU validation, persistence and final geometry even when direct graphics sharing works. Sharing can remove a Max re-upload or full-mesh copy; it does not automatically remove this pose readback. A GPU-only authoritative validator/result would be a separate qualification.

**No direct sharing:** GPU guide fitting can still return compact poses to CPU-owned memory. Then validate and upload the same complete pose through public graphics handles, or materialize on CPU. Measure both copies and synchronization. Reject A2 if those costs plus validation eliminate end-to-end benefit. **Different display/compute adapters:** do not call this zero-copy; use the explicit host-staged fallback and its measured byte budget.

## 7. Weighted decision, sensitivity and falsifiers

The following is an **engineering-priority model**, not a performance result. Scores are 1 (poor fit) to 5 (strong fit); weights sum to 100. It applies only after a measured need for GPU guide fitting. “Host integration” is held at 2 until the proof in [07](07_MAX_2027_INTEROP_FEASIBILITY.md) passes. Throughput is deliberately unscored because no matched test exists.

| Criterion | Weight | CUDA | OpenCL | D3D11 compute |
|---|---:|---:|---:|---:|
| Numerical/algorithm expression for this fitter | 20 | 4 | 4 | 3 |
| Supported Max resource/lifetime integration, currently unresolved | 30 | 2 | 2 | 2 |
| Reusable primitives and diagnostic tooling | 25 | 5 | 3 | 2 |
| Packaging and recovery complexity | 20 | 3 | 2 | 4 |
| Broader hardware reach | 5 | 1 | 5 | 5 |
| **Weighted score / 5** | **100** | **3.30** | **2.80** | **2.75** |

The first prototype remains A1, CPU solve plus HLSL deformation; the matrix does not compare a vertex shader with a collision solver. CUDA's lead is a proposed integration-effort judgment for an NVIDIA-first compute effort.

**Sensitivity:** if public D3D11 compute/resource access qualifies and its integration score rises from 2 to 5, its score rises to **3.65**, reversing this initial ranking. If broader hardware reach receives 25% and the other weights become expression20/integration20/tooling15/distribution20, CUDA scores **2.80**, OpenCL **3.30**, D3D11 **3.35**. If direct sharing is unavailable for every compute backend, compare compact readback end to end; the score alone cannot authorize any solver investment.

**Reject or reverse the proposal when:** CPU profiling finds publication/map copies dominate; HLSL pose binding fails; strict GPU fitting cannot satisfy the visible-surface contract; OpenCL matches quality and materially wins total supported-device cost; D3D11 eliminates the costly bridge; or the GPU path misses paired latency/memory gates in [10](10_BENCHMARK_AND_VALIDATION_PLAN.md). Recommend NVIDIA only after those tests, while preserving CPU startup and fallback. No expensive GPU purchase is justified by this research alone.
