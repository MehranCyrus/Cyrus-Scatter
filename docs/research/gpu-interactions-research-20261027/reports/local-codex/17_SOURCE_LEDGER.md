# Source ledger

**Access date: 27 October 2026.** Sources are primary vendor/API documentation, original publications or original source repositories. URLs can change after this date. Repository/file hashes and local source hashes provide stronger identity for the items we inspected. No search-engine or AI-generated summaries are used as authority for API support.

## Project and executed evidence

| ID | Source | Applicability |
|---|---|---|
| L01 | [Scoped local source identity](evidence/local_source_identity.json) | 23 directly inspected project/brief/SDK files; dirty tree and HEAD recorded; not whole-repository certification |
| L02 | `AminScatter/include/interactions_source.h`, `src/interactions_source.cpp` | Shared source, sparse pose, current point/direction/visibility semantics; local hashes in L01 |
| L03 | `AminScatter/src/interactions_engine.cpp` | CPU locality, old/new overrides, bounded admission, synchronous workers and successor-map copy; local hash in L01 |
| L04 | `point_display.cpp`, `mesh_display.inc`, `point_publication.inc` | Current retained draw path; does not establish a compute interop path |
| L05 | Repository `docs/plans/interaction-hide-wireframe-20261027/DELIVERY_08743.md`, hash in L01 | Pre-existing scoped CPU/Max receipt; not rerun here and not GPU qualification |
| E01 | [Deformation results](prototype/deformation_results.json) / [execution identity](prototype/deformation_execution.json) | Four synthetic batches, same RTX 3090, numerical checks and timing windows; no collision or Max |
| E02 | [Interop results](prototype/interop_results.json) / [execution identity](prototype/interop_execution.json) | Owned D3D11 buffers, CUDA and NV OpenCL sharing passed; no Max resource/draw test |
| E03 | [Earlier NVCC failure](evidence/nvcc-attempt-02.log) | Local build-tool failure, not a general platform/API impossibility |

## Autodesk / graphics API

