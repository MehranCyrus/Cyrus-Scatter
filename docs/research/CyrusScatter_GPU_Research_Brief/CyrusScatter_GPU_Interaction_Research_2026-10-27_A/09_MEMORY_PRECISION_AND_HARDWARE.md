# 09. Numerical Accuracy, Memory Budgets, and Hardware Practicality

## 1. Precision Analysis: Mixed FP64/FP32 Local-Frame Rebasing vs CPU Reference

### 1.1 Why Pure World-Space FP32 Fails in Architectural Scenes
In 3ds Max architectural and civil visualization scenes, scatter instances frequently sit at large world coordinates—for example, $X, Y \in [2{,}000\text{ m}, 50{,}000\text{ m}]$ (or $[2 \times 10^6\text{ mm}, 5 \times 10^7\text{ mm}]$ in millimetre scene units).
- IEEE 754 `binary32` (`float`) has $24$ bits of significand ($\text{ulp}(1.0) = 2^{-23} \approx 1.19 \times 10^{-7}$).
- At world coordinate $10{,}000\text{ m}$, $\text{ulp}(10{,}000\text{ m}) \approx 1.0\text{ mm}$, and computing a $5\text{ mm}$ grass segment length $\|\mathbf{p}_i - \mathbf{p}_{i-1}\|$ or a $1\text{ mm}$ `Contact gap` in world-space `float` loses **13 to 16 bits of precision** to catastrophic cancellation, causing visible blade jitter and false penetrations **[ANALYTICAL-ESTIMATE]**.

### 1.2 The Mixed-Precision Solution: Host FP64 Rebasing + Device FP32 Local Solve **[PROPOSED / UNVERIFIED]**
Because a single plant clump has physical radius $R_{\text{plant}} \le 0.5\text{ m}$ (grass/flowers) to $15\text{ m}$ (large trees), coordinates expressed in the **plant's local metre frame** have magnitude $|\mathbf{x}_{\text{local}}| \le 15\text{ m}$, where IEEE 754 `float` has machine epsilon:
$$\text{ulp}(0.5\text{ m}) = 2^{-24}\text{ m} \approx \mathbf{5.96 \times 10^{-8}\text{ m} = 0.06\text{ }\mu\text{m}}, \qquad \text{ulp}(15.0\text{ m}) = 2^{-20}\text{ m} \approx \mathbf{0.95\text{ }\mu\text{m}}$$

Therefore, we enforce a strict **Mixed-Precision Boundary**:
1. **On the Host CPU (in `double` / FP64):**
   - Convert Max scene units ($+Z$ up) to internal metres ($+Y$ up) in `double`.
   - For each candidate `(plant k, collider c)` pair, compute the relative translation in `double`:
     $$\Delta \mathbf{t}_{c\to k}^{(64)} = s_k^{-1} R_k^T \big(\mathbf{t}_{c,\text{world}}^{(64)} - \mathbf{t}_{k,\text{world}}^{(64)}\big)$$
   - Cast $\Delta \mathbf{t}_{c\to k}^{(64)}$, relative rotation quaternion $\mathbf{q}_{c\to k}$, relative scale $s_{c\to k}$, and local clearances $\tilde{g}_{\text{contact}} = g_{\text{contact}}/s_k$, $\tilde{m}_{\text{hide}} = m_{\text{hide}}/s_k$ to `float` **only after** world-origin subtraction!
2. **On the GPU (in `float` / FP32 with IEEE 754 Guard Thresholds):**
   - Run all BVH closest-point queries, root exclusions, FTL/XPBD guide iterations, and quaternion vertex deformations in plant-local `float` (`[-0.5 m, +0.5 m]` for grass).
   - **Degenerate Geometry Guards:**
     - Zero-length span guard: $L_{g,i} < 10^{-6}\text{ m} \implies \text{copy } \mathbf{p}_i = \mathbf{p}_{i-1}$ without division.
     - Grazing / zero-distance normal guard: $d = \|\mathbf{x} - \mathbf{c}\| < 10^{-7}\text{ m} \implies$ fall back to triangle face normal $\mathbf{n}_{\text{face}}$.
     - Nearly opposite vector rotation guard (`MinimalQuat`): $1 + \bar{\mathbf{d}} \cdot \mathbf{e} < 10^{-6} \implies$ pick orthogonal axis $\mathbf{a} = \text{ortho}(\bar{\mathbf{d}})$ to prevent $0/0 \to \text{NaN}$.
     - Final NaN/Inf sanitize gate: `if (!isfinite(p[i].x + p[i].y + p[i].z)) { infeasibleFlag[k] = ERR_NUMERICAL_NAN; }` — **never write a NaN into a published pose or viewport buffer!**

