# Memory, precision, and hardware policy

**E:** local hardware inventory and standalone probes. **A:** storage arithmetic below. **P:** proposed capacity policy.

## Observed workstation

| Component | Observed |
|---|---|
| OS | Windows 11 Pro, build 26300, x64 |
| CPU | AMD Ryzen 5 5600X, 6 cores / 12 logical processors |
| GPU | NVIDIA GeForce RTX 3090, 24,576 MiB reported memory, compute capability 8.6 |
| NVIDIA driver | 617.42 |
| CUDA toolkits | 11.8 and 12.1 installed; probes explicitly selected 12.1 |
| Probe runtime/driver API | CUDA runtime 12010; driver API 13040 |
| OpenCL | Device API reports OpenCL 3.0 CUDA; kernels requested OpenCL C 1.2 |
| Host compiler | MSVC 19.38.33145, toolset directory 14.38.33130 |
| Windows SDK | 10.0.19041.0 |

This is one machine, not a minimum or recommended customer specification. Other GPUs, vendors, drivers and laptop adapter arrangements were not executed. A newer driver API version does not mean the experiment used the newest toolkit/compiler.

## Why dense million-clump state does not fit

Use the real baseline source counts: 22,032 vertices and 451 guides. Assume **8 nodes per guide**, **32 bytes per posed node**, **16 bytes per output position**, and **64 bytes per instance record**. The node count/record layouts are illustrative, not measurements of current C++ allocations. Decimal GB is used in this table; 1 GiB = 1,073,741,824 bytes.

| Allocation | Per instance | 1,000 active/resident instances | 1,000,000 instances |
|---|---:|---:|---:|
| Illustrative instance record | 64 B | 64 KB | 64 MB |
| Dense pose nodes | 115,456 B | 115.456 MB | 115.456 GB |
| Two dense pose generations | 230,912 B | 230.912 MB | 230.912 GB |
| Full output positions only | 352,512 B | 352.512 MB | 352.512 GB |
| 4-byte per-guide lookup table | 1,804 B | 1.804 MB | 1.804 GB |
| 451 root bits, packed separately per instance | 57 B | 57 KB | 57 MB |

Normals/tangents, visibility/index structures, BVHs, collider fields, allocator slack, upload staging, graphics copies, CPU retained generations, textures and renderers add further memory. Even 1,000 active full-geometry outputs are hundreds of MB. Two or three generations multiply that cost.

By contrast, six changed guides with eight 32-byte nodes need 1,536 bytes of node payload before lookup, masks and allocator overhead. This is why **N resident, K active and changed-guide count must be separate**, and why absent pose data should refer to shared rest geometry.

## SDF storage arithmetic

A dense 256³ field at 4 bytes/sample is 64 MiB; 512³ is 512 MiB; 1024³ is 4 GiB. Gradient vectors, mip levels, sign metadata and staging can multiply this. Do not allocate one field per scattered tree instance. Share collider-local fields and transforms. Sparse/narrow-band fields reduce some cases but add indexing and band validity rules; they do not eliminate worst-case admission.

## Precision policy

Keep scene/world transforms and capture in robust CPU precision. Move GPU arithmetic into source-local or rebased coordinates where plant extents are small. FP32 spacing near 1,000,000 metres is approximately 0.0625 m, already far larger than millimetre contact gaps; adding tiny corrections directly in those coordinates is unsuitable. The relevant magnitude is the working coordinate after rebasing, not only the overall scene size.

Proposed representation: CPU double world transform/origin; GPU float source-local data and float relative transforms; explicit metre conversions at upload; world-up transformed consistently. Rebase only at a revision boundary that invalidates dependent transforms/bounds. Never change origin while old buffers use another origin without tagging both generations.

Use error budgets for FP32 quantization, interpolation, SDF approximation and contact tolerances separately. A high FP32 arithmetic rate does not imply high FP64 rate on a consumer GPU; avoid promising that moving all double arithmetic to the device preserves throughput. Mixed precision is a testable design, not automatic correctness.

The local surrogate compares float CPU/CUDA/OpenCL output against a double implementation on small local coordinates. Its roughly 1e-8 absolute errors do not qualify large-coordinate collisions, branch constraints, SDF sign or long-iteration stability.

## Numerical determinism

Normalize quaternions and handle hemisphere/near-degenerate cases explicitly. Test FMA/fast-math modes against tolerances instead of assuming bitwise CPU/GPU identity. Deterministic ordering of stable IDs does not make floating-point reductions bit-identical across devices. Define separate goals: exact identity/visibility decisions where required, bounded geometric error, repeatability on a qualified backend, and reproducibility of final authored state.

The probes deliberately request strict division/sqrt and disable contraction for the compared operation. Shipping faster math modes require fresh quality measurements. Use wide host counters and checked allocation arithmetic; a 32-bit device index can still be acceptable inside a bounded batch with checked base offsets.

## Admission and sharing the GPU

Compute shares VRAM and execution resources with Nitrous, materials, the compositor and possibly GPU rendering. Available memory at startup is not a permanent reservation. Maintain configurable budgets with headroom, account peak simultaneous generations/staging, and handle allocation failure without partially publishing a scene.

Pinned host buffers can help transfer overlap, but excessive page-locked memory harms the system and is not free. The executed transfer experiment used pageable synchronous copies; it does not measure an optimized overlapped upload pipeline. Unified memory or oversubscription should not hide page faults and migration stalls in a claimed realtime mode.

## Proposed hardware tiers

Define tiers from measured fixtures: CPU reference, public-shader deformation capability, optional CUDA fitting, and fallback. Query feature/adapter support at runtime. Publish exact qualified GPU/driver/toolkit combinations after testing rather than selecting “any NVIDIA” now. Include 8–12 GiB cards and hybrid laptops in future qualification; the 24 GiB desktop result alone is insufficient.

If render and compute devices differ, prefer a compatible CPU/shader path or explicitly measured compact transfers. Never choose CUDA ordinal zero and assume it is the viewport GPU. The standalone sharing probe matched the DXGI adapter; production must match the actual Max device.
