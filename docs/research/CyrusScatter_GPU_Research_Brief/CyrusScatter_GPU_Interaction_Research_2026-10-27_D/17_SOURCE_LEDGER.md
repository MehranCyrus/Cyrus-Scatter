<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 17 — Primary-source ledger

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed below.
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Method

Sources were selected from supplied project files, official vendor/specification documentation, original papers and public source repositories. Dates and versions are recorded where the source exposes them. “Inspected” means the public text or source path was read; it does not mean the code was compiled or executed. Legal notes identify public license terms for engineering review and are not legal conclusions.

## Supplied project sources

| ID | Source / version | Useful evidence | Limitations / confidence |
|---|---|---|---|
| S01 | Supplied `BRIEF_METADATA.json`, prepared 27 Oct 2026 | **[P]** baseline `0.87.4.3`, capability 11, schema 63, Max 2027/Windows x64, no delivered GPU backend/benchmark | coordinator-provided, hash verified; private repo not inspected — high confidence as provided context |
| S02 | Supplied `CURRENT_SYSTEM_CONTEXT.md`, prepared 27 Oct 2026 | **[P][M]** data flow, CPU/host boundaries, geometry semantics, admissions, viewport path and narrow measurements | not independently verified; measurements not reproduced — high confidence as supplied context, no external generalization |
| S03 | Supplied `RESEARCH_PROMPT.md` | decision questions, evidence discipline and required package | assignment, not technical evidence |

## Autodesk 3ds Max 2027 public SDK