---

## 2. Numerical and Visual Acceptance Invariants

Per `RESEARCH_PROMPT.md` §10, we separate **bitwise reproducibility**, **numerical correctness against the FP64 CPU reference**, and **visual acceptance**:

| Invariant | Definition | Required Tolerance (GPU FP32 Local vs CPU FP64 Reference) | Failure Action |
|---|---|---|---|
| **1. Same-Device Bitwise Reproducibility** | Running the identical input snapshot twice on the same GPU/driver | **Bitwise identical (`0 ulp`)** — achieved via deterministic prefix-scan compaction (no `atomicAdd` slot order dependence). | Bug in kernel determinism |
| **2. Root Anchor Drift** | $\|\mathbf{p}_{g,0}^{\text{GPU}} - \bar{\mathbf{p}}_{g,0}\|$ for unbranched roots ($d=0$) | **Exact `0.0 m` (`0 ulp`)** — $\mathbf{p}_{g,0}$ is copied verbatim from $\bar{\mathbf{p}}_{g,0}$ and never modified. | Hard test failure |
| **3. Parent-Child Branch Attachment Drift** | $\|\mathbf{p}_{g_{\text{child}},0} - \text{Attach}(\mathbf{p}_{g_{\text{parent}}})\|$ for $d > 0$ | **$\le 1.0 \times 10^{-6}\text{ m}$ ($1\text{ }\mu\text{m}$)** in plant-local metres. | Hard test failure |
| **4. Guide Node Position Deviation (Matched Algorithm)** | $\max_{g,i} \|\mathbf{p}_{g,i}^{\text{GPU,FP32}} - \mathbf{p}_{g,i}^{\text{CPU,FP64}}\|$ | **$\le 5.0 \times 10^{-5}\text{ m}$ ($0.05\text{ mm}$)** for well-conditioned contacts; $\le 2.0 \times 10^{-4}\text{ m}$ near grazing/bistable edges. | Audit warning if $> 0.05\text{ mm}$ |
| **5. Exterior Contact Clearance (Guide + Refined Foliage)** | $\min_{\mathbf{x} \in \mathcal{S}_{\text{visible}}} \big(d_{\text{signed}}(\mathbf{x}, C_c) - \tilde{g}_{\text{contact}}\big)$ | **$\ge -1.0 \times 10^{-5}\text{ m}$ ($-0.01\text{ mm}$)** for exact local BVH; if using interactive SDF proxy, conservative offset $+0.5\sqrt{3}h_{\text{voxel}}$ ensures $\ge 0\text{ m}$ penetrations. | Mark plant infeasible & retain prior valid publication |
| **6. Maximum Stem Segment Strain** | $\max_{g,i} \big|\|\mathbf{p}_{g,i} - \mathbf{p}_{g,i-1}\| - L_{g,i}\big| / L_{g,i}$ | **$\le 1.0 \times 10^{-4}$ ($0.01\%$)** after FTL length projection (strictly tighter than the $9.145\%$ observed in `0.87.4.3`). | Hard test failure |
| **7. Rest Pose Restoration** | $\|\mathbf{p}_{g,i} - \bar{\mathbf{p}}_{g,i}\|$ after collider leaves neighbourhood | **Exact `0.0 m` (`0 ulp`)** — plant pose handle resets to `REST_INSTANCE` (`-1`). | Hard test failure |

---

## 3. Complete Memory Budgets (VRAM and Host RAM) Across Representative Scenes

**[ANALYTICAL-ESTIMATE]**

We budget **shared immutable source data**, **resident placement tables**, **collider acceleration structures**, **active/retained poses**, **double-buffered GPU scratch**, and **viewport buffers** separately.

