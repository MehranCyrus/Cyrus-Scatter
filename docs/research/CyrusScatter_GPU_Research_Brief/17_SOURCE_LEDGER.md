# 17. Master Source Ledger

Every primary source cited across this research package is indexed below with its official URL, version/publication date, license (where applicable), and verification confidence.

---

## 1. Vendor Documentation & Specifications (NVIDIA, Khronos, Microsoft, Autodesk)

| Source ID | Title & Organization | URL | Version / Date Verified | License / Terms | Confidence |
|---|---|---|---|---|---|
| **[SRC-01]** | **NVIDIA CUDA C++ Programming Guide — Graphics Interoperability & Direct3D 11 Interop** | `https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html` and `https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__D3D11.html` | CUDA 12.x / 13.0 Documentation (2025–2026) | NVIDIA Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-02]** | **NVIDIA CUDA Runtime API — External Resource Interoperability (`cudaImportExternalMemory`, `cudaImportExternalSemaphore`)** | `https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__EXTRES__INTEROP.html` | CUDA 12.x / 13.0 Documentation (2025–2026) | NVIDIA Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-03]** | **NVIDIA CUDA Toolkit Release Notes — Driver Version Compatibility & Deprecated Architectures** | `https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html` | CUDA 12.6 / 12.8 / 13.0 Release Notes (2025–2026) | NVIDIA Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-04]** | **NVIDIA CUDA Installation Guide for Microsoft Windows — Visual Studio 2022 (`v143`) Support** | `https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html` | CUDA 12.x / 13.0 (2025–2026) | NVIDIA Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-05]** | **NVIDIA CUDA Toolkit End User License Agreement (EULA) — Attachment A (Redistributable Software)** | `https://docs.nvidia.com/cuda/eula/index.html` | CUDA 12.x / 13.0 EULA (2025–2026) | Proprietary Redistributable License | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-06]** | **NVIDIA CUDA C++ Best Practices Guide & Unified Memory on Windows WDDM (`concurrentManagedAccess`)** | `https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html` | CUDA 12.x / 13.0 (2025–2026) | NVIDIA Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-07]** | **NVIDIA Floating Point and IEEE 754 Compliance for NVIDIA GPUs** | `https://docs.nvidia.com/cuda/floating-point/index.html` | CUDA 12.x / 13.0 (2025–2026) | NVIDIA Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-08]** | **Khronos OpenCL 3.0 Specification & Extension Registry (`cl_khr_d3d11_sharing`, `cl_khr_external_memory`, `cl_khr_subgroups`)** | `https://registry.khronos.org/OpenCL/` | OpenCL 3.0.16+ (2024–2026) | Khronos Specification License | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-09]** | **Microsoft Direct3D 11 Documentation — `D3D11_BUFFER_DESC`, `D3D11_BIND_FLAG`, `D3D11_RESOURCE_MISC_FLAG`, and Windows TDR Registry Keys** | `https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ns-d3d11-d3d11_buffer_desc` and `https://learn.microsoft.com/en-us/windows-hardware/drivers/display/tdr-registry-keys` | Windows SDK `10.0.19041.0`+ (2024–2026) | Microsoft Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-10]** | **Autodesk Developer Blog & Help — What's New in 3ds Max 2027 SDK (MSVC `14.38`, VS 2022 `17.14.x`, C++20, Windows SDK `10.0.19041.0`, Qt `6.8.3`, `.NET 10`)** | `https://blog.autodesk.io/whats-new-in-3ds-max-2027/` and `https://help.autodesk.com/view/MAXDEV/2027/ENU/` | 3ds Max 2027 Release (2026) | Autodesk Documentation | **High (`[VERIFIED-PUBLIC]`)** |
| **[SRC-11]** | **Autodesk 3ds Max Developer Help — `MaxSDK::Graphics` (`IVirtualDevice`, `VertexBufferHandle`, `TextureHandle`, `HLSLMaterialHandle`, `ICustomRenderItem`, `RenderTimeInstancing`)** | `https://help.autodesk.com/view/MAXDEV/ENU/` and historical Low-Level Device API note `https://help.autodesk.com/cloudhelp/2022/ENU/Max-Developer-Help/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/low-level_device_api.html` | 3ds Max 2022–2027 Developer Help | Autodesk Documentation | **High for public class overview; Local 2027 header probe `P1–P2` required for exact 2027 signatures** |