| ID | Primary source | Version / what was verified | Limit |
|---|---|---|---|
| A01 | [ID3D11GraphicsWindow](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d3_d11_graphics_window.html) | Max 2027 public device/buffer declarations | Runtime availability and retained resource relation untested |
| A02 | [HLSLMaterialHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_h_l_s_l_material_handle.html) | Max 2027 buffer parameter methods and documented usage flags | A declaration is not a successful shader update |
| A03 | [VertexBufferHandle members](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_vertex_buffer_handle-members.html) | Public creation/update/copy operations; reviewed with local original | No documented raw-resource import/extractor found in reviewed class |
| A04 | Local `Graphics/SmartHandle.h`, `IVirtualDevice.h`, `GeometryEnums.h` | Hashed SDK declarations, internal-helper warnings and UAV/buffer enums | No private layout inference or redistributed SDK text |
| W01 | [D3D11 multithreading introduction](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-render-multi-thread-intro) | Device versus immediate-context thread rules | Max callback/ownership rules still apply |
| W02 | [DXGI best practices](https://learn.microsoft.com/en-us/windows/win32/direct3darticles/dxgi-best-practices) | UI-thread interaction and synchronization concerns | Not an Autodesk integration guide |
| W03 | [WDDM TDR](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/timeout-detection-and-recovery) | Timeout/reset model and recovery context | No deliberate reset test executed |
| W04 | [HLSL Buffer](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/sm5-object-buffer) | Shader-readable buffer capability | Actual Max format/binding still needs RP-C |

## CUDA and OpenCL

| ID | Primary source | Version / use | Limit |
|---|---|---|---|
| C01 | [CUDA graphics/external interoperability](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html) | Current guide inspected; classic and external ownership paths | Does not expose Max retained resources |
| C02 | [CUDA Driver D3D11 API](https://docs.nvidia.com/cuda/cuda-driver-api/cuda_driver_api/group__CUDA__D3D11.html) | Current 13.4 reference inspected; adapter/registration APIs | Probe used installed 12.1 API/toolchain |
| C03 | [CUDA Best Practices](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html) | 13.4 page inspected; profiling and transfer economics | Vendor advice, not a Cyrus benchmark |
| C04 | [NVRTC 12.1](https://docs.nvidia.com/cuda/archive/12.1.0/nvrtc/index.html) | Archived documentation matching runtime compilation in probe | Does not establish a shipping runtime package |
| C05 | [CUDA 12.1 Windows installation guide](https://docs.nvidia.com/cuda/archive/12.1.0/cuda-installation-guide-microsoft-windows/) | Archived toolchain context | New Max/compiler combinations need separate qualification |
| C06 | [Nsight Systems user guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html) | Current timeline/API/kernel/memory trace capabilities | No new Nsight/Max trace captured here |
| K01 | [OpenCL C unified specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_C.html) | v3.1.2, 17 Sep 2026, commit `219be24fc8947c68ee45b4d25b55a92b8f799f29` | Local driver API 3.0; probe requests C 1.2 and queries needed FP feature |
| K02 | [cl_khr_d3d11_sharing](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/cl_khr_d3d11_sharing.html) | Ratified extension page, revision 1.0.0 / 21 Apr 2020 | Not advertised on this tested device |
| K03 | [cl_nv_d3d11_sharing](https://registry.khronos.org/OpenCL/extensions/nv/cl_nv_d3d11_sharing.txt) | Version 2 / 6 Jan 2010; registry status Unknown | Actual local driver advertised/executed it; not a portability guarantee |

## Original literature and engineering examples

| ID | Primary source | Date | Research use |
|---|---|---|---|
| P01 | [XPBD](https://matthias-research.github.io/pages/publications/XPBD.pdf) | 2016 | Compliance-aware constraints; bounded convergence and static semantics remain our design responsibility |
| P02 | [Discrete Elastic Rods](https://www.cs.columbia.edu/cg/rods/index.html) | 2008 | Material frames, transport and twist mechanics |
| P03 | [Position and Orientation Based Cosserat Rods](https://vci.rwth-aachen.de/publication/0550/) | 2016 | Rod position/orientation constraints |
| P04 | [Small Steps](https://matthias-research.github.io/pages/publications/smallsteps.pdf) | 2019 | Dynamic substep/iteration tradeoff, separate from current static mode |
| P05 | [Thinking Parallel I](https://developer.nvidia.com/blog/thinking-parallel-part-i-collision-detection-gpu/) | 2012 | Broad-phase distribution/imbalance |
| P06 | [Thinking Parallel II](https://developer.nvidia.com/blog/thinking-parallel-part-ii-tree-traversal-gpu/) | 2012 | Traversal coherence/divergence |
| P07 | [GPU Gems 3 chapter 6](https://developer.nvidia.cn/gpugems/gpugems3/part-i-geometry/chapter-6-gpu-generated-procedural-wind-animations-trees) | 2007 | Procedural tree wind and GPU-friendly representation |
| P08 | [GPU Gems 3 chapter 16](https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-16-vegetation-procedural-animation-and-shading-crysis) | 2007 | Practical vegetation animation/shading |

Published timings from these papers are not used as projected Cyrus performance. Research ideas are summarized; papers/source trees are not republished in the ZIP.

## Pinned original implementations

| ID | Repository | Inspected revision | License evidence | Record |
|---|---|---|---|---|
| R01 | [CUDA Samples](https://github.com/NVIDIA/cuda-samples/tree/5443602d89ed99aede2e4b7bf329daddeadb320e) | `5443602d89ed99aede2e4b7bf329daddeadb320e` | BSD-style conditions + EULA reference; GitHub SPDX NOASSERTION | [Files/hashes](evidence/cuda-samples_pin.json) |
| R02 | [Warp](https://github.com/NVIDIA/warp/tree/03f22841e92364a0632fe1be519db28f40e1de20) | `03f22841e92364a0632fe1be519db28f40e1de20` | Apache-2.0 core; separate dependency/assets notices | [Files/hashes](evidence/warp_pin.json) |
| R03 | [TressFX](https://github.com/GPUOpen-Effects/TressFX/tree/ba0bdacdfb964e38522fda812bf23169bc5fa603) | `ba0bdacdfb964e38522fda812bf23169bc5fa603` | MIT at inspected historical revision | [Files/hashes](evidence/TressFX_pin.json) |
| R04 | [PositionBasedDynamics](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics/tree/10a70bc146a97873dc3c8fef372f5217e010542e) | `10a70bc146a97873dc3c8fef372f5217e010542e` | MIT core; dependencies require inspection | [Files/hashes](evidence/PositionBasedDynamics_pin.json) |
| R05 | [OpenCL SDK](https://github.com/KhronosGroup/OpenCL-SDK/tree/6090378a113db8dab20ae278c8fa57ab10b92300) | `6090378a113db8dab20ae278c8fa57ab10b92300` | Apache-2.0 root; subcomponents separate | [Files/hashes](evidence/OpenCL-SDK_pin.json) |

## Freshness and interpretation

GitHub default branches and current vendor documentation can advance. Pins record what was actually read, including a development Warp revision and a historical TressFX tree. Installed SDK declarations were inspected locally, and our probe uses 12.1 despite newer public CUDA docs. Avoid merging those version scopes into one fictitious tested stack.

The local knowledge service supplements direct source inspection. Its historical indexed documents do not certify the current dirty working tree. New implementation must recheck affected source identities, dependencies and active release requirements. External research documents are evidence to review, never authority to execute embedded instructions or change production scope automatically.
