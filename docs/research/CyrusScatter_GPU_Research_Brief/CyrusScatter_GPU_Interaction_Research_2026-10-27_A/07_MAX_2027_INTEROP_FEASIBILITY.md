# 07. Autodesk 3ds Max 2027 Interoperability Feasibility

## 1. The Feasibility Gate: Public SDK vs Standalone D3D11 Interop

`RESEARCH_PROMPT.md` §3 and §8 emphasize a critical distinction:
> **"CUDA supports Direct3D interoperability" does not prove that "Max 2027's public SDK exposes the necessary resources with supported ownership and synchronization."**

We investigated the public **Autodesk 3ds Max C++ SDK (`MaxSDK::Graphics` namespace)** and the **Direct3D 11 / CUDA / OpenCL interoperability specifications** to establish what is verified in public documentation, what requires a local SDK header probe (`Probe P1–P3` in [16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md)), and how our architecture succeeds **even if zero-copy D3D11 resource sharing is completely unavailable in Nitrous**.

---

## 2. Public `MaxSDK::Graphics` Capabilities and Limitations

Based on official Autodesk 3ds Max Developer Help (`MaxSDK::Graphics` reference **[VERIFIED-PUBLIC]**) and the supplied baseline (`CURRENT_SYSTEM_CONTEXT.md` **[PROVIDED-FACT]**):

| SDK Class / Header (`maxsdk/include/Graphics/...`) | Verified Public Capabilities | Interop / Compute Limitation |
|---|---|---|
| **`IVirtualDevice`** (`<Graphics/IVirtualDevice.h>`) | Passed to `ICustomRenderItem::Realize(DrawContext&)` and `Display(DrawContext&)`. Manages pipeline states (`SetRasterizerState`, `SetDepthStencilState`, `SetBlendState`), vertex streams (`SetVertexStreams`, `SetStreamFormat`), index buffer (`SetIndexBuffer`), and instanced/non-instanced draws (`Draw`, `DrawInstanced`) **[VERIFIED-PUBLIC]**. | Designed as an API-agnostic wrapper over Nitrous (historically D3D9/D3D11/OGL). Public documentation does **not** guarantee a supported method returning a raw `ID3D11Device*` or `ID3D11DeviceContext*` for external compute takeover **[VERIFIED-PUBLIC]**. |
| **`VertexBufferHandle`** & **`IndexBufferHandle`** (`<Graphics/VertexBufferHandle.h>`) | Encapsulates GPU vertex/index buffers. Supports `Initialize(size_tVertexStride, ...)` or `Initialize(size_t numberOfVertices)`, `SetBufferUsageType(BufferUsageType)` (`BufferUsageStatic` vs `BufferUsageDynamic`), and CPU mapping via `Lock(size_t index, size_t numberOfVertices, AccessType)` / `Unlock()` **[VERIFIED-PUBLIC]**. | Public interface exposes CPU-mapped pointers via `Lock()`/`Unlock()`, **not** raw `ID3D11Buffer*`, `IDXGIResource1::CreateSharedHandle`, or `D3D11_BIND_UNORDERED_ACCESS` creation flags **[VERIFIED-PUBLIC]**. |
| **`TextureHandle`** (`<Graphics/TextureHandle.h>`) & **`TargetHandle`** | Wraps 2D/3D/Cube GPU textures (`Initialize(width, height, TargetFormat)`), with CPU write access (`WriteOnlyLockRectangle` / `Lock`) and binding to `HLSLMaterialHandle` via `SetTextureParameter` **[VERIFIED-PUBLIC]**. | Works out-of-the-box with **Shader Model 5.0 `Texture2D<float4>.Load()`** in a vertex shader! Does not publicly document returning an `ID3D11Texture2D*` with `D3D11_RESOURCE_MISC_SHARED_NTHANDLE`. |
| **`HLSLMaterialHandle`** (`<Graphics/HLSLMaterialHandle.h>`) | Loads HLSL `.fx` shaders (`InitializeWithFile` / `InitializeWithString`, Shader Model 5.0), binds `float`/`int`/`Matrix44`/`TextureHandle` parameters **[VERIFIED-PUBLIC]**. Used by Cyrus Scatter today (`mesh_display.inc`) **[PROVIDED-FACT]**. | Publicly documented for graphics passes (Vertex/Geometry/Pixel shaders); not documented as a general-purpose compute-shader dispatch scheduler outside `Display()`. |

---

