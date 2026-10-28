# 10. Reproducible Benchmark and Validation Plan

## 1. Execution Status Disclosure

- **Production Cyrus Scatter + 3ds Max 2027 Benchmarks:** **NOT EXECUTED** (per project boundary in `RESEARCH_PROMPT.md` §2–3, we did not access or modify the production Cyrus Scatter repository or run inside 3ds Max 2027).
- **Deliverable:** Below is the complete, reproducible benchmark specification, parameter matrix, 7-stage timing decomposition, statistical reporting protocol, and standalone C++/CUDA/OpenCL/D3D11 harness specification ([14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)) ready for immediate local execution.

---

## 2. Core Benchmark Matrix + Stress Extensions

Rather than an intractable full Cartesian product, we define **12 Core Benchmark Cases (`BM-01` to `BM-12`)** that isolate each scaling dimension ($N, K, G, V, C$, hierarchy depth, and cache state) plus **4 Stress Extensions (`ST-01` to `ST-04`)**:

| Case ID | Total Instances $N$ | Affected Plants $K$ | Source Asset ($G$ guides, $Nn$ nodes, $V$ verts, Depth $D$) | Colliders ($C$ global / $C_k$ local, Tris $T_c$) | Scenario / Clearances (`gap`, `hide`, Mode) | Purpose |
|---|---:|---:|---|---|---|
| **BM-01** | $200$ | $3$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $1 / 1$ ($2\text{k}$ tris) | `gap=0`, `hide=0`, `Inside solid` | Exact regression anchor against `0.87.4.3` observed `4.05 ms` run. |
| **BM-02** | $1{,}000$ | $10$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $1 / 1$ ($2\text{k}$ tris) | `gap=10mm`, `hide=5mm`, `Inside solid` | Measures CPU vs GPU crossover point ($K \approx 10\text{--}20$). |
| **BM-03** | $10{,}000$ | $100$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $8 / 4$ ($10\text{k}$ tris) | `gap=10mm`, `hide=10mm`, `Under collider` | Standard interactive brush drag across lawn + raised obstacle. |
| **BM-04** | $100{,}000$ | $1$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $1 / 1$ ($10\text{k}$ tris) | `gap=10mm`, `hide=0`, `Inside solid` | **Population 1 test:** isolates $O(N)$ host snapshot-copy bug vs $O(K)$ fix when only 1 plant changes in 100k. |
| **BM-05** | $100{,}000$ | $500$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $64 / 8$ ($10\text{k}$ tris) | `gap=15mm`, `hide=10mm`, `Under collider` | **Population 2 core target:** 225,500 candidate guides, 11M candidate vertices. |
| **BM-06** | $100{,}000$ | $1{,}000$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $64 / 16$ ($10\text{k}$ tris) | `gap=15mm`, `hide=10mm`, `Inside solid` | Heavy multi-collider drag ($451{,}000$ candidate guides). |
| **BM-07** | $1{,}000{,}000$ | $100$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $1{,}024 / 8$ ($10\text{k}$ tris) | `gap=10mm`, `hide=10mm`, `Under collider` | **Max admission $N=1\text{M}$ sparse drag:** verifies horizontal spatial index & memory footprint at 1M scale. |
| **BM-08** | $1{,}000{,}000$ | $10{,}000$ | Simple Blade ($G=1, Nn=4, V=12, D=1$) | $16 / 4$ ($10\text{k}$ tris) | `gap=5mm`, `hide=0`, `Inside solid` | **Population 3 test:** high instance count, low per-instance guide count. |
| **BM-09** | $10{,}000$ | $250$ | Branched Bush ($G=180, Nn=12, V=45{,}000, D=3$) | $8 / 4$ ($10\text{k}$ tris) | `gap=20mm`, `hide=15mm`, `Inside solid` | Tests 3-level parent-child hierarchy ($d=0,1,2$) and long chains ($Nn=12$). |
| **BM-10** | $10{,}000$ | $250$ | Broad-Leaf Plant ($G=64, Nn=8, V=32{,}000, D=2$) | $8 / 4$ ($25\text{k}$ tris) | `gap=15mm`, `hide=10mm`, `Inside solid` | Tests Stage 5 visible-surface foliage envelope & axial twist refinement. |
| **BM-11** | $100{,}000$ | $500$ | Mixed 8 Sources ($G \in [1, 451]$, $V \in [12, 45\text{k}]$) | $64 / 64$ ($10\text{k}$ tris) | `gap=10mm`, `hide=10mm`, `Under collider` | Tests multi-source warp divergence and max 64 relevant colliders per plant. |
| **BM-12** | $10{,}000$ | $100$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $2$ Squeezing Colliders | Collider pair closes to $5\text{ mm} < 2 \times \text{gap}$ | **Infeasibility & Failure Retention Test:** verifies prior valid publication is retained with zero missing geometry. |
| **ST-01** | $1{,}000{,}000$ | $10{,}000$ | Baseline Grass ($G=451, Nn=8, V=22{,}032, D=1$) | $16{,}384 / 64$ ($10\text{k}$ tris) | Max admission stress ($4.51\text{M}$ guides) | Tests chunked watchdog execution ($M_{\text{chunk}}=65{,}536$) & VRAM admission ceiling. |
| **ST-02** | $100{,}000$ | $500$ | Baseline Grass at World Offset $(50{,}000\text{ m}, 50{,}000\text{ m}, 500\text{ m})$ | $8 / 4$ ($10\text{k}$ tris) | Millimetre vs Metre scene units | Verifies FP64 host rebasing prevents large-coordinate FP32 precision loss. |
| **ST-03** | $10{,}000$ | $500$ | Cold Start (Empty PTX/Driver Cache) vs Warm Cache | $8 / 4$ ($10\text{k}$ tris) | First-load compilation measurement | Measures cold fatbin/PTX load vs warm compute cache. |
| **ST-04** | $2{,}000{,}000$ | $20{,}000$ | Future Capability Probe (Beyond 1M Admission) | $16{,}384 / 64$ | Standalone harness only | Quantifies memory/compute scaling beyond current 1M safeguard. |

