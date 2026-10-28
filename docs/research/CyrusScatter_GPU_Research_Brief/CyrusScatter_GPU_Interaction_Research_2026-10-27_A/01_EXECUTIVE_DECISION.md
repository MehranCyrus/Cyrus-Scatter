# 01. Executive Decision

## 1. Core Architectural Recommendation

**[PROPOSED / UNVERIFIED — Conditional Recommendation]**

Do **not** begin by writing a monolithic GPU collision-and-constraint solver, and do **not** assume that 3ds Max 2027's public `MaxSDK::Graphics` API exposes raw `ID3D11Device` / `ID3D11Buffer` pointers suitable for zero-copy CUDA/OpenCL graphics interoperability.

Instead, adopt a **two-track, stage-gated hybrid architecture** that separates **viewport mesh deformation** from **contact/guide solving**:

1. **Immediate High-Value Track (Architecture 2 — CPU Guide Fit + Supported HLSL SM5 Vertex-Shader Pose-Pull Deformation):**
   - Keep spatial neighbourhood invalidation ($K$ affected instances out of $N$ total) and guide/contact fitting on the CPU initially, or consume compact guide poses from any backend.
   - Replace CPU unique-mesh vertex/normal deformation and multi-megabyte per-drag vertex buffer uploads with **shared-source instanced drawing** in `MaxSDK::Graphics`, where the existing Shader Model 5.0 vertex shader (`HLSLMaterialHandle`) pulls **compact active-guide segment transforms + visibility masks** from a dynamic GPU buffer/texture (`TextureHandle` or `VertexBufferHandle` locked via public `Lock`/`Unlock`).
   - **Why first:** In the supplied baseline (`CURRENT_SYSTEM_CONTEXT.md`), a single grass source has $G = 451$ guides ($Nn \approx 4\text{--}8$ nodes) but $V = 22{,}032$ vertices and $27{,}501$ triangles **[PROVIDED-FACT]**. Deforming and uploading $K = 500$ posed instances as unique meshes requires $500 \times 22{,}032 \times 32\text{ B} \approx 352.5\text{ MiB}$ of vertex data per drag step, whereas uploading compact posed guide nodes ($500 \times 451 \times 8 \times 16\text{ B} \approx 28.8\text{ MiB}$ worst case, and only $\sim 1.9\text{ MiB}$ when $30$ guides/plant are active) is **12× to 180× smaller** **[ANALYTICAL-ESTIMATE]** and uses **100% public, supported Max 2027 SDK interfaces** without requiring native D3D11 device extraction **[VERIFIED-PUBLIC]**.

2. **Scale-Up Compute Track (Architecture 3 — CPU Horizontal Neighbourhood Index + NVIDIA CUDA Quasistatic Guide/Surface Solver + Compact Pose Readback or Shared-Handle Interop):**
   - Once CPU profiling (Gate 1) confirms that native guide fitting + visible-surface refinement exceeds the interactive frame budget ($\ge 8\text{ ms}$ for 60 Hz or $\ge 16\text{ ms}$ for 30 Hz, typically when active candidate plants $K \ge 50\text{--}150$ or active fitted guides $M \ge 5{,}000$), offload **local-frame collider queries, root classification (`Inside solid` / `Under collider`), iterative Follow-The-Leader / XPBD guide fitting, and foliage-envelope surface refinement** to **NVIDIA CUDA** (with the existing multi-threaded C++ CPU solver retained as the mandatory, bit-compatible fallback for non-NVIDIA hardware and infeasible/recovery states).
   - **Why compact pose readback works even without D3D11 interop:** Because a posed plant is fully described by its hidden-root bitmask ($57\text{ bytes}$ for $G=451$) plus compact active guide nodes ($M \times Nn \times 16\text{ bytes}$), reading back even $M = 20{,}000$ active guides ($Nn = 8$) over PCIe 4.0 x16 pinned memory costs only $2.56\text{ MiB}$ ($\approx 0.12\text{ ms}$ transfer time) **[ANALYTICAL-ESTIMATE]**. Those compact poses then feed directly into Track 1's supported Max `Lock`/`Unlock` shader-deformation buffer—**eliminating Max D3D11 interop as a single point of failure**!

---

## 2. The Four Workload Populations Must Be Separated

Extrapolating from a single small fixture to "millions of plants on the GPU" is invalid. We define the four populations requested in `RESEARCH_PROMPT.md` §1 separately, with physical memory and bandwidth boundaries **[ANALYTICAL-ESTIMATE]**:

