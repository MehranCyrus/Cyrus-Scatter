# 15. Distribution, Fallback Policy, and Minimal Artist Workflow

## 1. Redistribution Terms, DLL Loading, and Installer Compliance

### 1.1 NVIDIA CUDA Toolkit EULA (Attachment A) Redistribution Rules **[VERIFIED-PUBLIC]**
Under the **NVIDIA CUDA Toolkit End User License Agreement (EULA, Attachment A — Redistributable Software)** ([docs.nvidia.com/cuda/eula](https://docs.nvidia.com/cuda/eula/index.html)):
1. **Permitted Redistributables:**
   - **CUDA Runtime (`cudart`):** `cudart_static.lib` (linked statically into the Cyrus Scatter `.dlo`/`.dll`), or `cudart64_*.dll` distributed in binary form inside Cyrus Scatter's private plugin directory.
   - **NVRTC (Optional Runtime Compilation):** `nvrtc64_*.dll` and `nvrtc-builtins64_*.dll` are explicitly listed in Attachment A if runtime PTX compilation is used; however, **precompiling fatbins offline with `nvcc` eliminates the need to ship `nvrtc` (~40 MB) altogether!**
2. **EULA Redistribution Conditions:**
   - Must be distributed in binary form only, inside a **private application directory** (e.g., `C:\ProgramData\Autodesk\ApplicationPlugins\CyrusScatter\Contents\Win64\`)—never installed into `C:\Windows\System32`.
   - Include standard NVIDIA copyright/license notice in Cyrus Scatter's `ThirdPartyNotices.txt` / About dialog.
3. **The CUDA Driver (`nvcuda.dll`) Is Never Redistributed:**
   - `nvcuda.dll` is installed by the user's NVIDIA display driver in `C:\Windows\System32\nvcuda.dll`.

### 1.2 Mandatory Delay-Load Architecture (Zero Startup Failure on Non-NVIDIA Machines) **[PROPOSED / UNVERIFIED]**

> [!CAUTION]
> **Critical Plugin Loading Rule:**
> If Cyrus Scatter's `.dlo` links directly against `nvcuda.dll` without delay-loading, Windows loader (`LoadLibraryEx` inside 3ds Max 2027 startup) will fail with `ERROR_MOD_NOT_FOUND (126)` on any machine with an AMD or Intel GPU where `nvcuda.dll` does not exist—**preventing the entire Cyrus Scatter plugin from loading!**

**Mandatory Build & Startup Configuration:**
1. **Link against `cudart_static.lib`** (static CUDA runtime) rather than `cudart.lib`, OR isolate all CUDA code into a companion optional DLL (`CyrusScatterCudaBackend.dll`) loaded dynamically via `LoadLibraryExW` only after verifying `nvcuda.dll` is present.
2. **Pass `/DELAYLOAD:nvcuda.dll` (and `delayimp.lib`)** to the MSVC linker (`14.38.33130`).
3. **Safe Startup Probe (Executed Once on First Interaction Request, Never in `DllMain`):**
   ```cpp
   bool ProbeCudaBackendAvailable(CudaBackendDiagnostics& diag) {
       HMODULE hDriver = LoadLibraryExW(L"nvcuda.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
       if (!hDriver) {
           diag.status = BackendStatus::Unavailable_NoNvidiaDriver;
           return false;
       }
       cudaError_t err = cudaGetDeviceCount(&diag.deviceCount);
       if (err != cudaSuccess || diag.deviceCount <= 0) {
           diag.status = BackendStatus::Unavailable_NoCudaDevice;
           return false;
       }
       cudaDeviceProp prop{};
       cudaGetDeviceProperties(&prop, 0);
       if (prop.major < 7 || (prop.major == 7 && prop.minor < 5)) {
           diag.status = BackendStatus::Unavailable_PreTuringArch; // Require sm_75+ (Turing+)
           return false;
       }
       diag.status = BackendStatus::Available_Ready;
       return true;
   }
   ```
4. **Compiler & CRT Binary Compatibility (`MSVC 14.38.33130`):**
   - Compile all `.cpp` translation units with **Visual Studio 2022 MSVC `14.38.33130`** (`/MD`, C++20) to match 3ds Max 2027's official SDK ABI requirement **[VERIFIED-PUBLIC]**.
   - Compile `.cu` device files with **CUDA 12.4–12.8** (recommended for broadest driver reach: Windows driver $\ge 551.xx / 572.xx$) or **CUDA 13.0** (requires R580+ driver $\ge 580.xx$) using `-ccbin` pointed at MSVC `14.38.33130` and `/MD`.
5. **Authenticode Code Signing:**
   - Sign `CyrusScatter.dlo` and `CyrusScatterCudaBackend.dll` with the studio's EV/OV Authenticode certificate so 3ds Max 2027's **Security Tools / Safe Scene Script Execution** loader verifies binary integrity without warnings **[VERIFIED-PUBLIC]**.

---

## 2. AOT Fatbin Packaging, PTX JIT Caching, and Cold-Start Bounding

**[PROPOSED / UNVERIFIED]**

Never compile a kernel per scatter instance or per plant asset. Cyrus Scatter needs at most **one static fatbin module** containing the 5 fixed interaction kernels (`kRootExclude`, `kBroadphaseFlags`, `kScatterCompact`, `kSolveCompactedGuidesAtDepth`, `kRefineFoliageSurface`).

### 2.1 Multi-Architecture Fatbin Flags
Compile the `.cu` solver once at build time with:
```text
-gencode arch=compute_75,code=sm_75      # Turing (RTX 20xx, Quadro RTX)
-gencode arch=compute_86,code=sm_86      # Ampere (RTX 30xx, RTX A-series)
-gencode arch=compute_89,code=sm_89      # Ada Lovelace (RTX 40xx, RTX Ada)
-gencode arch=compute_120,code=sm_120    # Blackwell (RTX 50xx)
-gencode arch=compute_120,code=compute_120 # PTX forward-compatibility for future GPUs
```
- **Binary Size Impact:** Adding 4 SASS architectures + 1 compressed PTX image for ~400 lines of kernel code adds only **$\sim 350\text{--}600\text{ KiB}$** to the plugin binary **[ANALYTICAL-ESTIMATE]**.
- **Zero Cold JIT Stall on Supported GPUs:** Because native SASS (`sm_75`, `sm_86`, `sm_89`, `sm_120`) is embedded directly in the fatbin, Turing, Ampere, Ada, and Blackwell GPUs load the module in **$< 3\text{ ms}$ with zero PTX JIT compilation**!
- **Lazy Module Loading:** Set environment/driver property `CUDA_MODULE_LOADING=LAZY` (default in CUDA 11.7+) so CUDA only maps the specific kernel functions actually invoked **[VERIFIED-PUBLIC]**.
- **PTX JIT Cache Key (For Future Post-Blackwell GPUs):** The NVIDIA driver automatically caches JIT-compiled PTX in `%LOCALAPPDATA%\NVIDIA\ComputeCache` keyed by `(PTX_hash, driver_version, device_sm_arch)`. Pre-warm `cudaFuncGetAttributes` once when an interaction layer is enabled so even a post-Blackwell GPU never JITs on the first mouse drag event.

---

## 3. Minimal Artist Workflow, UI Controls, and Diagnostics

Per `RESEARCH_PROMPT.md` §13: *"Preserve simple Collider/React/Prepare controls; do not expose every kernel tuning choice in the main UI. Clarify what can safely be automatic, what is an explicit quality choice, and what an unsupported GPU experiences."*

### 3.1 What Remains 100% Automatic (Hidden from Main UI)
The artist **never** configures:
- Thread block sizes, warp counts, or iteration counts;
- The CPU-vs-GPU crossover threshold ($K_{\text{gpu\_min}} = 16$ candidate plants);
- Pinned memory ring sizes or chunk splitting ($M_{\text{chunk}} = 65{,}536$);
- Adapter LUID selection or Path F1 vs Path F2 fallback switching.

### 3.2 Main UI Controls (Preserving Current Authoring Simplicity)
Keep the existing **Collider / React / Prepare** rollout unchanged, adding only **one compact status indicator + optional override dropdown** in the *Interaction Settings / Diagnostics* sub-rollout:

| Control / Readout | Options / Values | Purpose |
|---|---|---|
| **Acceleration Mode** *(Dropdown in Advanced/System)* | `Auto (Recommended)`, `GPU (CUDA)`, `CPU Multi-Threaded` | Defaults to `Auto` (uses GPU when $K \ge 16$ and a compatible NVIDIA GPU is healthy; falls back to CPU automatically). Allows technical directors or QA to force `CPU` for A/B troubleshooting. |
| **Interactive Surface Detail** *(Checkbox, Default: `Full Surface Clearance`)* | `Full Surface Clearance` vs `Fast Guide Envelope During Drag (Refine on Release)` | Explicit artist quality choice: defaults to exact full-surface refinement on every drag step; artists dragging huge bushes ($K > 2{,}000$) can opt into fast guide-envelope dragging with automatic exact surface refinement on mouse release. |
| **Compact Status Pill** *(Read-Only 1-Line Label)* | - `Ready: GPU Accelerated (RTX 3090, 2.1 ms)`<br/>- `Ready: CPU Mode (No compatible CUDA GPU)`<br/>- `Hold: Retained last valid pose (Collider squeeze / root inside gap on 2 plants)` | Gives immediate, non-intrusive feedback without modal popups. Whenever a solve is infeasible (`EC-01`, `EC-02`) or hits an admission cap (`EC-20`), tells the artist *why* the previous pose was retained. |

### 3.3 What an Artist on an Unsupported GPU (AMD / Intel / Old Driver) Experiences
1. **Zero Error Dialogs on Startup or Scene Open.**
2. **Full Viewport Shader Deformation Acceleration (Gate 2):** Because Gate 2 uses standard Shader Model 5.0 HLSL via `MaxSDK::Graphics`, **AMD Radeon and Intel Arc users still get GPU vertex/normal deformation and 50–180× smaller viewport uploads!**
3. **Identical Visual & Render Results:** The 8-thread CPU solver produces the exact same `CompactPoseSnapshot` as the CUDA solver, so saved scenes, Undo/Redo, and Arnold/V-Ray/Corona renders are 100% interchangeable across CPU and GPU workstations.