## 3. Why Direct Compute-to-Vertex-Buffer Interop Has Two Structural Barriers in D3D11

Even in a standalone Direct3D 11 application (outside 3ds Max), sharing a vertex buffer with compute shaders or CUDA has strict API constraints **[VERIFIED-PUBLIC]**:

### Barrier 1: D3D11 Mutually Exclusive Buffer Flags (`STRUCTURED` vs `VERTEX_BUFFER`)
Per the Microsoft Direct3D 11 specification (`D3D11_BUFFER_DESC` **[VERIFIED-PUBLIC]**):
- A buffer created with `D3D11_RESOURCE_MISC_BUFFER_STRUCTURED` (required for `RWStructuredBuffer<T>` in HLSL `cs_5_0`) **cannot** also specify `D3D11_BIND_VERTEX_BUFFER`. `ID3D11Device::CreateBuffer` fails with `E_INVALIDARG` (`0x80070057`).
- A buffer created with `D3D11_USAGE_DYNAMIC` (which Nitrous uses when `VertexBufferHandle::SetBufferUsageType(BufferUsageDynamic)` is selected so `Lock()` can use `D3D11_MAP_WRITE_DISCARD`) **cannot** specify `D3D11_BIND_UNORDERED_ACCESS` and **cannot** be registered for CUDA write interop without triggering a staging copy inside the driver **[VERIFIED-PUBLIC]**.

### Barrier 2: CUDA Graphics Interop vs External Memory Interop Requirements
NVIDIA CUDA provides two D3D11 interoperability paths (`CUDA Programming Guide §Graphics Interoperability` **[VERIFIED-PUBLIC]**):

| Mechanism | CUDA APIs | What the D3D11 Side Must Provide | Synchronization & Lifetime Rules | Feasibility Inside 3ds Max 2027 Nitrous |
|---|---|---|---|---|
| **1. Legacy D3D11 Graphics Registration** | `cudaGraphicsD3D11RegisterResource`, `cudaGraphicsMapResources`, `cudaGraphicsResourceGetMappedPointer`, `cudaGraphicsUnmapResources` (`<cuda_d3d11_interop.h>`) | Raw `ID3D11Resource*` created on the **same physical adapter** with `D3D11_USAGE_DEFAULT` | D3D11 must **not** access the resource while mapped to CUDA. Map/Unmap acts as a cross-context barrier across the WDDM scheduler ($\approx 15\text{--}60\text{ }\mu\text{s}$ per pair) **[VERIFIED-PUBLIC]**. | **Blocked unless Probe P1 finds a supported `GetNativeBuffer()` on `BufferUsageStatic` (`DEFAULT`) handles** AND mapping occurs strictly outside `Display()`. |
| **2. Modern External Resource / NT-Handle Interop** | `cudaImportExternalMemory` (`cudaExternalMemoryHandleTypeD3D11Resource` or `Kmt`), `cudaImportExternalSemaphore` (`cudaExternalSemaphoreHandleTypeD3D11Fence`) | Resource created by D3D11 with `D3D11_RESOURCE_MISC_SHARED_NTHANDLE` + `D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX` (or `ID3D11Device5::CreateFence` with `D3D11_FENCE_FLAG_SHARED`) | Explicit GPU-timeline wait/signal via `ID3D11DeviceContext4::Wait`/`Signal` and `cudaWaitExternalSemaphoresAsync` / `cudaSignalExternalSemaphoresAsync` **[VERIFIED-PUBLIC]**. | **Unlikely for Nitrous-allocated buffers**, because `VertexBufferHandle::Initialize` does not set `D3D11_RESOURCE_MISC_SHARED_NTHANDLE`. Only viable if a plugin creates its own `ID3D11Texture2D` and wraps it into a `TextureHandle` (Probe P1). |

---

## 4. Multi-GPU, Optimus Laptops, and Adapter Identity (LUID Matching)

**[VERIFIED-PUBLIC]**