### 3.1 Representative Scene Definitions
- **Scene S1 (Baseline Fixture):** $N = 200$ plants, $1$ grass source ($G=451, Nn=8, V=22{,}032$), $C = 1$ collider ($2\text{k}$ tris), $K_{\text{active}} = 10$, $K_{\text{retained}} = 20$.
- **Scene S2 (Medium Production Lawn):** $N = 100{,}000$ plants, $4$ unique sources (avg $G=451, V=22{,}032$), $C = 64$ collider instances ($4$ unique meshes, $10\text{k}$ tris each), $K_{\text{active}} = 500$ plants ($M_{\text{active}} = 15{,}000$ guides), $K_{\text{retained}} = 2{,}000$ deformed plants ($M_{\text{retained}} = 60{,}000$ guides).
- **Scene S3 (Max-Admission Stress Scene):** $N = 1{,}000{,}000$ plants, $8$ unique sources, $C = 16{,}384$ collider instances ($16$ unique meshes, $10\text{k}$ tris each), $K_{\text{active}} = 4{,}096$ plants ($M_{\text{active}} = 120{,}000$ guides), $K_{\text{retained}} = 10{,}000$ deformed plants ($M_{\text{retained}} = 300{,}000$ guides).

### 3.2 Lower-Bound Byte Budget Table (Proposed Sparse-Pose + Shader-Pull Architecture)

| Memory Category | Formula | Scene S1 ($N=200$) | Scene S2 ($N=100\text{k}$) | Scene S3 ($N=1\text{M}$, Max Admission) |
|---|---|---:|---:|---:|
| **1. Shared Immutable Sources (VRAM)** | $N_{\text{src}} \times (V \cdot 48\text{ B} + G \cdot (Nn \cdot 16 + 32)\text{ B} + T \cdot 12\text{ B})$ | $1.42\text{ MiB}$ | $5.68\text{ MiB}$ | $11.36\text{ MiB}$ |
| **2. Collider BVHs & Transforms (VRAM)** | $N_{\text{col\_src}} \times T_c \cdot 64\text{ B} + C \cdot 64\text{ B}$ | $0.13\text{ MiB}$ | $2.50\text{ MiB}$ | $11.00\text{ MiB}$ |
| **3. Resident Instance Placement Table (VRAM)** | $N \times 40\text{ B}$ (`pos+scale`, `quat`, `poseHandle`, `flags`) | $0.01\text{ MiB}$ | $3.81\text{ MiB}$ | $38.15\text{ MiB}$ |
| **4. Retained Pose Palette Texture/Buffer (VRAM)** | $K_{\text{retained}} \cdot (64 + G \cdot 2)\text{ B} + M_{\text{retained}} \cdot Nn \cdot 16\text{ B}$ | $0.11\text{ MiB}$ | $9.17\text{ MiB}$ | $45.85\text{ MiB}$ |
| **5. Double-Buffered Active Compute Scratch (VRAM, 2 Slots)** | $2 \times \big(K_{\text{active}} \cdot (G \cdot 8 + 128)\text{ B} + M_{\text{active}} \cdot Nn \cdot 16\text{ B}\big)$ | $0.18\text{ MiB}$ | $7.36\text{ MiB}$ | $59.10\text{ MiB}$ |
| **6. Pinned Host Transfer Ring (System RAM, 2 Slots)** | $2 \times \big(K_{\text{active}} \cdot 36\text{ B} + M_{\text{active}} \cdot Nn \cdot 16\text{ B}\big)$ | $0.05\text{ MiB}$ | $3.70\text{ MiB}$ | $29.60\text{ MiB}$ |
| **TOTAL CYRUS SCATTER GPU VRAM** | **Sum of Categories 1–5** | **$1.85\text{ MiB}$** | **$28.52\text{ MiB}$** | **$165.46\text{ MiB}$** |
| *(Comparison: Naive Per-Instance Deformed VBs for $K_{\text{retained}}$)* | $K_{\text{retained}} \times V \times 32\text{ B}$ | *(13.4 MiB)* | *(1,344.7 MiB)* | *(6,723.6 MiB)* |

