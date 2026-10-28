# CUDA, OpenCL, and graphics shader alternatives

**Decision scope:** Windows x64, Max 2027 retained viewport, current static contact behavior. Wider platforms are not implied.

## Compare the integration, not only kernel arithmetic

| Candidate | Strength for this workload | Cost/risk | Evidence status |
|---|---|---|---|
| Native CPU | Excellent small jobs, existing exact geometry and host data | Limited large-batch throughput; still needs careful locality | Current source and historical fixtures |
| Max HLSL vertex deformation | Uses the draw GPU and shared source data; no separate solver runtime | Public binding semantics, deformed bounds/picking/normals need a prototype | Public APIs inspected; no in-Max pose shader executed here |
| CUDA | Native C++ compute ecosystem, profiling, scans/sorts, explicit driver control | NVIDIA dependency, runtime/toolchain policy, graphics ownership | Executed standalone deformation and D3D11 sharing |
| OpenCL | Potential cross-vendor kernels and similar fine-grained parallelism | Optional feature discovery, JIT/driver variation, extension variants | Same NVIDIA device executed; other vendors untested |
| Direct3D 11 compute | Could share a device/resource domain with the viewport | Public Max dispatch/state integration not yet established | Raw D3D capability is not Max qualification |
| Vulkan/D3D12 compute | Modern explicit memory/synchronization | Different API domain from the reviewed draw path; import/export complexity | No product need demonstrated |
| Warp/Python GPU lab | Fast algorithm experiments, CPU/CUDA kernels | Additional Python/JIT/runtime embedding, version-specific requirements | Source reviewed, not installed or benchmarked |

A public HLSL buffer can be read in a vertex shader; therefore GPU deformation does not necessarily require a CUDA or compute shader launch. For our plugin this is a particularly useful first experiment because guide fitting can remain on its established CPU path. [Microsoft HLSL Buffer](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/sm5-object-buffer).

## CUDA versus OpenCL: what this machine establishes

Both executed on the RTX 3090 with matched source/binding sizes, 256-thread workgroups, aligned records, strict divide/sqrt, disabled contraction/FMA policy, and the same quaternion/translation operation. Larger device-only times were close. Compiler implementations and host scheduling still differ, and the measured operation omits collision traversal, branching, normals and rendering. See [results and limitations](10_BENCHMARK_AND_VALIDATION_PLAN.md).

The probe supplies **no evidence that CUDA is inherently faster** for Cyrus collision solving. CUDA remains a reasonable *preferred compute prototype* because we can build native experiments and inspect behavior with its tooling. That preference must survive actual end-to-end measurements and packaging gates. OpenCL's wider potential hardware coverage is valuable, but one NVIDIA test does not qualify AMD/Intel execution or graphics sharing.

Keep the algorithm/data contract independent of public UI terminology. Do not build a generic multi-backend production framework before selecting a successful path; keep small interchangeable research executables instead. An initially CUDA-only optional accelerator can still leave the existing CPU feature available to other users.

## Graphics sharing is not automatic

CUDA offers classic register/map/unmap interoperability and external-memory/synchronization routes. Resource registration is intended to persist; graphics must not access a resource while CUDA owns its mapping. Sharing still requires compatible adapters, resource flags, sequencing, and lifetime management. [NVIDIA graphics interoperability](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html).

OpenCL has the optional Khronos D3D11 extension and a vendor-specific NVIDIA variant. Our driver advertised **`cl_nv_d3d11_sharing`**, and the standalone test used it successfully; it did not advertise the Khronos variant. The NV registry text is old and labels its status Unknown, so capability must be queried and executed on the target driver rather than assumed from the name. [KHR extension](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/cl_khr_d3d11_sharing.html), [NV extension](https://registry.khronos.org/OpenCL/extensions/nv/cl_nv_d3d11_sharing.txt).

Neither standalone success grants permission to take a Max-owned resource or manipulate the host immediate context from a worker. Direct sharing must be a separate Max SDK experiment with documented ownership and graphics state restoration.

## Toolchain and distribution choices

The local default `CUDA_PATH` pointed to 11.8; the research explicitly selected 12.1. MSVC host compilation plus NVRTC 12.1 and CUDA Driver API loading worked. An earlier direct NVCC 12.1 attempt failed with “Host compiler targets unsupported OS.” That failure is retained in local build evidence. We did not bypass compiler checks, install tools, or conclude CUDA is incompatible with Max.

NVRTC compiles CUDA C++ strings into PTX for the Driver API. For shipping, compare a pinned offline cubin/PTX package against controlled JIT, including first-use stalls and compatible runtime DLLs. Do not compile on each mouse event. [NVRTC 12.1 documentation](https://docs.nvidia.com/cuda/archive/12.1.0/nvrtc/index.html).

“OpenCL 3.x” is not a complete capability policy. Discover required features, extension functions, local-memory/workgroup limits, and strict math support. The current unified OpenCL C page is v3.1.2, while this driver's reported device API is OpenCL 3.0 and the probe requests OpenCL C 1.2. These labels describe different things. [OpenCL C specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_C.html).

## How CUDA would earn a recommendation

Require matched CPU/CUDA/OpenCL input fixtures, the same supported contact quality, pinned toolchains, warmed and cold measurements, and full lifecycle costs. If CUDA wins the actual dominant stage and integrates reliably, recommend NVIDIA for accelerated operation with an exact supported GPU/driver matrix. If HLSL deformation removes the bottleneck while CPU fitting stays cheap, avoid adding a compute dependency merely because it is available.
