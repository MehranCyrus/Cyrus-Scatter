# Papers and reusable implementations

**D — primary literature and pinned source inspection. No upstream solver was installed, compiled, benchmarked or incorporated into the product by this research.**

## Papers and practices

| Source | Useful idea for Cyrus | Transfer limitation |
|---|---|---|
| [XPBD, Macklin/Müller/Chentanez, 2016](https://matthias-research.github.io/pages/publications/XPBD.pdf), DOI 10.1145/2994258.2994272 | Compliance-aware position constraints | Does not by itself solve static infeasibility, complete mesh contact, or Max integration |
| [Small Steps in Physics Simulation, Macklin et al., 2019](https://matthias-research.github.io/pages/publications/smallsteps.pdf), DOI 10.1145/3309486.3340247 | Compare substeps versus iterations for a future dynamic mode | A dynamic integration result is not evidence for current static-fit latency |
| [Discrete Elastic Rods, Bergou et al., 2008](https://www.cs.columbia.edu/cg/rods/index.html) | Material frames, bending/twist, parallel transport | More complete mechanics and global dependencies than a simple blade hinge |
| [Position and Orientation Based Cosserat Rods, Kugelstadt/Schömer, 2016](https://vci.rwth-aachen.de/publication/0550/) | Explicit position/orientation rod constraints | Finite solver schedule and collision system still need design/qualification |
| [Karras: Thinking Parallel I](https://developer.nvidia.com/blog/thinking-parallel-part-i-collision-detection-gpu/) | Broad-phase workload imbalance and mixed object sizes | Grid/BVH choice must be measured on our source distributions |
| [Karras: Thinking Parallel II](https://developer.nvidia.com/blog/thinking-parallel-part-ii-tree-traversal-gpu/) | Coherent traversal and divergence-aware organization | Historical hardware timings are not transferable benchmarks |
| [GPU Gems 3 chapter 6, Renaldas Zioma](https://developer.nvidia.cn/gpugems/gpugems3/part-i-geometry/chapter-6-gpu-generated-procedural-wind-animations-trees) | Instance-friendly hierarchical procedural tree wind | Visual animation, not rooted exact contact resolution |
| [GPU Gems 3 chapter 16, Tiago Sousa](https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-16-vegetation-procedural-animation-and-shading-crysis) | Main/detail vertex animation and practical vegetation shading | Wind appearance does not certify leaf/solid separation |

These references suggest alternatives; they do not choose our product semantics. First port existing pose evaluation and validate it. A new elastic-rod/wind solver is a separate design that must explain time, velocity, caching, reset, stiffness units and reproducible final states.

## Pinned repositories

All pins were resolved on 27 October 2026 through the public GitHub API. Machine-readable records include exact inspected file URLs, sizes and SHA-256 values under [evidence](evidence/). No downloaded engine trees, assets or SDK headers are bundled.

### NVIDIA CUDA Samples

Commit **`5443602d89ed99aede2e4b7bf329daddeadb320e`**, committed 9 September 2026. [Pinned source](https://github.com/NVIDIA/cuda-samples/tree/5443602d89ed99aede2e4b7bf329daddeadb320e), [inspection record](evidence/cuda-samples_pin.json).

Inspected `cpp/5_Domain_Specific/simpleD3D11/simpleD3D11.cpp`, `sinewave_cuda.cu`, and the D3D11 texture sample. The current buffer example uses external resource interoperability/keyed mutexes; the texture sample illustrates classic graphics resource use. This is useful for owned-device prototype sequencing, not proof that a Max retained handle can be imported.

The pinned tree advertises Toolkit 13.4 and uses the newer `cpp/...` layout. Do not copy an old `Samples/...` path from memory or assume it builds with our installed 12.1. Our local probe is independent source using APIs available in 12.1.

The root license has BSD-style three-clause conditions and an additional CUDA EULA reference; GitHub's SPDX field returns **NOASSERTION**. Preserve the exact license/third-party notices if reusing source. Assets and CUDA runtime redistribution have separate terms. [Pinned license](https://github.com/NVIDIA/cuda-samples/blob/5443602d89ed99aede2e4b7bf329daddeadb320e/LICENSE).

### NVIDIA Warp

Commit **`03f22841e92364a0632fe1be519db28f40e1de20`**, committed 27 October 2026. [Pinned source](https://github.com/NVIDIA/warp/tree/03f22841e92364a0632fe1be519db28f40e1de20), [inspection record](evidence/warp_pin.json).

Inspected native BVH build/traversal and mesh-query headers. Useful concepts include Morton-based hierarchy construction, device-callable traversal and different mesh sign queries. These are candidates for a numeric lab; each query's sign/degeneracy/maximum-distance behavior needs explicit tests before reuse.

The inspected development README's standard wheels use CUDA 13.4, require R580+ and sm_75+, and offer a different CUDA-12 path. That is **development-tree evidence**, not a pinned installed stable wheel. A Python-based Warp lab can speed algorithm experiments; embedding it into Max adds an additional runtime/JIT/distribution boundary that is unnecessary for the first C++/HLSL prototype.

Core license: **Apache-2.0**. The repository has separate third-party and asset notices; a root license does not cover every bundled image/library identically. [Pinned core license](https://github.com/NVIDIA/warp/blob/03f22841e92364a0632fe1be519db28f40e1de20/LICENSE.md).

### AMD GPUOpen TressFX

Commit **`ba0bdacdfb964e38522fda812bf23169bc5fa603`**, committed 24 January 2020. [Pinned source](https://github.com/GPUOpen-Effects/TressFX/tree/ba0bdacdfb964e38522fda812bf23169bc5fa603), [inspection record](evidence/TressFX_pin.json).

Inspected `TressFXSimulation.hlsl` and `TressFXSDFCollision.hlsl`: grouped strand work, shared memory, current/previous positions, and SDF collision buffers are useful examples. The reviewed repository is a historical DirectX 12/Vulkan hair system, not a current Max D3D11 vegetation component. Hair dynamics/root following differ from static broad-leaf fitting. Transfer the algorithmic ideas selectively.

License: **MIT** for the pinned root license. Preserve notices and inspect component dependencies if copying code. [Pinned license](https://github.com/GPUOpen-Effects/TressFX/blob/ba0bdacdfb964e38522fda812bf23169bc5fa603/license.txt).

### InteractiveComputerGraphics PositionBasedDynamics

Commit **`10a70bc146a97873dc3c8fef372f5217e010542e`**, committed 1 September 2026. [Pinned source](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics/tree/10a70bc146a97873dc3c8fef372f5217e010542e), [inspection record](evidence/PositionBasedDynamics_pin.json).

Inspected `PositionBasedDynamics/XPBD.cpp` and `PositionBasedElasticRods.cpp`, including distance, bending, stretch/shear and bend/twist constraint functions. Useful as readable CPU/reference mechanics and unit tests. It is not a ready CUDA solver, a complete leaf validator or a Max adapter.

License: **MIT**. Check dependency notices before adopting associated collision/distance-field libraries. [Pinned license](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics/blob/10a70bc146a97873dc3c8fef372f5217e010542e/LICENSE).

### Khronos OpenCL SDK

Commit **`6090378a113db8dab20ae278c8fa57ab10b92300`**, committed 22 September 2026. [Pinned source](https://github.com/KhronosGroup/OpenCL-SDK/tree/6090378a113db8dab20ae278c8fa57ab10b92300), [inspection record](evidence/OpenCL-SDK_pin.json).

Inspected the root license and `samples/core/copybuffer/main.cpp`. Useful for portable host-side buffer/queue patterns and build organization. This sample is not a D3D11 integration or collision solver. Extension declarations must be checked against actual platform/device capabilities.

License: **Apache-2.0** in the inspected root license; inspect each included submodule/component for distribution. [Pinned license](https://github.com/KhronosGroup/OpenCL-SDK/blob/6090378a113db8dab20ae278c8fa57ab10b92300/LICENSE).

## What not to treat as reusable GPU machinery

An existing CPU engine's C++ objects, virtual methods, allocator and threading cannot simply be passed into a kernel. Reuse numeric contracts, geometry definitions, tests and permitted source algorithms. GPU flat-buffer implementations need their own ownership, completeness and error reporting. Likewise a hair demo or procedural wind shader does not automatically supply robust signed collision, scene persistence, Max interaction or final renderer geometry.

## Reuse gate

Before bringing code into production: select one exact revision and file set; review original code and notices; identify dependencies and build/runtime requirements; create an independent analytic/reference fixture; measure copied-data overhead; then compare quality/performance in Max. Store modifications and observed failures alongside the pin. Do not infer production readiness from repository popularity, an AI recommendation or a paper's benchmark chart.
