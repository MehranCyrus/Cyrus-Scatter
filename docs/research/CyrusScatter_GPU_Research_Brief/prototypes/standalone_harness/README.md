# Standalone Prototype & Benchmark Harness (`prototypes/standalone_harness/`)

> **Evidence Status:** `[PROPOSAL]` / **Standalone Source Reference (Not Executed Inside 3ds Max 2027)**
>
> All source files in this directory are **standalone C++20 / CUDA Driver API & NVRTC benchmark harnesses** designed to measure synthetic guide-solving, local-frame BVH collision queries, and linear-blend skinning (LBS) kernel throughput outside 3ds Max.
>
> **Important Disclosure:** None of these files have been linked against or executed inside a live `3dsmax.exe` (3ds Max 2027) process. All performance figures discussed in the main report (`01_EXECUTIVE_DECISION.md` through `18_ACCEPTANCE_CHECKLIST.md`) that were not directly measured are explicitly tagged `[ESTIMATE]` with analytical derivations.

---

## Included Files

1. **`common.h`**
   - Synthetic scene generator for canonical plant presets (`Tree_A` at 60k vertices / 128 guides, `Bush_B` at 15k vertices / 48 guides, `Grass_C` at 2k vertices / 12 guides).
   - Structure-of-Arrays (SoA) and Array-of-Structures-of-Arrays (AoSoA-32) memory layouts for guide nodes (`GuideNodeStateSoA`), foliage witness samples, and dual-weight (`k = 2`) vertex bindings.
   - Reference multi-threaded CPU baselines (`std::execution::par` / thread-pool equivalents) for:
     - Active-neighbourhood candidate filtering and root exclusion (`Inside solid` / `Under collider`).
     - Iterative Follow-The-Leader (FTL) / XPBD guide solving with ancestor-before-child ordering and foliage witness normal-lift / axial-twist correction.
     - CPU vertex/normal deformation and compact pose-palette (`16 B/node`) packing.

2. **`fit_core.h`**
   - Deterministic hash and parity validation utilities (`FNV-1a` bitwise reproducibility checks across runs, max/RMS vertex and normal error comparators between `fp32` CPU reference, `fp32` GPU solver, and quantized `10:10:10:2` smallest-three quaternion pose palettes).

3. **`run_all_benchmarks.cpp`**
   - Standalone benchmark runner supporting:
     - CPU multi-threaded baseline timing (`P50`, `P95`, `P99`).
     - Dynamic `nvcuda.dll` + `nvrtc64_*.dll` loading (zero static CUDA runtime dependency) to compile and benchmark the 1-thread-per-active-guide CUDA solver kernel, local-frame BVH query kernel, and GPU vertex skinning kernel when run on an NVIDIA workstation.
     - Parity verification between CPU and GPU outputs.

---

## How to Build & Run (Standalone Windows x64)

From a **Visual Studio 2022 (`v143`, `14.38+`) x64 Native Tools Command Prompt**:

```bat
cl /std:c++20 /O2 /EHsc /W4 run_all_benchmarks.cpp /Fe:run_all_benchmarks.exe
run_all_benchmarks.exe
```

No CUDA SDK `.lib` files are required at link time because `run_all_benchmarks.cpp` dynamically loads `nvcuda.dll` and `nvrtc` at runtime via `LoadLibraryA` / `GetProcAddress`, falling back cleanly to the CPU benchmark suite if no NVIDIA driver or NVRTC DLL is present.