| Population | Definition ($N$ total, $K$ active plants, $G$ guides/plant, $V$ verts/plant) | Bottleneck Stage | Feasible Realtime Strategy (30–60 Hz drag) | Physically / Economically Impractical Regime |
|---|---|---|---|---|
| **Pop 1: Millions resident, small active neighbourhood** | $N = 10^6$ resident instances; $K = 1\text{--}50$ plants near collider; $M = 10\text{--}2{,}000$ active guides | Host snapshot copy / map cloning (`CURRENT_SYSTEM_CONTEXT.md` §CPU boundaries) & GPU launch latency, **not** arithmetic | **Incremental CPU spatial lookup + O(K) copy-on-write pose table + CPU solver (or CUDA with threshold bypass)** + Track 1 shader deformation | Cloning a 1M-entry `std::map`/`unordered_map` per pointer event or rebuilding full-scene GPU buffers on every drag |
| **Pop 2: Many thousands of affected guides/plants changing together** | $N = 10^4\text{--}10^6$; $K = 100\text{--}10{,}000$ active plants; $M = 10^4\text{--}5 \times 10^5$ active guides | Guide/surface collision queries ($P$ candidate pairs) + iterative constraint projection + vertex deformation if done on CPU | **Track 2 (CUDA 2-stage broadphase + warp/thread-per-guide solver)** + **Track 1 (HLSL SM5 vertex-shader deformation from compact pose buffer)** | Materializing $K = 10{,}000 \times 22{,}032$ unique CPU `Mesh` objects ($7.05\text{ GiB}$ of raw vertex buffers per drag frame) |
| **Pop 3: Millions of simple blades or vertices changing together** | $K_{\text{blades}} = 10^6\text{--}5 \times 10^6$ single-guide blades ($G=1, Nn=4, V=12$) or $10^7$ vertices deforming | Global memory bandwidth for pose storage + viewport triangle rasterization / overdraw | **CUDA thread-per-blade solver** + GPU instanced blade drawing ($10^6$ blades $\times 64\text{ B} = 64\text{ MiB}$ pose buffer) | CPU per-vertex deformation or CPU readback of $10^7$ deformed vertices ($320\text{ MiB/frame} \implies >15\text{ ms}$ PCIe stall) |
| **Pop 4: Millions of detailed plant clumps changing together** | $K = 10^6$ simultaneously active clumps, each with $G = 451$ guides ($4.51 \times 10^8$ active guides) and $V = 22{,}032$ vertices ($2.2 \times 10^{10}$ active vertices) | **VRAM capacity and memory bandwidth wall** | **Not physically feasible at full fidelity on any single workstation GPU.** Requires spatial culling, camera/distance LOD (guide-count decimation), or proxy footprints | Storing $4.51 \times 10^8$ active guide poses requires $\sim 57.7\text{ GiB}$ VRAM; deforming $2.2 \times 10^{10}$ vertices requires $\sim 705\text{ GiB}$ VRAM (exceeds 24 GB RTX 3090/4090 by **30×**) |

---

## 3. Summary Decision Matrix: Compute & Deformation APIs

Full justification and sensitivity analysis appear in [04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md). On the **same NVIDIA GPU** with matched algorithms, precision (`FP32` in local plant frame), and memory layout, raw kernel execution speed between CUDA, OpenCL, and D3D11 Compute (`cs_5_0`) is within **5–15%** because the hardware instructions (warp schedulers, SFUs, L1/shared memory) are identical **[VERIFIED-PUBLIC]**. The decisive differences are **integration friction in 3ds Max 2027, developer/profiling tooling, library maturity (CCCL/CUB, cuBQL), and multi-vendor reach**:

