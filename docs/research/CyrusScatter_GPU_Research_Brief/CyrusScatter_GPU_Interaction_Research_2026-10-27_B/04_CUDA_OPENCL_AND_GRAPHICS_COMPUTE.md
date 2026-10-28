# 04 — CUDA, OpenCL, and graphics compute

[Index](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Source ledger](17_SOURCE_LEDGER.md)

Researcher A · Source retrieval: 27 October 2026. **No CUDA/OpenCL compilation, GPU run, Windows driver qualification, or Max execution was available.** The API facts below come from primary documentation and the explicitly identified source inspections. Scheduling choices and recommendations are proposals. Supplied Cyrus timings are not API comparisons.

## Decision

Keep the CPU implementation as the reference and the small-neighborhood execution path. Test supported HLSL guide-to-vertex deformation before investing in a compute solver. If large active neighborhoods justify a compute backend, CUDA is the first NVIDIA prototype candidate because its reusable primitives, allocation facilities, profiling, and correctness tools can reduce implementation work. This is an engineering-cost hypothesis; no evidence here establishes that the same algorithm runs faster in CUDA than OpenCL on the same NVIDIA GPU.

OpenCL is a credible alternative when broader GPU support is a funded requirement, when a tested OpenCL/D3D11 route works better in Max, or when a matched implementation wins the quality-constrained end-to-end comparison. D3D11 compute is a third candidate if supported device/context/resource access is demonstrated and the solver remains small enough that writing missing primitives is affordable. Ordinary vertex-shader deformation needs neither CUDA nor OpenCL. The public Max feasibility gates and limitations are in [07](07_MAX_2027_INTEROP_FEASIBILITY.md).

## Version and toolchain findings

These are the live documentation versions retrieved on the research date, not promises about an artist's installed driver. Freeze downloaded installers, headers, licenses, and hashes before qualification.