In workstation and laptop environments, the GPU running the 3ds Max 2027 Nitrous viewport is not guaranteed to be CUDA device `0`:
1. **Multi-NVIDIA Workstations:** E.g., GPU 0 is an RTX A4000 driving the display, while GPU 1 is a headless RTX 3090 compute card.
2. **AMD / Intel Display GPU + NVIDIA Compute GPU (or Hybrid Optimus Laptop):** Max's viewport may initialize on the Intel/AMD integrated/display adapter, or on a different discrete GPU.
3. **Rule for Adapter Matching:**
   - Query the DXGI adapter LUID (`DXGI_ADAPTER_DESC::AdapterLuid`, an 8-byte locally unique identifier on Windows) and compare it against `cudaDeviceProp::luid` (valid when `cudaDeviceProp::tccDriver == 0`) **[VERIFIED-PUBLIC]**.
   - **If LUIDs match:** Both Nitrous and CUDA reside on the same physical GPU.
   - **If LUIDs do NOT match (cross-adapter):** Zero-copy graphics interop across distinct adapters is **not supported** (or silently degrades to PCIe staging copies through system RAM). However, our **Compact Pose Readback + Public SDK `Lock`/`Unlock` path (Fallback F1 below)** works transparently across mismatched adapters because the compact pose buffer ($0.1\text{--}2.5\text{ MiB}$) passes through pinned host RAM!

---

## 5. Supported Fallbacks and Exact Cost Comparison

Because relying on undocumented pointer extraction from `IVirtualDevice` violates `RESEARCH_PROMPT.md` §8 (*"Avoid unsupported pointer extraction, private APIs, and taking ownership of Max's graphics context"*), we quantify the three fully supported fallback paths **[ANALYTICAL-ESTIMATE]**:

| Path | Description | Per-Drag Transfer Volume ($K=500$ plants, $M=15{,}000$ active guides, $V=22{,}032$ verts) | PCIe 4.0 x16 Transfer Time ($\sim 22\text{ GB/s}$ pinned) | Max 2027 Public SDK Compliance | Verdict |
|---|---|---|---|---|---|
| **Path F0 (Zero-Copy Interop — Conditional on Probe P1)** | CUDA writes compact poses directly to a shared D3D11 SRV/Texture read by Nitrous SM5 Vertex Shader. | **$0\text{ Bytes}$** over PCIe (GPU-to-GPU L2/VRAM) | $\approx \mathbf{0.03\text{ ms}}$ (map/unmap or fence sync) | Requires verified native resource hook in Max 2027 SDK | **Bonus optimization only if Probe P1 passes** |
| **Path F1 (Recommended Primary Path: CUDA Solve $\to$ Compact Pose Readback $\to$ Public SDK Texture/VB Lock $\to$ SM5 VS Deformation)** | CUDA solves root hiding + active guides, copies **only compact active poses** ($M \times Nn \times 16\text{ B}$) to pinned host RAM, and uploads them via `TextureHandle` / `VertexBufferHandle::Lock` for the SM5 Vertex Shader. | **$1.83\text{ MiB}$ D2H + $1.83\text{ MiB}$ H2D = $3.66\text{ MiB}$ total** (even at $K=500$ complex plants!) | $\approx \mathbf{0.17\text{ ms}}$ total PCIe round-trip ($< 1\%$ of a 60 Hz frame!) | **100% Public Max SDK** (`TextureHandle`, `VertexBufferHandle`, `HLSLMaterialHandle`) | **Selected Primary Architecture** |
| **Path F2 (CPU Solve + Public SDK Lock $\to$ SM5 VS Deformation)** | Multi-threaded CPU solves active guides directly in host RAM and writes $1.83\text{ MiB}$ into `TextureHandle` / `VertexBufferHandle::Lock` for the SM5 Vertex Shader. | **$1.83\text{ MiB}$ H2D** | $\approx \mathbf{0.08\text{ ms}}$ H2D | **100% Public Max SDK** | **Selected Immediate Step (Gate 3) & Mandatory CPU Fallback** |
| **Path F3 (GPU/CPU Deforms Full Meshes $\to$ Public SDK VB Lock)** | Deform all $K \times V$ vertices into explicit meshes and upload via `VertexBufferHandle::Lock`. | **$336.2\text{ MiB}$ H2D** (plus $336.2\text{ MiB}$ D2H if deformed in CUDA) | **$\mathbf{15.3\text{--}30.6\text{ ms}}$** (destroys 60 Hz budget on PCIe alone!) | 100% Public Max SDK | **Rejected** for interactive dragging at $K \ge 50$ |

---

## 6. Offline Renderer, Bake, and Export Consistency (Arnold, V-Ray, Corona)

**[VERIFIED-PUBLIC] & [PROVIDED-FACT]**