| Criterion (Weight) | Option A: Enhanced CPU + HLSL SM5 Vertex Deformation | Option B: NVIDIA CUDA Solver + HLSL SM5 Deformation (Recommended Scale-Up) | Option C: OpenCL 3.0 Solver + HLSL SM5 Deformation | Option D: D3D11 Compute (`cs_5_0`) Solver + HLSL SM5 Deformation |
|---|---:|---:|---:|---:|
| **Max 2027 Viewport Integration (25%)** | **5 / 5** (100% public `MaxSDK::Graphics`) | **4 / 5** (Via compact pinned readback to `TextureHandle`; 5/5 only if D3D11 shared handle verified) | **3 / 5** (`cl_khr_d3d11_sharing` requires raw `ID3D11Device*`; fallback is pinned readback) | **3 / 5** (Requires raw `ID3D11Device*` from Nitrous or separate D3D11 device + staging) |
| **Solver & BVH Implementation Risk (20%)** | **5 / 5** (Existing C++ code + SIMD/tasks) | **5 / 5** (C++20 kernels, CCCL `cub::DeviceSelect`/`RadixSort`, `cuBQL`) | **2.5 / 5** (C99/CL3.0 kernel strings, no native C++ templates with shared host types) | **2.5 / 5** (`cs_5_0` 32 KB `groupshared`, manual scan/sort, UAV bind restrictions) |
| **Debugging, Profiling & Sanitization (15%)** | **5 / 5** (VS 2022, VTune, Superluminal) | **5 / 5** (Nsight Compute, Nsight Systems, `compute-sanitizer`) | **1.5 / 5** (Nsight Compute does **not** profile OpenCL kernels **[VERIFIED-PUBLIC]**) | **3.5 / 5** (RenderDoc, Nsight Graphics, PIX) |
| **Scale-Up Throughput ($K \ge 500$ plants) (20%)** | **2 / 5** (6–16 core CPU saturates around $K=100\text{--}300$) | **5 / 5** (10,496 FP32 cores on RTX 3090; sub-2 ms for $K=1{,}000$) | **4.5 / 5** (Same GPU hardware; lacks CUB decoupled look-back primitives) | **4.5 / 5** (Same GPU hardware; `cs_5_0` atomic/barrier overhead) |
| **Toolchain & Distribution Simplicity (10%)** | **5 / 5** (Zero new DLLs) | **4 / 5** (`cudart_static.lib` or redistributable `cudart64_*.dll` + delay-load `nvcuda.dll`) | **4 / 5** (Links `OpenCL.dll` ICD; runtime string compile or PTX cache) | **5 / 5** (`d3d11.dll` + `d3dcompiler_47.dll` built into Windows) |
| **Hardware Vendor Reach (10%)** | **5 / 5** (All x64 CPUs) | **3 / 5** (NVIDIA only; CPU fallback covers AMD/Intel) | **4.5 / 5** (NVIDIA, AMD, Intel via ICD) | **5 / 5** (All D3D11 GPUs) |
| **Weighted Total (100%)** | **4.40 / 5.00** *(Best immediate baseline & fallback)* | **4.45 / 5.00** *(Best high-scale solver backend)* | **3.23 / 5.00** | **3.68 / 5.00** |

---

## 4. Explicit Falsifiers (What Would Reverse This Recommendation)

1. **Falsifier 1 (CPU Sufficiency after O(K) Snapshot Fix + Shader Deformation):**
   - If local profiling in **Gate 1** shows that replacing full-map pose copying (`CURRENT_SYSTEM_CONTEXT.md` §CPU boundaries) with incremental $O(K)$ delta updates and moving vertex deformation into the `MaxSDK::Graphics` HLSL vertex shader (**Gate 3**) brings p95 drag update time under **8.0 ms** for up to $K = 500$ complex plants on an 8–16 core workstation CPU, **stop before Gate 4**: a CUDA/OpenCL contact solver is unnecessary for current artist scenes.
2. **Falsifier 2 (Public Max 2027 SDK Exposes Native `ID3D11Device*` + UAV Handles Cleanly):**
   - If local inspection of the 3ds Max 2027 SDK headers (`maxsdk/include/Graphics/IVirtualDevice.h`, `IDevice.h`, `VertexBufferHandle.h` — see Probe P1 in [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md)) proves that plugins can safely obtain the Nitrous `ID3D11Device*` and bind `ID3D11UnorderedAccessView*` directly to custom render item buffers, **D3D11 Compute (`cs_5_0`)** rises from `3.68` to `4.55` for medium-complexity solvers because it runs on the **exact same D3D11 context** with zero inter-API synchronization and supports AMD/Intel GPUs natively.
3. **Falsifier 3 (Mandatory Cross-Vendor GPU Acceleration Without CPU Fallback):**
   - If product management requires identical 10,000-plant GPU solver acceleration on AMD Radeon PRO and Intel Arc GPUs in the first GPU release, **CUDA is disqualified as sole GPU backend**; choose **D3D11 Compute (`cs_5_0`)** (or OpenCL 3.0 if host-independent) instead.