| ID | Source | Date/version and inspected scope | Useful finding | Limitation |
|---|---|---|---|---|
| S04 | [Autodesk `ICustomRenderItem`](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html) | Max 2027 API reference; realization/display/hit-test lifecycle | retained custom item can realize resources and has separate display/hit-test responsibilities | no proof of compute interop or renderer geometry |
| S05 | [Autodesk `IVirtualDevice`](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_virtual_device.html) | Max 2027 API reference; streams, draw/instancing, outputs/UAV binding | public retained drawing and graphics handles; useful for HLSL deformation proof | inspected page did not expose native D3D device/resource or compute dispatch; installed SDK probe required |
| S06 | [Autodesk `HLSLMaterialHandle`](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_h_l_s_l_material_handle.html) | Max 2027 API reference; shader source/file and typed/buffer parameters | possible public route for pose buffers and custom vertex deformation | exact structured-buffer layout/capacity/lifetime must be demonstrated locally |
| S07 | [Autodesk `DrawContext`](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_draw_context.html) | Max 2027 API reference; `GetVirtualDevice` and lifecycle note | confirms per-draw virtual-device access and warning not to retain it | not a native device ownership contract |
| S08 | [Autodesk Developer Blog — What’s New in 3ds Max 2027](https://blog.autodesk.io/whats-new-in-3ds-max-2027/) | 2026 host/SDK release overview | version context and local SDK follow-up lead | overview, not detailed interop contract |

## NVIDIA CUDA

| ID | Source | Date/version / location | Useful finding | Limitation / license |
|---|---|---|---|---|
| S09 | [CUDA Installation Guide for Microsoft Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html) | CUDA 13.3; compiler table | VS 2026/MSVC 195x and VS 2022/MSVC 193x x64 are listed with C++14/17/20 | exact supplied MSVC 14.38/Max package still needs local compile/load test |
| S10 | [CUDA Programming Guide — API Interoperability](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html) | current guide, accessed 27 Oct 2026; D3D11/12 graphics/external resources | registration/map/use/unmap; resource must not be concurrently accessed while mapped; registering is costly | standalone API capability does not prove Max resource exposure |
| S11 | [CUDA Programming Guide — CUDA Graphs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/cuda-graphs.html) | current guide; graph definition/instantiation/relaunch | repeated graph launch can reduce CPU launch setup, especially short kernels | optimization after stable workflow; graph update constraints must be measured |
| S12 | [CUDA C++ Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html) | current NVIDIA guidance | profile-first/APOD, memory-transfer and occupancy methodology | generic guidance, not Cyrus performance evidence |
| S13 | [CUDA Toolkit EULA](https://docs.nvidia.com/cuda/eula/index.html) | last updated 26 Jan 2026 | distribution only for identified distributables under stated conditions; dev tools not automatically distributable | release/legal review required; no legal conclusion here |
| S14 | [NVIDIA CUDA Samples](https://github.com/NVIDIA/cuda-samples), release `v13.4` | release 9 Sep 2026; inspected commit `5443602d89ed99aede2e4b7bf329daddeadb320e` | `simpleD3D11`, `simpleD3D11Texture`, graphs and primitive examples | samples create/own native devices/resources; not Max proof; BSD-style sample headers |
| S15 | [CUDA GPUs / compute capability](https://developer.nvidia.com/cuda-gpus) | current public architecture table | derive minimum architecture from selected feature/toolkit, not recency alone | product list changes; pin support matrix |
| S16 | [GeForce RTX 5090 specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/) | Blackwell consumer reference, 32 GB class | representative high-VRAM test class | not a product recommendation or performance proof |
| S17 | [GeForce RTX 5080 specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5080/) | Blackwell consumer reference, 16 GB class | representative lower supported-VRAM test class | not a minimum requirement |
| S18 | [Nsight Systems documentation](https://docs.nvidia.com/nsight-systems/) | current official profiler docs | host/GPU timeline, CUDA/graphics tracing lead | must correlate with Max input/presentation and avoid profiler distortion |
| S19 | [Nsight Compute documentation](https://docs.nvidia.com/nsight-compute/) | current official profiler docs | kernel-level metrics and source analysis | kernel metrics are not complete drag latency |

## Khronos OpenCL

| ID | Source | Date/version / location | Useful finding | Limitation / license |
|---|---|---|---|---|
| S20 | [OpenCL Registry](https://registry.khronos.org/OpenCL/) | latest listed OpenCL 3.1; API/C/SPIR-V specs dated 22 May 2026 | current standard/version map and official extensions | implementation features remain device/runtime dependent |
| S21 | [OpenCL Unified API Specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html) | v3.1.1, 22 May 2026, commit `9f68efb5d80e77a4e437c5b8ee67d581666d044c` | normative API, optional features, D3D11 sharing, command buffers | specification capability is not a vendor implementation claim |
| S22 | [OpenCL D3D11 sharing section](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html#cl_khr_d3d11_sharing) | `cl_khr_d3d11_sharing`; `ID3D11Device*`, `ID3D11Buffer*`, acquire/release | same D3D device required; use while unacquired is undefined; explicit synchronization | optional extension and still requires Max native objects |
| S23 | [OpenCL command-buffer section](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html#command-buffers) | `cl_khr_command_buffer` and mutable-dispatch metadata | repeated recorded commands and optional mutation can reduce host overhead | capability bits/extensions must be queried; not universal |
| S24 | [Khronos OpenCL SDK](https://github.com/KhronosGroup/OpenCL-SDK), tag `v2026.05.29` | tag commit `e26922bdf54eaa9fcc31fe1f91d21b8d2bd6970f`; synchronized to 3.1.1 | pinned headers/loader/examples for matched harness | does not include vendor device runtime; Apache-2.0 |
| S25 | [OpenCL ICD Loader](https://github.com/KhronosGroup/OpenCL-ICD-Loader) | official Khronos repository | optional dynamic platform discovery and loader packaging lead | loader presence is not a platform/device; Apache-2.0 repository terms apply |

## Microsoft Direct3D / Windows

| ID | Source | Scope | Useful finding | Limitation |
|---|---|---|---|---|
| S26 | [`ID3D11DeviceContext::Dispatch`](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/nf-d3d11-id3d11devicecontext-dispatch) | D3D11 compute dispatch API | proves ordinary D3D11 contexts can dispatch compute | Max public API still must expose/support equivalent access |
| S27 | [`D3D11_BIND_FLAG`](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_bind_flag) | buffer/texture bind roles including UAV/SRV/vertex/index | resource creation flags matter for compute/draw use | host-owned resource flags are unresolved |
| S28 | [`IDXGIKeyedMutex`](https://learn.microsoft.com/en-us/windows/win32/api/dxgi/nn-dxgi-idxgikeyedmutex) | shared-resource synchronization | explicit keyed acquisition/release and timeout behavior | only relevant when resources expose required interface/flags |
| S29 | [Windows TDR overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/timeout-detection-and-recovery) | GPU timeout/device reset | long work can trigger recovery; device resources need recreation | exact system policies vary; do not tune registry as product solution |
| S30 | [`IDXGIAdapter::GetDesc` / adapter LUID](https://learn.microsoft.com/en-us/windows/win32/api/dxgi/nf-dxgi-idxgiadapter-getdesc) | adapter identity | same-adapter gating lead for multi-GPU interop | Max must expose compatible identity/path |
| S31 | [Microsoft PIX on Windows](https://devblogs.microsoft.com/pix/documentation/) | D3D frame/GPU analysis | graphics timing/resource investigation lead | attach/use inside Max must be qualified and may perturb behavior |
| S32 | [PresentMon](https://github.com/GameTechDev/PresentMon) | open-source presentation telemetry | possible presented-frame and latency correlation | integration/permissions/measurement methodology must be validated |

## Numerical methods and reusable implementations

| ID | Source | Date/version / location | Useful finding | Limitations / license |
|---|---|---|---|---|
| S33 | [XPBD: Position-Based Simulation of Compliant Constrained Dynamics](https://matthias-research.github.io/pages/publications/XPBD.pdf) | Macklin et al., 2016 | compliance and accumulated multipliers for constraint stiffness | not a complete vegetation/contact/output system |
| S34 | [Discrete Elastic Rods](https://www.cs.columbia.edu/cg/rods/) | Bergou et al., SIGGRAPH 2008 | centerline/material frames, bend/twist and parallel transport | more state/complexity; collision and Max delivery separate |
| S35 | [Position and Orientation Based Cosserat Rods](https://animation.rwth-aachen.de/publication/0550/) | Kugelstadt & Schömer, SCA 2016 | rod position/orientation constraint formulation | dynamic/reference method; first static product may not need full model |
| S36 | [Projective Dynamics](https://www.projectivedynamics.org/Projective_Dynamics/index.html) | Bouaziz et al., SIGGRAPH 2014 | local/global solver for many deformation constraints | changing contacts and factorization complexity |
| S37 | [Maximizing Parallelism in BVH Construction](https://research.nvidia.com/publication/2012-06_maximizing-parallelism-construction-bvhs-octrees-and-k-d-trees) | Karras, 2012 | LBVH parallel hierarchy construction | not automatically the best persistent Cyrus broad phase |
| S38 | [PositionBasedDynamics repository](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics) | MIT; inspected commit `10a70bc146a97873dc3c8fef372f5217e010542e` | `PositionBasedElasticRods`, Cosserat demo, SDF examples | broad dynamic library; not compiled here; no Max integration |
| S39 | [TressFX repository](https://github.com/GPUOpen-Effects/TressFX) | MIT; latest tag 4.1.0 (24 Jan 2020); inspected code commit `ba0bdacdfb964e38522fda812bf23169bc5fa603` | HLSL pass scheduling: velocity shock, local shape, length/wind/collision | older engine-owned D3D12/Vulkan hair system; not Max/static fitter |
| S40 | [NVIDIA Warp](https://github.com/NVIDIA/warp), release `v1.18.0` | 5 Oct 2026; inspected main commit snapshot and `warp/native/mesh.h` | rapid GPU/CPU kernel research; mesh/BVH queries and benchmarks | Python/JIT/runtime production decision; Apache-2.0; not compiled here |
| S41 | [Jolt Physics](https://github.com/jrouwe/JoltPhysics), pin `1b2e77e3c6c09709e5edc79dc208459b8ff32051` | source header reports 5.6.1; MIT | collision shapes, CPU rods and job architecture as comparison | current Cyrus request does not gain plant binding/output automatically; GPU hair separate/experimental |

## Source-confidence notes

- **High confidence:** normative specifications, official SDK docs and exact public source files/revisions.
- **Medium confidence:** official overview/product pages whose details require exact local hardware or SDK confirmation.
- **Provided-only:** private Cyrus facts and measurements; accurately transcribed but not independently verified.
- **No executed performance evidence:** no source in this ledger is used to claim a Cyrus speedup. Published third-party performance claims were not transferred to this workload.

## Research gaps turned into local probes

The public ledger did not resolve:

1. a supported native D3D resource/device accessor in Max 2027;
2. exact `SmartHandle` structured-buffer limits and update rules;
3. intended production renderer geometry/procedural contracts;
4. current Cyrus stage cost and workload distributions;
5. matched CUDA/OpenCL performance on target hardware;
6. exact toolkit/runtime/CRT installer combination for the matched Max package.

These are specified in [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md).