---

## 2. Primary Peer-Reviewed Papers & Technical Reports

| Source ID | Full Citation | URL / DOI | Year | Confidence |
|---|---|---|---|---|
| **[PAP-01]** | Matthias Müller, Bruno Heidelberger, Marcus Hennix, John Ratcliff. *"Position Based Dynamics"*. Journal of Visual Communication and Image Representation 18(2), pp. 109–118. | `https://doi.org/10.1016/j.jvcir.2007.01.005` | 2007 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-02]** | Matthias Müller, Tae-Yong Kim, Nuttapong Chentanez. *"Fast Simulation of Inextensible Hair and Fur"*. Workshop on Virtual Reality Interaction and Physical Simulation (VRIPHYS), pp. 39–44. | `https://matthias-research.github.io/pages/publications/FTLHairFur.pdf` | 2012 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-03]** | Miles Macklin, Matthias Müller, Nuttapong Chentanez. *"XPBD: Position-Based Simulation of Compliant Constrained Dynamics"*. Proc. ACM Motion in Games (MIG), pp. 49–54. | `https://doi.org/10.1145/2994258.2994272` | 2016 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-04]** | Miles Macklin, Kenny Erleben, Matthias Müller, Nuttapong Chentanez, Stefan Jeschke, Viktor Makoviychuk. *"Small Steps in Physics Simulation"*. Proc. ACM SIGGRAPH / Eurographics SCA. | `https://doi.org/10.1145/3309486.3340247` | 2019 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-05]** | Tassilo Kugelstadt, Elmar Schömer. *"Position and Orientation Based Cosserat Rods"*. Proc. ACM SIGGRAPH / Eurographics Symposium on Computer Animation (SCA), pp. 169–178. | `https://doi.org/10.2312/sca.20161234` | 2016 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-06]** | Miklós Bergou, Max Wardetzky, Stephen Robinson, Basile Audoly, Eitan Grinspun. *"Discrete Elastic Rods"*. ACM Transactions on Graphics (SIGGRAPH) 27(3), Article 63. | `https://doi.org/10.1145/1360612.1360662` | 2008 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-07]** | Christoph Deul, Tassilo Kugelstadt, Marcel Weiler, Jan Bender. *"Direct Position-Based Solver for Stiff Rods"*. Computer Graphics Forum 37(6), pp. 313–323. | `https://doi.org/10.1111/cgf.13326` | 2018 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-08]** | Sofien Bouaziz, Sebastian Martin, Tiantian Liu, Ladislav Kavan, Mark Pauly. *"Projective Dynamics: Fusing Constraint Projections for Fast Simulation"*. ACM TOG (SIGGRAPH) 33(4), Article 154. | `https://doi.org/10.1145/2601097.2601116` | 2014 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-09]** | Marco Fratarcangeli, Valentina Tibaldo, Fabio Pellacini. *"Vivace: A Practical Gauss-Seidel Method for Stable Soft Body Dynamics"*. ACM TOG (SIGGRAPH Asia) 35(6), Article 214. | `https://doi.org/10.1145/2980179.2982437` | 2016 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-10]** | Klemens Jahrmann, Michael Wimmer. *"Responsive Real-Time Grass Rendering for General 3D Scenes"*. Proc. ACM Symposium on Interactive 3D Graphics and Games (I3D), Article 6. | `https://doi.org/10.1145/3023368.3023380` | 2017 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-11]** | Tero Karras. *"Maximizing Parallelism in the Construction of BVHs, Octrees, and k-d Trees"*. Proc. High Performance Graphics (HPG), pp. 33–37. | `https://dl.acm.org/doi/10.5555/2383795.2383801` | 2012 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-12]** | Gavin Barill, Neil G. Dickson, Ryan Schmidt, David I.W. Levin, Alec Jacobson. *"Fast Winding Numbers for Soups and Clouds"*. ACM TOG (SIGGRAPH) 37(4), Article 43. | `https://doi.org/10.1145/3197517.3201337` | 2018 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-13]** | Miles Macklin, Kenny Erleben, Matthias Müller, Nuttapong Chentanez, Stefan Jeschke, Zach Corse. *"Local Optimization for Robust Signed Distance Field Collision"*. Proc. ACM Comput. Graph. Interact. Tech. 3(1) (I3D). | `https://doi.org/10.1145/3384538` | 2020 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-14]** | Duane Merrill, Michael Garland. *"Single-pass Parallel Prefix Scan with Decoupled Look-back"*. NVIDIA Technical Report NVR-2016-002. | `https://research.nvidia.com/publication/2016-03_single-pass-parallel-prefix-scan-decoupled-look-back` | 2016 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-15]** | Christer Ericson. *"Real-Time Collision Detection"*. Morgan Kaufmann / Elsevier (§5.1.9 Closest Point on Triangle to Point / Segment-Triangle). | ISBN `978-1558607323` | 2004 | **High (`[VERIFIED-PUBLIC]`)** |
| **[PAP-16]** | J. Andreas Bærentzen, Henrik Aanæs. *"Signed Distance Computation Using the Angle Weighted Pseudonormal"*. IEEE TVCG 11(3), pp. 243–253. | `https://doi.org/10.1109/TVCG.2005.49` | 2005 | **High (`[VERIFIED-PUBLIC]`)** |