---

## 3. Experimental Controls and Reproducibility Specification

Every benchmark run must record and hold constant:
1. **Deterministic Trajectory:** A 120-step scripted collider path $\mathbf{T}_c(f)$ ($f = 0 \dots 119$) along a figure-eight spline through the scatter field at constant speed $v = 1.5\text{ m/s}$ (plus a fast-drag/teleport step $\Delta x = 5.0\text{ m}$ at $f = 60$ and an exit-to-rest step at $f = 119$), seeded with `uint64_t seed = 20261027ULL`.
2. **Warm-Up vs Measured Frames:** Run 10 warm-up steps (recorded separately as `cold_first_step_ms` and `warmup_p50_ms`), then measure 120 steps $\times 5$ repetitions ($600$ samples total).
3. **Matched Quality & Inputs:** All compared backends (CPU 8T, CPU 12T, CUDA, OpenCL, D3D11 CS) must use the **identical** prepared source arrays, iteration count ($I_{\text{iters}} = 8$), `Contact gap`, `Hide margin`, and surface-refinement rules.
4. **Build Flags & Environment Record:** Record exact OS build, GPU driver version, CPU model/core count, RAM speed, `cl.exe` version (`19.38.33130`), `nvcc` version, optimization flags (`/O2 /fp:fast` vs `-O3 --use_fast_math` vs IEEE strict `--fmad=true`), and Max 2027 viewport visual style (Shaded vs Wireframe).

---

## 4. Seven-Stage Timing Decomposition and Critical-Path Rules

Per `RESEARCH_PROMPT.md` §11, **never report a single `cudaEventElapsedTime` number as "drag latency," and never naively sum overlapping async stages**. Instrument and report these seven stages separately for every step $f$:

