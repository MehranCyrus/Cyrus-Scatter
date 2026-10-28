<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 04 — CUDA, OpenCL and graphics compute

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Decision frame

CUDA, OpenCL and D3D/HLSL are execution APIs. None changes the algorithmic requirement: sparse active lists, rooted constraints, whole-segment/visible-envelope collision, immutable source reuse, exact final validation and atomic publication.

**[R]** Compare them only after the same numerical workload exists in a standalone harness. Attribute gains to algorithm/data layout separately from API/tooling.

## Current verified ecosystem snapshot

| Item | Verified public state | Cyrus implication |
|---|---|---|
| CUDA samples | **[V]** CUDA Samples `v13.4`, published 9 Sep 2026, supports CUDA Toolkit 13.4 **[S14]** | useful current standalone interop and graphs examples; not Max support evidence |
| CUDA Windows toolchain | **[V]** CUDA 13.3 Windows guide lists Visual Studio 2022/2026 x64 compiler families **[S09]** | the supplied MSVC 14.38 build must still be compiled in an exact local matrix; newest toolkit is not automatically the correct production choice |
| OpenCL | **[V]** OpenCL 3.1.1 specification synchronized in the official SDK release `v2026.05.29` **[S20–S24]** | base language/API is current, but features/extensions remain device/runtime queries |
| NVIDIA Warp | **[V]** Warp `v1.18.0`, published 5 Oct 2026, Apache-2.0 **[S40]** | strong research harness for kernels/BVH/mesh queries; Python/JIT/runtime footprint makes it a separate production-dependency decision |
| TressFX | **[V]** public MIT code contains HLSL compute passes for strand constraints; latest tagged release is 4.1.0 (2020), repository code last pushed 2023 **[S39]** | useful scheduling/deformation reference; not a current drop-in Max or rooted-static-fitting backend |
| PositionBasedDynamics | **[V]** MIT C++ repository current at commit `10a70bc...` (1 Sep 2026), contains Cosserat rod and SDF examples **[S38]** | useful CPU/reference math; integration is larger than a focused fitter and does not solve Max delivery |

## CUDA

### Strengths

- **[V]** Native NVIDIA compiler/runtime, mature profiling through Nsight Systems and Nsight Compute. **[S09, S18–S19]**
- **[V]** CUDA Graphs can capture/relaunch repeated dependency graphs, reducing CPU submission overhead for short repeated kernels after graph construction/instantiation. **[S11]**
- **[V]** CUB/CCCL/Thrust provide scans, sorting, reductions and device containers useful for compact active lists. **[S12]**
- **[V]** D3D11 graphics registration and newer external-resource paths exist in standalone applications when the application owns/receives actual D3D devices/resources and follows map/unmap or fence/keyed-mutex ownership. **[S10, S14, S28]**
- **[R]** Best conditional production solver candidate when NVIDIA-only acceleration is accepted and Max resource transfer is proven.

### Risks

- NVIDIA-only optional path and extra deployment/runtime qualification.
- Toolkit/driver/host compiler combinations must match the Max plugin build and installer.
- Direct graphics registration is useless if Max exposes only opaque SDK handles.
- Kernel compilation/JIT/cache and driver changes become new support surfaces.
- GPU work already submitted generally cannot be synchronously cancelled; stale-result suppression is mandatory.
- Fast math, FMA and parallel reduction order can diverge from CPU double reference.

## OpenCL

### Strengths

- **[V]** Cross-vendor API and official ICD loader model. **[S20–S25]**
- **[V]** D3D11 sharing extension defines wrapping `ID3D11Buffer`/textures and explicit acquire/release ownership when the context is created for the corresponding `ID3D11Device`. **[S21–S22]**
- **[V]** Command-buffer and mutable-dispatch extensions can reduce repeated host submission overhead where the runtime reports support. **[S21, S23]**
- **[R]** Valuable matched benchmark and portability option; possibly preferable if AMD/Intel acceleration becomes a requirement.

### Risks

- OpenCL 3.x optional functionality means command buffers, subgroups, FP64, D3D sharing and SVM must be queried per device/runtime.
- ICD loader presence does not imply a usable vendor platform.
- Tooling and vendor-specific diagnosis on NVIDIA may be less integrated than CUDA/Nsight.
- Equivalent algorithm tuning still requires vendor-aware workgroup/subgroup choices.
- The same Max native-resource obstacle applies: the extension requires real D3D objects, not an opaque virtual handle.

## D3D11 compute and vertex shaders

### Ordinary vertex shader deformation

**[R] Preferred first GPU prototype.** Each draw reads shared source vertices plus compact per-instance guide poses, evaluates the canonical binding, and writes clip-space position and transformed normal/tangent. It requires no persistent deformed mesh and no solver compute dispatch.

Advantages:

- aligns with the already documented HLSL custom-material and instanced-draw viewport path;
- avoids CUDA/OpenCL runtime and cross-API synchronization;
- automatically runs only for visible drawn vertices;
- ideal for proving buffer indexing, bounds, normals, visibility and quality.

Limitations:

- does not solve collision or create poses;
- accurate culling bounds must be prepared on CPU or conservatively expanded;
- picking/hit-testing may need CPU pose evaluation;
- renderer/Bake still need canonical CPU materialization unless separately integrated.