---

## 3. Audited Open-Source Repositories

| Source ID | Repository | URL | License (SPDX) | Maintenance Status (2026) | Confidence |
|---|---|---|---|---|---|
| **[REPO-01]** | **NVIDIA CCCL (CUB / Thrust / libcu++)** | `https://github.com/NVIDIA/cccl` | `Apache-2.0 WITH LLVM-exception` | Active (Official CUDA Core Compute Libraries) | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-02]** | **NVIDIA cuBQL (CUDA BVH Build & Query Library)** | `https://github.com/NVIDIA/cuBQL` | `Apache-2.0` | Active | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-03]** | **NVIDIA Warp** | `https://github.com/NVIDIA/warp` | `Apache-2.0` (v1.6.2+) | Active | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-04]** | **AMD GPUOpen TressFX** | `https://github.com/GPUOpen-Effects/TressFX` | `MIT` | Reference (v4.1 / v5.0) | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-05]** | **NVIDIA CUDA Samples** | `https://github.com/NVIDIA/cuda-samples` | `BSD-3-Clause` | Active | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-06]** | **Khronos OpenCL SDK / Headers / ICD Loader** | `https://github.com/KhronosGroup/OpenCL-SDK` | `Apache-2.0` | Active | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-07]** | **Jacco Bikker `tinybvh`** | `https://github.com/jbikker/tinybvh` | `MIT` | Active | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-08]** | **Arsène Pérard-Gayot `madmann91/bvh`** | `https://github.com/madmann91/bvh` | `MIT` | Active | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-09]** | **InteractiveComputerGraphics `PositionBasedDynamics`** | `https://github.com/InteractiveComputerGraphics/PositionBasedDynamics` | `MIT` | Active | **High (`[VERIFIED-PUBLIC]`)** |
| **[REPO-10]** | **ASWF `openvdb` (`NanoVDB`)** | `https://github.com/AcademySoftwareFoundation/openvdb` | `Apache-2.0` | Active | **High (`[VERIFIED-PUBLIC]`)** |