> [!NOTE]
> **Why This Budget Fits Easily Alongside 3ds Max and GPU Renderers:**
> Even in the **1,000,000-instance max-admission stress scene (S3)** with $10{,}000$ simultaneously deformed 22k-vertex plants, our compact-pose + vertex-shader-pull architecture consumes only **$165.5\text{ MiB}$ of VRAM** (versus **$6.72\text{ GiB}$** if deformed meshes were stored per instance). On an 8 GB artist GPU where 3ds Max 2027 + Windows DWM already occupy $3.5\text{--}5.0\text{ GiB}$, $165.5\text{ MiB}$ fits with comfortable headroom whereas $6.72\text{ GiB}$ would immediately crash or page-thrash over PCIe!

---

## 4. Why `cudaMallocManaged` (Unified Memory) Must Not Be Used on Windows WDDM

Per `RESEARCH_PROMPT.md` §10: *"Unified memory is not automatically free of transfers or page faults."*
- On Windows 10 and Windows 11 under WDDM, the CUDA device attribute `cudaDevAttrConcurrentManagedAccess` is **`0` (false)** on all NVIDIA GPUs (including Ampere RTX 3090 and Ada RTX 4090) **[VERIFIED-PUBLIC]** ([CUDA Programming Guide — Unified Memory on Windows](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#um-requirements)).
- When `concurrentManagedAccess == 0`:
  1. The CPU **cannot** touch any `cudaMallocManaged` allocation while *any* kernel is running on the GPU (doing so causes undefined behavior or an access violation crash).
  2. Launching a kernel triggers **whole-allocation bulk migration** of dirtied managed buffers before the kernel can start, and `cudaStreamSynchronize()` migrates pages back on CPU read—incurring higher driver page-table overhead than explicit `cudaMemcpyAsync` over pinned memory (`cudaMallocHost`) **[VERIFIED-PUBLIC]**.
- **Rule:** Never use `cudaMallocManaged` in Cyrus Scatter on Windows. Always use explicit device allocations (`cudaMalloc` / `cudaMallocAsync`) paired with bounded pinned host staging buffers (`cudaMallocHost`).

---

## 5. Supported NVIDIA GPU Architecture & Hardware Matrix

**[VERIFIED-PUBLIC]**

| GPU Generation | Compute Capability | Example Cards (VRAM) | Status in CUDA 12.x | Status in CUDA 13.0+ (R580+) | Suitability & Recommendation for Cyrus Scatter |
|---|---|---|---|---|---|
| **Maxwell / Pascal / Volta** | `sm_50` – `sm_70` | GTX 1060/1080 Ti (6–11 GB), Quadro P4000 | Supported (Deprecated in 12.8) | **Dropped / Offline compilation removed in CUDA 13.0** **[VERIFIED-PUBLIC]** | Legacy support only if built with CUDA 12.x; route to CPU solver if built with CUDA 13.0+. |
| **Turing** | `sm_75` | RTX 2060–2080 Ti, Quadro RTX 4000 (8–11 GB) | Supported | Supported | **Minimum Recommended GPU Architecture (`sm_75`, $\ge 8\text{ GB}$ VRAM).** |
| **Ampere** | `sm_80`, `sm_86` | RTX 3060 (12 GB), **RTX 3090 (24 GB)**, RTX A4000/A5000 | Supported | Supported | **Baseline Reference Target** (local workstation has RTX 3090, 82 SMs, 936 GB/s bandwidth, 24 GB VRAM). |
| **Ada Lovelace** | `sm_89` | RTX 4060 Ti (16 GB), RTX 4080/4090 (16–24 GB), RTX 4000 Ada | Supported | Supported | **Recommended Production Workstation Target** (large 48–72 MB L2 cache dramatically accelerates BVH traversal). |
| **Blackwell** | `sm_100`, `sm_120` | RTX 5080/5090 (16–32 GB), RTX PRO Blackwell | CUDA 12.8+ | Supported | Supported via fatbin `compute_89`/`compute_120` + PTX JIT fallback. |

- **Sharing One GPU Between Viewport, Compute, and GPU Rendering:**
  - Create the Cyrus Scatter CUDA compute stream with **non-blocking flag (`cudaStreamNonBlocking`)** and **low/default priority** (`cudaStreamCreateWithPriority`) when an interactive GPU renderer (V-Ray IPR / Arnold GPU) is detected, or high priority during active viewport collider dragging so pointer responsiveness is prioritized over background tasks.