| Stage # | Metric Name | Start / Stop Instrumentation | Critical-Path Role |
|---|---|---|---|
| **Stage 1** | `t_host_search_ms` | CPU `QueryPerformanceCounter` (QPC) around scene transform capture + old/new horizontal spatial index query + candidate list build | **On Critical Path** |
| **Stage 2** | `t_h2d_upload_ms` | CUDA event `ev_h2d_start` $\to$ `ev_h2d_end` + bytes uploaded (`bytes_h2d`) | **On Critical Path** |
| **Stage 3** | `t_solve_refine_ms` | CUDA event `ev_solve_start` $\to$ `ev_solve_end` (subdivided into root exclusion, broadphase compaction, guide solve, and surface refinement) | **On Critical Path** |
| **Stage 4** | `t_deform_ms` | If compute/CPU deformation: kernel/CPU timer. If SM5 Vertex Shader deformation (Track 1): measured inside Stage 6 draw pass via `D3D11_QUERY_TIMESTAMP` | **On Critical Path** |
| **Stage 5** | `t_d2h_readback_ms` | CUDA event `ev_d2h_start` $\to$ host `cudaStreamSynchronize` completion + bytes read back (`bytes_d2h`) | **On Critical Path (Path F1)** |
| **Stage 6** | `t_publish_draw_ms` | Host QPC for $O(K)$ snapshot commit + `TextureHandle`/`VertexBufferHandle::Lock/Unlock` + Nitrous `MeshItem::Display` GPU draw time | **On Critical Path** |
| **Stage 7** | `t_input_to_present_ms` & `sustained_fps` | Wall-clock QPC from initial collider transform edit (`SetNodeTM` / pointer move) to DXGI `Present()` completion (measured via ** PresentMon / ETW `Microsoft-Windows-DxgKrnl` ** or Max viewport redraw completion hook) | **True End-to-End User Metric** |

### Statistical Reporting Table Format (Required for All Runs)
For each metric $m \in \{1 \dots 7\}$, report:
- **Latency Distribution:** `p50`, `p95`, `p99`, `max_spike_ms`, and `mean_ms`.
- **Frame Budget Compliance (Evaluated as Targets, Not Claims):**
  - **120 Hz Target ($8.33\text{ ms}$ total frame; $\le 4.0\text{ ms}$ interaction budget)**
  - **60 Hz Target ($16.67\text{ ms}$ total frame; $\le 8.0\text{ ms}$ interaction budget)**
  - **30 Hz Target ($33.33\text{ ms}$ total frame; $\le 16.0\text{ ms}$ interaction budget)**
- **Correctness & Reliability Counters:**
  - `active_candidates_K`, `active_guides_M`, `hidden_groups_H`, `infeasible_count`,
  - `max_root_drift_m` (must be `0.0`), `max_parent_attach_err_m` ($\le 10^{-6}\text{ m}$),
  - `max_penetration_m` ($\le 10^{-5}\text{ m}$), `max_edge_strain_pct`, and `vram_peak_mib`.

---

## 5. Profiler and Instrumentation Instructions (Version-Qualified)

1. **NVIDIA Nsight Systems (`nsys` 2024.x–2026.x):**
   - Command: `nsys profile --trace=cuda,nvtx,osrt,dx11 --sample=cpu -o cyrus_drag_report "C:\Program Files\Autodesk\3ds Max 2027\3dsmax.exe"`
   - Wrap stages 1–7 in **NVTX v3** ranges (`nvtxRangePushA("Cyrus::HostSearch")`, etc.) — `nvtx3` is a single header (`<nvtx3/nvtx3.hpp>`, Apache-2.0) with zero runtime DLL dependency when no profiler is attached **[VERIFIED-PUBLIC]**.
2. **NVIDIA Nsight Compute (`ncu` 2024.x–2026.x):**
   - Command (on standalone harness first, then targeted kernel filter in Max):
     `ncu --kernel-name regex:"kFit|kBroadphase|kDeform" --set full -o cyrus_kernels_report ./run_all_benchmarks.exe`
   - Inspect **Warp State Statistics** (specifically `Stall Long Scoreboard` from BVH global memory fetches and `Branch Efficiency` before vs after active-guide compaction).
3. **PresentMon (Intel / Windows ETW Presentation Latency):**
   - Command: `PresentMon-x64.exe -process_name 3dsmax.exe -output_file max2027_present.csv`
   - Captures `msBetweenPresents`, `msInPresentAPI`, and `msUntilDisplayed` without hooking or destabilizing Nitrous **[VERIFIED-PUBLIC]**.
