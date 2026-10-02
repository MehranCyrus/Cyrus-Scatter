# 06 — GPU and OpenCL feasibility plan

**Decision:** include a real OpenCL experiment after a measured CPU baseline and improvement pass. No GPU speedup or device compatibility is currently demonstrated. CPU operation remains available without a compute runtime.

**October 1 decision:** the first measured improvements are native source processing, boundary preparation, bounded CPU queries and redraw batching. OpenCL/CUDA compute is not enabled in 0.60. Measure the remaining interactive delay before choosing a kernel: supported Max 2027 viewport instancing is now a concrete next investigation, while GPU compute must still earn its transfer-inclusive benefit. See the [implementation report](../Performance_Implementation_2026-10-01.md).

## Why GPU details matter

A GPU path needs supported device features, adequate available memory, and a driver/runtime that can execute the chosen kernel. Kernel execution can be fast while data conversion, transfers, synchronization, and host drawing still make the complete operation slower. A GPU also shares resources with Max's viewport and possibly the renderer.

The product does not need to require a particular GPU brand. A successful result on the locally detected RTX 3090 would qualify that tested configuration only; it would not establish behavior on AMD, Intel, older NVIDIA cards, or laptops.

## Backend decision

| Option | Proposed role |
|---|---|
| Optimized CPU + bounded threading | Required reference and universal execution path within the supported CPU/host requirements |
| OpenCL | First optional compute prototype, selected to investigate more than one GPU vendor |
| CUDA | Separate NVIDIA-only experiment only if measured OpenCL limitations justify the extra backend; not a product requirement |
| Direct3D compute / Max display integration | Separate viewport project if draw submission dominates; investigate supported per-version Max display APIs before choosing an implementation |

Do not build several compute backends before one earns its maintenance cost. OpenCL compute alone does not turn the existing GraphicsWindow triangle loop into GPU instancing.

## G01 — Device probe and optional runtime

Keep the main CPU plugin loadable when no OpenCL loader or platform exists. Use an optional module or guarded dynamic loading with deliberate DLL search rules; do not introduce an unconditional startup import of OpenCL. Record load/probe errors and use CPU.

The prototype should use an OpenCL 1.2-compatible API/kernel subset where practical. Probe actual platform/device/compiler capabilities, limits and extensions; do not infer them from the newest published standard. Report device/vendor, driver, runtime/OpenCL C version, global and maximum-allocation memory, workgroup limits, and required numeric features. Feature and memory queries are specified by Khronos. [OpenCL API](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html)

If a kernel requires doubles, verify FP64 support explicitly. A GPU version string alone is insufficient. Three-component OpenCL vector types have four-component size/alignment; use explicit scalar arrays or padded structs with layout assertions and round-trip tests. [OpenCL C](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_C.html)

Start with a diagnostic command that only probes and reports. No device purchase or driver upgrade is a prerequisite for the CPU milestones.

## G02 — First kernel: live point-preview transforms

Prefer the independent transform stage of `aminScatterBuildPreview`, provided profiling shows enough work remains after CPU optimization. If it is too small to amortize GPU costs, record that result and select a measured independent boundary-query workload instead. Selection of a replacement kernel is a documented decision, not an automatic expansion of scope.

1. Keep scene extraction, MAXScript validation, sample selection and group offset calculation on CPU.
2. Upload immutable source sample arrays, transforms, source IDs and selected flattened indices in explicit layouts.
3. One work item transforms one selected point into a predetermined output slot.
4. Download results, restore the exact per-source stable sequence, and construct `AminPointCache` on the host thread.
5. Draw through the existing path. Measure this unchanged cost alongside total update time.

Use explicit matrix convention tests: translation, rotation, nonuniform scale, mirrored transforms and combinations. Preserve budget-selected points and group ordering exactly. A display-only float tolerance may be introduced only with a defined world/screen error bound and no effect on picking, placements, render data or CS Edit. Reject large-coordinate cases that exceed that bound and use CPU.

Baseline sizes include the actual point-preview cap of 500,000, not an imagined unlimited stream. Compare uncached/cached uploads and input changes. Do not invent GPU residency benefits when current data must return to CPU every update.

## Optional second candidate

If profiles justify it, prototype many independent boundary distance queries over prepared segment data. Keep side/classification and density decisions on the CPU initially. CPU rechecking of ambiguous threshold cases may protect correctness but its total cost must be measured. FP64 availability does not by itself guarantee the CPU's floating-point results or throughput.

Scatter random sampling, ordered collision/final acceptance, and global Analyzer spacing are excluded from the first GPU milestone because their current sequencing is part of scene compatibility.

## Correct sampling semantics if researched later

The research report's GPU sampler is conceptual and differs from current behavior. A compatibility implementation must use the same random draws and cumulative precision, select the first CDF entry **greater than** the target, then map through filtered original triangle indices. A binary search would advance `lo` when `cdf[mid] <= target`, not when it is merely less. Guard empty data and end conditions consistently with the CPU. Preserve barycentric sqrt and arithmetic behavior.

Even these corrections do not prove equal output across CPU/GPU arithmetic. Exact placement fixtures and CS Edit checks remain mandatory. Keep this out of the initial GPU build.

## G03 — Resource and failure policy

- Use overflow-checked byte calculations before allocation. Respect both per-buffer and total budget limits. Begin with a configurable **512 MiB plugin GPU-buffer budget** for the experiment; this is an engineering cap, not a promised VRAM minimum or an estimate of free memory.
- Retain renderer/viewport headroom. OpenCL total memory is not a reliable measurement of currently free VRAM. Bound cached generations, include staging copies, and evict old data before growing caches.
- Use bounded dispatch chunks, validated buffer ranges and explicit completion before publishing. A driver hang/device reset cannot be promised to recover safely inside the Max process; validate kernels in the standalone harness first and test host failure behavior.
- On recoverable probe/build/allocation/dispatch errors, release owned resources, record the reason and recompute on CPU. Avoid retrying every redraw; disable the failing backend for the session until explicitly retried.
- Key a program cache by device, driver, kernel source hash, options and layout/schema version. A cache hit never replaces capability checks.
- No partially computed output enters the scene. Reset/close/unload joins outstanding work before releasing native buffers.

## Experiment matrix and gate

Compare serial optimized CPU, threaded CPU, and OpenCL under the same scene/backend-independent settings. Test small/medium/maximum preview workloads, cold driver/program startup, warm execution, changed/unchanged source data, integrated/discrete devices when available, and active renderer load.

Record host preparation, upload, kernel, download, regroup/publication and draw separately, plus total elapsed time and peak host/device memory. Wall-clock total includes synchronization; device event timing is supplementary.

Promote only when correctness passes and the full nominated operation improves by the [02](02_Baseline_and_Benchmarks.md) threshold against **optimized threaded CPU** on a documented workload range. Require safe CPU fallback and no unacceptable p95, memory or renderer-contention regression. Tune the crossover by measured size; retain CPU below it.

A cross-vendor claim requires actual tested NVIDIA, AMD and Intel configurations for the features claimed. Until that evidence exists, label GPU execution experimental or qualify only named tested configurations. If the prototype loses, keep the result, ship CPU gains, and stop further GPU expansion until another measured workload justifies it.