### D3D11 compute shader

A standalone D3D11 application can bind UAVs and invoke `ID3D11DeviceContext::Dispatch`. The inspected Max `IVirtualDevice` documentation exposes UAV-related target binding and retained handles but does not document a compute-dispatch method or a native `ID3D11DeviceContext`.

**[U]** The installed Max 2027 SDK must prove whether a supported compute route exists. Do not downcast or extract private objects.

## Matched CUDA/OpenCL experiment rules

Both implementations must use:

- identical source/collider fixtures and stable ordering;
- identical FP mode and tolerance policy;
- identical broad-phase candidate list or both include broad phase;
- identical constraint equations, iteration/convergence limits and visible validator;
- equivalent data residency and preallocated pools;
- equivalent warm-up and cold compilation cases;
- same GPU, clock/power state, driver, OS and display/render load;
- equal transfer and synchronization accounting;
- comparable tuning effort and documented compiler flags.

Report separately:

1. host preparation;
2. H2D/D2H completed transfer;
3. kernel/command execution;
4. synchronization;
5. validation/materialization;
6. input-to-present or Update completion.

An API wins only if the **complete qualified path** is better enough to offset its integration and support cost.

## Precision and compiler policy

| Mode | Use | Risks / gate |
|---|---|---|
| FP64 reference | CPU/offline independent audit | cost on consumer GPUs; not required for every interactive operation |
| FP32 local coordinates | primary GPU geometry/pose path | requires local rebasing and scale-aware tolerances |
| mixed precision | double/64-bit request transforms and origins; float local kernels | recommended baseline for large architectural worlds |
| fast math | optional experiment only | must pass grazing/contact/frame fixtures; never default silently |
| fused operations | normal GPU behavior | tolerance comparison, not bitwise CPU equality |

## Toolchain and deployment comparison

| Criterion | CUDA | OpenCL | D3D/HLSL |
|---|---|---|---|
| compile model | NVCC/AOT plus driver JIT for code objects | source/SPIR-V/vendor compilation depending runtime | HLSL compile to shader bytecode through supported Max path |
| runtime discovery | CUDA driver/runtime API | ICD loader + platform/device enumeration | host graphics capability/material realization |
| profiling | Nsight Systems/Compute | vendor tools; PIX only for graphics/D3D path | PIX/GPUView/host instrumentation where attachable |
| graphs/replay | CUDA Graphs | optional command-buffer extensions | command lists/context controlled by host; availability unresolved |
| scan/sort libraries | mature CCCL/CUB/Thrust | custom or third-party kernels | custom compute; vertex path avoids them |
| portability | NVIDIA | multi-vendor in principle | Windows/D3D and host graphics device |
| Max integration risk | high unless direct share/compact transfer proven | high unless extension/device share proven | lowest for existing custom shader material path |
| plugin load fallback | dynamic optional module required | dynamic ICD/runtime query required | existing viewport fallback still required |

## Weighted API decision matrix

Scores are current risk-adjusted assessments, not benchmark results.

| Criterion | Weight | CUDA solver | OpenCL solver | HLSL deformation | CPU reference |
|---|---:|---:|---:|---:|---:|
| likely NVIDIA performance ceiling | 20 | 5 | 4 | 5 for deformation only | 2–4 workload-dependent |
| current Max integration confidence | 20 | 1 | 1 | 4 | 5 |
| tooling/debugging | 15 | 5 | 3 | 4 | 5 |
| portability | 10 | 1 | 5 | 3 | 5 |
| distribution simplicity | 10 | 2 | 3 | 4 | 5 |
| exact solver capability | 15 | 5 | 5 | 1 | 5 |
| failure/fallback maturity | 10 | 2 | 2 | 4 | 5 |
| **weighted score / 5** | **100** | **3.20** | **3.25** | **3.75** | **4.45** |

The table explains the recommended sequence, not a permanent rejection of GPU solving.

## Sensitivity

- If the supported in-Max direct-share proof passes, CUDA/OpenCL integration confidence can rise by two points.
- If typical `K` is 1–10 and CPU p99 is acceptable, solver API choice becomes irrelevant.
- If `K` routinely reaches thousands and fitting/refinement dominates, CUDA's tooling and graphs can make it the preferred optional backend.
- If AMD/Intel acceleration is a commercial requirement and matched performance is sufficient, OpenCL or D3D compute receives higher weight.
- If only compact pose readback is feasible, API choice is based on solver throughput plus D2H pose cost, not zero-copy graphics claims.

## Recommendation-reversal evidence

CUDA should replace the initial HLSL-deformation-first sequence only after all of these are observed:

1. P0 traces show fit/contact/refinement—not CPU publication or deformation—is the dominant p95/p99 cost.
2. Matched CUDA prototype meets exact invariant/visible-surface quality.
3. Complete CUDA path beats CPU by a commercially meaningful margin at observed `K` distributions.
4. Max/renderer/Bake delivery does not erase the gain.
5. missing runtime, device loss and multi-adapter tests preserve CPU fallback and plugin load.

OpenCL outranks CUDA when the same evidence holds and portability/support economics outweigh CUDA's tooling advantage.