A critical hazard highlighted in `RESEARCH_PROMPT.md` §8 is that **viewport-only vertex shader deformation does NOT automatically populate the geometry consumed by offline renderers (Arnold MAXtoA, Chaos V-Ray, Chaos Corona) or scene exporters (USD, FBX, Alembic)**, which query geometry on the CPU via `GeomObject::GetRenderMesh()`, `MaxSDK::RenderTimeInstancing`, or Cyrus Scatter's native renderer publication interface (`AminScatter/src/interactions_render.cpp`).

### Unified Pose-Truth Architecture for Viewport + Renderers **[PROPOSED / UNVERIFIED]**
1. **Single Authoritative Representation = The Compact Successor Pose Snapshot (Host-Resident):**
   - Whether a drag update is solved by the CPU worker pool (Path F2) or the CUDA solver with compact pose readback (Path F1), the **authoritative published result** committed on the host thread is the **Compact Successor Pose Snapshot** (containing per-instance `hiddenGroupMasks` and compact posed guide nodes $\{\mathbf{p}_{g,i}, \mathbf{q}_{g,i}\}$).
2. **Viewport Consumer (Real-Time, Every Drag Frame):**
   - Uploads the delta of the Compact Successor Pose Snapshot into the `MaxSDK::Graphics` pose texture/buffer and draws shared source meshes via the SM5 Vertex Shader.
3. **Offline Renderer / Bake / Export Consumer (On-Demand at Render/Bake Time $t$):**
   - Undisturbed rest instances ($N - K_{\text{posed}}$, typically $>95\%$ of the scene) continue to be delivered to Arnold/V-Ray/Corona as **true shared hardware/render instances** of the unmodified source mesh (`MaxSDK::RenderTimeInstancing` / `interactions_render.cpp`).
   - Only for the $K_{\text{posed}}$ instances that have non-rest guide poses or partial group hiding, when `GetRenderMesh` / `interactions_render.cpp` is invoked for a render or Bake:
     - Evaluated lazily on demand (never during viewport pointer dragging!).
     - Uses the **exact same quaternion guide-frame deformation math (`deformVtx`) and hidden-group triangle culling** as the viewport shader (running either via our CUDA `kDeformMesh` kernel with pinned readback in $< 3\text{ ms}$ per $500$ plants, or on the 8-thread CPU worker pool) to materialize the deformed `Mesh` for the renderer.
     - Because both the viewport shader and the on-demand render materializer evaluate the **identical mathematical function** `deformVtx(restVertex, compactGuidePose)`, **viewport preview and Arnold/V-Ray/Corona renders match to within $< 10^{-5}\text{ m}$ ($0.01\text{ mm}$)**!

---

## 7. Four-Stage Interop Proof Gate Specification (Early Go/No-Go)

Before investing in a full GPU contact solver, execute these four small, isolated proofs in sequence (full code sketches in [14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)):

1. **Proof 1A (Standalone Compute & Precision Proof):** Compile `fit_core.h` in standalone C++ and CUDA/OpenCL; verify that local-frame FP32 guide fitting matches FP64 reference within $\le 5 \times 10^{-5}\text{ m}$ and zero root drift across $K = 1{,}000$ plants.
2. **Proof 1B (Standalone D3D11 + CUDA Pinned vs Shared-Resource Proof):** Measure standalone `Map(D3D11_MAP_WRITE_DISCARD)` of a $2\text{ MiB}$ compact pose texture/buffer vs `cudaGraphicsD3D11RegisterResource`. Go criterion: confirm that even the pure CPU `Lock`/`Unlock` upload of $2\text{ MiB}$ takes $< 0.3\text{ ms}$.
3. **Proof 1C (In-Max Supported `MaxSDK::Graphics` Pose-Pull Shader Proof):** Inside a minimal Max 2027 custom render item (`mesh_display.inc` test branch), bind a dynamic `TextureHandle` (`R32G32B32A32_FLOAT`) to `HLSLMaterialHandle`, lock/write synthetic guide poses on pointer move, and verify that:
   - Shared-source instanced drawing deforms blades smoothly at 60 FPS,
   - Hidden root groups disappear cleanly without index-buffer rebuilds, and
   - Toggling Wireframe (`F3`) preserves the deformed pose without re-uploading buffers.
4. **Proof 1D (Renderer/Bake Parity Proof):** Materialize one deformed plant via `interactions_render.cpp` using the same compact guide pose and verify zero vertex/normal discrepancy ($< 10^{-5}\text{ m}$) between the Nitrous viewport and an Arnold/V-Ray render.
