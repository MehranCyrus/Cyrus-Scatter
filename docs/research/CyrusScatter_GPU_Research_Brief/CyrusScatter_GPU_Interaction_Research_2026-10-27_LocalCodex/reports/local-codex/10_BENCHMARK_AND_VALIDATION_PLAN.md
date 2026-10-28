# Executed probes and the product benchmark plan

## Executed experiment A — matched deformation surrogate

**E, 27 October 2026:** Windows 11 x64, Ryzen 5 5600X, RTX 3090, driver 617.42. MSVC host code, CUDA/NVRTC 12.1, and NVIDIA OpenCL on the same named GPU. [Source](prototype/deformation_probe.cpp), [results](prototype/deformation_results.json), [exact build command and source hash](prototype/deformation_execution.json).

The operation shares 4,096 rest vertices and bindings, with 512 pose nodes per instance. Each output gathers two quaternion/translation pairs, performs hemisphere-corrected normalized interpolation, rotates the position and adds translation. CUDA and OpenCL use aligned records, workgroup size 256, strict divide/sqrt and contraction-disabled policy. CPU scalar and up to six per-iteration `std::thread` workers evaluate the same formula. A separate double evaluator checks every output vertex and rejects nonfinite/error above 5e-6 local units.

Each case uses three warmups and 20 samples. The table reports the **latest captured run's p50 milliseconds**, not a best-of-run selection:

| Output vertices | Instances | CPU 1 | CPU up to 6 | CUDA device | OpenCL device | CUDA completed wall | OpenCL completed wall |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 0.0909 | 0.0909 | 0.00512 | 0.00512 | 0.0420 | 0.0252 |
| 65,536 | 16 | 1.5256 | 0.7644 | 0.01536 | 0.008064 | 0.0246 | 0.0273 |
| 1,048,576 | 256 | 20.3405 | 5.6409 | 0.045056 | 0.040960 | 0.0646 | 0.0635 |
| 4,194,304 | 1,024 | 81.6139 | 23.1896 | 0.134144 | 0.138240 | 0.1517 | 0.1652 |

Device times use CUDA events / OpenCL profiling events. Completed wall includes host enqueue and waiting for that kernel. Static upload and JIT are outside these warm-kernel windows. CPU parallel timing includes creating/joining its worker threads; this is not an optimized persistent CPU pool or a benchmark of the existing Cyrus native deformation code.

The second timing window uploads all pose data from pageable host memory, runs the kernel, and reads the complete output back:

| Vertices | Pose bytes uploaded | Position bytes read back | CUDA round trip p50 ms | OpenCL round trip p50 ms |
|---:|---:|---:|---:|---:|
| 4,096 | 16,384 | 65,536 | 0.1270 | 0.2344 |
| 65,536 | 262,144 | 1,048,576 | 0.2831 | 0.2503 |
| 1,048,576 | 4,194,304 | 16,777,216 | 2.9257 | 3.1801 |
| 4,194,304 | 16,777,216 | 67,108,864 | 12.8788 | 12.8412 |

At the largest case, about 0.14 ms of device arithmetic becomes about 12.9 ms for this transfer-inclusive batch. This supports avoiding full vertex copyback during preview. It does **not** measure the cost of compact pose readback, pinned/asynchronous transfers, drawing, or Max publication. The smallest transfer-inclusive GPU case is slower than the single-thread CPU operation here; dispatch/transfer thresholds matter.

Maximum absolute position error across the final four cases was below 1.4e-8 local units for each backend. That verifies this small-coordinate formula only. Normals, rest-frame spherical interpolation, attachment hierarchy, collisions and final mesh validity are absent.

NVRTC compilation measured 128.5789 ms and OpenCL build 7.9091 ms in this run. These are individual compile calls; driver caching and CUDA module/PTX compilation are not fully represented. They do not establish cold first-use latency or a universal JIT comparison.

### Methodological limits