| Item | Verified documentation | Consequence for Cyrus |
|---|---|---|
| CUDA Toolkit | 13.4 Update 2; compiler/runtime/NVRTC 13.4.92; CCCL 3.4.3 | A concrete candidate to qualify, not an automatic minimum for every future implementation. [API01](17_SOURCE_LEDGER.md#api01) |
| CUDA Windows compiler table | MSVC 195x / Visual Studio 2026; 193x / Visual Studio 2022; 192x / Visual Studio 2019 | The literal table does not name MSVC 194x. Visual Studio family labels and exact compiler numbers must both be checked locally. [API02](17_SOURCE_LEDGER.md#api02) |
| CUDA architectures | Current nvcc documentation lists architectures beginning at `sm_75` for this toolchain | A selected CUDA 13.x AOT package has a Turing-or-newer architecture floor. The vegetation algorithm itself does not require this floor. [API03](17_SOURCE_LEDGER.md#api03) |
| CUDA drivers | CUDA 13.x minor-version compatibility starts at driver family 580; release notes associate 13.4 with R615 | A compatible cubin may work on an older 13.x-compatible driver with restrictions. New features and PTX compilation can require newer drivers. Qualify an exact Windows driver build, not merely “580+.” [API01](17_SOURCE_LEDGER.md#api01) [API04](17_SOURCE_LEDGER.md#api04) |
| OpenCL specification | Unified specification 3.1.2, dated 17 September 2026 | This is a specification version, not proof that a particular NVIDIA Windows driver implements it. [API05](17_SOURCE_LEDGER.md#api05) |
| OpenCL SDK/loader | Release `v2026.05.29` synchronizes with OpenCL 3.1.1 | Do not mistake SDK header coverage for runtime support or label this SDK as the 3.1.2 implementation. [API44](17_SOURCE_LEDGER.md#api44) [API49](17_SOURCE_LEDGER.md#api49) |

**Provided project fact:** the recorded Cyrus Max 2027 build used MSVC tools 14.38.33130 and Windows SDK 10.0.19041.0. The separately researched Autodesk 2027 requirements identify Visual Studio 2022 17.14.13, the v143 toolset, C++20, and that Windows SDK; see [07](07_MAX_2027_INTEROP_FEASIBILITY.md) for Autodesk sources. The local observation does not qualify every supported host/compiler combination. Equally, CUDA's literal “193x” table row is insufficient to conclude that all 194x compilers fail.

**Required local probe:** record `cl /Bv`, `_MSC_VER`, `_MSC_FULL_VER`, `nvcc --version`, CMake generator/toolset, `/MD` configuration, and all CUDA flags. Compile a minimal C++20 backend, then the selected CUB operations, using the exact compiler. Inspect the installed `crt/host_config.h` guard. Do not use `--allow-unsupported-compiler` as a shipping qualification. If a single compiler does not satisfy both vendors, isolate the optional numerical backend behind an opaque C ABI, without passing Max classes, STL objects, exceptions, CRT-owned allocations, or compiler-specific vectors across it. This is a proposed boundary, not a waiver of either vendor's support matrix. Distribution details are in [15](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md).

## What is and is not an API comparison

The first comparison uses one NVIDIA card, one driver installation, one host CPU, and identical copied source/collider snapshots. Compare a bounded static fitter from rest, with the same capsule/contact rules, root constraints, convergence tolerances, visible-surface acceptance, iteration/work caps, and failure policy. Do not compare CUDA analytic proxies against OpenCL full triangle meshes and attribute the difference to the language.

Use two explicitly different experiments:

1. **Mechanism parity:** equivalent data layout, decomposition, operation ordering, precision, kernel boundaries, transfer policy, and fixed-work schedules. This makes compiler/runtime costs easier to interpret. It may leave each platform below its best attainable performance.
2. **Equal engineering effort:** allow CUDA CUB and OpenCL's chosen scan/sort implementation, subgroup specialization, graph replay, and different scheduling where correctness remains equal. Record changed algorithms, development effort, code size, memory, and validation burden. This measures the implementation decision the team actually faces.

Add the optimized CPU reference and CPU-fit/HLSL-deformation baseline to both. Include complete input-to-present latency, final success rate and error, cold setup, and peak memory. Kernel-only timings are secondary. Rejected or incomplete fits count as failures; finishing fewer contacts is not acceleration.

Use the same discrete GPU for CUDA and OpenCL. Separately test cross-vendor portability on actual AMD/Intel devices; don't mix the two questions. If one API cannot share with the host, compare the real compact readback path against the other API's real sharing path, and report that integration difference openly.

## Facilities that matter to this workload

| Facility | CUDA | OpenCL | D3D11/HLSL baseline |
|---|---|---|---|
| Parallel launch | Kernels in streams; explicit dependencies/events | NDRange kernels in queues; explicit events; query out-of-order capabilities | Compute `Dispatch`/`DispatchIndirect` if the host exposes a supported context; vertex shaders evaluate visible vertices during drawing |
| Intra-group work | Warps, cooperative operations, block shared memory | Workgroups, local memory, queried subgroups | Thread groups and group shared memory; ordinary SM5 must not assume later shader-model wave intrinsics |
| Repeated schedule | CUDA graphs | `cl_khr_command_buffer` where implemented | Application command submission; not equivalent to assuming a CUDA graph API exists |
| Scan/sort/compaction | CUB/Thrust supplied as source/header libraries | Choose, inspect, qualify, and maintain an implementation; OpenCL API alone is not a drop-in CUB library | Implement or integrate suitable kernels; main cost advantage may be staying on the graphics device |
| Allocation | Explicit buffers; stream-ordered allocation/pools where supported | Explicit buffers/subbuffers and application pooling; capability-specific SVM is not required for this design | Resource descriptions and usage/binding flags constrain operations |
| Precision/atomics | Architecture-dependent throughput and supported atomics | Query features/extensions and FP capability; subgroup size is not a portable constant | Feature-level and shader-profile restrictions; unsupported FP64/atomic assumptions must be removed |
| Diagnosis | Nsight Systems/Compute, Compute Sanitizer | Build logs, event profiling, vendor-dependent tools | Graphics debug layer and host/presentation tracing in a separately qualified setup |
| Graphics bridge | Register/map resources or external memory and synchronization | D3D11 sharing extension and acquire/release | Direct compute-to-draw possible only for compatible host-supported resources |

The facilities are documented in the CUDA programming guide, OpenCL specification and Microsoft compute-stage documentation; none establish Max's ownership contract. [API05](17_SOURCE_LEDGER.md#api05) [API13](17_SOURCE_LEDGER.md#api13) [API14](17_SOURCE_LEDGER.md#api14) [API22](17_SOURCE_LEDGER.md#api22)

### Streams, queues, and bounded scheduling

**Proposed:** begin with one compute stream/queue and explicit events around upload, solve, compact readback, and reuse. More queues are useful only after a trace identifies overlap that can actually occur. Ordering independent guides across queues does not remove parent/child dependencies or reserve graphics capacity. Device-wide synchronization after every stage would erase useful overlap; withholding every dependency would produce races.

Bucket work by chain length and contact complexity. A thread per whole plant can leave most lanes idle when plant sizes differ. A warp/subgroup per short guide or workgroup per bounded guide bundle is a testable starting point. Parent-depth barriers and contact refresh are algorithmic costs shared by all APIs. Tile oversized jobs and impose a maximum dispatch work count so cancellation and superseded requests can be observed between submissions. A Windows timeout is not a cancellation interface.

CUDA graphs encode dependencies and reduce repeated host submission work. They do not make collision traversal regular, remove convergence work, or guarantee speedups for a tiny drag. For a prototype, capture a fixed upper-bound iteration schedule with completed guides masked out, or use a small library of size buckets; measure wasted work and graph-update cost. [API13](17_SOURCE_LEDGER.md#api13)

The base OpenCL command-buffer extension is now **Ratified 1.0.0, 9 September 2026**. Its page retains an older experimental-status paragraph, but the status field and version history explicitly mark the ratification. Mutable-dispatch and multi-device companion extensions must be evaluated separately; don't assume support from the base name. Base command buffers restrict the operations they record, so a complete upload/readback/solve cycle is not automatically one replayable command buffer. Query the actual device extension string, properties and entry points, and retain ordinary queue submissions. [API06](17_SOURCE_LEDGER.md#api06)

### Scans, sorting, and deterministic accumulation

Candidate pairs need counted, bounded allocation. Prefix sums over integer counts produce deterministic offsets; reject integer overflow before the scan. Stable keys such as `(source, plant ID, guide ID, span ID, collider ID, feature ID)` make input ordering repeatable. Contact arrays require overflow flags and capacity-aware fallback; truncating them can turn an incomplete query into a false clearance claim.

CUB exposes `DeviceScan`, `DeviceSelect`, `DeviceRadixSort`, and reductions. The inspected live `cub/cub/device/device_radix_sort.cuh` documents stable sorting, separate input/output ranges, a temporary-storage sizing query, and dispatch using the caller's stream. This is useful reusable plumbing, not a vegetation solver. The live source also treats NaN sort keys by representation; reject non-finite geometry instead of treating a successful sort as data validation. The inspected live file was **not established to equal the proposed release pin**. [API11](17_SOURCE_LEDGER.md#api11) [API12](17_SOURCE_LEDGER.md#api12)

**Proposed:** reserve scan/sort scratch per size bucket outside pointer handling; measure the actual queried byte requirement. Use a fixed reduction tree for residuals and deterministic segmented accumulation where required. Floating-point atomics can make a sum depend on execution order; stable IDs alone do not fix that. Test repeated runs and reordered work lists, and separately compare their mathematical residuals. OpenCL and HLSL versions need equally explicit reduction/order policies. An API-neutral CPU sort can be the first sparse-case baseline; don't move sorting to the GPU when data is already small and CPU-resident without measurement.

## Precision and reproducibility

Floating-point addition is not associative, and fused multiply-add rounds differently from a separate multiply and add. CPU and GPU outputs can differ while satisfying the same constraints. NVIDIA's numerical guidance describes these effects; it does not provide Cyrus-specific acceptable penetration or strain thresholds. [API15](17_SOURCE_LEDGER.md#api15)

Use three named policies in the experiment: strict FP32 local geometry; mixed precision with FP64 transform/rebase and qualified difficult predicates; CPU FP64 reference. Do not silently change root tolerances to improve GPU success. CUDA `--use_fast_math` enables flush-to-zero and approximate division/square-root policies and affects contraction settings; compare these separately from the initial correctness run. Record OpenCL `-cl-fast-relaxed-math`, contraction and denormal flags explicitly instead of calling both builds simply “optimized.” [API03](17_SOURCE_LEDGER.md#api03)

**Proposed:** compute plant/collider relative transforms in host FP64, then transfer local coordinates only after their quantization error is below a fraction of the contact tolerance. Preserve high precision host transforms for final audit. Narrow gaps, near-parallel features, zero-length spans, invalid quaternions and large-coordinate subtraction require a declared error/ambiguity path. A small FP32 error must not change an unknown solid occupancy result into “outside.” CPU or higher-precision refinement is a valid result path if measured and reported.

Consumer, workstation and datacenter labels do not specify an interchangeable FP64 rate, cache, memory bandwidth, or power budget. Identify the exact device and kernel instruction mix. Tensor throughput and marketing FP32 rates do not predict branch-heavy BVH traversal or constrained contact fitting. No Tensor Core dependency is proposed. Hardware feature and memory checks belong in [09](09_MEMORY_PRECISION_AND_HARDWARE.md).

## Graphics interoperability: three different bridges

### 1. CUDA graphics registration

The CUDA runtime provides `cudaD3D11GetDevice`, `cudaD3D11GetDevices`, and `cudaGraphicsD3D11RegisterResource`. Registration retains the resource and can be expensive; reuse registrations across updates rather than register per drag. Supported resource/format restrictions apply, including primary render-target and depth/stencil restrictions. Compute accesses a mapped resource; graphics must not concurrently access it while mapped. [API18](17_SOURCE_LEDGER.md#api18)

**Proposed Max proof:** obtain the device/resource only through the documented public SDK path, identify the actual adapter, inspect the resource descriptor, register once, map/write/unmap under a supported ownership boundary, draw, resize, recreate the graphics device, and destroy. Passing a standalone sample only establishes the API mechanics. A raw pointer returned by an SDK interface does not establish permission to mutate every resource or synchronize an arbitrary context.

### 2. CUDA external memory and synchronization

Current CUDA documentation describes graphics external-resource interoperability and refers readers to the CUDA 12.9 guide for D3D11 specifics. This is an explicit historical detail source, not a claim the current guide contains a new Max-specific D3D11 contract. [API17](17_SOURCE_LEDGER.md#api17)

The archived D3D11 path matches DXGI adapter LUID to CUDA device LUID, imports suitably shared resources, and describes NT/KMT handle ownership and dedicated-allocation flags. External fences/keyed mutexes provide synchronization where the corresponding resources and APIs exist. Map sizes/offsets must agree with the original resource. Existing buffers lacking required creation flags cannot be made shareable by merely importing a pointer. [API19](17_SOURCE_LEDGER.md#api19)

**Proposed choice:** prefer the least complicated supported bridge. Do not adopt external handles merely because they sound more asynchronous. Prove that Max permits creating/binding the shareable buffer and that graphics/compute have compatible wait/signal ownership. Bind lifetime to a graphics-device generation; retire only after both users finish. Keep compute on the same adapter for the first prototype.

### 3. OpenCL D3D11 sharing

The ratified `cl_khr_d3d11_sharing` extension supplies device discovery from a D3D11 device, creation of OpenCL objects from buffers/textures, and acquire/release operations. Query extension availability and obtain the implementation's entry points. A context created for the wrong GPU is not repaired by matching device marketing names. [API20](17_SOURCE_LEDGER.md#api20)

With the default false `CL_CONTEXT_INTEROP_USER_SYNC` property, documented acquire behavior orders earlier D3D commands before subsequent OpenCL access. Explicit user synchronization changes the application's obligations. Release and draw ordering still require the specified completion relationship. Do not describe this API as unconditional zero-copy or cross-adapter sharing. [API21](17_SOURCE_LEDGER.md#api21)

OpenCL UUID/LUID queries are available under documented versions/extensions; if LUID validity is false, don't use the returned bytes as a valid identity. Prefer the D3D-specific device query for this bridge. An Intel/AMD display GPU plus a separate NVIDIA compute device, multiple NVIDIA cards, Optimus selection, remote sessions, and graphics-device recreation all require tests. A monitor does not uniquely identify the active compute adapter. [API05](17_SOURCE_LEDGER.md#api05)

### When sharing fails

Return compact changed guide poses, visibility masks, status and residuals to owned CPU memory. Validate and upload through the existing supported Max path. Alternatively retain CPU fitting and perform deformation in the existing shader path. Measure these paths before rejecting GPU computation: compact pose transfer can be much smaller than downloading every deformed vertex, but publication, CPU validation and synchronization can still dominate. The costs scale with changed guide nodes and visible output, not simply with total scatter count.

D3D11 compute avoids a cross-API registration step only if the host exposes the necessary device/context and resources support appropriate UAV bindings. `CSSetUnorderedAccessViews` is a public D3D11 API, not proof that Max's retained vertex-buffer handles were created with these flags. HLSL vertex deformation instead gathers completed poses while drawing and does not run an iterative collision solve. [API22](17_SOURCE_LEDGER.md#api22) [API23](17_SOURCE_LEDGER.md#api23)

## Tooling and what to measure

Nsight Systems can correlate CUDA activity with CPU ranges; annotate capture, neighborhood gathering, solve, validation, publish and draw request with stable update IDs. Nsight Compute provides kernel-level metrics and may replay kernels, so its instrumented run is not the drag-latency result. Compute Sanitizer supplies memory, initialization, synchronization and shared-memory race checks; none proves collision completeness. [API36](17_SOURCE_LEDGER.md#api36) [API37](17_SOURCE_LEDGER.md#api37) [API38](17_SOURCE_LEDGER.md#api38)

OpenCL event profiling exposes queued/submitted/start/end timestamps when profiling is enabled and the event has completed. Record timer resolution and separate queued delay from execution. Do not assume Nsight Systems provides equivalent OpenCL kernel profiling merely because the GPU is NVIDIA. Use available vendor tooling and the same external host/presentation instrumentation. [API39](17_SOURCE_LEDGER.md#api39)

**Proposed benchmark procedure:** warm context/program/pools separately from steady state; use the same active buffers and correctness audits; alternate API run order; log thermals/power policy and background graphics/render load; collect p50/p95/p99 and failures. Compare with the viewport busy as well as an isolated device. Record cold module load/JIT and graph creation. Driver/compiler changes invalidate performance qualification even when numerical tests still pass. See [10](10_BENCHMARK_AND_VALIDATION_PLAN.md).

## Conditional API decision and falsifiers

The weighted architecture matrix is in [01](01_EXECUTIVE_DECISION.md). For the API decision, these are the consequential sensitivities rather than claimed performance scores:

| Condition established by local evidence | Decision effect |
|---|---|
| Sparse updates already spend most time in capture/copy/publication | Prefer CPU work reduction and supported shader deformation; compute solver cannot remove that serial cost |
| Many guides dominate, CUDA toolchain and same-adapter sharing pass | CUDA is the first compute implementation; reuse CUB and vendor diagnosis |
| Sharing fails, compact readback still meets the complete target | CUDA/OpenCL remain viable with readback; no zero-copy claim is needed |
| Sharing fails and validation/readback erase the gain | Stop the solver integration; retain CPU fit plus GPU deformation |
| Cross-vendor deployment is a funded requirement and OpenCL features pass | Increase portability weight; qualify OpenCL per vendor/device/driver rather than assume one binary recipe |
| D3D11 compute is supported in Max while external interop is not | Increase HLSL compute's integration advantage; include primitive-maintenance cost |
| Matched OpenCL implementation has equal correctness and better total cost/latency | Reverse the first CUDA preference |
| FP64 or conservative refinement dominates either GPU path | Optimize predicate design and locality, or retain CPU exact checks; don't buy a GPU based on FP32 advertising |

There is no measured active-guide crossover yet. Fit an empirical model using active nodes, contact pairs, iterations and bytes—not total plants alone—and choose the lowest end-to-end time only among paths meeting the same acceptance criteria. Use hysteresis to prevent API selection oscillating near the measured crossover. Keep this automatic policy out of the main artist UI.