- Fixed execution order: CPU, then CUDA, then OpenCL; desktop load/clocks were not isolated or locked. Run-to-run variability is visible even in small cases.
- Twenty samples are sufficient for a feasibility probe, not reliable tail qualification. Reported p99 is effectively the maximum observation. Raw per-iteration samples were not retained; quantiles/counts and source are included.
- Synthetic regular bindings and Z-axis rotation data underrepresent general branch/leaf workloads. No triangle adjacency, collision divergence, normal generation or transparency draw cost is included.
- CUDA/OpenCL compiler generations differ; identical math requests do not guarantee identical instructions. CPU is neither SIMD-tuned nor a production pool comparator.
- Matching by device name is adequate on this one-GPU workstation; multi-GPU qualification needs UUID/LUID/adapter identity.
- Earlier layout experiments demonstrated sensitivity to alignment/inlining. The final matched source is the comparison artifact; preliminary outcomes are not product speed claims.

## Executed experiment B — owned D3D11 resource sharing

[Source](prototype/interop_probe.cpp), [result](prototype/interop_results.json), [build identity](prototype/interop_execution.json).

An owned feature-level-11.0 device on a CUDA-matched DXGI adapter created a 16 KiB buffer. CUDA wrote 1,024 float4 values via register/map/unmap. OpenCL wrote a separate buffer through `cl_nv_d3d11_sharing` acquire/release. D3D11 staging reads matched every expected value. **Both passed.** This is functional platform evidence; there are no interoperability latency or Max presentation measurements.

## Not executed in this research

No new Max host test, actual GPU guide solver, renderer/Bake/export test, multi-vendor run, large-scene GPU test, cancellation/device-loss campaign, or CPU-vs-GPU contact-quality benchmark was executed. Current product receipts are historical and separate from these probes.

## Product measurement protocol — P

Instrument stage boundaries with stable request/source/layout IDs and timestamp units. Record CPU wall time separately from accumulated worker time and GPU event duration. Correlate a published draw generation with the frame that actually presents it; a fast function return does not prove a visible update. Nsight Systems distinguishes API, kernel and memory-operation timelines, which is useful for exposing transfer and synchronization gaps. [NVIDIA profiler documentation](https://docs.nvidia.com/nsight-systems/UserGuide/index.html).

For each fixture collect at least 1,000 drag updates after warmup across three sessions, plus cold startup/preparation. Preserve individual samples, tool/driver versions, input paths/seeds, median/p95/p99/max, missed/retained/stale counts, queue age and memory peaks. Randomize/interleave backend order where practical. Keep quality settings, preview percentage, draw mode, camera, shader/materials and accepted placements identical.

| Fixture axis | Required cases |
|---|---|
| Resident N versus active K | Small N/K; large N with K=0/1/10; dense K=100/1,000+ within admission |
| Source complexity | Thin blades, broad fern leaves, folded grass, branched flower, bush, tree trunk/fixed decoration |
| Collider complexity | Sphere, capsule, rotated box, compound root proxy, convex stone, concave closed mesh, wall/large slab |
| Input | Slow drag, rapid drag, reversal, teleport, scale/rotation edits, many independent stones |
| Visibility | All onscreen, mostly offscreen, several viewports, Wireframe/Mesh/Textured mesh |
| Quality | No contact, light contact, root infeasibility, broad-leaf surface refinement, 100% preview |
| Lifecycle | Undo/Redo, reset/open, delete while pending, backend failure and CPU fallback |
| Hardware | Current 3090; smaller VRAM NVIDIA; hybrid laptop; AMD/Intel if claiming OpenCL portability |

Separate measurements for K=0 navigation, collider movement, source re-preparation and first buffer residency. Include a case with many previously retained poses but few currently changed guides to expose successor-map copying and retirement overhead.

## Proposed acceptance thresholds

Targets require confirmation against measured baselines, not marketing promises:

- No correctness regression under independent geometry validation; all admitted relevant guides remain represented.
- At least 25% median edit-to-visible improvement in the chosen dominant-stage fixture; small-case p95 regression below 10% unless an explicit automatic CPU threshold avoids it.
- Reference interactive goals: p95 below 33 ms and, for a more demanding tier, below 16.7 ms on specified fixtures/hardware. These are goals, not achieved frame rates.
- Unchanged navigation must not re-fit or upload unchanged source/pose buffers.
- Resource admission accounts peak staging and retained readers; failures preserve a coherent result and permit recovery.
- Final mouse release produces the exact requested revision; no pending starvation, stale-owner publication or silent geometry deletion.

Do not divide isolated kernel time into one second and call that viewport FPS. Report each stage and the actual presented result separately.
